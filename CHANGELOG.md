# Changelog

Cambios del marketplace `ai-forge`. Orden descendente (lo más reciente primero).

## project-foundation

### 0.1.0 — 2026-08-03
- Plugin nuevo: empaqueta el skill personal `project-foundation` para distribuirlo como standard de empresa (opcional). Crea o back-fillea los seis documentos fundacionales de un proyecto — PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan — desde cero (entrevista, greenfield) o derivando de un codebase existente (subagentes de exploración en paralelo, luego confirma supuestos).
- Escribe por defecto en `docs/foundation/`, con dependencia declarada PRD → TRD → (UI/UX Brief ∥ App Flow ∥ Backend Schema) → Implementation Plan.
- **Interopera con `sdd-flow`** (si también está instalado, no es requisito): habilita que `enrich-user-story` lea el PRD, `sdd-plan` chequee el Implementation Plan, y `/sdd-init` referencie el TRD/Backend Schema en vez de duplicarlos — ver `sdd-flow` 0.7.0.
- Nuevo comando `/project-foundation:init`.

## sdd-flow

### 0.8.0 — 2026-08-04
Calidad **verificable** en vez de declarada. El plugin ya cerraba bien *qué* construir; esta versión cierra *cómo se prueba* que se construyó bien, para que la salida sea consistente sin importar el requerimiento. Spec en `docs/specs/2026-08-04-quality-gates-design.md`.

- **Nuevo `standards/quality-gates.md`** — fuente normativa que ship con el plugin (ya no un puntero al repo de standards de la empresa): Definition of Done idéntica para cualquier requerimiento, acceptance criteria numerados, binding AC↔test, escalera de gates, contrato de evidencia, mitigaciones prohibidas, severidades de review y perfiles por stack.
- **Acceptance criteria numerados `AC1..ACn`** en el HLTC (comportamiento observable, uno por test, IDs estables entre versiones) + **impact set** (callers reales de cada símbolo que se modifica, grepeados). Cada brief recibe sus ACs con el ID original; un AC pertenece a exactamente un agente.
- **Binding AC ↔ test obligatorio**: el implementing agent declara el test literal (`archivo::"caso"`) que cubre cada AC. **AC sin test = BLOCKER**, sin importar que la suite esté verde. Un AC sólo verificable a mano se declara `manual-only: <razón>` con pasos de smoke.
- **Escalera de gates fija** (format → lint → type-check → unit → integration → build → e2e → cobertura del diff), corta al primer rojo, suite completa obligatoria antes de integrar. Cobertura **del diff** en lugar de thresholds globales (que son frágiles y se bajan solos).
- **Nuevo `SDD/docs/doc_quality_gates.md`**, generado por `/sdd-init` (nuevo template): los comandos **reales** de cada repo, sus prerequisitos de entorno, rojos preexistentes de la base, tiempo esperado de la suite y markers prohibidos del stack. Ningún agente inventa comandos de verificación; un gate ausente se declara `N/A` con razón.
- **Evidencia como artefacto** (nuevo `templates/verification-report.md` → `tasks/<slug>/verification/AGENT_<slug>.md`, o `SDD/verification/<branch>.md` en single-repo): comando exacto · exit code · timestamp · output por gate, más impact set y rojos preexistentes. Evidencia ausente = BLOCKER. Bugfix: **doble corrida** obligatoria del test de reproducción (rojo antes del fix, verde después).
- **Mitigaciones prohibidas explícitas** (§6): tests borrados/skipeados/aflojados, `@ts-ignore`/`eslint-disable`/`# type: ignore` sin referencia al contract, `any` para callar al type-checker, thresholds bajados, `--no-verify`/`--force`, retry de flaky, catch silencioso, hardcodeo del valor esperado. Ante un gate que no pasa sin uno de estos atajos → BLOCKED y pregunta al planner.
- **`reviewer-agent` con dientes**: Fase 1 mecánica antes de opinar (grep de tests tocados y markers prohibidos, verificación del binding, auditoría de la evidencia y **re-corrida propia del subset barato** — si difiere de la evidencia, la evidencia está podrida). Severidades `BLOCKER`/`MAJOR`/`MINOR`/`ADVISORY`, `APPROVED` sólo con cero BLOCKER y cero MAJOR, y tercer veredicto **`ESCALATE`**.
- **Loop de review acotado a 3 rondas** (`/sdd` Fase 4 y `sdd-plan`). Sin cota, el agente empieza a ablandar tests para salir del loop; con cota, el disenso escala al planner y, si hace falta, al gate humano.
- **Checklist de Feature Ready** en `/sdd` Fase 5: ACs cubiertos, suite completa corrida, evidencia por agente, cero mitigaciones prohibidas, `APPROVED` por brief, docs delta aplicado.
- **Nuevo command + skill `/sdd-verify`**: corre la escalera on-demand, distingue rojo propio de rojo preexistente de la base, corre los chequeos mecánicos sobre el diff y escribe el verification report. Veredicto `GATES VERDES` / `GATES ROJOS` / `EVIDENCIA INCOMPLETA`.
- **Enforcement determinístico (nuevo `hooks/hooks.json` + `hooks/guard-git.sh`)**: `PreToolUse` sobre `Bash` que bloquea las tres reglas duras que un agente apurado igual rompe — commit con HEAD en rama protegida, `--no-verify`, y `git push --force` sin `--force-with-lease`. **Fail-open** por diseño (sin `jq`, sin git o JSON inesperado → deja pasar) y con escape hatch `SDD_ALLOW_BASE_COMMIT=1`.
- **`base-standards.md` reescrito** en las core rules: cada AC tiene test, nada se declara `done` sin evidencia, reuse antes de crear, bugfix con test rojo primero. Las reglas con forma de lenguaje (`any`, Zod) se despegaron de TypeScript hacia perfiles por stack.
- **Docs delta como parte del `done`**: si el Architectural Delta tocó capas/rutas/contratos, se actualiza `doc_architecture.md`; si aparecieron comandos nuevos, `doc_verification_guide.md` y `doc_quality_gates.md`. Evita que los docs fundacionales se desactualicen y degraden el refinement siguiente.
- `/sdd-status` ahora reporta gates por agente, ACs sin test, y marca los `done` sin evidencia como trabajo en curso. `write-pr-report` funda la sección Validation en la evidencia registrada (permitido decir qué no se corrió; prohibido afirmar un check sin resultado).

