# Verification Report — AGENT_r0 · R0-project-scaffold

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R0 del contract `SDD/contracts/2026-08-13-sicop-hardening.md` v1.

- **Branch**: `feat-GEN-94-sicop-hardening` (creada desde `prod`)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v1, sección R0
- **Base branch HEAD al momento de la corrida**: `e5ef90c` (`prod`, sin cambios de R0 todavía — el sellado de `sdd-run-gates.sh` estampa este hash porque sella `HEAD`, no el árbol trabajado; es exactamente el bug que R1 va a corregir, ver "Nota sobre el sellado" abajo)
- **Commit evaluado**: el commit único de R0 creado en T4.3, sobre esta misma branch (mensaje `[ADD] [GEN-94] [sdd-flow] ...`) — su hash no puede conocerse antes de crearlo (no puede auto-referenciarse); queda declarado en el `sdd.result` final de este agente y es el `HEAD` de la branch inmediatamente después de este reporte.
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (creado en esta misma tarea — no existía antes de R0)

---

## Nota sobre el sellado HEAD-vs-árbol (para que quede registrado, no para arreglarlo)

Las dos corridas de `sdd-run-gates.sh` de abajo estampan `Commit: e5ef90c` en su encabezado — el `HEAD` de la branch en el momento de la corrida — aunque los gates se ejecutaron contra el árbol de trabajo con los 8 archivos nuevos/modificados de R0 todavía sin commitear. Es el bug descrito en la sección R1 del contract (`sdd-run-gates.sh:120`, sella `HEAD` en vez del árbol verificado). **No lo arreglo acá**: es scope de R1 y su test de reproducción tiene que correr rojo primero contra el script actual. Lo dejo señalado porque es la ilustración más directa posible del problema que R1 ataca: este mismo reporte es un caso real de "evidencia sellada contra el código equivocado".

---

## Gates — evidencia GENERADA (no escrita a mano)

Corridas reales, en esta máquina (macOS, bash 3.2.57(1), shellcheck 0.11.0, git 2.50.1), en este orden:

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh -d SDD/docs/doc_quality_gates.md -o .sdd/gates-run.md
```
- Exit: `0` — `{"type":"sdd.gates","green":3,"red":0,"skipped":7,"report":".sdd/gates-run.md"}`
- Corrida exploratoria (T3.3), reporte en `.sdd/` (gitignoreado, no viaja en el PR) — se usó para verificar la escalera antes de generar la evidencia commiteada de abajo.

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md
```
- Exit: `0` — `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md"}`
- **Reporte generado y commiteado**: [`SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md`](./feat-GEN-94-sicop-hardening-R0-gates.md) — mismo directorio que este archivo, no `.sdd/`. **Esta es la evidencia oficial de AC5**: `red: 0`, y los 7 `[SKIPPED]` son las filas `N/A — <razón>` declaradas a propósito en `doc_quality_gates.md` (gates 1, 3, 5, 6, 7, 8, 10 — formatter/type-check/integration/build/e2e/coverage-tool/smoke-manual no existen en este repo, cada uno con su razón en el doc), **ninguno por comando inexistente o placeholder olvidado** (los 3 gates con comando real — lint, unit tests, security — corren y salen verdes; `--full` corre además la "suite completa" declarada, 4to verde).

No hubo corridas rojas de la escalera completa en ningún momento de R0 (los 3 gates reales nacieron verdes porque los archivos que ejercitan se escribieron y probaron de forma incremental antes de este run final — ver mutación de AC2 abajo, que sí generó un rojo real, pero en el test unitario, no en la escalera).

---

## AC2 — prueba por mutación (verde → rojo → verde)

AC2 es un AC de detección ("`run.sh` sale 1 cuando un test falla") — no alcanza con verlo verde. Se rompió `SDD/tests/run.sh` a propósito, se corrió el test que lo cubre, se confirmó rojo, y se revirtió.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar) | `bash SDD/tests/test_harness.sh` | `0` | `PASS` — los 3 casos (incluido el de AC2) en verde |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_harness.sh` | `1` | `FAIL — 1 assert(s) fallaron` — falló exactamente el assert de AC2: `FAIL  run.sh sale 1 y nombra el archivo que falló (exit 1) — esperado [1], obtenido [0]` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_harness.sh` | `0` | `PASS` — los 3 casos vuelven a verde |

