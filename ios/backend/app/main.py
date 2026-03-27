from fastapi import FastAPI

from app.config import get_settings
from app.db.database import Base, engine
from app.routers import auth, graph, search


settings = get_settings()
Base.metadata.create_all(bind=engine)

app = FastAPI(title="InstaSemantic Backend", version="0.1.0")
app.include_router(auth.router)
app.include_router(graph.router, prefix=settings.api_prefix)
app.include_router(search.router, prefix=settings.api_prefix)
app.include_router(auth.router, prefix=settings.api_prefix)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
