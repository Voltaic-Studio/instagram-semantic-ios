from __future__ import annotations

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.db.models import Account, ProfileCache, Relationship
from app.services.instagram_client import InstagramProfile


class AccountStore:
    def upsert_account(
        self,
        db: Session,
        profile: InstagramProfile,
        encrypted_settings: str,
        encrypted_sessionid: str | None,
    ) -> Account:
        account = db.scalar(select(Account).where(Account.instagram_user_id == profile.id))
        if account is None:
            account = Account(
                instagram_user_id=profile.id,
                username=profile.username,
                full_name=profile.full_name,
                profile_pic_url=profile.profile_pic_url,
                bio=profile.bio,
                follower_count=profile.follower_count,
                following_count=profile.following_count,
                is_private=profile.is_private,
                is_verified=profile.is_verified,
                encrypted_settings=encrypted_settings,
                encrypted_sessionid=encrypted_sessionid,
            )
            db.add(account)
        else:
            account.username = profile.username
            account.full_name = profile.full_name
            account.profile_pic_url = profile.profile_pic_url
            account.bio = profile.bio
            account.follower_count = profile.follower_count
            account.following_count = profile.following_count
            account.is_private = profile.is_private
            account.is_verified = profile.is_verified
            account.encrypted_settings = encrypted_settings
            account.encrypted_sessionid = encrypted_sessionid
        db.flush()
        return account

    def replace_relationships(self, db: Session, account: Account, relationship_type: str, users: list[InstagramProfile]) -> None:
        db.execute(
            delete(Relationship).where(
                Relationship.owner_account_id == account.id,
                Relationship.relationship_type == relationship_type,
            )
        )
        for user in users:
            db.add(
                Relationship(
                    owner_account_id=account.id,
                    target_instagram_user_id=user.id,
                    username=user.username,
                    full_name=user.full_name,
                    profile_pic_url=user.profile_pic_url,
                    relationship_type=relationship_type,
                )
            )

    def upsert_profiles(self, db: Session, account: Account, profiles: list[InstagramProfile], captions_by_user: dict[str, list[str]] | None = None, tags_by_user: dict[str, list[str]] | None = None, embeddings_by_user: dict[str, list[float]] | None = None) -> None:
        captions_by_user = captions_by_user or {}
        tags_by_user = tags_by_user or {}
        embeddings_by_user = embeddings_by_user or {}

        existing = {
            row.instagram_user_id: row
            for row in db.scalars(select(ProfileCache).where(ProfileCache.owner_account_id == account.id)).all()
        }
        for profile in profiles:
            row = existing.get(profile.id)
            if row is None:
                row = ProfileCache(owner_account_id=account.id, instagram_user_id=profile.id, username=profile.username)
                db.add(row)
            row.username = profile.username
            row.full_name = profile.full_name
            row.profile_pic_url = profile.profile_pic_url
            row.bio = profile.bio
            row.follower_count = profile.follower_count
            row.following_count = profile.following_count
            row.is_private = profile.is_private
            row.is_verified = profile.is_verified
            row.captions = captions_by_user.get(profile.id)
            row.tags = tags_by_user.get(profile.id)
            row.embedding = embeddings_by_user.get(profile.id)

