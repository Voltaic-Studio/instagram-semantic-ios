# Backend

FastAPI backend for Instagram private-session login, graph sync, and semantic search.

## Run

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
uvicorn app.main:app --reload
```

The iOS app expects the backend to expose `/api/...` routes and an auth start route at `/auth/instagram/start`.

## Models

This backend uses OpenRouter for embeddings, query orchestration, and VLM tagging. Fill in `OPENROUTER_API_KEY` and the model ids in `.env`.
