# Verification Report — planner inline · refactor-GEN-101-optimizacion-consumo

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5). Lo escribe quien hizo el
trabajo — acá, el planner corriendo inline sin spawn de subagentes (declarado en
`.sdd/state.json`, `execution_mode: inline`) — y lo audita el reviewer-agent. Un gate sin fila
acá **no corrió**, independientemente de lo que diga cualquier resumen previo en el chat.

- **Branch**: `refactor-GEN-101-optimizacion-consumo`
- **Contract**: `SDD/contracts/2026-08-25-consumption-optimization.md` v8
- **Commit evaluado**: HEAD al momento de escribir este archivo (ver el commit real en el log de git — este archivo se escribe antes del commit final del ciclo, así que no hay un sha fijo previo que citar sin mentir)
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — hash en cada reporte generado referenciado abajo

**Por qué existe este archivo, cuando no existía hasta ahora**: revisión externa (`reviewer-agent`
Opus, ronda 1) encontró que los cuatro reportes previos (`-R1.md`, `-R2-R3.md`, `-R4.md`,
`-R6.md`) eran **reportes del runner** —su propia primera línea lo dice: "Este archivo lo
escribió el runner, no un modelo"— ocupando el nombre que `quality-gates.md` §5 reserva al
reporte que escribe el agente (impact set, rojos preexistentes, y sobre todo: las corridas de
mutación, que el runner no conoce). Se renombraron a `-gates.md` y este archivo es el que
faltaba. BLOCKER 1 de la ronda 1.

---

## Gates — evidencia GENERADA (no se reescribe a mano)

Cuatro corridas del runner durante el ciclo, una por hito de trabajo:

| Reporte generado | Commit | Tree | Resultado |
|---|---|---|---|
| `SDD/verification/refactor-GEN-101-optimizacion-consumo-R1-gates.md` | `669efdf` | `420b7f5cf7cba465adb80431c8450d687041bd12` | 4 verdes / 0 rojos / 7 skipped |
| `SDD/verification/refactor-GEN-101-optimizacion-consumo-R2-R3-gates.md` | `86ba9c5` | `6a457fba09a3cf04fcf2c7c74f5dc7660950354c` | 4 verdes / 0 rojos / 7 skipped |
| `SDD/verification/refactor-GEN-101-optimizacion-consumo-R4-gates.md` | `f7660f5` | `3011c52687b0d37ae1340d98fe11b81a22ca6078` | 4 verdes / 0 rojos / 7 skipped |
| `SDD/verification/refactor-GEN-101-optimizacion-consumo-R6-gates.md` | `7087d04` | `37a1d16decb9af594015030882699531b0fa56f6` | 4 verdes / 0 rojos / 7 skipped |

Corridas rojas intermedias: ninguna — la suite estuvo verde en cada punto donde se generó
evidencia. Eso no significa que no hubiera rojos durante el desarrollo (los hubo, ver más
abajo cada AC de detección: la corrida 2 de cada triple es roja por diseño); significa que no
se selló evidencia commiteable con la suite general en rojo.

**Corrida final, post-v7** (todos los fixes de esta ronda ya aplicados):

```
$ bash SDD/tests/run.sh
PASS  test_analysis_archetype.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
12 passed, 0 failed (12 total)
```

Un quinto reporte del runner, sellado sobre el árbol con todos los fixes de v7 aplicados,
se genera y commitea junto con este archivo (mismo patrón que R1/R2-R3/R4/R6, sufijo `-gates.md`).

---

## Prueba por mutación (ACs de detección)

12 secciones — las 11 ACs de detección del contract completo (R1: AC19, AC20 · R2: AC10 · R4:
AC1, AC2, AC3, AC4, AC6, AC9 · R6: AC23, AC24) más AC27 (R4), que **no** es de detección por
§10.1 pero lleva triple voluntario (ver su sección, corregida tras MINOR m4 de ronda 2). Cada
triple se corrió de verdad,
contra archivos reales o copias en tmpdir — nunca contra el repo commiteado (verificado:
`git status --short` después de las 12 corridas no muestra ningún archivo tocado por una
mutación, sólo los cambios intencionales de este ciclo).

### AC10 — el grep de versiones pinneadas detecta una violación real

