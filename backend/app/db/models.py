from __future__ import annotations

from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    instagram_user_id: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    username: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    profile_pic_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    follower_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    following_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_private: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    is_verified: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    encrypted_settings: Mapped[str] = mapped_column(Text)
    encrypted_sessionid: Mapped[str | None] = mapped_column(Text, nullable=True)
    sync_status: Mapped[str] = mapped_column(String(32), default="idle")
    sync_message: Mapped[str | None] = mapped_column(String(255), nullable=True)
    sync_progress: Mapped[int] = mapped_column(Integer, default=0)
    sync_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_synced_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    relationships: Mapped[list[Relationship]] = relationship(back_populates="owner", cascade="all, delete-orphan")
    profile_cache: Mapped[list[ProfileCache]] = relationship(back_populates="owner", cascade="all, delete-orphan")


class Relationship(Base):
    __tablename__ = "relationships"
    __table_args__ = (
        UniqueConstraint("owner_account_id", "target_instagram_user_id", "relationship_type", name="uq_relationship"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    owner_account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), index=True)
    target_instagram_user_id: Mapped[str] = mapped_column(String(64), index=True)
    username: Mapped[str] = mapped_column(String(128), index=True)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    profile_pic_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    relationship_type: Mapped[str] = mapped_column(String(32), index=True)
    snapshot_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, index=True)

    owner: Mapped[Account] = relationship(back_populates="relationships")


class ProfileCache(Base):
    __tablename__ = "profile_cache"
    __table_args__ = (UniqueConstraint("owner_account_id", "instagram_user_id", name="uq_profile_cache"),)

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    owner_account_id: Mapped[int] = mapped_column(ForeignKey("accounts.id"), index=True)
    instagram_user_id: Mapped[str] = mapped_column(String(64), index=True)
    username: Mapped[str] = mapped_column(String(128), index=True)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    profile_pic_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    follower_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    following_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_private: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    is_verified: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    captions: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    tags: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    embedding: Mapped[list[float] | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    owner: Mapped[Account] = relationship(back_populates="profile_cache")
