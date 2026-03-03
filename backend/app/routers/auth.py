from __future__ import annotations

import logging
from datetime import datetime
from urllib.parse import urlencode

from fastapi import APIRouter, BackgroundTasks, Depends, Form, HTTPException, status
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db.database import SessionLocal, get_db
from app.db.models import Account, ProfileCache
from app.dependencies import get_current_account
from app.schemas.auth import AuthStartResponse, LoginRequest, LoginResponse, SyncStatusResponse
from app.schemas.common import InstagramUserResponse
from app.services.account_store import AccountStore
from app.services.auth_tokens import create_access_token
from app.services.enrichment import EnrichmentService
from app.services.graph_engine import GraphEngine
from app.services.instagram_client import InstagramAuthError, InstagramClientService, InstagramTwoFactorRequired


router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()
logger = logging.getLogger(__name__)
store = AccountStore()
instagram = InstagramClientService()
graph_engine = GraphEngine()
enrichment = EnrichmentService()


def _serialize_user(account: Account) -> InstagramUserResponse:
    return InstagramUserResponse(
        id=account.instagram_user_id,
        username=account.username,
        full_name=account.full_name or account.username,
        profile_pic_url=account.profile_pic_url or "",
        bio=account.bio,
        follower_count=account.follower_count,
        following_count=account.following_count,
        is_private=account.is_private,
        is_verified=account.is_verified,
    )


def _serialize_sync_status(account: Account) -> SyncStatusResponse:
    return SyncStatusResponse(
        status=account.sync_status,
        message=account.sync_message,
        progress=account.sync_progress,
        error=account.sync_error,
    )


def _set_sync_state(
    db: Session,
    account: Account,
    *,
    status: str,
    message: str | None,
    progress: int,
    error: str | None = None,
    mark_synced: bool = False,
) -> None:
    account.sync_status = status
    account.sync_message = message
    account.sync_progress = progress
    account.sync_error = error
    if mark_synced:
        account.last_synced_at = datetime.utcnow()
    db.add(account)
    db.commit()
    db.refresh(account)


@router.get("/instagram/start", response_model=AuthStartResponse)
def start_instagram_auth() -> AuthStartResponse:
    url = f"{settings.public_base_url}/auth/instagram/login"
    return AuthStartResponse(url=url)


@router.get("/instagram/login", response_class=HTMLResponse, include_in_schema=False)
def instagram_login_page(error: str | None = None) -> HTMLResponse:
    error_markup = f"<p style='color:#b91c1c;margin:0 0 16px'>{error}</p>" if error else ""
    html = f"""
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Connect Instagram</title>
        <style>
          body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #09090b; color: white; padding: 24px; }}
          .card {{ max-width: 420px; margin: 48px auto; background: #18181b; border-radius: 20px; padding: 24px; box-shadow: 0 20px 60px rgba(0,0,0,.35); }}
          h1 {{ margin: 0 0 8px; font-size: 28px; }}
          p {{ color: #a1a1aa; line-height: 1.5; }}
          input {{ width: 100%; box-sizing: border-box; border: 1px solid #27272a; background: #09090b; color: white; border-radius: 12px; padding: 14px 16px; margin-top: 12px; }}
          button {{ width: 100%; margin-top: 16px; border: 0; border-radius: 14px; padding: 14px 16px; font-weight: 700; color: white; background: linear-gradient(90deg,#673ab7,#d81b60,#fb8c00,#fdd835); }}
        </style>
      </head>
      <body>
        <div class="card">
          <h1>Connect Instagram</h1>
          <p>Sign in with your Instagram credentials to create a private session for follower graph sync.</p>
          {error_markup}
          <form method="POST" action="/auth/instagram/login/web">
            <input type="text" name="username" placeholder="Instagram username" autocapitalize="none" required />
            <input type="password" name="password" placeholder="Password" required />
            <input type="text" name="two_factor_code" placeholder="2FA code (if needed)" />
            <button type="submit">Connect account</button>
          </form>
        </div>
      </body>
    </html>
    """
    return HTMLResponse(html)


def _sync_graph(db: Session, account: Account) -> None:
    _set_sync_state(db, account, status="syncing", message="Pulling your followers", progress=20)
    client = instagram.get_client_from_settings(account.encrypted_settings)
    followers = instagram.fetch_followers(client, account.instagram_user_id)
    _set_sync_state(db, account, status="syncing", message="Pulling who you follow", progress=45)
    following = instagram.fetch_following(client, account.instagram_user_id)
    store.replace_relationships(db, account, "follower", followers)
    store.replace_relationships(db, account, "following", following)
    _hydrate_basic_profiles(db, account, client, followers + following)
    _set_sync_state(db, account, status="ready", message="Search is ready", progress=100, mark_synced=True)


