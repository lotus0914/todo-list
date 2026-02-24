---
description: Refactor both frontend (React) and backend (FastAPI) in the current project without large-scale design changes
allowed-tools: Read, Grep, Glob, Edit, Bash(git status:*), Bash(git diff:*), Bash(find:*), Bash(ls:*), Bash(pnpm:*), Bash(npm:*), Bash(yarn:*), Bash(pytest:*), Bash(python:*), Bash(ruff:*), Bash(mypy:*), Bash(uv:*), Bash(poetry:*), Bash(make:*)
---

## Context (Current Repo Snapshot)
- Current directory listing: !`ls`
- Git status: !`git status`
- Git diff (working tree): !`git diff`

## Task
You are Claude working in the CURRENT DIRECTORY.
This repository contains a React frontend and a FastAPI backend. Your task is to refactor BOTH codebases.

## Hard constraints (must follow)
1) **NO large-scale design/UX changes**
   - Do not redesign screens, layouts, visual style, or interaction flows.
   - Do not change UI structure in ways that alter how the app looks or behaves for users.
   - UI changes are limited to **bug fixes**, **accessibility fixes**, and **small consistency tweaks** that do not change the overall look/flow.
2) **No external behavior changes** unless required to fix a clear bug.
3) Keep changes **incremental, reviewable, and low-risk**.
4) Avoid API contract changes. If unavoidable, update BOTH:
   - Backend: routes + schemas(Pydantic) + service layer
   - Frontend: API client + types + usage sites

## Scope discovery (do this first)
1) Identify frontend and backend roots by searching common folder patterns:
   - Frontend candidates: `frontend/`, `web/`, `client/`, `apps/web/`, `src/`
   - Backend candidates: `backend/`, `server/`, `api/`, `apps/api/`, `app/`
2) Detect tooling and commands:
   - Frontend: `package.json`, lockfile (`pnpm-lock.yaml`, `yarn.lock`, `package-lock.json`)
   - Backend: `pyproject.toml`, `requirements.txt`, `uv.lock`, `poetry.lock`, `Pipfile`
3) Confirm you found BOTH. If one side is missing, refactor what exists and report the absence.

## Refactor objectives (prioritized)

### A) Frontend (React)
- Reduce duplication, improve readability, simplify components
- Strengthen typing and prop/interface consistency
- Normalize loading/error handling patterns
- Improve module boundaries with **small, safe moves only** (avoid large restructures)

### B) Backend (FastAPI)
- Clarify router/service boundaries and remove dead code
- Improve Pydantic schema consistency and typing
- Consolidate repeated validation/error handling
- Keep endpoints/backward compatibility intact

## Execution plan (required)
1) Before editing, write a short plan of 3–6 bullets.
2) Make changes in small batches (cohesive diffs).
3) After each batch, run the most relevant checks available:
   - Frontend (pick what exists): `pnpm lint`, `pnpm test`, `pnpm build` (or `npm/yarn`)
   - Backend (pick what exists): `ruff check`, `pytest`, `mypy`
   - If there is a `Makefile`, use `make test`/`make lint` if present.
4) If commands fail, fix straightforward issues. If fixing would require large refactors or design changes, stop and report.

## Output format (required)
- What you found (frontend/backend roots + tooling)
- Plan
- Changes made (file-by-file with rationale)
- Commands run + results (or exact commands to run)
- Risks / follow-ups (optional)

