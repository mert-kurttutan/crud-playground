from itertools import count
from math import isfinite

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field, field_validator


router = APIRouter()

_benchmark_ids = count(1)
_benchmarks: list["BenchmarkRead"] = []


class BenchmarkCreate(BaseModel):
    name: str = Field(min_length=1)
    script: str = Field(min_length=1)
    hardware: str = Field(min_length=1)
    score: float
    unit: str = Field(default="ops/sec", min_length=1)
    notes: str = ""

    @field_validator("score")
    @classmethod
    def validate_score(cls, score: float) -> float:
        if not isfinite(score):
            raise ValueError("Score should be a number.")
        return score


class BenchmarkRead(BenchmarkCreate):
    id: int


@router.get("", response_model=list[BenchmarkRead])
def list_benchmarks() -> list[BenchmarkRead]:
    return _benchmarks


@router.get("/{benchmark_id}", response_model=BenchmarkRead)
def read_benchmark(benchmark_id: int) -> BenchmarkRead:
    for benchmark in _benchmarks:
        if benchmark.id == benchmark_id:
            return benchmark

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Benchmark not found.",
    )


@router.post("", response_model=BenchmarkRead, status_code=status.HTTP_201_CREATED)
def create_benchmark(benchmark: BenchmarkCreate) -> BenchmarkRead:
    created = BenchmarkRead(id=next(_benchmark_ids), **benchmark.model_dump())
    _benchmarks.append(created)
    return created