- **Mutación declarada en el contract**: reintroducir el literal `Opus 4.8` en `plugins/sdd-flow/README.md` línea 5 · queda revertido.

| # | Estado del sistema | Comando | Resultado |
|---|---|---|---|
| 1 | intacto | grep sobre `plugins/` + `CLAUDE.md`, excluyendo líneas de prohibición | **0 hits** |
| 2 | con la mutación | reintroducido `Opus 4.8` en README.md:5 | **1 hit** |
| 3 | mutación revertida | `cp` del backup sobre README.md | **0 hits** |

```
--- 2) con la mutación ---
hits: 1
5:Planner Opus 4.8 cierra decisiones — MUTACION DE PRUEBA
--- 3) revertida ---
hits: 0
diff contra el repo real: 0 líneas (0 = idéntico)
```

Reversión verificada por diff contra el repo real (0 líneas), no a ojo.

---

### AC1 — falta Threat model

- **Mutación declarada**: vaciar `SECTIONS_CONTRACT` y `SECTIONS_REQ` en `sdd-lint-contract.sh` · tras el bucle · queda revertida.

| # | Estado | Comando | Exit | Resultado |
|---|---|---|---|---|
| 1 | intacto | `sdd-lint-contract.sh completo_sin_threat.md` | **2** | `BLOCKER 0 seccion-ausente Threat model` |
| 2 | mutante | ídem, listas vacías | **0** | (sin salida — pierde la detección) |
| 3 | revertido | ídem, script real | **2** | `BLOCKER 0 seccion-ausente Threat model` |

---

### AC2 — faltan las 4 secciones de contract

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **2** | 4 líneas `BLOCKER seccion-ausente` (Objective, Out of scope, Threat model, concerns:) |
| 2 | mutante | **2** | sólo 1 línea (`concerns:` — no gobernada por la lista mutada, ver nota) |
| 3 | revertido | **2** | 4 líneas de nuevo |

Nota real, no anticipada: `concerns:` sigue detectándose bajo la mutación porque su chequeo
vive en un acumulador separado (`HAS_CONCERNS`), no en `SECTIONS_CONTRACT`. El rojo es parcial
(4→1), no total (4→0) — y eso es correcto: la mutación declarada sólo vacía dos listas, no las
tres formas de chequeo del linter.

---

### AC3 — R1 sin Acceptance criteria

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **2** | `BLOCKER 0 seccion-ausente R1: Acceptance criteria` |
| 2 | mutante | **0** | (sin salida) |
| 3 | revertido | **2** | `BLOCKER 0 seccion-ausente R1: Acceptance criteria` |

---

### AC4 — sin bloques `# R<n>`, documento entero es un requerimiento

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **2** | `BLOCKER 0 seccion-ausente Architectural Delta` |
| 2 | mutante | **0** | (sin salida) |
| 3 | revertido | **2** | `BLOCKER 0 seccion-ausente Architectural Delta` |

---

### AC6 — regresión contract GEN-94 (artefacto real, no una fixture del propio brief)

- **Mutación declarada**: ampliar `SECTIONS_CONTRACT` con `Seccion Que No Existe` · antes de `Objective` · queda revertida.

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **0** | sólo 5 `WARN path-inexistente` (paths reales del propio contract de GEN-94, no `seccion-ausente`) |
| 2 | mutante | **2** | los mismos 5 `WARN` + `BLOCKER 0 seccion-ausente Seccion Que No Existe` |
| 3 | revertido | **0** | sólo los 5 `WARN`, de nuevo |

Este es el único triple de los 12 que corre contra un artefacto que nadie escribió para este
ciclo (`SDD/contracts/2026-08-13-sicop-hardening.md`, de GEN-94) — el resto corre contra
fixtures nuevas que comparten los supuestos de quien las escribió.

---

### AC9 — frase abierta y sección ausente, chequeos independientes

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **2** | `frase-abierta` (línea 3) **y** `seccion-ausente Threat model` |
| 2 | mutante | **2** | sólo `frase-abierta` — pierde `seccion-ausente`, exit sigue en 2 por el otro chequeo |
| 3 | revertido | **2** | ambos de nuevo |

