# Deuda técnica — ledger

Registro append-only de deuda **conocida y aceptada**. Acá cae lo que el ciclo SDD decidió no arreglar ahora: `MINOR` de review que no se corrigieron, gates `N/A` con razón, vulnerabilidades de dependencias sin fix aplicable, `manual-only` que deberían automatizarse. Si no se registra, la deuda es invisible hasta que vuelve como incidente.

Reglas:
- Escriben el planner y el reviewer (al cerrar un review con minors abiertos). Una fila por ítem.
- `Estado` se actualiza en la fila (`abierta | pagada <fecha> | aceptada-permanente <razón>`); nada se borra.
- En Feature Ready, el planner revisa las filas `abierta` del área tocada: si una feature pasa por encima de una deuda registrada, o la paga o la re-acepta explícito.

| ID | Fecha | Origen (task/review) | Descripción | Severidad | Dueño | Estado |
|---|---|---|---|---|---|---|
| D1 | 2026-08-13 | sicop-hardening · R0 contract v1 | AI-Forge no tiene CI (`.github/workflows` ausente). La escalera de `SDD/docs/doc_quality_gates.md` sólo corre local, sin paridad en el remoto. Crear el workflow cambia la política de merge del equipo, que es decisión de Gabriel. | MAJOR | Gabriel Rojas | abierta |
| D2 | 2026-08-13 | sicop-hardening · R2 contract v1 | Los commits de agente no van firmados con GPG. La identidad `sdd-agent` previene el descuido, no a un actor decidido: cualquiera puede declarar cualquier `user.name`. | MINOR | Gabriel Rojas | abierta |
| D3 | 2026-08-13 | sicop-hardening · R2 contract v1 | El enforcement de identidad de agente nace apagado: no protege nada hasta que un repo exporte `SDD_AGENT_ENFORCE=1`. Falta decidir en qué repos se activa. | MINOR | Gabriel Rojas | abierta |
| D4 | 2026-08-13 | sicop-hardening · R0 review ronda 1 | 3 hallazgos `SC2016` (info) de shellcheck en `plugins/sdd-flow/scripts/*.sh`, preexistentes en `prod`. Son backticks literales dentro de plantillas markdown — uso correcto, no defecto. Fuerzan el piso del gate 2 a `--severity=warning` en vez del default `style`. | MINOR | Gabriel Rojas | abierta |
| D5 | 2026-08-13 | sicop-hardening · R0 review ronda 1 | La "Suite completa" de `SDD/docs/doc_quality_gates.md` es el mismo comando que el gate 4, así que `--full` lo re-ejecuta y suma un verde sin agregar cobertura. Cuando el repo tenga una suite más lenta que la escalera, separarlas. | MINOR | Gabriel Rojas | abierta |
