from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Account, ProfileCache
from app.schemas.common import InstagramUserResponse, SearchResultResponse
from app.services.deep_search import DeepSearchAnalyzer
from app.services.embeddings import EmbeddingService
from app.services.graph_engine import GraphEngine
from app.services.query_router import QueryRouter


class SearchService:
    def __init__(self) -> None:
        self.router = QueryRouter()
        self.embeddings = EmbeddingService()
        self.graph_engine = GraphEngine()
        self.deep_search = DeepSearchAnalyzer()

    def search(self, db: Session, account: Account, query: str, scope: str) -> list[SearchResultResponse]:
        intent = self.router.classify(query)
        candidate_ids: set[str] | None = None

        if intent.graph_filter == "non_mutuals":
            candidate_ids = {user.id for user in self.graph_engine.non_mutuals(db, account)}
        elif intent.graph_filter == "mutuals":
            candidate_ids = {user.id for user in self.graph_engine.mutuals(db, account)}

        rows = db.scalars(select(ProfileCache).where(ProfileCache.owner_account_id == account.id)).all()
        if scope == "followers":
            follower_ids = {user.id for user in self.graph_engine.followers(db, account)}
            rows = [row for row in rows if row.instagram_user_id in follower_ids]
        if candidate_ids is not None:
            rows = [row for row in rows if row.instagram_user_id in candidate_ids]
        if intent.tags:
            tagged_rows = [row for row in rows if set(intent.tags).intersection(set(row.tags or []))]
            if tagged_rows:
                rows = tagged_rows

        query_embedding = self.embeddings.embed_text(intent.semantic_query or query)
        results: list[SearchResultResponse] = []
        lowered = query.lower()
        row_by_id: dict[str, ProfileCache] = {}

        for row in rows:
            row_by_id[row.instagram_user_id] = row
            haystack = " ".join(filter(None, [row.username, row.full_name or "", row.bio or "", " ".join(row.tags or []), " ".join(row.captions or [])])).lower()
            tag_bonus = 0.25 if any(token in haystack for token in lowered.split()) else 0.0
            score = self.embeddings.cosine_similarity(query_embedding, row.embedding) + tag_bonus
            if score <= 0 and lowered not in haystack:
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
                    score=round(score, 4),
                    match_type="hybrid" if intent.graph_filter and intent.semantic_query else ("graph" if intent.graph_filter else "semantic"),
                    tags=row.tags or [],
                )
            )

        results.sort(key=lambda item: item.score or 0.0, reverse=True)
        deep_candidates = [row_by_id[result.id] for result in results[:8] if result.id in row_by_id]
        deep_scores = self.deep_search.rerank(account, query, deep_candidates)
        if deep_scores:
            reranked_results: list[SearchResultResponse] = []
            for result in results:
                deep = deep_scores.get(result.id)
                if deep:
                    deep_score, deep_tags = deep
                    merged_tags = list(dict.fromkeys((result.tags or []) + deep_tags))
                    reranked_results.append(
                        SearchResultResponse(
                            id=result.id,
                            user=result.user,
                            score=round(((result.score or 0.0) * 0.4) + (deep_score * 0.6), 4),
                            match_type=result.match_type,
                            tags=merged_tags,
                        )
                    )
                else:
                    reranked_results.append(result)
            results = sorted(reranked_results, key=lambda item: item.score or 0.0, reverse=True)
        return results[:50]
