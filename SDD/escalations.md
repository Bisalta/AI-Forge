# Ledger de eventos contables — clasificación por causa raíz

**Evento contable** (definición cerrada en `plugins/sdd-flow/standards/orchestration.md` §6.1):
toda ratificación de contract motivada por un defecto — `ESCALATE`, `REJECTED`, un `BLOCKED`
que ratificó (no sólo respondió una pregunta), o una re-review que encontró que el propio
contract incumplía su propia regla. No cuenta una ampliación de scope sin defecto de por medio.

La clasificación la escribe el planner **en el mismo acto** de ratificar — no después, y no
otra persona releyendo el ciclo más tarde. Es la misma regla que `Mutación:` en
`quality-gates.md` §10.

**Clase** (cerrado — elegí una):
- `plan` — el defecto vive en lo que el contract/checklist pedía: el implementador cumplió
  literalmente y estaba mal, **o** lo detectó antes de implementar y preguntó (`BLOCKED`).
- `decisión` — dos ingenieros razonables lo habrían resuelto distinto; no es un defecto.
- `medición` — el arnés o el instrumento de verificación estaba roto, no el plan ni el código.
- `otro` — ninguna de las anteriores; explicar en la fila.

`SDD/scripts/sdd-escalation-tally.sh` cuenta esta tabla por Clase. **No se re-deriva a mano** —
se corre el script.

| # | Fecha | Ciclo · brief | Evento | Clase | Retro ref |
|---|---|---|---|---|---|
| E1 | 2026-08-13 | sicop-hardening · R0 (v1→v2) | `ESCALATE` R0 ronda 1 — threat model y declaración de concerns ausentes; AC3 exigía tocar lo prohibido por el propio out-of-scope | plan | RT1, RT2 |
| E2 | 2026-08-13 | sicop-hardening · R0 (v2→v3) | `REJECTED` R0 ronda 2 — el fix de un MAJOR excluyó `SDD/contracts/` entero del secret-scan; causa raíz: AC6bis citaba credenciales que disparaban el propio detector | plan | RT3, RT4 |
| E3 | 2026-08-13 | sicop-hardening · R2 (v4→v5) | `ESCALATE` R2 ronda 1 — bloque de identidad ubicado "tras X" quedó aguas abajo de 4 salidas tempranas del chequeo de rama | plan | RT9 |
| E4 | 2026-08-14 | sicop-hardening · R3 (v5→v6) | Review de R3 `APPROVED`, pero encontró 3 gaps del propio contract: AC39/AC40 (consumidores de la regla de mutación ausentes del Delta — "gaps de mi Architectural Delta", autodeclarado) y AC41 (ambigüedad de closure en un AC previo, R2/AC16) | plan | — (no tiene fila propia en retro.md; documentado sólo en la ratificación v6 del contract) |
| E5 | 2026-08-14 | sicop-hardening · R3 (v6→v7) | Re-review por AC24 encontró que el contract incumplía su propia regla nueva (§10.2): ningún AC de detección declaraba `Mutación:` | plan | — (idem E4, ratificación v7) |
| E6 | 2026-08-14 | sicop-hardening · R4 (v7→v8) | `BLOCKED` ronda 1 — el implementador auditó el checklist estadístico del arquetipo `analysis` y encontró 2 de 7 ítems autosatisfacibles por el error que pretenden prevenir | plan | RT10 |

**Total en este repo**: 6 eventos, 6 `plan`, 0 `decisión`, 0 `medición`, 0 `otro`.

**Backfill, no derivación en vivo**: reconstruido el 26-ago-2026, en dos pasadas. La primera
(grep literal de `ESCALATE|REJECTED` sobre el historial de versiones) encontró sólo E1, E2, E3
— y quedó mal: el propio método no puede ver un evento que forzó ratificación sin usar esas dos
palabras, que es exactamente lo que le pasó a E4 y E5 (ambos narrados como "review" o
"re-review", nunca como "ESCALATE"/"REJECTED" literal). Encontrado por revisión externa
(`reviewer-agent`, ronda 1 de este mismo ciclo). La segunda pasada leyó las 8 entradas de
"Historial de versiones" del contract completo, no sólo las que contenían el literal buscado.

**Por qué el total no coincide con ningún número ya publicado, y por qué eso está bien**:
`CLAUDE.md` dice *"tres `ESCALATE`/REJECTED resueltos"* y *"de los ocho defectos... seis eran
del plan"*. Ninguna de esas dos cifras es la misma unidad que esta tabla. "Tres ESCALATE/REJECTED"
cuenta sólo los eventos que usan esos dos nombres literales (E1, E2, E3) — excluye E4-E6 porque
llegaron por `APPROVED`-con-gaps, re-review y `BLOCKED`, no por esas dos palabras. "Ocho
defectos" cuenta *defectos individuales*, no *eventos de ratificación* — un solo evento puede
agrupar más de un defecto (E1 agrupa dos: RT1 y RT2). No se fuerza una reconciliación entre las
tres cifras porque no miden lo mismo; forzarla sería fabricar una precisión que no existe.
