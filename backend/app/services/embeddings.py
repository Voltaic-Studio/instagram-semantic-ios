from __future__ import annotations

import math
import re

from app.services.openrouter_client import OpenRouterClient


class EmbeddingService:
    def __init__(self) -> None:
        self.client = OpenRouterClient()

    def embed_text(self, text: str) -> list[float]:
        remote_embedding = self.client.embed_text(text)
        if remote_embedding:
            return [float(value) for value in remote_embedding]

        tokens = re.findall(r"[a-z0-9]+", text.lower())
        if not tokens:
            return [0.0, 0.0, 0.0]
        vowels = sum(sum(1 for char in token if char in "aeiou") for token in tokens)
        average_len = sum(len(token) for token in tokens) / len(tokens)
        diversity = len(set(tokens)) / len(tokens)
        return [float(len(tokens)), float(vowels), float(average_len * diversity)]

    def cosine_similarity(self, left: list[float] | None, right: list[float] | None) -> float:
        if not left or not right:
            return 0.0
        numerator = sum(a * b for a, b in zip(left, right))
        left_norm = math.sqrt(sum(a * a for a in left))
        right_norm = math.sqrt(sum(b * b for b in right))
        if not left_norm or not right_norm:
            return 0.0
        return numerator / (left_norm * right_norm)
