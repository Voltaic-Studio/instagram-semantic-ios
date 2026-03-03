from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
import logging

from app.db.models import Account, ProfileCache
from app.services.model_orchestrator import ModelOrchestrator
from app.services.openrouter_client import OpenRouterClient


logger = logging.getLogger(__name__)


class DeepSearchAnalyzer:
    def __init__(self) -> None:
        self.client = OpenRouterClient()
        self.orchestrator = ModelOrchestrator()
        self.disallowed_terms = {"boobs", "big boobs", "tits", "breasts", "rack"}
        self.visual_terms = {
            "blonde",
            "brunette",
            "red hair",
            "dark hair",
            "hair",
            "glasses",
            "tattoos",
            "tattoo",
            "beard",
            "mustache",
            "tall",
            "short",
            "blue eyes",
            "green eyes",
            "brown eyes",
            "girl",
            "girls",
            "boy",
            "boys",
            "guy",
            "guys",
            "man",
            "men",
            "woman",
            "women",
        }

    def rerank(self, account: Account, query: str, candidates: list[ProfileCache]) -> dict[str, tuple[float, list[str]]]:
        lowered = query.lower()
        if any(term in lowered for term in self.disallowed_terms):
            return {}
        if not self.client.enabled:
            return {}
        reranked: dict[str, tuple[float, list[str]]] = {}
        shortlisted = candidates
        if not shortlisted:
            return reranked

        with ThreadPoolExecutor(max_workers=min(6, len(shortlisted))) as executor:
            futures = {
                executor.submit(self._score_candidate, query, candidate): candidate.instagram_user_id
                for candidate in shortlisted
            }
            for future in as_completed(futures):
                candidate_id = futures[future]
                try:
                    reranked[candidate_id] = future.result()
                except Exception as exc:
                    logger.warning("deep search rerank failed for %s: %s", candidate_id, exc)

        return reranked

    def _score_candidate(self, query: str, candidate: ProfileCache) -> tuple[float, list[str]]:
        content: list[dict[str, object]] = [
            {
                "type": "text",
                "text": (
                    "Return strict JSON with keys score (0 to 1 float), tags (array of lowercase tags), "
                    "and matches_query (boolean).\n"
                    f"query: {query}\n"
                    f"username: {candidate.username}\n"
                    f"full_name: {candidate.full_name or ''}\n"
                    f"bio: {candidate.bio or ''}\n"
                    f"cached_tags: {' | '.join(candidate.tags or [])}\n"
                    f"recent_captions: {' | '.join(candidate.captions or [])}\n"
                    "Use the visible profile image plus cached bio/caption evidence only. "
                    "Focus on non-sensitive style, appearance, and interests. "
                    "If this is a visual/physical query, set matches_query to true only if the profile image clearly matches. "
                    "If the image is ambiguous or insufficient for a visual/physical query, set matches_query to false."
                ),
            }
        ]

        if candidate.profile_pic_url:
            content.append({"type": "image_url", "image_url": {"url": candidate.profile_pic_url}})

        data = self.client.chat_json(
            self.orchestrator.vlm_plan(),
            [
                {"role": "system", "content": "You rerank Instagram search candidates using visible profile image and cached text evidence."},
                {"role": "user", "content": content},
            ],
        )
        if not isinstance(data, dict):
            return 0.0, []

        if self._is_visual_query(query) and not bool(data.get("matches_query")):
            return 0.0, []

        score = data.get("score")
        tags = data.get("tags")
        parsed_score = max(0.0, min(float(score), 1.0)) if isinstance(score, (int, float)) else 0.0
        parsed_tags = [str(tag).strip().lower() for tag in tags] if isinstance(tags, list) else []
        return parsed_score, parsed_tags

    def _is_visual_query(self, query: str) -> bool:
        lowered = query.lower()
        return any(term in lowered for term in self.visual_terms)

    def is_visual_query(self, query: str) -> bool:
        return self._is_visual_query(query)
