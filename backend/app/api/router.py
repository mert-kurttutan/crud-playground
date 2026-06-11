from fastapi import APIRouter

from app.api.routes.benchmarks import router as benchmarks_router
from app.api.routes.health import router as health_router


api_router = APIRouter()
api_router.include_router(benchmarks_router, prefix="/benchmarks", tags=["benchmarks"])
api_router.include_router(health_router, prefix="/health", tags=["health"])