**Mutación aplicada** (`SDD/tests/run.sh`, bloque final): se quitó el `exit 1` del branch `if [ "$FAIL_COUNT" -gt 0 ]`, dejando que el script siempre llegue al `exit 0` final aunque haya fallos — el defecto exacto que AC2 existe para prevenir. Diff aplicado durante la corrida 2 (revertido antes de la corrida 3):

```diff
 if [ "$FAIL_COUNT" -gt 0 ]; then
   printf 'Archivos con fallos: %s\n' "$FAILED_FILES"
-  exit 1
+  # MUTACION-AC2-TEMPORAL: exit 1 removido a propósito para la corrida roja
+  # exigida por quality-gates.md (prueba de detección) — se revierte enseguida.
 fi
```

Salida completa de la corrida 2 (la roja), pegada tal cual:
```
  ok    run.sh sale 0 cuando todos los test_*.sh pasan (exit 0)
  FAIL  run.sh sale 1 y nombra el archivo que falló (exit 1) — esperado [1], obtenido [0]
  ok    run.sh sale 1 y nombra el archivo que falló
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh (exit 1)
FAIL — 1 assert(s) fallaron
```

Conclusión: el test que respalda AC2 tiene poder de detección real — no es tautológico. `SDD/tests/run.sh` en el repo, al momento de este commit, es la versión sin mutar (verde).

---

## AC6 — limpieza garantizada incluso si el test falla

Además de las 3 corridas normales verdes de `SDD/tests/test_run_gates.sh` (que aseguran `green:2`/`red:0` del JSON — ver binding), se verificó empíricamente que el `trap ... EXIT` limpia el directorio temporal **incluso cuando el test falla**, no sólo en el camino feliz:

| Corrida | Comando | Exit code | `SDD/tests/.tmp/` tras terminar |
|---|---|---|---|
| fallo forzado | `bash SDD/tests/test_run_gates.sh` (con un `assert_eq "1" "2" "..."` agregado a propósito al final) | `1` | vacío — el subdirectorio `test_run_gates-<pid>` no sobrevivió |
| revertido | `bash SDD/tests/test_run_gates.sh` (sin el assert agregado) | `0` | vacío (comportamiento normal) |

El assert agregado para forzar el fallo se revirtió inmediatamente después de confirmar la limpieza; `SDD/tests/test_run_gates.sh` en el repo es la versión sin ese agregado.

---

## Test de reproducción (sólo bugfix)

N/A — R0 es arquetipo `project-scaffold`, no `bugfix`. No aplica el test de reproducción de la DoD §5.

## Smoke manual (sólo ACs `manual-only`)

N/A — R0 no declara ningún AC `manual-only`.

---

## Impact set

R0 es infraestructura nueva (scaffold): no modifica símbolos existentes de `plugins/`. El "impacto" relevante es qué consume cada artefacto nuevo:

| Símbolo / artefacto | Caller / consumidor | Cobertura |
|---|---|---|
| `SDD/docs/doc_quality_gates.md` (NEW) | `plugins/sdd-flow/scripts/sdd-run-gates.sh` (existente, sin modificar) | AC4, AC5 — el runner parseó la tabla sin error de formato (no salió `exit 3`) y corrió los 3 gates con comando real |
| `SDD/docs/doc_quality_gates.md` (NEW) | Futuras tareas R1-R4 del mismo contract, que van a correr su propia evidencia contra esta misma escalera | fuera del scope de R0 verificarlo; señalado para el planner |
| `SDD/tests/lib.sh` (NEW, único lugar con `assert_*`) | `SDD/tests/test_harness.sh`, `SDD/tests/test_run_gates.sh` (los dos únicos `test_*.sh` a la fecha) | ejercitado indirectamente por ambos — ver binding AC1/AC2/AC6 |
| `SDD/tests/run.sh` (NEW) | Gate 4 y "suite completa" de `doc_quality_gates.md` | AC1, AC2 (`test_harness.sh`) |
| `plugins/sdd-flow/scripts/sdd-run-gates.sh` (existente, NO modificado) | Invocado por `SDD/tests/test_run_gates.sh` y por la escalera de arriba | AC6 lo ejercita end-to-end contra un repo temporal, sin tocar su código |
| `.gitignore` (MOD — se agregó `SDD/tests/.tmp/`) | `git status`/`git add`/`git ls-files` de todo el repo | Verificado indirectamente: los conteos de `git ls-files` en cada corrida de `secret-scan.sh` (69, luego 71 archivos) nunca incluyeron nada bajo `SDD/tests/.tmp/` |

