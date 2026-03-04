from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Account
from app.dependencies import get_current_account
from app.schemas.common import InstagramUserResponse, ProfileStatsResponse
from app.services.graph.graph_engine import GraphEngine
from app.services.graph.sync_scheduler import queue_account_refresh
from app.routers.auth import _sync_graph_for_account


router = APIRouter(tags=["graph"])
graph = GraphEngine()


@router.get("/followers", response_model=list[InstagramUserResponse])
def followers(
    background_tasks: BackgroundTasks,
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return graph.followers(db, current_account)


@router.get("/following", response_model=list[InstagramUserResponse])
def following(
    background_tasks: BackgroundTasks,
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return graph.following(db, current_account)


@router.get("/mutuals", response_model=list[InstagramUserResponse])
def mutuals(
    background_tasks: BackgroundTasks,
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return graph.mutuals(db, current_account)


@router.get("/non-mutuals", response_model=list[InstagramUserResponse])
def non_mutuals(
    background_tasks: BackgroundTasks,
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return graph.non_mutuals(db, current_account)


@router.get("/profile-stats", response_model=ProfileStatsResponse)
def profile_stats(
    background_tasks: BackgroundTasks,
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> ProfileStatsResponse:
    queue_account_refresh(background_tasks, db, current_account, _sync_graph_for_account)
    return graph.stats(db, current_account)
