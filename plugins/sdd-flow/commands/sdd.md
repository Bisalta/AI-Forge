---
description: Corre el ciclo SDD completo desde una idea cruda hasta Feature Ready (refinement -> contract -> spec -> ejecucion multi-agente).
argument-hint: "<descripcion de lo que queres lograr>"
---

# /sdd — Ciclo Spec-Driven Development

Sos el **planner Opus 4.8**. Orquestás el ciclo SDD completo para: **$ARGUMENTS**

Pipeline autónomo hasta **Feature Ready** (sin gate humano intermedio). El humano revisa de Feature Ready en adelante. Mantené las *closure rules* — el contract debe quedar cerrado igual, solo que sin aprobación humana intermedia.

**Contrato de máquina**: todo el ciclo se rige por `standards/orchestration.md` — vos escribís `.sdd/state.json` en cada transición (single-writer), los subagentes te devuelven bloques `sdd.result`/`sdd.review`, y los caps (3 rondas de review, 2 reintentos de gate, 3 agentes en paralelo, 1 re-spawn por `failed`) son duros.

## Fases

### −1. RESUME (antes que nada)
Si existe `.sdd/state.json` con `phase < 5`: hay un ciclo a medias. Mostrá task, fase y estado por agente, y **ofrecé reanudar** antes de arrancar nada nuevo (protocolo en `orchestration.md` §5 — agentes `APPROVED` no se relanzan; agentes `spawned` sin retorno se verifican contra su branch real y se re-spawnean desde su brief avisando que puede haber trabajo parcial). State corrupto → `.sdd/state.json.bak` y arrancás limpio. Verificá que `.sdd/` esté en `.gitignore` (agregalo si falta).

### 0. PROXIMA TRACKING (gate de arranque)
1. Detectá el MCP `proxima`: probá `proxima_list_projects`. Si el MCP no está o falla → avisá "sin tracking Proxima" y saltá a Fase 1 (el resto del flujo corre igual, con branch fallback).
2. Si responde: matcheá el trabajo (`$ARGUMENTS` + repo actual) contra los proyectos por `key`/`name`/`description`.
   - **Match único y claro** → usalo (solo avisá cuál).
   - **Varios candidatos** → listalos y pedí elegir uno.
   - **Ningún match** → preguntá en qué proyecto registrar (o seguir sin tracking).
3. Preguntá al usuario: **¿creo las tareas de este trabajo en Proxima?** (sí/no). Si **no** → seguí sin tracking (branch fallback).
4. Si **sí**: creá la **tarea madre** (la feature) con `proxima_create_task` (`projectKey`, `phase` 3 Implementación por defecto, `startAt`=ahora UTC, `endAt`=+2h) y `proxima_set_status` `in_progress`. Guardá su `key` (ej. `TRANS-23`) — es el padre de las subtasks por agente.

**Single-writer Proxima**: SOLO vos (el planner) llamás al MCP `proxima` (crear, set_status, log_progress, cerrar). Los implementing-agents NO tocan Proxima — reportan estado por el canal file-based y vos ratificás.

**Capa de integración** (detectá ahora, ver `standards/base-standards.md`): git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → corré el ciclo sin branch/PR (avisá). Proxima es independiente de la capa.

### 1. DECISION-CLOSED REFINEMENT
Invocá el skill **`enrich-user-story`**. Cerrá decisiones en las dimensiones obligatorias: las 6 funcionales (solution shape, output, behavior, actor, scope, success criteria) + **arquetipo** (exactamente uno, `standards/archetypes.md` — si parece dos, son dos requerimientos) + **NFR del arquetipo** + **concerns** (`standards/concerns.md`). Usá `AskUserQuestion` con opciones clickeables para forzar decisiones rápido. No avances con decisiones abiertas.
- Si el scope tiene frontend, el refinement cierra el bloque `seo:` (applies/indexable/locales) — ver `enrich-user-story`.