El rojo de este AC es la **desaparición de una de las dos líneas**, no un cambio de exit code —
el exit code por sí solo no lo hubiera distinguido, que es justo por lo que el AC pide "reporta
ambas", no sólo "sale 2".

---

### AC27 — `concerns:` en blockquote no produce falso `BLOCKER` (v7, hallazgo de revisión externa)

- **Triple voluntario, no exigido por §10.1** (corregido tras ronda 2, MINOR m4 — la versión previa de este archivo decía "mutación declarada", pero el contract clasifica AC27 junto a AC5/AC7 como afirmación de ausencia-de-falso-positivo, no como AC de detección; §10.1 no lo exige). Se documenta igual porque ya se ejecutó y es evidencia real de que el fix sostiene: revertir el strip-prefix (quitar `'|'*|'>'*` del case) reproduce el falso positivo.

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto (con el fix) | **0** | limpio |
| 2 | mutante (fix revertido) | **2** | `BLOCKER 0 seccion-ausente concerns:` — el falso positivo original, reproducido |
| 3 | revertido (fix real de nuevo) | **0** | limpio |

---

### AC19 — rol inválido

- **Mutación declarada**: quitar la validación de rol del bloque de argv · queda revertida.

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **2** | `ERROR: rol desconocido: arquitecto` + uso |
| 2 | mutante | **0** | `TOTAL 0 0 0 archivo(s)` (ver nota) |
| 3 | revertido | **2** | `ERROR: rol desconocido: arquitecto` + uso |

Nota real y no predicha de antemano (`RT15` — no se anticipa el comportamiento exacto de un
mutante, se compara contra las corridas limpias): el mutante no crashea con un exit distinto,
como hubiera sido razonable esperar de `set -u` sobre una variable sin asignar. La salida real
capturada:

```
mut_rol.sh: line 68: ENTRY_POINTS: unbound variable
mut_rol.sh: line 66: ENTRY_POINTS: unbound variable
# sdd-context-budget 0.2.0 — contexto ESTÁTICO del rol `arquitecto`
...
TOTAL          0         0  0 archivo(s)
exit=0
```

El error de variable no asignada ocurre **dentro de una sustitución de comando** (`STANDARDS_REFS="$(for ep in $ENTRY_POINTS...)"`), y bajo `set -u` sin `-e`, un error ahí no mata al script padre — la sustitución devuelve vacío y la ejecución sigue. El resultado observable (`TOTAL 0`, exit 0) sigue siendo una pérdida de detección real: la corrida 1 y la 3 devuelven el mismo `ERROR`/exit 2, la 2 devuelve otra cosa — las tres se distinguen, que es lo que el AC exige, sin que hiciera falta predecir la forma exacta del rojo.

---

### AC20 — total re-derivado, rol `implementing`

- **Mutación declarada**: sumar el peso del primer archivo dos veces en el acumulador · queda revertida.

| # | Estado | Suma independiente (`awk`) | `TOTAL` reportado |
|---|---|---|---|
| 1 | intacto | 59238 | 59238 (coincide) |
| 2 | mutante | 59238 | 67912 (**difiere** — el acumulador interno duplicó `implementing-agent.md`) |
| 3 | revertido | — | 59238 (coincide de nuevo) |

---

### AC23 — el tally cuenta correcto, responde al archivo real

- **Mutación declarada**: agregar una séptima fila `E7` con `Clase: decisión` a una copia · antes del backfill note · queda revertida.

| # | Estado | Resultado |
|---|---|---|
| 1 | intacto | `TOTAL 6` / `plan 6` / `decisión 0` |
| 2 | mutante (copia con `E7`) | `TOTAL 7` / `plan 6` / `decisión 1` |
| 3 | revertido (ledger real, nunca tocado) | `TOTAL 6` / `plan 6` / `decisión 0` |

---

### AC24 — detecta `Clase` ausente, no la pierde en el total

- **Mutación declarada**: vaciar el campo `Clase` de la fila `E2` en una copia · queda revertida.

| # | Estado | Exit | Resultado |
|---|---|---|---|
| 1 | intacto | **0** | `TOTAL 6` / `plan 6` |
| 2 | mutante | **3** | `TOTAL 6` / `plan **5**` / `INVALIDA 1 fila(s): E2(clase='')` |
| 3 | revertido (ledger real) | **0** | `TOTAL 6` / `plan 6` |

