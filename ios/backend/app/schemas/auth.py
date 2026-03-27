from pydantic import BaseModel, HttpUrl

from app.schemas.common import InstagramUserResponse


class LoginRequest(BaseModel):
    username: str
    password: str
    two_factor_code: str | None = None


class LoginResponse(BaseModel):
    success: bool
    token: str | None = None
    user: InstagramUserResponse | None = None
    requires_two_factor: bool | None = None
    message: str | None = None


class AuthStartResponse(BaseModel):
    url: HttpUrl


class SyncStatusResponse(BaseModel):
    status: str
    message: str | None = None
    progress: int = 0
    error: str | None = None
