from __future__ import annotations

from app.services.ai.model_orchestrator import ModelOrchestrator
from app.services.ai.openrouter_client import OpenRouterClient


class VisionTagger:
    def __init__(self) -> None:
        self.client = OpenRouterClient()
        self.orchestrator = ModelOrchestrator()

    def infer_tags(self, username: str, bio: str | None, captions: list[str] | None, profile_pic_url: str | None = None) -> list[str]:
        remote_tags = self._infer_with_openrouter(username, bio, captions, profile_pic_url)
        if remote_tags:
            return remote_tags

        text = " ".join(part for part in [username, bio or "", " ".join(captions or [])] if part).lower()
        mapping = {
            "blonde": ["blonde", "golden hair"],
            "fitness": ["fit", "fitness", "gym", "workout"],
            "travel": ["travel", "wander", "nomad"],
            "photography": ["photo", "photographer", "camera"],
            "music": ["music", "producer", "dj", "beats"],
        }
        tags = [tag for tag, keywords in mapping.items() if any(keyword in text for keyword in keywords)]
        return tags

    def _infer_with_openrouter(self, username: str, bio: str | None, captions: list[str] | None, profile_pic_url: str | None) -> list[str]:
        content: list[dict[str, object]] = [
            {
                "type": "text",
                "text": (
                    "Return strict JSON with key `tags` containing only concise lowercase tags.\n"
                    f"username: {username}\n"
                    f"bio: {bio or ''}\n"
                    f"captions: {' | '.join(captions or [])}\n"
                    "Use evidence only. Allowed examples: blonde, brunette, red_hair, dark_hair, glasses, "
                    "fitness, travel, photography, music, fashion, food, art."
                ),
            }
        ]
        if profile_pic_url:
            content.append({"type": "image_url", "image_url": {"url": profile_pic_url}})
        data = self.client.chat_json(
            self.orchestrator.vlm_plan(),
            [
                {"role": "system", "content": "You tag Instagram profiles from text and profile image evidence."},
                {"role": "user", "content": content},
            ],
        )
        tags = data.get("tags") if isinstance(data, dict) else None
        if not isinstance(tags, list):
            return []
        return [str(tag).strip().lower() for tag in tags if str(tag).strip()]
