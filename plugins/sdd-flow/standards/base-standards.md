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

## Git / branches (de Construplaza)
- **TODO trabajo (feature, fix, mejora, lo que sea) nace en branch nueva. NUNCA commits directos a ramas normales** (`main`, `dev`, `qa`, `pre-prod` — protegidas, no push directo, no se borran).
- **Rama base: elegirla y confirmarla SIEMPRE** antes de crear la branch — proponé `dev` si existe, sino la default del repo, y confirmá con el usuario/planner.
- **Orden estricto**: primero la tarea Proxima, después la branch (el key debe existir para nombrarla).
- Branch de trabajo:
  - **Con Proxima**: `{action}-{KEY}-{desc}`, `action ∈ feat|fix|chore|refactor|docs`, `KEY` = key de la tarea/subtask Proxima (ej. `feat-TRANS-24-add-endpoint`). Reemplaza al formato viejo.
  - **Sin Proxima** (MCP ausente o el usuario declinó): `<MODULO>-<TICKET>` (ej. `COMPRAS-FAC-81`); sin ticket: `<MODULO>-<desc-corta>`.
  - Se borra al mergear.
- Commits: `[TIPO] [TICKET] [Módulo] [Descripción]`. Tipos: ADD/FIX/REF/IMP/REM/REV/MOV/REL.
- **Integración SOLO vía PR** (a CODEOWNERS) hacia la base de la que se copió. Tests verdes obligatorio. Nada se mergea a mano.
- **Cierre Proxima**: la tarea/subtask pasa a `done` **cuando su PR se mergea** (no antes). Solo el planner llama al MCP `proxima`; los implementing-agents reportan estado/merge por el canal file-based.

## AI agent behavior
- Scope acotado al task brief. Escalá (BLOCKED) ante decisión faltante — no adivines.
- Confirmá operaciones destructivas.
- Nunca declares una validación que no corriste.

> Nota: este archivo es el puente. Cuando el plugin se instala en un repo Construplaza, los `.mdc` detallados ya viven en `SDD/ai-specs/specs/base-standards/` y mandan esos.
