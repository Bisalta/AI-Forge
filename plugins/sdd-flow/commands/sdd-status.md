---
description: Muestra el tablero de estado de los agentes y tareas SDD en vuelo.
---

# /sdd-status — Tablero SDD

Leé el directorio de coordinación (por defecto `cross_agent_implementations/` o el `.sdd/` del proyecto) y mostrá:

1. **Tareas activas** (`tasks/<slug>/status.md`) — estado por agente: `pending | in_progress | blocked | done`.
2. **Mensajes sin procesar** por outbox `messages/AGENT_a__to__AGENT_b/` (los que NO están en `archive/`).
3. **Contract version** actual por tarea.
4. **Bloqueos** abiertos (agentes en `blocked` + razón).
5. **Orden de integración** pendiente (qué repo mergea antes que cuál).

Formato: tabla compacta. No edites nada — solo lectura.
