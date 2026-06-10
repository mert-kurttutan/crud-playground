from fastapi import APIRouter

from app.db.session import get_database_status


router = APIRouter()


@router.get("")
def read_health() -> dict[str, str]:
    return {
        "status": "ok",
        "database": get_database_status(),
    }
