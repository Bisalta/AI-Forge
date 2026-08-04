# Deuda técnica — ledger

Registro append-only de deuda **conocida y aceptada**. Acá cae lo que el ciclo SDD decidió no arreglar ahora: `MINOR` de review que no se corrigieron, gates `N/A` con razón, vulnerabilidades de dependencias sin fix aplicable, `manual-only` que deberían automatizarse. Si no se registra, la deuda es invisible hasta que vuelve como incidente.

Reglas:
- Escriben el planner y el reviewer (al cerrar un review con minors abiertos). Una fila por ítem.
- `Estado` se actualiza en la fila (`abierta | pagada <fecha> | aceptada-permanente <razón>`); nada se borra.
- En Feature Ready, el planner revisa las filas `abierta` del área tocada: si una feature pasa por encima de una deuda registrada, o la paga o la re-acepta explícito.

| ID | Fecha | Origen (task/review) | Descripción | Severidad | Dueño | Estado |
|---|---|---|---|---|---|---|
| D1 | <YYYY-MM-DD> | <task-slug · ronda 2> | <qué quedó debiendo, con archivo si aplica> | MINOR | <quién decide pagarla> | abierta |
