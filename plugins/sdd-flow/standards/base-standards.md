# Base Development Standards — sdd-flow

Single source of truth para todos los agentes del ciclo SDD. (Condensado de `Construplaza/TemplateNewRepository` → `SDD/ai-specs/specs/base-standards`.)

## Core Rules (no negociables)
1. Leer archivos antes de editar. Nunca adivinar estructura existente.
2. Hacer exactamente lo pedido. Nada más.
3. Cero secretos en código.
4. Solo queries parametrizadas. Nada de concatenación de strings en SQL.
5. Validar todo input en los bordes del sistema (Zod / Pydantic / equivalente del stack).
6. Sin escapes del type-checker: `any`, `dynamic`, `interface{}`, `@ts-ignore`, `# type: ignore` (ver perfiles, `quality-gates.md` §9).
7. **Cada acceptance criterion tiene un test.** "Tests verdes" sin tests nuevos no es cobertura — ver `standards/quality-gates.md`.
8. **Nada se declara `done` sin evidencia**: comando + exit code registrados. Escalera de gates en `quality-gates.md` §4-§5.
9. **Reuse antes de crear**: buscar lo existente (grep) antes de escribir una función/servicio nuevo. Duplicar lógica es un rechazo de review.
10. Tareas chicas, una a la vez. Cambios incrementales. Bugfix = test rojo primero.

## Calidad verificable
`standards/quality-gates.md` es la fuente normativa: Definition of Done, acceptance criteria numerados, binding AC↔test, escalera de gates, contrato de evidencia, **mitigaciones prohibidas** (nunca ablandar un test o silenciar el linter para pasar un gate — eso es BLOCKED y pregunta al planner) y el modelo de severidades del review con cota de 3 rondas.

Los **comandos concretos** de cada repo viven en `SDD/docs/doc_quality_gates.md` (lo genera `/sdd-init`). Ningún agente inventa comandos de verificación.

## Áreas (detalle en el repo standard de la empresa)
- `000-core-principles` · `001-code-quality` · `002-security` · `003-git-workflow`
- `004-testing` · `005-typescript` · `006-react-nextjs` · `007-api-design`
- `008-performance` · `009-ai-agent-behavior`
- **Calidad y testing**: `standards/quality-gates.md` (ship con el plugin — no depende del repo de la empresa).
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
