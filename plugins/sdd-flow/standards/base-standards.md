# Base Development Standards — sdd-flow

Single source of truth para todos los agentes del ciclo SDD. (Condensado de `Construplaza/TemplateNewRepository` → `SDD/ai-specs/specs/base-standards`.)

## Core Rules (no negociables)
1. Leer archivos antes de editar. Nunca adivinar estructura existente.
2. Hacer exactamente lo pedido. Nada más.
3. Cero secretos en código.
4. Solo queries parametrizadas. Nada de concatenación de strings en SQL.
5. Validar todo input en los bordes del sistema (Zod / equivalente).
6. Sin `any` en TypeScript.
7. Tests deben pasar antes de cualquier PR.
8. Tareas chicas, una a la vez. TDD. Cambios incrementales.

## Áreas (detalle en el repo standard de la empresa)
- `000-core-principles` · `001-code-quality` · `002-security` · `003-git-workflow`
- `004-testing` · `005-typescript` · `006-react-nextjs` · `007-api-design`
- `008-performance` · `009-ai-agent-behavior`
- **SEO (frontend)**: ver `standards/seo-frontend.md`. Advisory; aplica solo si el contract trae `seo.applies == true`.

## Capas de integración (degradación por entorno)

El flujo se adapta al entorno — detectá una vez al arrancar y avisá la capa elegida:
1. **Git con remote** (`git remote` no vacío) → branch + **PR** contra la base (capa completa, abajo).
2. **Git sin remote** → branch + review obligatorio (`reviewer-agent` Opus o self-review) + **merge local** a la base con `--no-ff`. NUNCA commit directo a la base igual. No hay PR (no hay dónde).
3. **No es git** (carpeta suelta) → avisá una vez y corré el ciclo SDD **sin** la capa de branch/PR. Proxima sigue siendo opcional e independiente de esto.

Proxima es ortogonal a la capa de integración: puede haber tracking Proxima en capa 2 o 3, y no haberlo en capa 1.

## Git / branches (de Construplaza)
- **TODO trabajo (feature, fix, mejora, lo que sea) nace en branch nueva. NUNCA commits directos a ramas normales** (`main`, `dev`, `qa`, `pre-prod` — protegidas, no push directo, no se borran).
- **Rama base: elegirla y confirmarla SIEMPRE** antes de crear la branch — proponé `dev` si existe, sino la default del repo, y confirmá con el usuario/planner.
- **Orden estricto**: primero la tarea Proxima, después la branch (el key debe existir para nombrarla).
- Branch de trabajo:
  - **Con Proxima**: `{action}-{KEY}-{desc}`, `action ∈ feat|fix|chore|refactor|docs`. **`KEY` = key de la tarea madre** (ej. `GEN-30`) — las subtasks Proxima NO tienen key (solo UUID), por eso la branch usa siempre el key de la madre. Multi-agente: insertá el slug del agente para desambiguar → `{action}-{KEY}-{agente}-{desc}` (ej. `feat-GEN-30-be-add-endpoint`). Single-repo: `{action}-{KEY}-{desc}` (ej. `feat-GEN-30-add-endpoint`).
  - **Sin Proxima** (MCP ausente o el usuario declinó): `<MODULO>-<TICKET>` (ej. `COMPRAS-FAC-81`); sin ticket: `<MODULO>-<desc-corta>`.
  - Se borra al integrar.
- Commits: `[TIPO] [TICKET] [Módulo] [Descripción]`. Tipos: ADD/FIX/REF/IMP/REM/REV/MOV/REL.
- **Integración** según capa: con remote → **PR** (a CODEOWNERS) hacia la base; sin remote → **merge local `--no-ff`** tras review. Tests verdes obligatorio en ambas. Nunca commit directo a la base.
- **Cierre Proxima**: la tarea/subtask pasa a `done` **cuando se integra** (PR mergeado, o merge local hecho) — no antes. Solo el planner llama al MCP `proxima`; los implementing-agents reportan estado/integración por el canal file-based.

## AI agent behavior
- Scope acotado al task brief. Escalá (BLOCKED) ante decisión faltante — no adivines.
- Confirmá operaciones destructivas.
- Nunca declares una validación que no corriste.

> Nota: este archivo es el puente. Cuando el plugin se instala en un repo Construplaza, los `.mdc` detallados ya viven en `SDD/ai-specs/specs/base-standards/` y mandan esos.
