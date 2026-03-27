from __future__ import annotations

from dataclasses import dataclass

from app.config import get_settings


@dataclass(frozen=True)
class ModelPlan:
    classifier_model: str
    embedding_model: str
    vlm_model: str
    text_model: str


class ModelOrchestrator:
    def __init__(self) -> None:
        settings = get_settings()
        self.plan = ModelPlan(
            classifier_model=settings.openrouter_classifier_model,
            embedding_model=settings.openrouter_embedding_model,
            vlm_model=settings.openrouter_vlm_model,
            text_model=settings.openrouter_text_model,
        )

    def classify_plan(self) -> str:
        return self.plan.classifier_model

    def embedding_plan(self) -> str:
        return self.plan.embedding_model

    def vlm_plan(self) -> str:
        return self.plan.vlm_model

    def text_plan(self) -> str:
        return self.plan.text_model
