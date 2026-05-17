from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health():
    return {
        "status": "ok",
        "service": "agent-identity",
    }


@router.get("/ready")
def ready():
    return {"ready": True}
