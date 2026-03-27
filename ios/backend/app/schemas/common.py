from pydantic import BaseModel


class InstagramUserResponse(BaseModel):
    id: str
    username: str
    full_name: str
    profile_pic_url: str
    bio: str | None = None
    follower_count: int | None = None
    following_count: int | None = None
    is_private: bool | None = None
    is_verified: bool | None = None
    follows_back: bool | None = None


class SearchResultResponse(BaseModel):
    id: str
    user: InstagramUserResponse
    score: float | None = None
    match_type: str | None = None
    tags: list[str] | None = None


class ProfileStatsResponse(BaseModel):
    followers: int
    following: int
    mutuals: int
    non_mutuals: int
    profile_views: int | None = None