La fila inválida **no** se cuenta como ninguna categoría (`plan` bajó de 6 a 5, no se movió a
otra columna) — se reporta aparte, que es exactamente lo que AC24 exige.

---

## Test de reproducción (bugfix)

Ningún requerimiento de este ciclo es arquetipo `bugfix` — R1 es `analysis`, R2/R3/R6 son
`refactor`, R4 es `refactor`. `N/A`.

---

## Smoke manual (ACs `manual-only`)

Ninguno de los 27 ACs (+ AC27bis) está marcado `manual-only`. `N/A`.

---

## Impact set

| Símbolo/archivo cambiado | Caller / consumidor | Cobertura |
|---|---|---|
| `sdd-lint-contract.sh` (0.10.0→0.12.0) | `sdd-plan/SKILL.md` (self-review, Fase A) | AC1-AC4, AC6, AC9, AC27 |
| `sdd-lint-contract.sh` | `commands/sdd.md` Fase 2 (auto-aprobación) | mismos ACs — es el mismo binario |
| `sdd-lint-contract.sh` | `agents/reviewer-agent.md` (Fase 1 mecánica) | mismos ACs |
| `sdd-context-budget.sh` (nuevo, canónico) | ninguno todavía en runtime — es instrumentación on-demand | AC17-AC20, AC27bis |
| `sdd-escalation-tally.sh` (nuevo, canónico) | ninguno todavía en runtime — checkpoint `GEN-102` lo invoca en el futuro | AC22-AC24 |
| `commands/sdd.md` (regla de Retro ampliada) | todo ciclo `/sdd` futuro que emita `ESCALATE`/`REJECTED`/`BLOCKED`-que-ratifica | AC25 |
| `orchestration.md` §6.1 (nueva) | `escalations.md`, `commands/sdd.md` — los dos la citan en vez de restatearla | verificado por grep en `test_regla_retro_ampliada` y `test_backfill_gen94_completo` |
| `archetypes.md` (criterio trivial + trivial-brief) | `sdd-plan/SKILL.md` línea "Modelo asignado" | AC14, AC15 |
| `write-pr-report/SKILL.md`, `commands/sdd-status.md`, `commands/sdd-pr.md` (model: haiku) | invocación directa (skill) o vía `/sdd-pr`, `/sdd-status` | AC13 |
| `SDD/docs/doc_quality_gates.md` (gate 2 amplía glob) | `sdd-run-gates.sh`, cualquier corrida de la escalera | verificado: `SDD/scripts/*.sh` no existía en los árboles de R4/R2-R3 (`git ls-tree` vacío), así que el cambio no alteró ningún resultado histórico — sólo corridas futuras |

Sin callers externos al propio plugin — es contenido normativo y scripts de desarrollo, no una
librería que otro código importe.

---

## Rojos preexistentes

Ninguno — `origin/prod` no tiene gates rojos (verificado en el R4-gates.md original, primera
corrida del ciclo sobre esa base).

---

## AC26 — evidencia de la tarea Proxima (arquetipo `infra`, sin test de repo)

Respuesta real de `proxima_create_task` (proyecto `GEN`, fase 1 Análisis), pegada tal cual —
no re-escrita ni resumida (v6 sólo la había pegado en el propio contract, que escribe el mismo
planner que se audita; BLOCKER 4 de la ronda 1):

```json
{
  "id": "a4a0483d-a30b-48ab-aa29-d82807fdb24b",
  "key": "GEN-102"
}
```

- **Título**: "Checkpoint R6 — tallar ESCALATE de plan en AI-Forge, Odoo-Addons y Documentos_Customer_Experience (sdd-escalation-tally.sh)"
- **startAt**: `2026-09-22T14:00:00-06:00`
- **projectKey**: `GEN`

Respuesta real de `proxima_log_progress` sobre `GEN-102`, agregando el detalle operativo que
`create_task` no acepta como parámetro (confirmado contra el schema — no tiene campo `description`):

```json
{
  "id": "2f894108-e5a8-4010-b33d-6bf0c6ef12b6"
}
```
