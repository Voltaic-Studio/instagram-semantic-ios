from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.db.models import Account
from app.dependencies import get_current_account
from app.schemas.common import InstagramUserResponse, ProfileStatsResponse
from app.services.graph_engine import GraphEngine


router = APIRouter(tags=["graph"])
graph = GraphEngine()


@router.get("/followers", response_model=list[InstagramUserResponse])
def followers(
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    return graph.followers(db, current_account)


@router.get("/following", response_model=list[InstagramUserResponse])
def following(
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    return graph.following(db, current_account)


@router.get("/mutuals", response_model=list[InstagramUserResponse])
def mutuals(
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    return graph.mutuals(db, current_account)


@router.get("/non-mutuals", response_model=list[InstagramUserResponse])
def non_mutuals(
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> list[InstagramUserResponse]:
    return graph.non_mutuals(db, current_account)


@router.get("/profile-stats", response_model=ProfileStatsResponse)
def profile_stats(
    current_account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
) -> ProfileStatsResponse:
    return graph.stats(db, current_account)

