from __future__ import annotations

from app.db.models import Account, ProfileCache
from app.services.instagram_client import InstagramClientService
from app.services.model_orchestrator import ModelOrchestrator
from app.services.openrouter_client import OpenRouterClient


class DeepSearchAnalyzer:
    def __init__(self) -> None:
        self.instagram = InstagramClientService()
        self.client = OpenRouterClient()
        self.orchestrator = ModelOrchestrator()
        self.disallowed_terms = {"boobs", "big boobs", "tits", "breasts", "rack"}

    def rerank(self, account: Account, query: str, candidates: list[ProfileCache]) -> dict[str, tuple[float, list[str]]]:
        lowered = query.lower()
        if any(term in lowered for term in self.disallowed_terms):
            return {}
        if not self.client.enabled:
            return {}

        instagram_client = self.instagram.get_client_from_settings(account.encrypted_settings)
        reranked: dict[str, tuple[float, list[str]]] = {}

        for candidate in candidates[:8]:
            context = self.instagram.fetch_candidate_context(instagram_client, candidate.instagram_user_id)
            score, tags = self._score_candidate(query, candidate, context)
            reranked[candidate.instagram_user_id] = (score, tags)

        return reranked

    def _score_candidate(self, query: str, candidate: ProfileCache, context: dict[str, list[str]]) -> tuple[float, list[str]]:
        content: list[dict[str, object]] = [
            {
                "type": "text",
                "text": (
                    "Return strict JSON with keys score (0 to 1 float) and tags (array of lowercase tags).\n"
                    f"query: {query}\n"
                    f"username: {candidate.username}\n"
                    f"full_name: {candidate.full_name or ''}\n"
                    f"bio: {candidate.bio or ''}\n"
                    f"cached_tags: {' | '.join(candidate.tags or [])}\n"
                    f"recent_captions: {' | '.join(context.get('captions', []))}\n"
                    "Use visible profile/post/story evidence only. Focus on non-sensitive style, appearance, and interests."
                ),
            }
        ]

        for image_url in (context.get("image_urls", []) + context.get("story_urls", []))[:6]:
            content.append({"type": "image_url", "image_url": {"url": image_url}})

        data = self.client.chat_json(
            self.orchestrator.vlm_plan(),
            [
                {"role": "system", "content": "You rerank Instagram search candidates using visible profile, post, and story evidence."},
                {"role": "user", "content": content},
            ],
        )
        if not isinstance(data, dict):
            return 0.0, []

        score = data.get("score")
        tags = data.get("tags")
        parsed_score = max(0.0, min(float(score), 1.0)) if isinstance(score, (int, float)) else 0.0
        parsed_tags = [str(tag).strip().lower() for tag in tags] if isinstance(tags, list) else []
        return parsed_score, parsed_tags