def _hydrate_basic_profiles(db: Session, account: Account, client, profiles: list) -> None:
    unique_profiles: dict[str, object] = {profile.id: profile for profile in profiles}
    hydrated_profiles = []
    total = max(len(unique_profiles), 1)
    for index, profile in enumerate(unique_profiles.values(), start=1):
        try:
            detailed_profile = instagram.fetch_user_info(client, profile.id)
            hydrated_profiles.append(detailed_profile)
        except Exception:
            hydrated_profiles.append(profile)

        if index == 1 or index == total or index % 20 == 0:
            progress = 45 + int((index / total) * 55)
            _set_sync_state(
                db,
                account,
                status="syncing",
                message=f"Fetching profile info {index}/{total}",
                progress=min(progress, 99),
            )

    store.upsert_profiles(db, account, hydrated_profiles)
    db.commit()


def _run_semantic_enrichment(account_id: int) -> None:
    db = SessionLocal()
    try:
        account = db.scalar(select(Account).where(Account.id == account_id))
        if account is None:
            return
        client = instagram.get_client_from_settings(account.encrypted_settings)
        profiles = db.scalars(select(ProfileCache).where(ProfileCache.owner_account_id == account.id)).all()
        semantic_profiles = []
        for profile in profiles[:75]:
            try:
                semantic_profiles.append(instagram.fetch_user_info(client, profile.instagram_user_id))
            except Exception:
                continue
        enrichment.enrich_profiles(
            db,
            account,
            instagram,
            semantic_profiles,
            max_profiles=75,
            throttle_seconds=0.35,
        )
        db.commit()
    except Exception as exc:
        logger.error("Semantic enrichment failed for account %s: %s", account_id, type(exc).__name__)
        db.rollback()
    finally:
        db.close()


def _sync_graph_for_account(account_id: int) -> None:
    db = SessionLocal()
    try:
        account = db.scalar(select(Account).where(Account.id == account_id))
        if account is None:
            logger.warning("Background sync skipped: account %s not found", account_id)
            return
        _set_sync_state(db, account, status="syncing", message="Starting your sync", progress=5)
        _sync_graph(db, account)
    except Exception as exc:
        logger.error("Background sync failed for account %s: %s", account_id, type(exc).__name__)
        account = db.scalar(select(Account).where(Account.id == account_id))
        if account is not None:
            _set_sync_state(db, account, status="failed", message="Sync paused", progress=0, error="Background sync failed")
        db.rollback()
    finally:
        db.close()
    _run_semantic_enrichment(account_id)


def _persist_login(db: Session, settings_payload: dict, user_profile) -> tuple[Account, str]:
    encrypted_settings = instagram.serialize_settings(settings_payload)
    encrypted_sessionid = instagram.serialize_sessionid(settings_payload.get("authorization_data", {}).get("sessionid"))
    account = store.upsert_account(db, user_profile, encrypted_settings, encrypted_sessionid)
    db.commit()
    db.refresh(account)
    _set_sync_state(db, account, status="queued", message="Preparing your follower sync", progress=0, error=None)
    token = create_access_token(str(account.id))
    return account, token


@router.post("/instagram/login", response_model=LoginResponse)
def instagram_login_json(
    payload: LoginRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
) -> LoginResponse:
    try:
        settings_payload, user_profile = instagram.login(payload.username, payload.password, payload.two_factor_code)
        account, token = _persist_login(db, settings_payload, user_profile)
        background_tasks.add_task(_sync_graph_for_account, account.id)
    except InstagramTwoFactorRequired:
        return LoginResponse(success=False, requires_two_factor=True, message="Two-factor code required")
    except InstagramAuthError as exc:
        return LoginResponse(success=False, message=str(exc))

    return LoginResponse(success=True, token=token, user=_serialize_user(account))


@router.post("/instagram/login/web", include_in_schema=False, response_class=RedirectResponse)
def instagram_login_form(
    background_tasks: BackgroundTasks,
    username: str = Form(...),
    password: str = Form(...),
    two_factor_code: str | None = Form(default=None),
    db: Session = Depends(get_db),
):
    try:
        settings_payload, user_profile = instagram.login(username, password, two_factor_code)
        account, token = _persist_login(db, settings_payload, user_profile)
        background_tasks.add_task(_sync_graph_for_account, account.id)
    except InstagramTwoFactorRequired:
        return RedirectResponse(url="/auth/instagram/login?error=Two-factor%20code%20required", status_code=status.HTTP_303_SEE_OTHER)
    except InstagramAuthError as exc:
        return RedirectResponse(url=f"/auth/instagram/login?error={str(exc)}", status_code=status.HTTP_303_SEE_OTHER)

    callback = f"{settings.ios_callback_url}?{urlencode({'token': token, 'username': account.username})}"
    return RedirectResponse(url=callback, status_code=status.HTTP_303_SEE_OTHER)


@router.get("/me", response_model=InstagramUserResponse)
def me(current_account: Account = Depends(get_current_account)) -> InstagramUserResponse:
    return _serialize_user(current_account)


@router.post("/refresh")
def refresh(current_account: Account = Depends(get_current_account), db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        _sync_graph(db, current_account)
    except InstagramAuthError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    return {"status": "ok"}


@router.get("/sync-status", response_model=SyncStatusResponse)
def sync_status(current_account: Account = Depends(get_current_account)) -> SyncStatusResponse:
    return _serialize_sync_status(current_account)
