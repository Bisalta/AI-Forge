# Architecture Guide

## Purpose

This document is the canonical architecture reference for AI agents and developers working in this repository.

Use it to decide:
1. Where a new file belongs
2. How modules should be structured
3. How the main runtime flows are organized
4. What contracts and boundaries must not be changed without explicit approval

For verification commands and test paths, use [`SDD/docs/doc_verification_guide.md`](./doc_verification_guide.md).

---

## ⚠️ Template Notice

**This file is a skeleton. Fill it in before starting development.**

Replace every `[PLACEHOLDER]` section with the specifics of your project.

---

## Project Stack

| Layer | Technology |
|-------|-----------|
| Frontend | [e.g. Next.js 14, React 18] |
| Backend | [e.g. Node.js, AWS Lambda, Express] |
| Database | [e.g. PostgreSQL, SQL Server] |
| Search | [e.g. Algolia NeuralSearch] |
| Auth | [e.g. NextAuth, AWS Cognito] |
| Infrastructure | [e.g. AWS, Vercel] |

---

## Project Layout

```
[Fill in your actual directory structure here]

Example:
src/
  app/           ← Next.js App Router pages and layouts
  components/    ← Reusable UI components
  lib/           ← Utilities, API clients, helpers
  types/         ← TypeScript type definitions
functions/       ← AWS Lambda handlers
prisma/          ← Database schema and migrations
```

---

## Layer Responsibilities

### Frontend (`src/app/`, `src/components/`)

[Describe what belongs here and what does not]

### API / Backend (`functions/` or `src/api/`)

[Describe what belongs here and what does not]

### Data Layer

[Describe your ORM, query patterns, and what belongs in this layer]

---

## Main Flows

[Describe the key user flows and their entry points]

Example:
- **Checkout flow**: starts at `app/(shop)/checkout/page.tsx` → `lib/orders/createOrder.ts` → database
- **Search flow**: `components/SearchBar` → Algolia `instantsearch` → product results

---

## Naming Conventions

| Artifact | Convention |
|----------|-----------|
| Files | [e.g. kebab-case] |
| React components | [e.g. PascalCase] |
| Functions/variables | [e.g. camelCase] |
| Constants | [e.g. SCREAMING_SNAKE_CASE] |
| Database tables | [e.g. snake_case] |

---

## File Placement Rules

When adding code, decide by intent:

1. New page → `[path]`
2. New reusable component → `[path]`
3. New API endpoint → `[path]`
4. New business logic → `[path]`
5. New external integration → `[path]`

---

## API Contracts

[Describe your API response shape standard and error format]

---

## Error Handling

[Describe your error handling strategy across layers]

---

## Configuration and Environment

[Describe env vars, secrets management, and config loading]

---

## Anti-patterns (Do Not Introduce)

[List the specific patterns your team wants to avoid]

Examples:
- Business logic in route handlers
- Direct database calls from UI components
- Hardcoded secrets or URLs
