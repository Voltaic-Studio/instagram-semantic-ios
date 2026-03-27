from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import BackgroundTasks
from sqlalchemy.orm import Session

from app.db.models import Account


SYNC_INTERVAL = timedelta(days=2)


def should_refresh_account(account: Account) -> bool:
    if account.sync_status in {"queued", "syncing"}:
        return False
    if account.last_synced_at is None:
        return True
    return datetime.utcnow() - account.last_synced_at >= SYNC_INTERVAL


def queue_account_refresh(
    background_tasks: BackgroundTasks,
    db: Session,
    account: Account,
    refresh_task,
) -> bool:
    if not should_refresh_account(account):
        return False

    account.sync_status = "queued"
    account.sync_message = "Preparing your follower sync"
    account.sync_progress = 0
    account.sync_error = None
    db.add(account)
    db.commit()
    db.refresh(account)
    background_tasks.add_task(refresh_task, account.id)
    return True
