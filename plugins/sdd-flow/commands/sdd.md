---
description: Corre el ciclo SDD completo desde una idea cruda hasta Feature Ready (refinement -> contract -> spec -> ejecucion multi-agente).
argument-hint: "<descripcion de lo que queres lograr>"
---

# /sdd — Ciclo Spec-Driven Development

Sos el **planner Opus 4.8**. Orquestás el ciclo SDD completo para: **$ARGUMENTS**

Pipeline autónomo hasta **Feature Ready** (sin gate humano intermedio). El humano revisa de Feature Ready en adelante. Mantené las *closure rules* — el contract debe quedar cerrado igual, solo que sin aprobación humana intermedia.

## Fases

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
Invocá el skill **`enrich-user-story`**. Cerrá decisiones en las 6 dimensiones (solution shape, output, behavior, actor, scope, success criteria). Usá `AskUserQuestion` con opciones clickeables para forzar decisiones rápido. No avances con decisiones abiertas.

### 2. HIGH-LEVEL TECHNICAL CONTRACT
Invocá el skill **`sdd-plan`** para producir el HLTC con *Architectural Delta*, *Decision Closure* y *Data Contract Closure*. **Auto-aprobá y logueá** el contract (no frenes a esperar humano). Single-writer: solo vos editás el contract; versionalo (v1, v2...).

### 3. IMPLEMENTATION SPEC + TOPOLOGIA
- Detectá los repos involucrados. Definí un `AGENT_{uuid}` por repo+branch+working-dir.
- **Si hay tracking Proxima** (Fase 0): creá una **subtask por agente** con `proxima_create_task` (`parentKey`=key de la tarea madre). Guardá el `key` de cada subtask (ej. `TRANS-24`) — va en el task brief de ese agente y nombra su branch.
- **Branch por agente** (orden estricto: subtask Proxima primero → branch después): `{action}-{KEY}-{desc}`, `action ∈ feat|fix|chore|refactor|docs` (ej. `feat-TRANS-24-add-endpoint`). Sin Proxima → fallback `<MODULO>-<TICKET>` / `<MODULO>-<desc>`. **Confirmá la rama base SIEMPRE; nunca commit/push directo a la base; integración SOLO vía PR** hacia la base de la que se copió.
- Cortá el HLTC en task briefs por agente (task IDs `T<fase>.<i>`, checkboxes, Execution Report vacío). Cada brief lleva su `proxima_subtask_key` y la `branch` a usar.
- **Asigná modelo por tarea**: `sonnet` default; `opus` si es pesada/arquitectónica; `haiku` si es trivial.
- Si hay dependencias entre repos, definí **orden de integración** (ej. BE -> FE -> mobile).
- Creá la estructura de coordinación file-based (ver protocolo del repo `cross_agent_implementations`): `contract.md`, `status.md`, `messages/AGENT_a__to__AGENT_b/`.

### 4. EJECUCIÓN
Spawneá un subagente por task brief con su modelo asignado (`implementing-agent`). Para cada output, corré `reviewer-agent` (Opus, sin sesgo) sobre la spec/diff. Loop hasta cumplir acceptance criteria.
- Agente bloqueado (decisión no resuelta) → **BLOCKED → te pregunta, no adivina** → actualizás contract/spec → desbloqueás.

### 5. FEATURE READY → PARÁ
Cuando todas las tareas estén `done` y validadas: **parate y pingueá al humano** con resumen. NO sigas a PR sin revisión humana.
- **Cierre Proxima por integración**: Feature Ready NO cierra la tarea. Cada subtask pasa a `done` (con `proxima_set_status`, lo hacés vos al confirmar el agente) **solo cuando se integra** (PR mergeado con remote, o merge local `--no-ff` sin remote). Cuando TODAS las subtasks están `done` → marcá la **tarea madre** `done`. Logueá milestones con `proxima_log_progress` (PR abierto/CI verde/merge, o review ok/merge local).

## Reglas
- Leé `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` de cada repo antes de planear.
- Seguí `standards/base-standards.md` del plugin.
- Validación no es opcional: cada task brief lleva al menos un check ejecutable.
