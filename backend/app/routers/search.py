from fastapi import APIRouter, BackgroundTasks, Depends, Query
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Account
from app.dependencies import get_current_account
from app.schemas.common import SearchResultResponse
from app.services.sync_scheduler import queue_account_refresh
from app.services.search_service import SearchService
from app.routers.auth import _sync_graph_for_account


router = APIRouter(tags=["search"])
search_service = SearchService()


@router.get("/semantic-search", response_model=list[SearchResultResponse])
def semantic_search(
    background_tasks: BackgroundTasks,
    query: str = Query(..., min_length=1),
    scope: str = Query(default="following"),
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[SearchResultResponse]:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return search_service.search(db, current_account, query=query, scope=scope)
