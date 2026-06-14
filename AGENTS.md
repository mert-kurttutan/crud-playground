# Project Architecture

This repository is a small full-stack CRUD playground for a benchmark repository
domain. The app models benchmark runs as the first concrete resource and is
intended to grow toward users, memberships, benchmark scripts, hardware
profiles, and benchmark results.

## Tech Stack

- Frontend: SvelteKit, Svelte 5 runes, TypeScript, Vite, pnpm
- Backend: FastAPI, Pydantic, SQLAlchemy, Alembic, uv
- Database: PostgreSQL
- Dev environment: Nix flake with Python, uv, Node.js, and pnpm

## Backend Design

The FastAPI backend lives in `backend/app`. `main.py` creates the application,
adds CORS, and mounts API routes under the configured API prefix, currently
`/api/v1`.

Routes are grouped under `backend/app/api/routes` and composed through
`backend/app/api/router.py`. The health route checks database connectivity. The
benchmark route currently provides create and read endpoints backed by in-memory
state, while database session wiring already exists in `backend/app/db`.

Configuration is centralized in `backend/app/core/config.py` using
`pydantic-settings` and environment variables.

## Frontend Design

The SvelteKit frontend lives in `frontend/src`. The main page is
`frontend/src/routes/+page.svelte`, which provides a compact CRUD-style
interface for adding, listing, and removing benchmark runs.

The frontend currently stores benchmark runs in local Svelte state and calls the
backend only for the health check. Future work should connect the UI to the
benchmark API and replace local-only state with persisted backend data.

## Development Notes

Use the repo root `flake.nix` for the recommended development shell. Run backend
commands from `backend` with `uv`, and frontend commands from `frontend` with
`pnpm`.

Keep changes scoped and preserve the simple separation between frontend UI,
backend API routes, configuration, and database access.
