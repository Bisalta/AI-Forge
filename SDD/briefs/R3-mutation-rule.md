# Task brief — R3 · infra: prueba por mutación de todo AC que afirme detectar algo

- **Agente**: `AGENT_r3` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v5**, sección `R3` (AC19-AC24)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening`
- **Proxima subtask id**: `68813f9e-1c53-4d0e-959e-5fd1492dfcd6` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R3.md`
- **Depende de**: R0, R1, R2 y R5, los cuatro `APPROVED`

## Qué es esto

Es el requerimiento de mayor rendimiento de todo el ciclo, y es casi todo markdown. Convierte en norma escrita lo que este ciclo viene haciendo de facto en cada AC de detección.

## El problema

Cuatro controles medidos en SICOP tenían forma de control y ningún poder: un test de partición que nada ejecutaba y que salía 0 con y sin violación; una comparación donde 4 de 25 casos comparaban un build contra una copia de sí mismo; un criterio que exigía `LEFT JOIN` y pasaba igual con `INNER` porque el lookup contiene las claves sin familia; y una guarda de autoría verdadera siempre. Ninguno era un error de lógica: los cuatro se veían bien y no podían fallar, y los cuatro se encontraron rompiéndolos a propósito.

**La regla ya existe en el plugin con alcance angosto**: `plugins/sdd-flow/standards/quality-gates.md:19` (DoD ítem 5) exige el rojo antes y el verde después **sólo para el arquetipo `bugfix`**. R3 la generaliza a todo AC de detección, en cualquier arquetipo.

Este mismo ciclo tiene la evidencia de que sirve: el gate de secretos de R0 no detectaba 4 de 5 formas reales, el par AC14/AC16 de R2 sólo se sostiene porque cada mutación rompe un lado, y AC30 de R5 necesitó partirse en estabilidad y sensibilidad porque un hash constante y uno siempre-distinto pasan uno cada sub-check.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **Alcance**: un AC es de detección cuando su condición de aprobación es *"algo falla cuando X está mal"* — guardas, validaciones, constraints, tests que afirman prevenir. Un AC que afirma un valor devuelto **no** entra: ya es falsable por construcción.
2. **Evidencia**: el triple **verde → rojo → verde**, con comando y exit code por corrida. El rojo solo no alcanza, porque un control permanentemente roto produce la misma salida que uno correcto.
3. **La mutación se declara en el contract**: cada AC de detección lleva escrito qué se rompe para probarlo. El planner la escribe, el implementador la ejecuta.
4. **Toda cifra citada va con la salida del comando que la produce**, no con su resumen.
5. **Las correcciones posteriores a `APPROVED` vuelven al loop**: un diff que corrige un artefacto ya aprobado se revisa como el cambio original.

## Out of scope

