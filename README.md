# Benchmark Repository Playground

This project is a personal playground for trying out CRUD development concepts in a domain I find interesting: benchmarking. The benchmark repository idea gives the app a concrete shape, with users, memberships, benchmark scripts, hardware profiles, and benchmark results, but the main goal is to explore full-stack CRUD patterns through a practical example.

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

### Prepare Environment

You need to have necessary dependencies to continue development. You can get them in different ways, e.g. nix below.

#### Nix

Enter the development shell from the repository root:

```bash
nix develop
```

### Run Services

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