### 0.7.0 — 2026-08-03
- **Nuevo comando + skill `/sdd-init`**: bootstrapea `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` — derivando de un codebase existente o entrevistando en greenfield — en vez de dejarlos como esqueleto `[PLACEHOLDER]`. Cierra el punto de entrada bloqueado: hasta ahora, si esos dos archivos no existían llenos, `enrich-user-story` frenaba antes de la primera pregunta sin ninguna ruta de recuperación dentro del propio plugin.
- **Interoperabilidad con `docs/foundation/`**: si el repo ya tiene los seis documentos fundacionales de un day-zero externo (PRD/TRD/UI-UX/App Flow/Backend Schema/Implementation Plan — convención del skill `project-foundation`), `/sdd-init` referencia `02-trd.md`/`05-backend-schema.md` en vez de duplicar su contenido en `doc_architecture.md`. `doc_verification_guide.md` siempre se genera fresco (ningún equivalente en esos seis documentos).
- **`enrich-user-story` lee el PRD si existe** (`docs/foundation/01-prd.md`, opcional, no bloqueante): las dimensiones *actor y contexto de uso* y *success criteria* ahora pueden anclarse en personas/jobs-to-be-done/métricas de producto reales, en vez de fundamentarse solo en arquitectura de código.
- **`sdd-plan` chequea el roadmap si existe** (`docs/foundation/06-implementation-plan.md`, opcional): antes de cerrar el alcance del HLTC, señala si el scope propuesto choca con una fase declarada como futura, en vez de aceptarlo en silencio.
- Spec en `docs/specs/2026-08-03-foundation-docs-bootstrap-design.md`.

### 0.6.0 — 2026-06-22
- **SEO frontend advisory**: concern SEO agregado al flujo SDD para proyectos con front. Es **advisory** — nunca bloquea Feature Ready. Activación explícita en `enrich-user-story` (pregunta al usuario si aplica SEO); resultado persiste como bloque `seo: { applies, indexable, locales }` en el contract.
- **Checklist 2 tiers en `standards/seo-frontend.md`**: tier Universal (aplica a todo proyecto con front: meta tags, og/twitter cards, canonical, robots, sitemap básico) y tier Indexable (solo cuando `seo.indexable: true`: structured data, hreflang, Core Web Vitals, lazy-load, preload LCP).
- **`sdd-plan` inyecta criterios SEO**: cuando `seo.applies` está seteado en el contract, el planner incluye criterios SEO decision-closed en el HLTC y en los task briefs de los agentes de front.
- **`reviewer-agent` reporta sección "SEO (advisory)"**: sección separada en el reporte de review, sin capacidad de bloquear la aprobación del agente.
- **Nuevo command + skill `/sdd-seo`**: auditoría SEO on-demand del frontend. Corre Lighthouse si está disponible; fallback a auditoría estática contra el checklist de `standards/seo-frontend.md`. Reporta findings sin bloquear el flujo.
- Spec en `docs/specs/2026-06-22-seo-frontend-advisory-design.md`.