- No toques `scripts/`, `hooks/` ni `SDD/tests/` salvo el test nuevo de este brief.
- No implementes R4 (arquetipo `analysis`).
- No reabras ningún AC de R0, R1, R2 ni R5.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/standards/quality-gates.md` | (mod) DoD ítem 5 generalizado · sección nueva de prueba por mutación · §5 con el triple · regla de correcciones post-`APPROVED` |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | (mod) el AC de detección declara su mutación |
| `plugins/sdd-flow/agents/implementing-agent.md` | (mod) produce el triple; adjunta la salida de cada cifra |
| `plugins/sdd-flow/agents/reviewer-agent.md` | (mod) AC de detección sin triple = `BLOCKER`; cifra sin salida = `MAJOR`. **Más el MINOR de R5**, abajo |
| `plugins/sdd-flow/skills/write-pr-report/SKILL.md` | (mod) las cifras del PR report llevan su salida |
| `SDD/tests/test_mutation_rule.sh` | (NEW) |

## Pasos

- [x] T1.1 Leer los cinco archivos antes de tocarlos. Leé también `SDD/retro.md` entero: las nueve entradas son la evidencia de campo de esta regla, escrita durante este mismo ciclo.
- [x] T1.2 Escribir `SDD/tests/test_mutation_rule.sh` (AC19-AC24) con `SDD/tests/lib.sh`. Son ACs de contenido verificables por grep, igual que AC38 en R2 y AC32-AC35 en R5. **Corré el test antes del cambio**: tiene que salir ≠0. → corrida roja registrada: exit `1`, 33 de 41 asserts en rojo (los 8 verdes son justo los de ausencia de AC23, que es lo que motiva su prueba por mutación).
- [x] T2.1 `quality-gates.md`: sección nueva de prueba por mutación con el criterio del punto 1 y el triple del punto 2. El **DoD ítem 5 referencia esa sección** en vez de limitar la regla a `bugfix`. → §10 «Prueba por mutación (AC de detección)» con 10.1 criterio / 10.2 quién declara la mutación / 10.3 el triple.
- [x] T2.2 `quality-gates.md` §5: el triple entra al contrato de evidencia, junto a las dos corridas del bugfix que ya están. → viñeta nueva + la regla de que toda cifra va con la salida del comando que la produce.
- [x] T2.3 `quality-gates.md`: la regla de que un diff que corrige un artefacto ya `APPROVED` vuelve al loop de review (AC24). → §7.5.
- [x] T3.1 Propagar a `sdd-plan/SKILL.md`, `implementing-agent.md`, `reviewer-agent.md` y `write-pr-report/SKILL.md`. **Referenciá la sección de `quality-gates.md` por su título; no recopies el texto normativo** — es AC23.
- [x] T3.2 **MINOR heredado del review de R5**: en `plugins/sdd-flow/agents/reviewer-agent.md`, la rama "hashes distintos" de la comparación de hash del doc dice "reportalo aparte" y **nunca nombra la severidad**, y `quality-gates.md` §7.2 no tiene fila para ese caso. El reviewer termina improvisando la severidad de un hallazgo que el plugin le ordena levantar. Nombrala: `MAJOR` cuando el doc que cambió gobierna los gates que sostienen el `done`, `MINOR` cuando el cambio no toca las filas que corrieron. → nombradas en la rama del reviewer y en las dos filas de `quality-gates.md` §7.2, con 4 asserts que las cubren.
- [x] T4.1 Test verde. `bash SDD/tests/run.sh` completo (7 archivos). `shellcheck --severity=warning` en 0.
- [x] T4.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md` — **commiteá primero, regenerá después**.
- [x] T4.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent`.

## Acceptance criteria (IDs del contract v5 — no los renumeres)

- **AC19** — `quality-gates.md` tiene una sección de prueba por mutación que define el triple verde→rojo→verde y el criterio de qué AC lo requiere, y el DoD ítem 5 referencia esa sección en vez de limitar la regla al arquetipo `bugfix`.
- **AC20** — `sdd-plan/SKILL.md` exige que cada AC de detección declare su mutación en el contract.
- **AC21** — `reviewer-agent.md` clasifica como `BLOCKER` un AC de detección sin las tres corridas, y como `MAJOR` una cifra reportada sin la salida que la produce.
- **AC22** — `implementing-agent.md` y `write-pr-report/SKILL.md` exigen adjuntar la salida del comando de cada cifra reportada.
- **AC23** — Los cinco archivos referencian la sección de `quality-gates.md` **por su título**, y ninguno recopia el texto normativo del triple. Verificable con grep del título en los cinco.
- **AC24** — `quality-gates.md` declara que un diff que corrige un artefacto ya aprobado vuelve al loop de review.

**AC23 es el AC de detección de este requerimiento**: su condición de aprobación es "no hay texto normativo duplicado". Un grep que busca una frase que no existe en ningún lado pasa siempre. Probalo por mutación: recopiá el texto normativo en uno de los cinco archivos, verificá que el test se ponga rojo, y revertí. Sin eso, AC23 es exactamente el tipo de control tautológico que este requerimiento existe para prohibir.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC19 | `quality-gates.md` tiene la sección de prueba por mutación (triple + criterio) y el DoD ítem 5 la referencia en vez de limitarse a `bugfix` | `SDD/tests/test_mutation_rule.sh::"AC19 quality-gates.md - existe la seccion 10 de prueba por mutacion"`, `"AC19 quality-gates.md - la seccion define las tres corridas del triple"`, `"AC19 quality-gates.md - la seccion define el criterio de que AC requiere la prueba por mutacion"`, `"AC19 DoD item 5 - referencia la seccion de prueba por mutacion por su titulo"`, `"AC19 DoD item 5 - ya no condiciona la regla al arquetipo bugfix"` (+1: la forma corta del triple) | grep (automatizado) | [x] |
| AC20 | `sdd-plan/SKILL.md` exige que cada AC de detección declare su mutación en el contract | `SDD/tests/test_mutation_rule.sh::"AC20 sdd-plan - el contract escribe la mutacion debajo del AC de deteccion"`, `"AC20 sdd-plan - la regla habla del AC de deteccion"`, `"AC20 sdd-plan - el self-review chequea que cada AC de deteccion tenga su mutacion"` | grep (automatizado) | [x] |
| AC21 | `reviewer-agent.md`: AC de detección sin las tres corridas = `BLOCKER`; cifra sin la salida que la produce = `MAJOR` | `SDD/tests/test_mutation_rule.sh::"AC21 reviewer-agent - AC de deteccion sin las tres corridas es BLOCKER"`, `"AC21 reviewer-agent - cifra sin su salida es MAJOR"`, `"AC21 quality-gates 7.2 - AC de deteccion sin las tres corridas es BLOCKER"`, `"AC21 quality-gates 7.2 - cifra reportada sin su salida es MAJOR"` (+2 asserts de anclaje de cada regla) | grep (automatizado) | [x] |
| AC22 | `implementing-agent.md` y `write-pr-report/SKILL.md` exigen adjuntar la salida del comando de cada cifra reportada | `SDD/tests/test_mutation_rule.sh::"AC22 implementing-agent - toda cifra reportada va con la salida del comando que la produce"`, `"AC22 write-pr-report - toda cifra del PR report va con la salida del comando que la produce"`, `"AC22 implementing-agent - una cifra copiada de otro documento no cuenta como medicion"`, `"AC22 write-pr-report - una cifra copiada de otro documento no cuenta como medicion"` | grep (automatizado) | [x] |
| AC23 | **AC de detección**: los cinco archivos referencian la sección por su título y ninguno recopia el texto normativo del triple | `SDD/tests/test_mutation_rule.sh::"AC23 quality-gates.md - contiene la seccion referenciada por su titulo"`, `"AC23 sdd-plan - referencia la seccion por su titulo"`, `"AC23 implementing-agent - referencia la seccion por su titulo"`, `"AC23 reviewer-agent - referencia la seccion por su titulo"`, `"AC23 write-pr-report - referencia la seccion por su titulo"`, `"AC23 quality-gates.md - el texto normativo del triple vive aca"`, `"AC23 implementing-agent - no recopia el texto normativo del triple"`, `"AC23 implementing-agent - no recopia la forma corta del triple"` (+6: los otros tres archivos × 2 formas) | grep (automatizado) · **probado por mutación** (triple en el verification report) | [x] |
| AC24 | `quality-gates.md` declara que un diff que corrige un artefacto ya aprobado vuelve al loop de review | `SDD/tests/test_mutation_rule.sh::"AC24 quality-gates.md - existe la regla de correcciones posteriores a APPROVED"`, `"AC24 quality-gates.md - la regla apunta al artefacto ya aprobado"`, `"AC24 quality-gates.md - la correccion se revisa como el cambio original"` | grep (automatizado) | [x] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce — es la regla que estás escribiendo, aplicada a vos.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe** (`RT7`).
- **Verificá cómo se mide antes de creerle a la medición** (`RT8` y tres incidentes del ciclo).
- **No verifiques lint con `git ls-files`** (`D8`). Usá el glob del gate.
- Literales con forma clave-valor, **partidos**, o el gate 9 se pone rojo.
- Prohibidas las mitigaciones de `quality-gates.md` §6, en particular **cualquier exclusión por path**.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Riesgo declarado

La regla sube el costo de cada AC de detección de una corrida a tres. El punto 1 del alcance es lo único que evita que eso se aplique a todos los ACs. Si tu redacción del criterio deja lugar a que un AC de valor devuelto entre, el requerimiento triplica el costo del pipeline entero — escribí ese criterio con la misma dureza que las closure rules.

## Rollback

`git revert`. Todo markdown salvo el test.

## Execution Report

- **Summary**: `quality-gates.md` gana §10 «Prueba por mutación (AC de detección)» — criterio de clasificación cerrado (cuatro formas que entran: rechazo, hallazgo, ausencia, sensibilidad; dos que no: valor devuelto y fallback declarado; desempate = el AC que cae en las dos listas se parte en dos), la mutación declarada por el planner en el contract, y el triple como evidencia. El ítem 5 de la DoD referencia esa sección en vez de limitar la regla a `bugfix` (AC19); §5 suma las tres corridas al contrato de evidencia más la regla de que toda cifra va con la salida que la produce; §7.2 suma las severidades nuevas; §7.5 declara que un diff que corrige un artefacto ya aprobado vuelve al loop (AC24). Los otros cuatro archivos la referencian **por su título** sin recopiar el texto normativo (AC20-AC23). Incluye el MINOR heredado del review de R5 (T3.2).
- **Task status**: 10/10 pasos `[x]` (T1.1-T4.3). 0 `BLOCKED`.
- **Validation executed** (comando · exit code) — detalle completo y salidas pegadas en `SDD/verification/feat-GEN-94-sicop-hardening-R3.md`:
  - `bash SDD/tests/test_mutation_rule.sh` **antes** del cambio → exit `1`, 33 de 41 asserts en rojo (los 8 verdes son los de ausencia de AC23, que es lo que obliga a probarlo por mutación).
  - `bash SDD/tests/test_mutation_rule.sh` después del cambio → exit `0`, 41/41 `ok`.
  - **Mutación de AC23** (recopiar el texto normativo del triple en `implementing-agent.md`) → exit `1`, exactamente los 2 asserts de ese archivo en rojo; revertida → exit `0`, 41/41, y el archivo vuelve byte a byte al mismo `sha256` (`377ad222b0e3d283…`).
  - `bash SDD/tests/run.sh` (suite completa, 7 archivos) → exit `0`.
  - `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` → exit `0` (glob del gate, no `git ls-files`).
  - `bash SDD/tests/secret-scan.sh` con el archivo nuevo ya stageado → exit `0`, 92 archivos versionados. Sin `git add` el escaneo cubría 91 y **no** incluía el test nuevo: medido, no supuesto (`D8`).
  - Escalera completa por el runner → `SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md`.
- **Blockers**: ninguno.
- **Files changed**: los 6 de la tabla Files (5 modificados + `SDD/tests/test_mutation_rule.sh` nuevo), más este brief y los dos archivos de evidencia. Ningún archivo fuera de la tabla.
- **Final statement**: los 6 ACs (AC19-AC24) tienen test real y pasan; AC23, el único AC de detección del requerimiento, va probado por mutación con el triple registrado; el criterio de §10.1 se escribió con desempate explícito para que un AC de valor devuelto no pueda entrar; cero mitigaciones prohibidas y ninguna exclusión por path; ningún gate `[SKIPPED]` sin razón declarada en el doc.
