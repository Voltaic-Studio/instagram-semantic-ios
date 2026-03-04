from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any

from app.config import get_settings
from app.services.auth.crypto import xor_decrypt, xor_encrypt

try:
    from instagrapi import Client
    from instagrapi.exceptions import LoginRequired, TwoFactorRequired
except Exception:  # pragma: no cover
    Client = None
    LoginRequired = Exception
    TwoFactorRequired = Exception


settings = get_settings()


@dataclass
class InstagramProfile:
    id: str
    username: str
    full_name: str
    profile_pic_url: str
    bio: str | None
    follower_count: int | None
    following_count: int | None
    is_private: bool | None
    is_verified: bool | None


class InstagramAuthError(Exception):
    pass


class InstagramTwoFactorRequired(InstagramAuthError):
    pass


class InstagramClientService:
    def __init__(self) -> None:
        if Client is None:
            raise RuntimeError("instagrapi is not installed")

    def login(self, username: str, password: str, two_factor_code: str | None = None) -> tuple[dict[str, Any], InstagramProfile]:
        client = Client()
        try:
            if two_factor_code:
                client.login(username=username, password=password, verification_code=two_factor_code)
            else:
                client.login(username=username, password=password)
        except TwoFactorRequired as exc:
            raise InstagramTwoFactorRequired("Two-factor code required") from exc
        except Exception as exc:
            raise InstagramAuthError(str(exc)) from exc

        user_info = client.account_info()
        return client.get_settings(), self._to_profile(user_info)

    def get_client_from_settings(self, encrypted_settings: str):
        client = Client()
        settings_json = xor_decrypt(encrypted_settings, settings.session_encryption_key)
        client.set_settings(json.loads(settings_json))
        try:
            client.get_timeline_feed()
        except LoginRequired as exc:
            raise InstagramAuthError("Instagram session expired") from exc
        return client

    def serialize_settings(self, settings_payload: dict[str, Any]) -> str:
        return xor_encrypt(json.dumps(settings_payload), settings.session_encryption_key)

    def serialize_sessionid(self, sessionid: str | None) -> str | None:
        if not sessionid:
            return None
        return xor_encrypt(sessionid, settings.session_encryption_key)

    def fetch_followers(self, client, user_id: str) -> list[InstagramProfile]:
        users = client.user_followers(user_id, amount=0)
        return [self._to_profile(user) for user in users.values()]

    def fetch_following(self, client, user_id: str) -> list[InstagramProfile]:
        users = client.user_following(user_id, amount=0)
        return [self._to_profile(user) for user in users.values()]

    def fetch_user_info(self, client, user_id: str) -> InstagramProfile:
        return self._to_profile(client.user_info(user_id))

    def fetch_user_info_by_username(self, client, username: str) -> InstagramProfile:
        return self._to_profile(client.user_info_by_username(username))

    def search_followers(self, client, user_id: str, query: str) -> list[InstagramProfile]:
        users = client.search_followers(user_id, query)
        return [self._to_profile(user) for user in users]

    def search_following(self, client, user_id: str, query: str) -> list[InstagramProfile]:
        users = client.search_following(user_id, query)
        return [self._to_profile(user) for user in users]

    def fetch_recent_captions(self, client, user_id: str, amount: int = 6) -> list[str]:
        captions: list[str] = []
        try:
            medias = client.user_medias(user_id, amount=amount)
        except Exception:
            return captions
        for media in medias:
            if media.caption_text:
                captions.append(media.caption_text)
        return captions

    def fetch_candidate_context(self, client, user_id: str, media_amount: int = 6, story_amount: int = 3) -> dict[str, list[str]]:
        captions: list[str] = []
        image_urls: list[str] = []
        story_urls: list[str] = []

        try:
            medias = client.user_medias(user_id, amount=media_amount)
        except Exception:
            medias = []

        for media in medias:
            caption_text = getattr(media, "caption_text", None)
            if caption_text:
                captions.append(str(caption_text))
            media_url = self._extract_media_url(media)
            if media_url:
                image_urls.append(media_url)

        try:
            stories = client.user_stories(user_id)
        except Exception:
            stories = []

        for story in stories[:story_amount]:
            story_url = self._extract_media_url(story)
            if story_url:
                story_urls.append(story_url)

        return {
            "captions": captions,
            "image_urls": image_urls[:media_amount],
            "story_urls": story_urls[:story_amount],
        }

    def _extract_media_url(self, media: Any) -> str | None:
        direct_fields = [
            getattr(media, "thumbnail_url", None),
            getattr(media, "thumbnail_url_hd", None),
            getattr(media, "photo_url", None),
        ]
        for field in direct_fields:
            if field:
                return str(field)

        image_versions = getattr(media, "image_versions2", None)
        candidates = getattr(image_versions, "candidates", None) if image_versions else None
        if candidates:
            first = candidates[0]
            candidate_url = getattr(first, "url", None)
            if candidate_url:
                return str(candidate_url)
        return None

    def _to_profile(self, user: Any) -> InstagramProfile:
        raw_profile_pic_url = getattr(user, "profile_pic_url", "") or ""
        return InstagramProfile(
            id=str(getattr(user, "pk", getattr(user, "id", ""))),
            username=getattr(user, "username", ""),
            full_name=getattr(user, "full_name", "") or getattr(user, "fullName", "") or "",
            profile_pic_url=str(raw_profile_pic_url),
            bio=getattr(user, "biography", None) or getattr(user, "bio", None),
            follower_count=getattr(user, "follower_count", None),
            following_count=getattr(user, "following_count", None),
            is_private=getattr(user, "is_private", None),
            is_verified=getattr(user, "is_verified", None),
        )
