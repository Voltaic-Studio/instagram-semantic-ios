from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Account
from app.dependencies import get_current_account
from app.schemas.common import SearchResultResponse
from app.services.search_service import SearchService


router = APIRouter(tags=["search"])
search_service = SearchService()


@router.get("/semantic-search", response_model=list[SearchResultResponse])
def semantic_search(
    query: str = Query(..., min_length=1),
    scope: str = Query(default="following"),
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[SearchResultResponse]:
    return search_service.search(db, current_account, query=query, scope=scope)
