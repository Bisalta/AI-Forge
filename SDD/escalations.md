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
| E7 | 2026-08-26 | consumo GEN-101 · ronda 1 (v6→v7) | `REJECTED` — `reviewer-agent`, primera revisión independiente del ciclo: 4 BLOCKER (sin verification report de agente, 4 ACs de detección sin triple, una pata de triple fabricada, AC26 sin evidencia independiente) + 8 MAJOR + 6 MINOR | plan | (sin fila propia en `retro.md` — el detalle vive en la ratificación v7 del contract y en el propio `sdd.review` de la ronda) |
| E8 | 2026-08-27 | consumo GEN-101 · ronda 2 (v7→v8) | `REJECTED` — segunda revisión independiente: 7 MAJOR, la mayoría (5 de 7) fixes de la ronda 1 que no se propagaron a todos los lugares que citaban el valor viejo (AC23 seguía en 3, AC8 seguía en 0.11.0, AC17 nombraba `planner` pero el test corría `reviewer`, la cita a `RT18-RT21` en la propia ratificación v7 nombraba entradas de retro que nunca se escribieron, el binding de AC26 apuntaba a un archivo ya renombrado) + 1 MAJOR residual real (el fix de M4/MAJOR10 sólo cubría la forma prefijada de las citas a `standards/`, no la pelada) + su propio gemelo irónico (esta misma fila: el mecanismo de R6 no se usó sobre su propio primer evento calificado, en el mismo commit que lo construyó) | plan | (ídem E7 — `sdd.review` de la ronda 2) |

**Total en este repo**: 8 eventos, 8 `plan`, 0 `decisión`, 0 `medición`, 0 `otro`.

**Backfill, no derivación en vivo (E1-E6)**: reconstruido el 26-ago-2026, en dos pasadas. La
primera (grep literal de `ESCALATE|REJECTED` sobre el historial de versiones) encontró sólo E1,
E2, E3 — y quedó mal: el propio método no puede ver un evento que forzó ratificación sin usar
esas dos palabras, que es exactamente lo que le pasó a E4 y E5 (ambos narrados como "review" o
"re-review", nunca como "ESCALATE"/"REJECTED" literal). Encontrado por revisión externa
(`reviewer-agent`, ronda 1 de este mismo ciclo). La segunda pasada leyó las 7 entradas rotuladas
"Historial de versiones" (v2 a v8) más la versión base v1 — 8 versiones en total, no 8 entradas
de ese rótulo (corregido, hallazgo de ronda 2, MINOR m2) — del contract completo, no sólo las
que contenían el literal buscado.

**E7 y E8, en vivo — y la ironía que E8 documenta**: el mecanismo de R6 se construyó
específicamente para que "toda ratificación por defecto" quedara clasificada sin depender de
que alguien se acuerde de escribirla. Su primer uso real debía ser E7 (la ratificación v6→v7,
forzada por el propio `REJECTED` de la ronda 1) — y no se escribió en el mismo acto: se escribió
recién acá, al corregir el hallazgo de la ronda 2 que lo señaló. Es la misma clase de defecto que
el resto de este archivo cataloga, aplicada al archivo mismo.

**Por qué el total no coincide con ningún número ya publicado, y por qué eso está bien**:
`CLAUDE.md` dice *"tres `ESCALATE`/REJECTED resueltos"* y *"de los ocho defectos... seis eran
del plan"*. Ninguna de esas dos cifras es la misma unidad que esta tabla. "Tres ESCALATE/REJECTED"
cuenta sólo los eventos que usan esos dos nombres literales (E1, E2, E3) — excluye E4-E6 porque
llegaron por `APPROVED`-con-gaps, re-review y `BLOCKED`, no por esas dos palabras. "Ocho
defectos" cuenta *defectos individuales*, no *eventos de ratificación* — un solo evento puede
agrupar más de un defecto (E1 agrupa dos: RT1 y RT2). No se fuerza una reconciliación entre las
tres cifras porque no miden lo mismo; forzarla sería fabricar una precisión que no existe.
