from __future__ import annotations

import json
from typing import Any

import httpx

from app.config import get_settings


class OpenRouterClient:
    def __init__(self) -> None:
        self.settings = get_settings()

    @property
    def enabled(self) -> bool:
        return bool(self.settings.openrouter_api_key)

    def embed_text(self, text: str) -> list[float] | None:
        if not self.enabled:
            return None
        payload = {"model": self.settings.openrouter_embedding_model, "input": text}
        data = self._post("/embeddings", payload)
        items = data.get("data") or []
        if not items:
            return None
        return items[0].get("embedding")

    def chat_json(self, model: str, messages: list[dict[str, Any]]) -> dict[str, Any] | None:
        if not self.enabled:
            return None
        payload = {
            "model": model,
            "messages": messages,
            "response_format": {"type": "json_object"},
        }
        data = self._post("/chat/completions", payload)
        try:
            content = data["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError):
            return None
        if not isinstance(content, str):
            return None
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return None

    def _post(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        headers = {
            "Authorization": f"Bearer {self.settings.openrouter_api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": self.settings.openrouter_site_url or self.settings.public_base_url,
            "X-Title": self.settings.openrouter_app_name,
        }
        with httpx.Client(timeout=45.0) as client:
            response = client.post(f"{self.settings.openrouter_base_url}{path}", headers=headers, json=payload)
            response.raise_for_status()
            return response.json()

