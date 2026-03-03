from __future__ import annotations

import time

from app.db.models import Account
from app.services.account_store import AccountStore
from app.services.embeddings import EmbeddingService
from app.services.instagram_client import InstagramClientService, InstagramProfile
from app.services.vlm import VisionTagger


class EnrichmentService:
    def __init__(self) -> None:
        self.embedding_service = EmbeddingService()
        self.vision_tagger = VisionTagger()
        self.store = AccountStore()

    def enrich_profiles(
        self,
        db,
        account: Account,
        instagram_client: InstagramClientService,
        profiles: list[InstagramProfile],
        *,
        max_profiles: int = 50,
        throttle_seconds: float = 0.2,
    ) -> None:
        client = instagram_client.get_client_from_settings(account.encrypted_settings)
        captions_by_user: dict[str, list[str]] = {}
        tags_by_user: dict[str, list[str]] = {}
        embeddings_by_user: dict[str, list[float]] = {}

        for index, profile in enumerate(profiles[:max_profiles]):
            captions = instagram_client.fetch_recent_captions(client, profile.id)
            tags = self.vision_tagger.infer_tags(profile.username, profile.bio, captions, profile.profile_pic_url)
            text_blob = " ".join(filter(None, [profile.username, profile.full_name, profile.bio or "", " ".join(captions)]))
            captions_by_user[profile.id] = captions
            tags_by_user[profile.id] = tags
            embeddings_by_user[profile.id] = self.embedding_service.embed_text(text_blob)
            if throttle_seconds > 0 and index < max_profiles - 1:
                time.sleep(throttle_seconds)

        self.store.upsert_profiles(
            db,
            account=account,
            profiles=profiles,
            captions_by_user=captions_by_user,
            tags_by_user=tags_by_user,
            embeddings_by_user=embeddings_by_user,
        )
