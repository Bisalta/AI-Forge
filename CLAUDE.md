# CLAUDE.md — AI-Forge

Guía para Claude Code al trabajar en este repo. Captura el contexto de diseño de la sesión donde nació el proyecto.

## Qué es

**AI-Forge** = marketplace interno de **Bisalta Ltda** (hosteado en `github.com/Bisalta/AI-Forge`) para tooling de Claude Code. Dos plugins: **`sdd-flow`** (SDD multi-agente) y **`project-foundation`** (los seis docs fundacionales de un proyecto).

**Objetivo**: standard de empresa (NO obligatorio) para que todos los devs usen Claude de forma eficiente y consistente.

Install para cualquier dev:
```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow
/plugin install project-foundation
```

## El plugin sdd-flow — concepto

Pipeline SDD: **planner Opus 4.8** cierra decisiones y corta tareas → **subagentes** las ejecutan (Sonnet default, Opus si pesada, Haiku si trivial) → coordinación file-based multi-repo con topología flexible `AGENT_{uuid}` (cada agente = repo + branch + working-dir).

### Ciclo (basado en el "Ciclo de desarrollo SDD" de LIDR)
```
USER STORY
  → DECISION-CLOSED REFINEMENT      (skill enrich-user-story · Opus)
  → HIGH-LEVEL TECHNICAL CONTRACT   (skill sdd-plan · auto-approve+log · single-writer)
  → IMPLEMENTATION SPEC             (task briefs por AGENT_{uuid} · modelo por tarea)
  → IMPLEMENTING AGENT + REVIEW ↻   (implementing-agent Sonnet · reviewer-agent Opus)
  → BRANCH·TESTS·DOCS·CODE·TESTING REPORT·PROPOSAL UPDATE
  → FEATURE READY  ←★ ÚNICO gate humano  → FEATURE FOR PR → FEATURE PUBLISHED
```
Diagrama renderizado: `cross_agent_implementations/sdd-cycle-v2.jpg`.

## El plugin project-foundation — concepto

Empaqueta el skill personal `project-foundation` (que ya vivía en `~/.claude-personal/skills/`) para distribuirlo como standard de empresa. Genera los **seis documentos fundacionales** de un proyecto (PRD → TRD → UI/UX Brief · App Flow · Backend Schema → Implementation Plan) en `docs/foundation/`, greenfield (entrevista) o derivando de un codebase existente. Standalone — no depende de `sdd-flow` — pero si ambos están instalados, `sdd-flow` puede leer sus outputs (ver PR de bootstrap de docs fundacionales en `sdd-flow`, si ya se mergeó).

## Decisiones de diseño tomadas (no re-litigar)

1. **Forma = plugin** (no skill suelto): empaqueta commands+skills+agents+hooks, distribuible por marketplace, versionable.
2. **Gate humano único = desde Feature Ready.** El pipeline `User Story → Feature Ready` corre **autónomo, sin aprobación humana intermedia**. (Se descartó el gate de aprobación de contract — opción A elegida por el usuario.)
3. **Spec review = solo agentes, sin humano**: self-review ó `reviewer-agent` en Opus (sin sesgo). Configurable.
4. **Contract single-writer**: solo el planner escribe `contract.md`; los agentes mandan `contract-change-request`; el planner ratifica y bumpea versión (v1→vN). Mejor que ack-gating peer-to-peer; escala a N agentes.
5. **Orden de integración**: cuando hay dependencias entre repos, se declara el orden de merge (ej. BE→FE→mobile).
6. **Escape hatch**: "decision-closed" = lista de open-questions vacía o riesgo aceptado. En ejecución, decisión no resuelta → agente queda **BLOCKED → pregunta al planner, NO adivina**.
7. **Closure rules innegociables** (porque el contract se auto-aprueba): prohibido "if needed / or / prefer / may be / when available / derived from". Si dos ingenieros lo implementarían distinto, el contract es inválido.

