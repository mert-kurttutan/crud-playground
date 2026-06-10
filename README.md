# Benchmark Repository Playground

This project is a personal playground for testing CRUD app ideas around a benchmark repository. The main concept is a small system where users can log in, manage memberships, register benchmark scripts and hardware profiles, and store benchmark results. It is meant both as a practical full-stack exercise and as a foundation for experimenting with computation- and hardware-oriented app design.

## Stack

- Frontend: `SvelteKit` with `TypeScript`
- Backend: `FastAPI`
- Database: `PostgreSQL`
- ORM and migrations: `SQLAlchemy` + `Alembic`

## Development

Run it locally with separate frontend and backend services.

1. Start PostgreSQL locally.
2. Run the FastAPI backend.
3. Run the SvelteKit frontend.

Planned local development flow:

```bash
# backend
cd backend
uv sync
cp .env.example .env
uv run uvicorn app.main:app --reload

# frontend
cd frontend
pnpm install
pnpm dev
```
