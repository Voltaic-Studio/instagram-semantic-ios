from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    api_prefix: str = "/api"
    database_url: str = "sqlite:///./backend.db"
    jwt_secret: str = Field(..., alias="JWT_SECRET")
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30
    session_encryption_key: str = Field(..., alias="SESSION_ENCRYPTION_KEY")
    ios_callback_scheme: str = "instasemantic"
    ios_callback_host: str = "auth-callback"
    public_base_url: str = "http://localhost:8000"
    openrouter_api_key: str | None = None
    openrouter_base_url: str = "https://openrouter.ai/api/v1"
    openrouter_app_name: str = "InstaSemantic"
    openrouter_site_url: str | None = None
    openrouter_embedding_model: str = "openai/text-embedding-3-small"
    openrouter_classifier_model: str = "openai/gpt-4.1-mini"
    openrouter_vlm_model: str = "openai/gpt-4.1-mini"
    openrouter_text_model: str = "openai/gpt-4.1-mini"

    @property
    def ios_callback_url(self) -> str:
        return f"{self.ios_callback_scheme}://{self.ios_callback_host}"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