## Orígenes (de dónde se copió)

- **Núcleo SDD** ← `github.com/Construplaza/TemplateNewRepository`, carpeta `SDD/`:
  - `skills/enrich-user-story` y `skills/write-pr-report` → copiados tal cual.
  - `docs/doc_ai_planning_mode.md` → base del skill `sdd-plan` (HLTC, Architectural Delta, closure rules, task briefs con IDs `T<fase>.<i>`, Execution Report, Accountability).
  - `specs/base-standards/` (000-009) → condensado en `standards/base-standards.md`.
  - `docs/doc_architecture.md` + `docs/doc_verification_guide.md` → `templates/`.
  - Patrón symlinks `.claude/.codex/.cursor → ai-specs` (un set de specs, 3 herramientas).
- **Capa multi-agente** ← protocolo de `cross_agent_implementations/` (inbox/outbox numerado, ownership 1-way, status board). Generalizado de BE/FE/mobile hardcodeado a `AGENT_{uuid}`.

## Estructura

```
AI-Forge/
├── .claude-plugin/marketplace.json   índice (owner: Bisalta Ltda)
├── plugins/sdd-flow/
│   ├── .claude-plugin/plugin.json    v0.7.0
│   ├── commands/   sdd-init · sdd · sdd-enrich · sdd-contract · sdd-status · sdd-pr · sdd-fixes · sdd-agents · sdd-seo
│   ├── skills/     sdd-init · enrich-user-story · sdd-plan · sdd-seo · write-pr-report
│   ├── agents/     implementing-agent (sonnet) · reviewer-agent (opus)
│   ├── hooks/      statusline.sh
│   ├── standards/  base-standards.md
│   └── templates/  doc_architecture.md · doc_verification_guide.md · coordination-README.md
├── plugins/project-foundation/
│   ├── .claude-plugin/plugin.json    v0.1.0
│   ├── commands/   project-foundation
│   └── skills/     project-foundation (los seis docs fundacionales)
├── CHANGELOG.md · README.md · .gitignore
```

## Estado actual: v0.7.0 — bootstrap de docs fundacionales

**v0.7.0**: nuevo comando+skill `/sdd-init` — bootstrapea `SDD/docs/doc_architecture.md` y `doc_verification_guide.md` (derivar de codebase existente o entrevistar en greenfield) en vez de dejarlos como esqueleto `[PLACEHOLDER]`. Antes de esto, si esos docs no existían llenos, `enrich-user-story` frenaba sin ninguna ruta de recuperación dentro del plugin. Si el repo ya tiene `docs/foundation/` (seis documentos de un day-zero externo — convención del skill `project-foundation`), `doc_architecture.md` referencia `02-trd.md`/`05-backend-schema.md` en vez de duplicarlos; `doc_verification_guide.md` siempre se genera fresco. Además, `enrich-user-story` ahora lee `docs/foundation/01-prd.md` si existe (opcional, no bloqueante) para anclar actor/success-criteria en producto real, y `sdd-plan` chequea `docs/foundation/06-implementation-plan.md` si existe para detectar scope creep contra el roadmap. Spec en `docs/specs/2026-08-03-foundation-docs-bootstrap-design.md`.

**v0.6.0**: SEO frontend como concern **advisory** (nunca bloquea Feature Ready) para proyectos con front. Activación por pregunta en `enrich-user-story` (no automática): persiste como bloque `seo: { applies, indexable, locales }` en el contract. Checklist 2 tiers (Universal / Indexable) en `standards/seo-frontend.md`. `sdd-plan` inyecta criterios SEO decision-closed al HLTC y briefs cuando `seo.applies`. `reviewer-agent` reporta sección "SEO (advisory)" sin bloquear. Nuevo command + skill `/sdd-seo` (auditoría on-demand, Lighthouse o fallback estático). Spec en `docs/specs/2026-06-22-seo-frontend-advisory-design.md`.