### 2. HIGH-LEVEL TECHNICAL CONTRACT
Invocá el skill **`sdd-plan`** para producir el HLTC con *Architectural Delta*, *Decision Closure* y *Data Contract Closure*. Antes de auto-aprobar: **`sdd-lint-contract.sh` verde** (frases abiertas y paths alucinados — exit 2 = el contract no está cerrado). **Auto-aprobá y logueá** el contract (no frenes a esperar humano). Single-writer: solo vos editás el contract; versionalo (v1, v2...).
- **Greenfield / repo sin escalera funcional**: si `doc_quality_gates.md` quedó todo `N/A` o no hay runner de tests, la **primera task es `project-scaffold`** (`standards/archetypes.md`) — el requerimiento funcional se planifica como segunda task, con gates ya vivos. No corras un ciclo de calidad con el sistema de calidad apagado.
- **Trabajo trivial detectado en el refinement** → cortá acá y derivá a `/sdd-fixes` (vía corta con mini-DoD). No infles la ceremonia.

### 3. IMPLEMENTATION SPEC + TOPOLOGIA
- Detectá los repos involucrados. Definí un `AGENT_{uuid}` por repo+branch+working-dir.
- **Si hay tracking Proxima** (Fase 0): creá una **subtask por agente** con `proxima_create_task` (`parentKey`=key de la tarea madre). Las subtasks NO devuelven key (solo UUID) — guardá su `id` para set_status/cierre. La **branch usa el key de la MADRE** (no el de la subtask).
- **Branch por agente**: `{action}-{KEY}-{agente}-{desc}` con `KEY` = key de la tarea madre y `agente` = slug del `AGENT_` para desambiguar (ej. `feat-GEN-30-be-add-endpoint`); single-repo sin slug (`feat-GEN-30-add-endpoint`). `action ∈ feat|fix|chore|refactor|docs`. Sin Proxima → fallback `<MODULO>-<TICKET>` / `<MODULO>-<desc>`. **Confirmá la rama base SIEMPRE; nunca commit directo a la base; integración según la capa** (con remote → PR; sin remote → merge local `--no-ff` tras review) hacia la base de la que se copió.
- Cortá el HLTC en task briefs por agente (task IDs `T<fase>.<i>`, checkboxes, Execution Report vacío). Cada brief lleva su `proxima_subtask_key` y la `branch` a usar.
- **Asigná modelo por tarea**: `sonnet` default; `opus` si es pesada/arquitectónica; `haiku` si es trivial.
- Si hay dependencias entre repos, definí **orden de integración** (ej. BE -> FE -> mobile).
- Creá la estructura de coordinación file-based (ver protocolo del repo `cross_agent_implementations`): `contract.md`, `status.md`, `messages/AGENT_a__to__AGENT_b/`.

### 4. EJECUCIÓN + GATES
Ejecutá los briefs según `orchestration.md` §4:

