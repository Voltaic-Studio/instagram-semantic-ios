from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.models import Account, ProfileCache, Relationship
from app.schemas.common import InstagramUserResponse, ProfileStatsResponse


class GraphEngine:
    def _list(self, db: Session, account: Account, relationship_type: str) -> list[Relationship]:
        return db.scalars(
            select(Relationship)
            .where(Relationship.owner_account_id == account.id, Relationship.relationship_type == relationship_type)
            .order_by(Relationship.username.asc())
        ).all()

    def followers(self, db: Session, account: Account) -> list[InstagramUserResponse]:
        follower_rows = self._list(db, account, "follower")
        following_ids = {row.target_instagram_user_id for row in self._list(db, account, "following")}
        return [self._to_user(db, account, row, follows_back=row.target_instagram_user_id in following_ids) for row in follower_rows]

    def following(self, db: Session, account: Account) -> list[InstagramUserResponse]:
        follower_ids = {row.target_instagram_user_id for row in self._list(db, account, "follower")}
        return [self._to_user(db, account, row, follows_back=row.target_instagram_user_id in follower_ids) for row in self._list(db, account, "following")]

    def mutuals(self, db: Session, account: Account) -> list[InstagramUserResponse]:
        followers = {row.target_instagram_user_id: row for row in self._list(db, account, "follower")}
        following = {row.target_instagram_user_id: row for row in self._list(db, account, "following")}
        return [self._to_user(db, account, followers[user_id], follows_back=True) for user_id in sorted(set(followers) & set(following), key=lambda item: followers[item].username)]

    def non_mutuals(self, db: Session, account: Account) -> list[InstagramUserResponse]:
        followers = {row.target_instagram_user_id for row in self._list(db, account, "follower")}
        following = {row.target_instagram_user_id: row for row in self._list(db, account, "following")}
        return [self._to_user(db, account, row, follows_back=False) for user_id, row in sorted(following.items(), key=lambda item: item[1].username) if user_id not in followers]

    def stats(self, db: Session, account: Account) -> ProfileStatsResponse:
        followers = self._list(db, account, "follower")
        following = self._list(db, account, "following")
        follower_ids = {row.target_instagram_user_id for row in followers}
        following_ids = {row.target_instagram_user_id for row in following}
        return ProfileStatsResponse(
            followers=len(followers),
            following=len(following),
            mutuals=len(follower_ids & following_ids),
            non_mutuals=len(following_ids - follower_ids),
            profile_views=None,
        )

    def _to_user(self, db: Session, account: Account, row: Relationship, *, follows_back: bool | None) -> InstagramUserResponse:
        cached_profile = db.scalar(
            select(ProfileCache).where(
                ProfileCache.owner_account_id == account.id,
                ProfileCache.instagram_user_id == row.target_instagram_user_id,
            )
        )
        return InstagramUserResponse(
            id=row.target_instagram_user_id,
            username=row.username,
            full_name=row.full_name or row.username,
            profile_pic_url=row.profile_pic_url or "",
            bio=cached_profile.bio if cached_profile else None,
            follower_count=cached_profile.follower_count if cached_profile else None,
            following_count=cached_profile.following_count if cached_profile else None,
            is_private=cached_profile.is_private if cached_profile else None,
            is_verified=cached_profile.is_verified if cached_profile else None,
            follows_back=follows_back,
        )
