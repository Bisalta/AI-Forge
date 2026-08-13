# Task brief — R1 · bugfix: el runner sella el árbol verificado, no `HEAD`

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v3**, sección `R1` (los ACs de R1 no cambiaron entre v1 y v3; las ratificaciones fueron todas de R0)
- **Arquetipo**: `bugfix`
- **Repo**: `.` (AI-Forge) · **Branch**: `feat-GEN-94-sicop-hardening` (ya creada desde `prod`; NO crear otra, NO commitear a `prod`)
- **Proxima subtask id**: `3441b401-8389-468f-9040-26e2516aaf23` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R1.md`
- **Depende de**: R0 (el harness `SDD/tests/` ya existe y está verde)

## Causa raíz (ya diagnosticada — no la re-investigues, verificala)

`plugins/sdd-flow/scripts/sdd-run-gates.sh:120` hace `COMMIT="$(git rev-parse --short HEAD)"` y la línea 124 lo estampa como `**Commit**:` en el encabezado del reporte. La línea 125 afirma *"Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia."*

Los gates corren con `bash -c "$cmd"` (línea 80) sobre el **working tree**, que puede diferir de `HEAD` en dos direcciones: cambios sin commitear al momento de la corrida, y commits posteriores a que el reporte se escribiera. El artefacto se presenta como evidencia de un commit que no es necesariamente el código ejecutado.

**Este bug ya se reprodujo en este mismo ciclo**: `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md:3` sella `Commit: e5ef90c`, que es `prod` y no contiene ni uno de los archivos que R0 creó. Verificalo vos mismo con `git ls-tree -r e5ef90c -- SDD/` antes de arrancar: es tu caso de prueba real.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. El reporte estampa **siempre** el hash del árbol realmente verificado, además del commit:
   - árbol limpio → `git rev-parse HEAD^{tree}`;
   - árbol sucio → `git stash create` (produce un objeto commit con working tree **e** índice sin tocar la branch ni el stash log), y de ahí `git rev-parse <obj>^{tree}`.
   - **`git write-tree` está descartado por el contract**: escribe el árbol del índice, así que un cambio sin `git add` no quedaría representado y el hash seguiría mintiendo. No lo uses.
2. La estrictez se deriva del **destino del reporte**:
   - `-o` dentro de `.sdd/` → uso ad-hoc: escribe y sale normal, con el estado del árbol marcado.
   - `-o` fuera de `.sdd/` → evidencia que se commitea: **exige árbol limpio**; si está sucio no escribe el reporte y sale **4**.
3. Escape hatch explícito: `--allow-dirty` permite escribir evidencia con árbol sucio; el encabezado lleva la marca `ARBOL SUCIO` y la lista de archivos sucios.

## Out of scope

- No toques el parser de la tabla de gates (líneas 56-74) ni `run_gate` (líneas 89-107). El diff de R1 es el bloque de sellado, el parseo de argumentos y la constante `VERSION`.
- No implementes R2, R3 ni R4.
- No arregles el sello viejo de `...-R0-gates.md`. Se regenera al final del ciclo, no acá.

## Pasos

### Fase 1 — El test rojo primero (regla dura del arquetipo `bugfix`)

- [x] T1.1 Escribir `SDD/tests/test_run_gates_tree.sh` cubriendo AC7 a AC12. Usá los helpers de `SDD/tests/lib.sh`; no definas asserts propios. Repos git temporales en `SDD/tests/.tmp/`, limpieza con `trap ... EXIT`.
- [x] T1.2 **Correr el test contra el `sdd-run-gates.sh` actual, sin tocarlo.** Tiene que salir **≠0** porque el script todavía no emite `Tree:`. Guardá comando y exit code: es la corrida roja que exige `plugins/sdd-flow/standards/quality-gates.md` §1.5. Un bugfix sin test rojo previo no está probado, está supuesto. **Hecho**: `bash SDD/tests/test_run_gates_tree.sh` → exit `1`, 11 asserts fallidos (AC7, AC8, AC9, AC10, AC11, AC12) — ver verification report.

### Fase 2 — El fix

- [x] T2.1 Implementar el sellado en `plugins/sdd-flow/scripts/sdd-run-gates.sh`: hash del árbol verificado, estado limpio/sucio, y el `Tree:` en el encabezado junto a `Commit:`.
- [x] T2.2 Implementar la estrictez derivada del path de `-o` y el exit **4**.
- [x] T2.3 Agregar `--allow-dirty` al parseo de argumentos (bloque `while` de las líneas 35-44) y a la ayuda del encabezado del script.
- [x] T2.4 Bumpear `VERSION` a `0.11.0` (línea 28).
- [x] T2.5 Degradación sin git (AC12): el sellado no puede abortar la corrida. `Tree:` en `-` y la escalera sigue.

### Fase 3 — Verde y propagación

- [x] T3.1 Correr `SDD/tests/test_run_gates_tree.sh` → verde. Registrá comando y exit code. **Hecho**: exit `0`, 19/19 asserts `ok`.
- [x] T3.2 Correr `bash SDD/tests/run.sh` completo → verde. El fix no puede romper `test_run_gates.sh` de R0. **Hecho**: exit `0`, 4 passed, 0 failed (4 total) — incluye `test_run_gates.sh` de R0 sin modificar.
- [x] T3.3 `shellcheck --severity=warning` sobre el script modificado → exit 0. **Hecho**: exit `0`.
- [x] T3.4 Actualizar `plugins/sdd-flow/standards/quality-gates.md` §5 (contrato de evidencia): nombrar el hash de árbol y el exit 4.
- [x] T3.5 Actualizar `plugins/sdd-flow/skills/sdd-verify/SKILL.md`: la regla del `-o` explica la estrictez derivada.

### Fase 4 — Hermanos, evidencia y commit

- [x] T4.1 **AC13**: `grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/`. Clasificá **cada** aparición: evidencia sellada (se corrige) o uso legítimo (se justifica en una línea). La salida del grep va al verification report. **Hecho**: 2 apariciones, ambas en `sdd-run-gates.sh` (una es la línea ya arreglada por este mismo diff, la otra es el comentario nuevo que documenta el fix) — clasificación completa en el verification report.
- [x] T4.2 Escribir `SDD/verification/feat-GEN-94-sicop-hardening-R1.md` con las **dos corridas** del test de reproducción (roja antes, verde después) con comando y exit code, más el resto de la evidencia.
- [x] T4.3 Regenerar la evidencia de gates a `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md`. **Ojo**: con tu propio fix aplicado, ese path exige árbol limpio — o sea, commiteá primero y regenerá después, que es exactamente el comportamiento que el fix busca forzar.
- [x] T4.4 Llenar el binding AC↔test.
- [x] T4.5 Commitear con `[FIX] [GEN-94] [sdd-flow] <descripción>`.

### Ronda 2 — `APPROVED` en ronda 1, 3 MINOR a corregir antes del PR + regenerar evidencia de R0

El reviewer aprobó R1 (cero `BLOCKER`, cero `MAJOR`) y pidió corregir 3 `MINOR` de ≤3 líneas antes del PR, más una tarea adicional: regenerar la evidencia de gates de R0 (arrastrada como `ADVISORY` desde su ronda 1, cerrable ahora que el sellado funciona).

- [x] T5.1 (MINOR 1) `sdd-run-gates.sh`: con `--allow-dirty`, sufijar `TREE_STATE` con `(el hash no incluye N archivo(s) sin trackear)` cuando `DIRTY_FILES` tiene al menos una entrada `??` — el encabezado no decía que el hash de `Tree:` excluye los archivos sin trackear, esa semántica sólo vivía en un comentario del script. Verificado a mano contra un repo con 1 modificado + 2 sin trackear.
- [x] T5.2 (MINOR 2) `test_run_gates_tree.sh`: invertir los 2 argumentos de los 6 `assert_eq` que los tenían al revés de `lib.sh:25` (`assert_eq <actual> <esperado>`) — líneas 103, 122, 126, 142, 156, 185. El veredicto no cambiaba (comparación simétrica) pero el mensaje de `FAIL` mentía sobre cuál valor era cuál.
- [x] T5.3 (corrección propia, no pedida) Al recapturar shellcheck para el MINOR 3 encontré una 4ta aparición de `SC2016` que mi propia verificación de ronda 1 no vio (`test_run_gates_tree.sh:183`, invisible en `git ls-files` porque corrí ese chequeo antes de hacer `git add` del archivo). Justificado inline con la misma disciplina que las otras 3.
- [x] T5.4 (MINOR 3) Recapturar AC13 (grep) y la nota de `SC2016` en `SDD/verification/feat-GEN-94-sicop-hardening-R1.md` contra el árbol con los fixes ya aplicados — los números de línea de ronda 1 habían quedado stale por el crecimiento del propio diff (retro `RT7` del coordinador).
- [x] T5.5 Segundo commit `[FIX] [GEN-94] [sdd-flow] ...` con los 3 MINOR + la corrección propia + el verification report actualizado.
- [x] T5.6 Regenerar `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md` **y** `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` contra el árbol limpio post-commit (tarea nueva del coordinador — R0 quedaba sellada contra `c516902`, el commit del planner, no el del trabajo de R0).
- [x] T5.7 Tercer commit `[FIX] [GEN-94] [sdd-flow] ...` con las dos evidencias de gates regeneradas.

## Acceptance criteria (IDs del contract v2 — no los renumeres)

- **AC7** — Con árbol limpio, el encabezado incluye una línea con `Tree:` seguida del hash de `git rev-parse HEAD^{tree}` en ese repo, y el runner sale 0.
- **AC8** — Con árbol sucio y `-o .sdd/gates-run.md`, el reporte se escribe, el encabezado marca el árbol como sucio, el hash de `Tree:` difiere de `git rev-parse HEAD^{tree}`, y sale 0.
- **AC9** — Con árbol sucio y `-o SDD/verification/x-gates.md`, el runner **no crea el archivo** y sale 4.
- **AC10** — Con árbol sucio, `-o SDD/verification/x-gates.md` y `--allow-dirty`, el archivo se crea, el encabezado contiene `ARBOL SUCIO`, y sale 0.
- **AC11** — `sdd-run-gates.sh --version` imprime `0.11.0`.
- **AC12** — En un directorio que no es repo git, el runner escribe el reporte con `Tree:` en `-` y sale con el código que corresponde al resultado de los gates, sin abortar por el sellado.
- **AC13** — El grep de hermanos corrió, cada aparición está clasificada, y el resultado está en el verification report.

**AC9 es un AC de detección**: su condición de aprobación es "el runner se niega cuando el árbol está sucio". Probalo por mutación y registrá el par verde→rojo→verde. Un runner que se niega siempre, o que nunca se niega, produce salidas indistinguibles de uno correcto si sólo mirás el caso feliz.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC7 | árbol limpio → `Tree:` con el hash de `HEAD^{tree}`, sale 0 | `SDD/tests/test_run_gates_tree.sh::"AC7 arbol limpio - sale 0"`, `"AC7 arbol limpio - encabezado tiene Tree:"`, `"AC7 arbol limpio - Tree coincide con el hash de HEAD^{tree}"`, `"AC7 arbol limpio - el reporte se escribe"` | unit/integration | [x] |
| AC8 | árbol sucio + `-o .sdd/gates-run.md`: escribe, marca sucio, `Tree:` difiere del limpio, sale 0 | `SDD/tests/test_run_gates_tree.sh::"AC8 arbol sucio con -o dentro de .sdd - sale 0"`, `"AC8 arbol sucio con -o dentro de .sdd - el reporte se escribe"`, `"AC8 arbol sucio con -o dentro de .sdd - encabezado marca el arbol sucio"`, `"AC8 arbol sucio - Tree usa el hash de git stash create"`, `"AC8 arbol sucio - Tree difiere del hash de HEAD^{tree} limpio"` | unit/integration | [x] |
| AC9 | árbol sucio + `-o SDD/verification/x-gates.md` sin `--allow-dirty`: no crea el archivo, sale 4 | `SDD/tests/test_run_gates_tree.sh::"AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - sale 4"`, `"AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - no crea el archivo"` — AC de detección, mutación verde→rojo→verde registrada en el verification report | unit/integration + mutación | [x] |
| AC10 | árbol sucio + `-o SDD/verification/x-gates.md` + `--allow-dirty`: crea el archivo, `ARBOL SUCIO` en el encabezado, sale 0 | `SDD/tests/test_run_gates_tree.sh::"AC10 arbol sucio con --allow-dirty - sale 0"`, `"AC10 arbol sucio con --allow-dirty - crea el archivo"`, `"AC10 arbol sucio con --allow-dirty - encabezado marca ARBOL SUCIO"` | unit/integration | [x] |
| AC11 | `--version` imprime `0.11.0` | `SDD/tests/test_run_gates_tree.sh::"AC11 --version sale 0"`, `"AC11 --version imprime 0.11.0"` | unit | [x] |
| AC12 | sin repo git: `Tree: -`, sale con el exit code de los gates, sin abortar por el sellado | `SDD/tests/test_run_gates_tree.sh::"AC12 sin repo git - sale con el exit code de los gates (hay un rojo)"`, `"AC12 sin repo git - Tree en guion"`, `"AC12 sin repo git - el reporte se escribe igual, sin abortar por el sellado"` | unit/integration | [x] |
| AC13 | grep de hermanos corrido y cada aparición clasificada | `grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/` — 2 apariciones, ambas en `sdd-run-gates.sh`, clasificación completa en `SDD/verification/feat-GEN-94-sicop-hardening-R1.md` sección AC13 | gate + grep | [x] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Cada exit code viene de una corrida real.
- Toda cifra que reportes va con la salida del comando que la produce, no con tu resumen.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner. No adivines.
- Prohibidas las mitigaciones de `plugins/sdd-flow/standards/quality-gates.md` §6.
- No toques `SDD/contracts/`, `SDD/debt.md` ni `.sdd/state.json`.

## Riesgo declarado

R1 se prueba a sí mismo: tus tests corren contra el script que estás modificando. Por eso la corrida roja de T1.2 es obligatoria y va antes del fix — es lo único que distingue "el test detecta el bug" de "el test siempre pasa".

## Rollback

`git revert` del commit de R1. El script vuelve a v0.10.0 y la evidencia deja de llevar `Tree:`.

## Done criteria

AC7 a AC13 con test verde, las dos corridas del test de reproducción registradas, `SDD/tests/run.sh` completo verde, `shellcheck` limpio, docs propagados, verification report escrito, binding completo, un commit.

## Execution Report

- **Summary**: Ronda 1 dejó `sdd-run-gates.sh` sellando el hash del árbol REALMENTE verificado (`Tree:`, `HEAD^{tree}` limpio o el árbol de `git stash create` sucio) junto al `Commit:` de HEAD, con la estrictez derivada del destino del reporte (exit 4 fuera de `.sdd/` con árbol sucio, salvo `--allow-dirty`) — `APPROVED` en ronda 1, cero `BLOCKER`, cero `MAJOR`. Ronda 2 corrigió los 3 `MINOR` que dejó esa aprobación (el encabezado ahora dice cuántos archivos sin trackear excluye el hash; los 6 `assert_eq` con argumentos invertidos del test quedaron en el orden que declara `lib.sh`; los números de línea stale de AC13/`SC2016` en el verification report se recapturaron), sumó una corrección propia (una 4ta aparición de `SC2016` que la verificación de ronda 1 no había visto por un archivo todavía sin trackear al momento de ese chequeo), y regeneró — con el árbol ya limpio tras commitear los fixes — la evidencia de gates de R1 **y** de R0 (esta última arrastrada como `ADVISORY` desde la ronda 1 de R0, cerrable recién ahora que el sellado funciona).
- **Task status**: ronda 1, 17/17 (T1.1-T1.2, T2.1-T2.5, T3.1-T3.5, T4.1-T4.5). Ronda 2, 7/7 (T5.1-T5.7). Cero bloqueadas, cero skipped en las dos rondas.
- **Validation executed** — ronda 2, la vigente:
  - `bash SDD/tests/test_run_gates_tree.sh` (antes del fix de ronda 1) · exit `1` (11 asserts fallidos) — corrida roja de reproducción, registrada en ronda 1 y sin alterar en ronda 2.
  - `bash SDD/tests/test_run_gates_tree.sh` (después de los 3 MINOR + la corrección propia) · exit `0` (19/19 `ok`) — mismo conteo que ronda 1, sin regresión.
  - AC9 mutación (ronda 1, sigue vigente): verde (exit `0`) → rojo con `exit 4` removido (exit `1`, exactamente 2 asserts fallidos) → verde revertido (exit `0`).
  - `bash SDD/tests/run.sh` (suite completa, post ronda 2) · exit `0` — 4 passed, 0 failed (4 total).
  - `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` · exit `0`.
  - `git ls-files -z -- '*.sh' | xargs -0 shellcheck` (default, recapturado) · exactamente 3 `SC2016` (los preexistentes de `plugins/`, `D4`), cero en `SDD/tests/` — ver "Ronda 2" en el verification report para la corrección de la 4ta aparición.
  - `grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/` (AC13, recapturado) · exit `0`, 2 apariciones, números de línea frescos.
  - `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md` (post-commit de ronda 2, árbol limpio) y el mismo comando con `-o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` — exit codes y JSON en esos dos archivos y en el `sdd.result` de esta ronda.
  - Detalle completo en `SDD/verification/feat-GEN-94-sicop-hardening-R1.md`, sección "Ronda 2".
- **Blockers**: ninguno.
- **Files changed en ronda 2**: `plugins/sdd-flow/scripts/sdd-run-gates.sh` (mod — sufijo de archivos sin trackear), `SDD/tests/test_run_gates_tree.sh` (mod — 6 `assert_eq` reordenados + 1 `SC2016` justificado), `SDD/verification/feat-GEN-94-sicop-hardening-R1.md` (mod — sección Ronda 2, AC13/`SC2016` recapturados), `SDD/briefs/R1-runner-tree-seal.md` (mod, este archivo), `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md` (mod, regenerado), `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` (mod, regenerado — tarea del coordinador, no del brief original). Cero cambios en `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md`, `.sdd/state.json` (verificado, no tocados).
- **Final statement**: Done. AC7-AC13 con test verde (o gate+grep para AC13), las dos corridas del test de reproducción registradas, AC9 probado por mutación, `SDD/tests/run.sh` completo verde, `shellcheck --severity=warning` en `0`, los 3 MINOR de ronda 1 corregidos y verificados sin regresión, evidencia de gates de R1 y R0 regenerada contra árbol limpio. Límite conocido de `git stash create` con archivos sin trackear sigue documentado (no bloqueante, heredado de la decisión cerrada del contract) — ahora también visible en el propio encabezado del reporte (MINOR 1), no sólo en el comentario del script.
