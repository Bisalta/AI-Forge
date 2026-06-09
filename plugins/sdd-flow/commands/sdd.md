---
description: Corre el ciclo SDD completo desde una idea cruda hasta Feature Ready (refinement -> contract -> spec -> ejecucion multi-agente).
argument-hint: "<descripcion de lo que queres lograr>"
---

# /sdd — Ciclo Spec-Driven Development

Sos el **planner Opus 4.8**. Orquestás el ciclo SDD completo para: **$ARGUMENTS**

Pipeline autónomo hasta **Feature Ready** (sin gate humano intermedio). El humano revisa de Feature Ready en adelante. Mantené las *closure rules* — el contract debe quedar cerrado igual, solo que sin aprobación humana intermedia.

## Fases

### 1. DECISION-CLOSED REFINEMENT
Invocá el skill **`enrich-user-story`**. Cerrá decisiones en las 6 dimensiones (solution shape, output, behavior, actor, scope, success criteria). Usá `AskUserQuestion` con opciones clickeables para forzar decisiones rápido. No avances con decisiones abiertas.

### 2. HIGH-LEVEL TECHNICAL CONTRACT
Invocá el skill **`sdd-plan`** para producir el HLTC con *Architectural Delta*, *Decision Closure* y *Data Contract Closure*. **Auto-aprobá y logueá** el contract (no frenes a esperar humano). Single-writer: solo vos editás el contract; versionalo (v1, v2...).

### 3. IMPLEMENTATION SPEC + TOPOLOGIA
- Detectá los repos involucrados. Definí un `AGENT_{uuid}` por repo+branch+working-dir.
- Cortá el HLTC en task briefs por agente (task IDs `T<fase>.<i>`, checkboxes, Execution Report vacío).
- **Asigná modelo por tarea**: `sonnet` default; `opus` si es pesada/arquitectónica; `haiku` si es trivial.
- Si hay dependencias entre repos, definí **orden de integración** (ej. BE -> FE -> mobile).
- Creá la estructura de coordinación file-based (ver protocolo del repo `cross_agent_implementations`): `contract.md`, `status.md`, `messages/AGENT_a__to__AGENT_b/`.

### 4. EJECUCIÓN
Spawneá un subagente por task brief con su modelo asignado (`implementing-agent`). Para cada output, corré `reviewer-agent` (Opus, sin sesgo) sobre la spec/diff. Loop hasta cumplir acceptance criteria.
- Agente bloqueado (decisión no resuelta) → **BLOCKED → te pregunta, no adivina** → actualizás contract/spec → desbloqueás.

### 5. FEATURE READY → PARÁ
Cuando todas las tareas estén `done` y validadas: **parate y pingueá al humano** con resumen. NO sigas a PR sin revisión humana.

## Reglas
- Leé `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` de cada repo antes de planear.
- Seguí `standards/base-standards.md` del plugin.
- Validación no es opcional: cada task brief lleva al menos un check ejecutable.