Ningún caller de `plugins/` quedó sin cubrir porque R0 no modifica ningún archivo de `plugins/` (`git diff HEAD -- plugins/` da vacío, verificado).

---

## Rojos preexistentes

- No hay corridas previas de esta escalera contra `prod`: `SDD/docs/doc_quality_gates.md` y `SDD/tests/` no existían antes de R0 (los crea esta misma tarea), así que no hay un baseline de gates previo con el cual comparar.
- **Sí hay un hallazgo preexistente relevante para la decisión de diseño del gate de lint**: `shellcheck` (severidad default, `style`) sobre los 5 scripts que YA existían en `plugins/sdd-flow/` antes de este branch (`scripts/sdd-check.sh`, `scripts/sdd-lint-contract.sh`, `scripts/sdd-run-gates.sh`, `hooks/guard-git.sh`, `hooks/statusline.sh`) reporta 3 hallazgos `SC2016` (info) — backticks literales dentro de strings de una comilla en plantillas markdown, uso correcto y preexistente en `prod`, no introducido por R0 (`git diff HEAD -- plugins/` confirma cero cambios). Comando y salida:

  ```
  $ shellcheck plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh
  (exit 1 — 3 x SC2016 info, ver detalle abajo)
  ```
  ```
  In plugins/sdd-flow/scripts/sdd-lint-contract.sh line 54: ... SC2016 (info)
  In plugins/sdd-flow/scripts/sdd-run-gates.sh line 73: ... SC2016 (info)
  In plugins/sdd-flow/scripts/sdd-run-gates.sh line 124: ... SC2016 (info)
  ```
  Es la razón medida (no supuesta) de declarar el gate 2 con `--severity=warning` en `doc_quality_gates.md` en vez del default: a esa severidad, `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh` sale `0` (verificado). No es un ablandamiento posterior de un threshold ya configurado — este repo no tenía shellcheck configurado antes de R0; es la elección de piso inicial, documentada en el propio `doc_quality_gates.md`. Los 3 hallazgos `SC2016` quedan señalados acá para que el planner decida si registrarlos en `SDD/debt.md` (que no existe todavía — su creación no está en el scope de R0 y lo escriben planner/reviewer, `templates/debt-ledger.md`).
- Los propios archivos nuevos de R0 (`SDD/tests/*.sh`) también muestran hallazgos a severidad `style` (default): `SC2329` (info) sobre las funciones `cleanup()` invocadas únicamente por `trap ... EXIT` — limitación conocida de shellcheck para reconocer invocación por trap, no un hallazgo real. A `--severity=warning`, `shellcheck --severity=warning SDD/tests/*.sh` sale `0`.

---

## Prerequisitos verificados en esta máquina

- `shellcheck --version` → `0.11.0` (`/opt/homebrew/bin/shellcheck`).
- `bash --version` → `GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)` — piso 3.2 confirmado, ningún script de R0 usa `declare -A`, `mapfile`, `readarray`, `${var^^}` ni `&>>` (verificado a ojo y por el hecho de que todo corrió sin error de sintaxis en esta misma bash).
- `git --version` → `2.50.1`.
- `shfmt`, `timeout`, `gtimeout`: no instalados — de ahí el `N/A` del gate 1 (format) en `doc_quality_gates.md`, y la nota de que `sdd-run-gates.sh` corre sin límite de tiempo por gate en esta máquina.
