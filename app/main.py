from fastapi import FastAPI

from .api.health import router as health_router
from .config import settings
from .logging import setup_logging

setup_logging()

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.include_router(health_router)


@app.get("/")
def root():
    return {
        "name": settings.APP_NAME,
        "environment": settings.ENVIRONMENT,
        "docs": "/docs",
    }