- **Spawn real**: un subagente `implementing-agent` por brief vía Agent tool, **pasando el modelo del brief** como override (el frontmatter es solo default). El prompt de spawn lleva: brief completo, ruta+versión del contract, ruta de `doc_quality_gates.md`, y la instrucción de cerrar con el bloque `sdd.result`. Si el entorno no tiene Agent tool → **degradá a inline** (vos ejecutás los briefs en serie, mismo contrato de estado y evidencia) y avisá una vez.
- **Serialización por repo**: máximo un agente activo por repo (dos en el mismo working tree se pisan). Mismo repo → en serie u worktrees separados declarados en el brief. Repos distintos → paralelo hasta `max_parallel_agents`.
- **State en cada transición**: escribí `.sdd/state.json` ANTES de spawnear (`spawned`) y al retornar (parseá el `sdd.result`; no parsea → `failed`, 1 re-spawn máximo).
- **Aceptación de un `done`**: validá el artefacto antes de creerle — `verification/` existe con exit codes, ningún AC `missing`/`fail`, `contract_version` vigente. Falla algo → sigue `working` y cuenta ronda.
- Para cada `done` aceptado, spawneá `reviewer-agent` (Opus, sin sesgo) sobre la spec/diff; parseá su `sdd.review`.
- **Loop acotado a 3 rondas** por brief (`standards/quality-gates.md` §7.4). Si la ronda 3 no cierra en `APPROVED`, el reviewer emite `ESCALATE` y vos decidís: ratificar contract (bump de versión), cortar scope, o elevar al gate humano. No dejes el loop abierto — es donde el agente empieza a ablandar tests para salir.
- **Ningún brief cierra sin evidencia**: escalera de gates corrida (`quality-gates.md` §4) y `verification.md` escrito con comando + exit code por gate. Un `done` sin evidencia lo tratás como no hecho, aunque el Execution Report diga verde.
- **Ningún AC sin test**: la tabla `AC ↔ test binding` del brief tiene que estar completa, con nombres de test que existen literal.
- Agente bloqueado (decisión no resuelta, o un gate que no pasa sin ablandar un test) → **BLOCKED → te pregunta, no adivina** → actualizás contract/spec → re-spawneás con la decisión en el brief. Un blocked NO consume ronda de review. Mismo gate rojo 2 veces con el mismo error → `blocked`, no tercer intento idéntico.
- **Retro**: cada `ESCALATE` resuelto, blocker repetido o prerequisito no documentado → una línea en `SDD/retro.md` (`orchestration.md` §6).
- Si `seo.applies == true`, el reviewer-agent adjunta una sección **SEO (advisory)** al testing/PR report. No bloquea Feature Ready.

### 5. FEATURE READY → PARÁ
Cuando todas las tareas estén `done` y validadas: **parate y pingueá al humano**. NO sigas a PR sin revisión humana. Escribí el state final (`phase: 5`) y releé `SDD/retro.md`: si un patrón se repitió, proponé el ajuste al doc que corresponda.
- **Checklist de Feature Ready** (si algo falla, no es Feature Ready — es trabajo en curso): todos los ACs del HLTC con test verde o smoke `manual-only` ejecutado · suite completa corrida al menos una vez · reporte de gates **generado por el runner** por cada agente · cero mitigaciones prohibidas en el diff · veredicto `APPROVED` de cada brief · docs delta aplicado · deuda registrada en el ledger.
- **El ping al humano es el brief de `templates/feature-ready-brief.md` — UNA pantalla**: qué es, las decisiones que tomaste por él, dónde está el riesgo, qué mirar en 5 minutos, estado honesto en tabla, y la evidencia completa como apéndice de links. Un muro de ACs y exit codes en el único gate humano lo convierte en rubber-stamp — el detalle está disponible, no en el cuerpo.
- **Cierre Proxima por integración**: Feature Ready NO cierra la tarea. Cada subtask pasa a `done` (con `proxima_set_status` por su `id` — las subtasks no tienen key) **solo cuando se integra** (PR mergeado con remote, o merge local `--no-ff` sin remote). Cuando TODAS las subtasks están `done` → marcá la **tarea madre** `done` (por su `key`). Logueá milestones con `proxima_log_progress` (PR abierto/CI verde/merge, o review ok/merge local).

## Reglas
- Leé `SDD/docs/doc_architecture.md`, `doc_verification_guide.md` y `doc_quality_gates.md` de cada repo antes de planear. Si falta alguno → `/sdd-init` (no inventes comandos de validación).
- Seguí `standards/base-standards.md` y `standards/quality-gates.md` del plugin.
- Validación no es opcional y no es declarativa: cada task brief lleva la escalera de gates con comandos reales, y cada `done` deja evidencia con exit codes.
- Los ACs del HLTC son la unidad de verdad de "está probado": numerados, asignados a un brief, con un test cada uno.