### 0.5.0 — 2026-06-16
- **Integración Proxima**: nueva Fase 0 en `/sdd` — detecta el MCP `proxima`, matchea proyecto (auto si único, pregunta si ambiguo), pregunta al usuario si crear tareas y crea la **tarea madre** `in_progress`. En Fase 3, **subtask por agente** (`parentKey`); cada branch usa el key de su subtask. **Single-writer Proxima**: solo el planner llama al MCP; los implementing-agents reportan estado por el canal file-based.
- **Branch atada al task key**: nuevo formato `{action}-{KEY_MADRE}-{agente}-{desc}` (single-repo sin slug) que reemplaza `<MODULO>-<TICKET>` cuando hay Proxima; fallback al viejo formato sin Proxima. Orden estricto: tarea Proxima primero → branch después. Nota: las subtasks Proxima no tienen key (solo UUID) — la branch usa siempre el key de la tarea madre; las subtasks se cierran por su UUID.
- **Cierre por integración**: subtask → `done` cuando se integra (no en Feature Ready); tarea madre → `done` cuando todas las subtasks están `done`.
- **Capas de integración (flexibilidad por entorno)**: el flujo se adapta — git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → corre el ciclo sin capa de branch/PR. Proxima es ortogonal a la capa (sirve en local, sin remote, o sin git). Funciona también sin el MCP `proxima` configurado (Fase 0 cae a fallback).
- Aplicado en `commands/sdd.md`, `standards/base-standards.md`, `skills/sdd-plan`, `agents/implementing-agent`, `commands/sdd-agents` (columnas Proxima key / Branch en el contract + kickoff), `templates/coordination-README.md` (sección Proxima single-writer) y `commands/sdd-fixes`. Spec en `docs/specs/2026-06-16-proxima-branch-pr-rules-design.md`.

### 0.4.0 — 2026-06-10
- Regla dura de branching en todo el flujo: cada feature/fix nace en branch propia (`<MODULO>-<TICKET>`), rama base elegida y confirmada siempre, NUNCA commits directos a ramas normales, integración SOLO vía PR. Aplicada en `base-standards.md`, `/sdd-fixes` (branch+PR por item), protocolo de coordinación (`coordination-README.md`) y kickoffs de `/sdd-agents` (rama base declarada en contract).

### 0.3.0 — 2026-06-10
- Nuevo comando `/sdd-agents`: bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) — estructura de task (contract single-writer, status, logs, mensajes numerados por par direccional) + kickoff prompts por agente. Cierra pendiente #2 del roadmap.
- Template `coordination-README.md`: protocolo completo generalizado a N agentes (mensajes con frontmatter, archive, ownership 1-way, BLOCKED ante ambigüedad, orden de integración).

### 0.2.0 — 2026-06-09
- Nuevo comando `/sdd-fixes`: estructura tandas de fixes/ajustes en `fixes.md` con intake, triage automático (trivial/mediano/ambiguo) y apertura del archivo como visualizador lateral editable. No implementa hasta orden explícita.
- Statusline: badge `⚡ fixes N/M` con progreso del batch, combinable con el badge SDD existente.

### 0.1.1 — 2026-06-09
- Fix: manifest `plugin.json` inválido bloqueaba `/plugin install` (`agents: Invalid input`). Se eliminan las claves `commands`/`skills`/`agents` — apuntaban a los directorios default que Claude Code auto-descubre, y el schema de `agents` espera array de archivos, no string de directorio.

### 0.1.0 — 2026-06-09
- Esqueleto inicial del plugin SDD multi-agente.
- Comandos: `/sdd`, `/sdd-enrich`, `/sdd-contract`, `/sdd-status`, `/sdd-pr`.
- Skills: `enrich-user-story`, `sdd-plan`, `write-pr-report`.
- Agentes: `implementing-agent` (Sonnet), `reviewer-agent` (Opus).
- Hook statusline + standards + templates de contexto.
- Pendiente: cableo del orquestador real (spawn de subagentes, protocolo `AGENT_{uuid}`).
