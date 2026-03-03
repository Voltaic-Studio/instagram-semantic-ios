from __future__ import annotations

from dataclasses import dataclass

from app.services.model_orchestrator import ModelOrchestrator
from app.services.openrouter_client import OpenRouterClient


@dataclass
class QueryIntent:
    graph_filter: str | None = None
    semantic_query: str | None = None
    tags: list[str] | None = None


class QueryRouter:
    def __init__(self) -> None:
        self.client = OpenRouterClient()
        self.orchestrator = ModelOrchestrator()

    def classify(self, query: str) -> QueryIntent:
        remote_intent = self._classify_with_openrouter(query)
        if remote_intent is not None:
            return remote_intent

        lowered = query.lower().strip()
        graph_filter = None
        if "don't follow me back" in lowered or "dont follow me back" in lowered or "non mutual" in lowered:
            graph_filter = "non_mutuals"
        elif "mutual" in lowered:
            graph_filter = "mutuals"

        semantic_query = None
        semantic_tokens = [token for token in ["blonde", "fitness", "travel", "photography", "music"] if token in lowered]
        if semantic_tokens or graph_filter is None:
            semantic_query = lowered

        return QueryIntent(graph_filter=graph_filter, semantic_query=semantic_query, tags=semantic_tokens or None)

    def _classify_with_openrouter(self, query: str) -> QueryIntent | None:
        data = self.client.chat_json(
            self.orchestrator.classify_plan(),
            [
                {
                    "role": "system",
                    "content": (
                        "Return strict JSON with keys graph_filter, semantic_query, tags. "
                        "graph_filter must be null, mutuals, or non_mutuals. "
                        "tags must be an array of lowercase attribute or interest tags."
                    ),
                },
                {"role": "user", "content": query},
            ],
        )
        if not isinstance(data, dict):
            return None
        tags = data.get("tags")
        return QueryIntent(
            graph_filter=data.get("graph_filter") if data.get("graph_filter") in {None, "mutuals", "non_mutuals"} else None,
            semantic_query=data.get("semantic_query") if isinstance(data.get("semantic_query"), str) else None,
            tags=[str(tag).strip().lower() for tag in tags] if isinstance(tags, list) else None,
        )
