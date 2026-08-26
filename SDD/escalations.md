# Ledger de ESCALATE / REJECTED — clasificación por causa raíz

Un evento por fila: `ESCALATE` que agotó las 3 rondas, `REJECTED` que forzó una ratificación
de contract, o un `blocked` repetido con el mismo error (`orchestration.md` §4). La clasificación
la escribe el planner **en el mismo acto** en que resuelve el evento — ratifica contract,
re-spawnea, o corta scope — no después, y no otra persona releyendo el ciclo más tarde. Es la
misma regla que `Mutación:` en `quality-gates.md` §10: se declara con el contexto fresco, no se
reconstruye por arqueología.

**Clase** (cerrado — elegí una):
- `plan` — el implementador cumplió literalmente lo pedido y lo pedido estaba mal.
- `decisión` — dos ingenieros razonables lo habrían resuelto distinto; no es un defecto.
- `medición` — el arnés o el instrumento de verificación estaba roto, no el plan ni el código.
- `otro` — ninguna de las anteriores; explicar en la fila.

`SDD/scripts/sdd-escalation-tally.sh` cuenta esta tabla por Clase. **No se re-deriva a mano** —
se corre el script.

| # | Fecha | Ciclo · brief | Evento | Clase | Retro ref |
|---|---|---|---|---|---|
| E1 | 2026-08-13 | sicop-hardening · R0 (v1→v2) | `ESCALATE` R0 ronda 1 — threat model y `concerns:` ausentes; AC3 exigía tocar lo prohibido por el propio out-of-scope | plan | RT1, RT2 |
| E2 | 2026-08-13 | sicop-hardening · R0 (v2→v3) | `REJECTED` R0 ronda 2 — el fix de un MAJOR excluyó `SDD/contracts/` entero del secret-scan; causa raíz: AC6bis citaba credenciales que disparaban el propio detector | plan | RT3, RT4 |
| E3 | 2026-08-13 | sicop-hardening · R2 (v4→v5) | `ESCALATE` R2 ronda 1 — bloque de identidad ubicado "tras X" quedó aguas abajo de 4 salidas tempranas del chequeo de rama | plan | RT9 |

**Backfill, no derivación en vivo**: las 3 filas de arriba se reconstruyeron el 26-ago-2026 —
después del hecho, cruzando el historial de versiones de
`SDD/contracts/2026-08-13-sicop-hardening.md` (`grep -nE 'ESCALATE|REJECTED'`) contra las filas
de `SDD/retro.md` que ya nombraban la causa raíz. Es exactamente la arqueología manual que este
archivo existe para no tener que repetir cada vez — a partir de la primera fila que se escriba
en vivo (`commands/sdd.md`, regla de Retro), la clasificación se declara en el momento.

**Total en este repo**: 3 eventos, 3 `plan`, 0 `decisión`, 0 `medición`, 0 `otro`. Corresponde con
`CLAUDE.md` ("tres ESCALATE/REJECTED resueltos" en GEN-94) — coincidencia verificada, no
asumida: la cifra de `CLAUDE.md` nombraba el conteo total, no la clasificación por causa; esta
tabla es la primera vez que las 3 quedan clasificadas explícitamente.
