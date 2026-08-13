# Task brief — R1 · bugfix: el runner sella el árbol verificado, no `HEAD`

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v2**, sección `R1`
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

- [ ] T1.1 Escribir `SDD/tests/test_run_gates_tree.sh` cubriendo AC7 a AC12. Usá los helpers de `SDD/tests/lib.sh`; no definas asserts propios. Repos git temporales en `SDD/tests/.tmp/`, limpieza con `trap ... EXIT`.
- [ ] T1.2 **Correr el test contra el `sdd-run-gates.sh` actual, sin tocarlo.** Tiene que salir **≠0** porque el script todavía no emite `Tree:`. Guardá comando y exit code: es la corrida roja que exige `plugins/sdd-flow/standards/quality-gates.md` §1.5. Un bugfix sin test rojo previo no está probado, está supuesto.

### Fase 2 — El fix

- [ ] T2.1 Implementar el sellado en `plugins/sdd-flow/scripts/sdd-run-gates.sh`: hash del árbol verificado, estado limpio/sucio, y el `Tree:` en el encabezado junto a `Commit:`.
- [ ] T2.2 Implementar la estrictez derivada del path de `-o` y el exit **4**.
- [ ] T2.3 Agregar `--allow-dirty` al parseo de argumentos (bloque `while` de las líneas 35-44) y a la ayuda del encabezado del script.
- [ ] T2.4 Bumpear `VERSION` a `0.11.0` (línea 28).
- [ ] T2.5 Degradación sin git (AC12): el sellado no puede abortar la corrida. `Tree:` en `-` y la escalera sigue.

### Fase 3 — Verde y propagación

- [ ] T3.1 Correr `SDD/tests/test_run_gates_tree.sh` → verde. Registrá comando y exit code.
- [ ] T3.2 Correr `bash SDD/tests/run.sh` completo → verde. El fix no puede romper `test_run_gates.sh` de R0.
- [ ] T3.3 `shellcheck --severity=warning` sobre el script modificado → exit 0.
- [ ] T3.4 Actualizar `plugins/sdd-flow/standards/quality-gates.md` §5 (contrato de evidencia): nombrar el hash de árbol y el exit 4.
- [ ] T3.5 Actualizar `plugins/sdd-flow/skills/sdd-verify/SKILL.md`: la regla del `-o` explica la estrictez derivada.

### Fase 4 — Hermanos, evidencia y commit

- [ ] T4.1 **AC13**: `grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/`. Clasificá **cada** aparición: evidencia sellada (se corrige) o uso legítimo (se justifica en una línea). La salida del grep va al verification report.
- [ ] T4.2 Escribir `SDD/verification/feat-GEN-94-sicop-hardening-R1.md` con las **dos corridas** del test de reproducción (roja antes, verde después) con comando y exit code, más el resto de la evidencia.
- [ ] T4.3 Regenerar la evidencia de gates a `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md`. **Ojo**: con tu propio fix aplicado, ese path exige árbol limpio — o sea, commiteá primero y regenerá después, que es exactamente el comportamiento que el fix busca forzar.
- [ ] T4.4 Llenar el binding AC↔test.
- [ ] T4.5 Commitear con `[FIX] [GEN-94] [sdd-flow] <descripción>`.

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
| AC7 | | | | [ ] |
| AC8 | | | | [ ] |
| AC9 | | | | [ ] |
| AC10 | | | | [ ] |
| AC11 | | | | [ ] |
| AC12 | | | | [ ] |
| AC13 | | | | [ ] |

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

- **Summary**:
- **Task status** (completadas / bloqueadas / skipped):
- **Validation executed** (comando · exit code):
- **Blockers**:
- **Files changed**:
- **Final statement**:
