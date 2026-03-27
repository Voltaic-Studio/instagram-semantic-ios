from __future__ import annotations

import logging
from time import perf_counter

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Account, ProfileCache, Relationship
from app.schemas.common import InstagramUserResponse, SearchResultResponse
from app.services.ai.embeddings import EmbeddingService
from app.services.graph.graph_engine import GraphEngine
from app.services.search.deep_search import DeepSearchAnalyzer
from app.services.search.query_router import QueryRouter


logger = logging.getLogger(__name__)


class SearchService:
    def __init__(self) -> None:
        self.router = QueryRouter()
        self.graph_engine = GraphEngine()
        self.deep_search = DeepSearchAnalyzer()
        self.embedding_service = EmbeddingService()

    def search(self, db: Session, account: Account, query: str, scope: str) -> list[SearchResultResponse]:
        started_at = perf_counter()
        intent = self.router.classify(query)
        candidate_ids: set[str] | None = None
        effective_scope = intent.audience_scope or scope or "following"

        if intent.graph_filter == "non_mutuals":
            candidate_ids = {user.id for user in self.graph_engine.non_mutuals(db, account)}
        elif intent.graph_filter == "mutuals":
            candidate_ids = {user.id for user in self.graph_engine.mutuals(db, account)}

        rows_query = select(ProfileCache).where(ProfileCache.owner_account_id == account.id)
        if effective_scope == "followers":
            rows_query = rows_query.join(
                Relationship,
                (Relationship.owner_account_id == ProfileCache.owner_account_id)
                & (Relationship.target_instagram_user_id == ProfileCache.instagram_user_id),
            ).where(Relationship.relationship_type == "follower")
        elif effective_scope == "following":
            rows_query = rows_query.join(
                Relationship,
                (Relationship.owner_account_id == ProfileCache.owner_account_id)
                & (Relationship.target_instagram_user_id == ProfileCache.instagram_user_id),
            ).where(Relationship.relationship_type == "following")
        rows = db.scalars(rows_query).all()
        if candidate_ids is not None:
            rows = [row for row in rows if row.instagram_user_id in candidate_ids]
        if intent.tags:
            tagged_rows = [row for row in rows if set(intent.tags).intersection(set(row.tags or []))]
            if tagged_rows:
                rows = tagged_rows
        logger.info(
            "semantic search prescreen owner=%s scope=%s graph_filter=%s rows=%s query=%r",
            account.id,
            effective_scope,
            intent.graph_filter,
            len(rows),
            query,
        )

        results: list[SearchResultResponse] = []
        query_text = (intent.semantic_query or query).lower().strip()
        query_tokens = [token for token in query_text.replace("-", " ").split() if token]
        query_embedding = self.embedding_service.embed_text(query_text) if query_text else None
        row_by_id: dict[str, ProfileCache] = {}

        for row in rows:
            row_by_id[row.instagram_user_id] = row
            score = self._prescreen_score(row, query_text, query_tokens, intent.tags or [], query_embedding)
            if score <= 0:
                continue
            results.append(
                SearchResultResponse(
                    id=row.instagram_user_id,
                    user=InstagramUserResponse(
                        id=row.instagram_user_id,
                        username=row.username,
                        full_name=row.full_name or row.username,
                        profile_pic_url=row.profile_pic_url or "",
                        bio=row.bio,
                        follower_count=row.follower_count,
                        following_count=row.following_count,
                        is_private=row.is_private,
                        is_verified=row.is_verified,
                    ),
                    score=self._normalize_score(score),
                    match_type="hybrid" if intent.graph_filter and intent.semantic_query else ("graph" if intent.graph_filter else "semantic"),
                    tags=row.tags or [],
                )
            )

        results.sort(key=lambda item: item.score or 0.0, reverse=True)
        if not results and rows:
            fallback_rows = rows[: min(8, len(rows))]
            results = [
                SearchResultResponse(
                    id=row.instagram_user_id,
                    user=InstagramUserResponse(
                        id=row.instagram_user_id,
                        username=row.username,
                        full_name=row.full_name or row.username,
                        profile_pic_url=row.profile_pic_url or "",
                        bio=row.bio,
                        follower_count=row.follower_count,
                        following_count=row.following_count,
                        is_private=row.is_private,
                        is_verified=row.is_verified,
                    ),
                    score=0.05,
                    match_type="semantic",
                    tags=row.tags or [],
                )
                for row in fallback_rows
            ]
        results = sorted(results, key=lambda item: item.score or 0.0, reverse=True)[:24]
        deep_candidates = [row_by_id[result.id] for result in results if result.id in row_by_id]
        deep_started_at = perf_counter()
        deep_scores = self.deep_search.rerank(account, query, deep_candidates)
        logger.info(
            "semantic search rerank owner=%s candidates=%s duration_ms=%s",
            account.id,
            len(deep_candidates),
            int((perf_counter() - deep_started_at) * 1000),
        )
        if deep_scores:
            reranked_results: list[SearchResultResponse] = []
            visual_query = self.deep_search.is_visual_query(query)
            for result in results:
                deep = deep_scores.get(result.id)
                if deep:
                    deep_score, deep_tags = deep
                    if visual_query and deep_score <= 0:
                        continue
                    merged_tags = list(dict.fromkeys((result.tags or []) + deep_tags))
                    reranked_results.append(
                        SearchResultResponse(
                            id=result.id,
                            user=result.user,
                            score=self._normalize_score(((result.score or 0.0) * 0.4) + (deep_score * 0.6)),
                            match_type=result.match_type,
                            tags=merged_tags,
                        )
                    )
                else:
                    if not visual_query:
                        reranked_results.append(result)
            results = sorted(reranked_results, key=lambda item: item.score or 0.0, reverse=True)
        final_results = results[:50]
        logger.info(
            "semantic search complete owner=%s results=%s duration_ms=%s",
            account.id,
            len(final_results),
            int((perf_counter() - started_at) * 1000),
        )
        return final_results

    def _prescreen_score(
        self,
        row: ProfileCache,
        query_text: str,
        query_tokens: list[str],
        intent_tags: list[str],
        query_embedding: list[float] | None,
    ) -> float:
        text_parts = [
            row.username,
            row.full_name or "",
            row.bio or "",
            " ".join(row.tags or []),
            " ".join(row.captions or []),
        ]
        haystack = " ".join(part for part in text_parts if part).lower()
        row_tags = {tag.lower() for tag in (row.tags or [])}

        score = 0.0
        if query_embedding and row.embedding:
            score += max(0.0, self.embedding_service.cosine_similarity(query_embedding, row.embedding)) * 1.6
        if query_text and query_text in haystack:
            score += 0.8

        for token in query_tokens:
            if token in row_tags:
                score += 0.55
            elif token in haystack:
                score += 0.18

        for tag in intent_tags:
            if tag in row_tags:
                score += 0.9

        if row.bio and any(token in row.bio.lower() for token in query_tokens):
            score += 0.12
        if row.captions and any(token in " ".join(row.captions).lower() for token in query_tokens):
            score += 0.12

        return score

    def _normalize_score(self, score: float) -> float:
        return round(max(0.0, min(score, 1.0)), 4)