**v0.5.0**: integración Proxima (Fase 0 en `/sdd`: detectar MCP → match proyecto → preguntar → tarea madre + subtask por agente, planner single-writer del MCP) y branch `{action}-{KEY_MADRE}-{agente}-{desc}` atada al key de la tarea madre (las subtasks Proxima no tienen key, solo UUID; reemplaza `<MODULO>-<TICKET>` con Proxima, fallback sin él); cierre de tarea al integrar. **Flexible por entorno (capas de integración)**: git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → ciclo sin branch/PR. Corre con o sin el MCP `proxima`. Spec en `docs/specs/2026-06-16-proxima-branch-pr-rules-design.md`.

**v0.4.0**: regla dura de branching (branch por trabajo, base confirmada, integración solo PR) aplicada en standards, `/sdd-fixes`, protocolo de coordinación y kickoffs.

**v0.2.0**: comando `/sdd-fixes` (batch de fixes con intake+triage+visualizador `fixes.md`) y badge statusline `⚡ fixes N/M` — spec en `docs/specs/2026-06-09-sdd-fixes-command-design.md`.

**v0.3.0**: comando `/sdd-agents` (bootstrap coordinación multi-agente `AGENT_<slug>` + kickoff prompts) y template `coordination-README.md` con el protocolo — spec en `docs/specs/2026-06-10-sdd-agents-bootstrap-design.md`. Cierra pendiente #2.

**Funciona de verdad**: bootstrap de docs (`sdd-init`), refinement (`enrich-user-story`) y generación de contract (`sdd-plan`). Son prompts/skills reales.

**NO cableado todavía (pendiente)**:
1. **Orquestador real `/sdd`**: hoy describe el flujo y dispara skills, pero NO spawnea subagentes de verdad con su modelo asignado. → cablear con Agent/Workflow.
2. ~~**Bootstrap `AGENT_{uuid}`**~~ — ✅ CERRADO en v0.3.0 con `/sdd-agents`.
3. **statusline**: `hooks/statusline.sh` lee `.sdd/state.json` que nadie escribe aún. Falta que el orquestador escriba ese estado.
4. **Design doc formal** del plugin (el flujo de brainstorming quedó en diagrama, falta el doc en `docs/`).

## Convenciones

- **Versionado**: SemVer por plugin en su `plugin.json`. Bumpear + anotar en `CHANGELOG.md` (orden descendente) + commit/push. Marketplace no tiene versión propia.
- **Plugin nuevo**: `plugins/<nombre>/.claude-plugin/plugin.json` + registrar en `marketplace.json` (`source: "./plugins/<nombre>"`).
- **Modelos**: Opus 4.8 = `claude-opus-4-8`, Sonnet 4.6 = `claude-sonnet-4-6`, Haiku 4.5 = `claude-haiku-4-5-20251001`. En agents frontmatter alcanza con `opus`/`sonnet`/`haiku`.
- **Commits**: convención Construplaza `[TIPO] [TICKET] [Módulo] [Descripción]` (ADD/FIX/REF/IMP/REM/REV/MOV/REL). Cerrar con `Co-Authored-By: Claude Opus 4.8`.
- **Branching (regla dura, aplica también a ESTE repo)**: todo trabajo (feature/fix/lo que sea) nace en branch nueva — NUNCA commits directos a `main` ni ramas normales. Elegir y confirmar la rama base antes de crear la branch (`<MODULO>-<TICKET>`, sin ticket `<MODULO>-<desc>`). Integración SOLO vía PR.
- Idioma: bilingüe ES/EN, match al thread.

## Próximo paso sugerido

Cablear el orquestador `/sdd` (#1) + bootstrap `AGENT_{uuid}` (#2) — es lo que convierte el esqueleto en algo que realmente ejecuta. Antes de codear: brainstorming/design doc de CÓMO spawnear (Agent tool vs Workflow tool) y cómo el orquestador escribe el estado para statusline.
