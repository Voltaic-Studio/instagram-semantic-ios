from pydantic import BaseModel

from app.schemas.common import SearchResultResponse


class SearchResponse(BaseModel):
    results: list[SearchResultResponse]

