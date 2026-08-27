# Ledger de eventos contables — clasificación por causa raíz

**Evento contable** (definición cerrada en `plugins/sdd-flow/standards/orchestration.md` §6.1):
toda ratificación de contract motivada por un defecto — `ESCALATE`, `REJECTED`, un `BLOCKED`
que ratificó (no sólo respondió una pregunta), o una re-review que encontró que el propio
contract incumplía su propia regla. No cuenta una ampliación de scope sin defecto de por medio.

La clasificación la escribe el planner **en el mismo acto** de ratificar — no después. Es la
misma regla que `Mutación:` en `quality-gates.md` §10.

**Clase** (cerrado — elegí una):
- `plan` — el defecto vive en lo que el contract/checklist pedía: el implementador cumplió
  literalmente y estaba mal, **o** lo detectó antes de implementar y preguntó (`BLOCKED`).
- `decisión` — dos ingenieros razonables lo habrían resuelto distinto; no es un defecto.
- `medición` — el arnés o el instrumento de verificación estaba roto, no el plan ni el código.
- `otro` — ninguna de las anteriores; explicar en la fila.

`SDD/scripts/sdd-escalation-tally.sh` cuenta esta tabla por Clase. No se re-deriva a mano.

| # | Fecha | Ciclo · brief | Evento | Clase | Retro ref |
|---|---|---|---|---|---|
