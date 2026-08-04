---
description: Muestra el tablero de estado de los agentes y tareas SDD en vuelo.
---

# /sdd-status — Tablero SDD

Leé el directorio de coordinación (por defecto `cross_agent_implementations/` o el `.sdd/` del proyecto) y mostrá:

1. **Tareas activas** (`tasks/<slug>/status.md`) — estado por agente: `pending | in_progress | blocked | done`.
2. **Mensajes sin procesar** por outbox `messages/AGENT_a__to__AGENT_b/` (los que NO están en `archive/`).
3. **Contract version** actual por tarea.
4. **Gates**: por agente, leé `tasks/<slug>/verification/AGENT_<slug>.md` y mostrá cuántos gates están en verde / rojo / `[SKIPPED]`, y `sin evidencia` si el archivo no existe.
5. **ACs sin test**: filas incompletas de la tabla `AC ↔ test binding` de cada brief.
6. **Bloqueos** abiertos (agentes en `blocked` + razón).
7. **Orden de integración** pendiente (qué repo mergea antes que cuál).

Marcá en la tabla cualquier agente en `done` **sin** evidencia de gates o con ACs sin test: es un `done` que no cumple la Definition of Done (`standards/quality-gates.md` §1) y hay que tratarlo como trabajo en curso.

Formato: tabla compacta. No edites nada — solo lectura.
