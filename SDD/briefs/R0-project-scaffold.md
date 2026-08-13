# Task brief — R0 · project-scaffold: escalera de gates viva para AI-Forge

- **Agente**: `AGENT_r0` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v2** (bumpeado por el planner tras el `ESCALATE` de la ronda 1 — ver "Ronda 2" abajo), sección `R0`
- **Arquetipo**: `project-scaffold`
- **Repo**: `.` (AI-Forge) · **Branch**: `feat-GEN-94-sicop-hardening` (ya creada desde `prod`; NO crear otra, NO commitear a `prod`)
- **Proxima subtask id**: `f7d63c89-3acd-423b-bb32-8e234630ca95` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R0.md`

## Objective

Dejar viva la escalera de gates de ESTE repo: un runner de tests en bash que corre de verdad, `shellcheck` limpio, y `SDD/docs/doc_quality_gates.md` con los comandos reales verificados contra la máquina. Sin esto, los requerimientos R1 a R4 no tienen forma de probar nada.

## Out of scope

- No toques nada dentro de `plugins/`. R0 no modifica el producto distribuible.
- No crees `.github/workflows` (declarado `N/A` con razón en el contract; ya está en el ledger de deuda).
- No implementes R1 a R4. Si ves el bug del sellado en `sdd-run-gates.sh`, **no lo arregles**: es el scope de R1 y su test tiene que correr rojo primero.

## Prerequisites

- `shellcheck` está instalado (`/opt/homebrew/bin/shellcheck`, v0.11.0). Verificalo antes de arrancar.
- El piso de bash es **3.2** (el de macOS). Prohibido `declare -A`, `mapfile`, `readarray`, `${var^^}`, `&>>`. Los scripts del plugin ya respetan ese piso: imitá su estilo.

## Files to create

| Path | Qué es |
|---|---|
| `SDD/tests/lib.sh` | Helpers de assert. Único lugar donde se definen `assert_*` |
| `SDD/tests/run.sh` | Descubre y corre `SDD/tests/test_*.sh`, agrega resultados |
| `SDD/tests/test_harness.sh` | Auto-test del harness: un caso que falla se reporta como fallo |
| `SDD/tests/test_run_gates.sh` | Humo de `sdd-run-gates.sh` sobre un repo git temporal |
| `SDD/tests/secret-scan.sh` | Gate 9: sale 0 cuando no encuentra secretos en los archivos versionados |
| `SDD/docs/doc_quality_gates.md` | La escalera con los comandos reales |
| `SDD/docs/doc_architecture.md` | Layout del repo, desde `plugins/sdd-flow/templates/doc_architecture.md` |
| `.gitignore` | (modificar) agregar `SDD/tests/.tmp/` |
| `SDD/tests/test_secret_scan.sh` | **(ronda 2, AC6bis)** Cinco formas de secreto, cada una probada por mutación |

## Pasos

### Fase 1 — Harness

- [x] T1.1 Escribir `SDD/tests/lib.sh` con al menos `assert_eq`, `assert_contains`, `assert_exit` y un contador de fallos exportable. Sin dependencias fuera de coreutils y bash 3.2.
- [x] T1.2 Escribir `SDD/tests/run.sh`: descubre `SDD/tests/test_*.sh`, corre cada uno en su propio proceso, imprime una línea por archivo con su resultado, y agrega. **Sale 0 si todos pasan, 1 si alguno falla, 1 si no encontró ningún test.**
- [x] T1.3 Escribir `SDD/tests/test_harness.sh`: verifica que `run.sh` propaga el fallo. Para eso genera un test falso temporal que sale ≠0 y comprueba que `run.sh` sale 1 y nombra el archivo. El test falso vive en `SDD/tests/.tmp/`, nunca versionado.
- [x] T1.4 Agregar `SDD/tests/.tmp/` a `.gitignore`.

### Fase 2 — Primer test real

- [x] T2.1 Escribir `SDD/tests/test_run_gates.sh`: crea un repo git en `SDD/tests/.tmp/`, le escribe un `doc_quality_gates.md` mínimo con dos gates que salen 0, corre `plugins/sdd-flow/scripts/sdd-run-gates.sh` contra él, y assertea el campo `green` de la línea JSON `sdd.gates`. **Limpieza garantizada con `trap ... EXIT`**, incluso si el test falla.
- [x] T2.2 Escribir `SDD/tests/secret-scan.sh`. Semántica: **exit 0 cuando NO hay secretos**. Sin pipes en la invocación que va a la tabla de gates (el parser del runner toma la primera celda backtickeada de la línea).

### Fase 3 — Escalera declarada y verificada

- [x] T3.1 Escribir `SDD/docs/doc_quality_gates.md` con la tabla en el formato exacto que parsea `sdd-run-gates.sh` (filas `| N | gate | \`cmd\` | obligatorio | notas |`). Escalera propuesta, ajustala a la realidad que midas:

  **Desvío medido respecto de la propuesta** (autorizado por el propio texto de T3.1, "ajustala a la realidad que midas"): el gate 2 quedó como `` `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` `` (con `--severity=warning`, no el comando literal propuesto). Medido: a severidad default (`style`), shellcheck sale `1` sobre los 5 scripts YA existentes en `plugins/sdd-flow/` — 3 hallazgos `SC2016` (info) por backticks literales en plantillas markdown, preexistentes en `prod`, uso correcto — y sobre los `SDD/tests/*.sh` nuevos de R0 — `SC2329` (info) por `cleanup()` invocado sólo vía `trap`, falso positivo conocido de shellcheck. A `--severity=warning` el mismo comando sale `0`. Detalle y comando exacto en `SDD/verification/feat-GEN-94-sicop-hardening-R0.md`, sección "Rojos preexistentes".

  | # | Gate | Comando | Nota |
  |---|---|---|---|
  | 1 | format / style | `N/A — shfmt no está instalado` | |
  | 2 | lint | `shellcheck plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | |
  | 3 | type-check | `N/A — bash no es tipado` | |
  | 4 | unit tests | `bash SDD/tests/run.sh` | |
  | 5 | integration | `N/A — los tests del harness ya ejercitan los scripts end-to-end` | |
  | 6 | build | `N/A — el plugin no compila` | |
  | 7 | e2e | `N/A` | |
  | 8 | cobertura del diff | `N/A — sin reporte de coverage; se verifica con el binding AC↔test` | |
  | 9 | security | `bash SDD/tests/secret-scan.sh` | |
  | 10 | smoke manual | `N/A` | |

- [x] T3.2 Escribir `SDD/docs/doc_architecture.md` desde el template, describiendo el layout real (marketplace + `plugins/sdd-flow/` + `plugins/project-foundation/` + `SDD/` + `docs/`).
- [x] T3.3 Correr `sdd-run-gates.sh -d SDD/docs/doc_quality_gates.md -o .sdd/gates-run.md` y verificar `red: 0` y cero `[SKIPPED]` por comando inexistente. **Si un gate sale rojo, arreglá la causa; prohibido ablandar el gate** (`quality-gates.md` §6). Corrido dos veces: exploratoria a `.sdd/gates-run.md` y final (`--full`) a `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` (commiteada). Ambas `red: 0`; los 7 `[SKIPPED]` son las filas `N/A — <razón>` declaradas, ninguno por comando inexistente.
- [x] T3.4 Correr `shellcheck` sobre todos los `.sh` nuevos hasta exit 0. Si `shellcheck` marca algo en `lib.sh` por ser un archivo sourceado, usá la directiva `# shellcheck shell=bash`, nunca un `disable` genérico. `lib.sh` lleva `# shellcheck shell=bash` en su primera línea. `shellcheck --severity=warning` sobre `git ls-files -- '*.sh'` completo sale `0`.

### Fase 4 — Evidencia y commit

- [x] T4.1 Escribir `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` con `plugins/sdd-flow/templates/verification-report.md`: referencia al reporte generado, comando y exit code por gate, impact set.
- [x] T4.2 Llenar la tabla `AC ↔ test binding` de abajo con nombres de test que existan literal.
- [x] T4.3 Commitear en `feat-GEN-94-sicop-hardening` con el formato `[ADD] [GEN-94] [sdd-flow] <descripción>`. **Un solo commit** para R0.

### Ronda 2 — ESCALATE del reviewer, contract bumpeado a v2

El planner cerró los dos defectos de plan (threat model + concerns; AC3/AC5 reescritos) directamente en el contract v2 — no son tarea de este agente. Lo que sí es tarea de este agente:

- [x] T5.1 (AC6bis) Corregir `SDD/tests/secret-scan.sh`: el patrón de la ronda 1 exigía comillas y sólo matcheaba la palabra disparadora exacta en minúscula, dejando pasar 4 de las 5 formas reales. Nuevo patrón case-insensitive, con/sin comillas, `SCREAMING_SNAKE`, separador `:` o `=`.
- [x] T5.2 (AC6bis) Escribir `SDD/tests/test_secret_scan.sh`: un caso de test por cada una de las cinco formas del contract v2, cada uno probado por mutación (plantar → rojo → remover → verde).
- [x] T5.3 (efecto colateral medido, no pedido explícitamente pero necesario para que AC5 siguiera en `red:0`) Corregir dos falsos positivos nuevos que introdujo el patrón más amplio de T5.1: `plugins/sdd-flow/commands/sdd-agents.md:12` (charset del valor acotado a lo que un token real usa) y `SDD/contracts/2026-08-13-sicop-hardening.md:77-80` (exclusión de `SDD/contracts/` por la misma razón autorreferencial que la auto-exclusión de `secret-scan.sh`).
- [x] T5.4 (MAJOR) Re-correr la mutación de AC2 contra el `test_harness.sh` real (6 asserts, no los 4 de la evidencia stale de ronda 1) y reemplazar la salida pegada en el verification report.
- [x] T5.5 (AC3bis) Agregar `# shellcheck disable=SC2329  # invocada por trap EXIT` inline en los tres `cleanup()` de `SDD/tests/` (`test_harness.sh`, `test_run_gates.sh`, `test_secret_scan.sh`), para que el piso `--severity=warning` quede justificado únicamente por los `SC2016` preexistentes de `plugins/` (`D4`).
- [x] T5.6 (MINOR) Reemplazar la cifra "69, luego 71" del Impact set por conteos frescos con su comando (`git ls-files`, `secret-scan.sh`).
- [x] T5.7 Actualizar `SDD/docs/doc_quality_gates.md` (notas de gate 2 y 9, timing con 3 archivos de test, convención de fixtures que parecen un secreto) y regenerar `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md`.
- [x] T5.8 Segundo commit `[FIX] [GEN-94] [sdd-flow] ...` sobre la misma branch.

## Acceptance criteria (IDs del contract v2 — no los renumeres)

- **AC1** — `SDD/tests/run.sh` sale 0 cuando todos los `test_*.sh` pasan.
- **AC2** — `SDD/tests/run.sh` sale 1 cuando al menos un `test_*.sh` falla, y su salida nombra el archivo que falló.
- **AC3** — `shellcheck --severity=warning` sale 0 sobre todos los `.sh` versionados del repo. **Ratificación v2**: piso `warning`, no `style`, justificado por los `SC2016` de `plugins/` (fuera de scope de R0).
- **AC3bis** *(nuevo v2)* — Los `SC2329` propios de archivos creados por R0 llevan `# shellcheck disable=SC2329` inline con el comentario que lo justifica, de modo que el piso `warning` quede justificado únicamente por hallazgos preexistentes de `plugins/`.
- **AC4** — `SDD/docs/doc_quality_gates.md` tiene la tabla en el formato que parsea el runner, y cada fila con comando declarado ejecuta un binario presente en la máquina. Las filas sin comando llevan `N/A — <razón>`.
- **AC5** — `sdd-run-gates.sh -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` termina con `red: 0` en su línea JSON `sdd.gates`, sin gates `[SKIPPED]` por comando inexistente. **Ratificación v2**: destino `SDD/verification/`, no `.sdd/`.
- **AC6** — `SDD/tests/test_run_gates.sh` ejercita el runner sobre un repo git en `SDD/tests/.tmp/` y assertea el campo `green` del JSON. El temporal se borra al terminar incluso si el test falla.
- **AC6bis** *(nuevo v2)* — `SDD/tests/secret-scan.sh` detecta, cada una en su propio caso de `SDD/tests/test_secret_scan.sh`, las cinco formas: `api_key=` sin comillas minúscula, `PASSWORD="..."` SCREAMING_SNAKE, `AWS_SECRET_ACCESS_KEY=` sin comillas mayúscula, `GITHUB_TOKEN:` separador dos puntos, y clave privada PEM. Sale limpio sobre un árbol sin secretos.

**AC2 es un AC de detección**: su condición de aprobación es "el harness se pone rojo cuando un test falla". No alcanza con verlo verde. Probalo rompiendo a propósito: generá un test que falle, verificá que `run.sh` sale 1, y revertí. Registrá las tres corridas (verde → rojo → verde) con comando y exit code en el verification report. Un harness que reporta éxito sin haber detectado el fallo es exactamente el modo de falla que este contract ataca.

**AC6bis también es un AC de detección**: se prueba por mutación (plantar cada forma → rojo → remover → verde), cinco veces, una por forma. Ver `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` sección "AC6bis" para las cinco corridas.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC1 | `run.sh` sale 0 cuando todos los `test_*.sh` pasan | `SDD/tests/test_harness.sh::"run.sh sale 0 cuando todos los test_*.sh pasan"` | unit | [x] |
| AC2 | `run.sh` sale 1 cuando un `test_*.sh` falla, y nombra el archivo | `SDD/tests/test_harness.sh::"run.sh sale 1 y nombra el archivo que falló"` | unit + mutación (verde→rojo→verde **re-corrida en ronda 2** contra el `test_harness.sh` real de 6 asserts — `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` sección AC2) | [x] |
| AC3 | `shellcheck --severity=warning` sale 0 sobre todos los `.sh` versionados | gate-evidence: `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` Gate 2 (lint), + `shellcheck --severity=warning $(git ls-files -- '*.sh')` → exit 0 (comando y salida en el verification report) | gate | [x] |
| AC3bis | `SC2329` propios de R0 con `disable` inline justificado | `SDD/tests/test_harness.sh:20`, `SDD/tests/test_run_gates.sh:21`, `SDD/tests/test_secret_scan.sh:29` (grep literal) + verificación `shellcheck` default sin `SC2329` en `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` sección AC3bis | gate + grep | [x] |
| AC4 | `doc_quality_gates.md` con tabla parseable y comandos reales; filas sin comando llevan `N/A — <razón>` | gate-evidence: el runner parseó `SDD/docs/doc_quality_gates.md` sin `exit 3` y corrió los 3 gates con comando declarado (2, 4, 9) contra binarios presentes — ver `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` | gate | [x] |
| AC5 | `sdd-run-gates.sh -d ... -o SDD/verification/...-gates.md` termina `red: 0`, sin `[SKIPPED]` por comando inexistente | gate-evidence: línea `{"type":"sdd.gates","green":4,"red":0,"skipped":7,...}` en `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` (los 7 skipped son las filas `N/A` declaradas, no comandos faltantes; destino ya no es `.sdd/`, ratificación v2) | gate | [x] |
| AC6 | `test_run_gates.sh` ejercita el runner sobre un repo git temporal, asserta `green`, y limpia incluso si falla | `SDD/tests/test_run_gates.sh::"el JSON sdd.gates reporta green:2"` (+ `"sdd-run-gates.sh sale 0 con dos gates que salen 0"`, `"el JSON sdd.gates reporta red:0 con dos gates verdes"`); limpieza-en-fallo verificada empíricamente, ver `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` sección AC6 | integration | [x] |
| AC6bis | `secret-scan.sh` detecta las 5 formas reales, cada una por mutación | `SDD/tests/test_secret_scan.sh::"forma1 api_key sin comillas - rojo al plantar"`, `"forma2 PASSWORD screaming-snake con comillas - rojo al plantar"`, `"forma3 AWS_SECRET_ACCESS_KEY sin comillas - rojo al plantar"`, `"forma4 GITHUB_TOKEN separador dos puntos - rojo al plantar"`, `"forma5 clave privada PEM - rojo al plantar"` (+ sus pares verde antes/después) — 22 asserts, salida completa en `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` sección AC6bis | unit + mutación ×5 | [x] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Cada exit code del report tiene que venir de una corrida real.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner. No adivines.
- Prohibidas las mitigaciones de `plugins/sdd-flow/standards/quality-gates.md` §6.
- No toques `.sdd/state.json` ni Proxima. Eso lo escribe el planner.

## Rollback

`git revert` de los commits de R0 (ronda 1 + ronda 2). No hay migración ni estado externo.

## Done criteria

Los ocho ACs (AC1-AC6, AC3bis, AC6bis) con test verde o gate-evidence, `SDD/tests/run.sh` verde con los 3 archivos de test, `sdd-run-gates.sh` con `red: 0` apuntando a `SDD/verification/` (no `.sdd/`), verification report escrito, binding completo, dos commits en la branch (ronda 1 `[ADD]`, ronda 2 `[FIX]`).

## Execution Report

- **Summary**: Ronda 1 dejó la escalera de gates viva (harness, primer test real, gate de seguridad, docs) pero el reviewer emitió `ESCALATE`: `secret-scan.sh` no detectaba 4 de 5 formas reales de secreto (AC6bis nuevo), la evidencia de mutación de AC2 estaba stale, los `SC2329` propios no tenían justificación inline (AC3bis nuevo), y una cifra del Impact set no tenía corrida detrás. Ronda 2 corrige los cuatro puntos sobre el contract v2 (que también ratificó AC3/AC5 y agregó threat model — trabajo del planner, no de este agente), más dos falsos positivos nuevos que el patrón ampliado de AC6bis introdujo (medidos y corregidos en la misma ronda: un placeholder de doc en `plugins/` y la propia prosa de `SDD/contracts/`).
- **Task status**: ronda 1, 13/13 (T1.1-T1.4, T2.1-T2.2, T3.1-T3.4, T4.1-T4.3). Ronda 2, 8/8 (T5.1-T5.8). 0 bloqueadas, 0 skipped en ambas rondas.
- **Validation executed** (comando · exit code) — ronda 2, la vigente:
  - `bash SDD/tests/test_secret_scan.sh` · `0` (22 asserts — AC6bis, las 5 formas por mutación)
  - `bash SDD/tests/test_harness.sh` · `0` (y `1` durante la mutación deliberada de AC2 **re-corrida fresca**, revertida)
  - `bash SDD/tests/test_run_gates.sh` · `0` (y `1` durante el fallo forzado deliberado de la prueba de limpieza de AC6, revertido)
  - `bash SDD/tests/run.sh` · `0` (`3 passed, 0 failed (3 total)`, ~2s)
  - `bash SDD/tests/secret-scan.sh` · `0` (`75` archivos escaneados, `2` excluidos: self + `SDD/contracts/`)
  - `git ls-files -z -- '*.sh' | xargs -0 shellcheck --severity=warning` · `0`
  - `git ls-files -z -- '*.sh' | xargs -0 shellcheck` (default) · `1` — exactamente los 3 `SC2016` de `plugins/` (`D4`), cero `SC2329` (AC3bis verificado)
  - `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` · `0` (`green:4,red:0,skipped:7`) — evidencia oficial commiteada, reemplaza la de ronda 1
  - Detalle completo, con las corridas rojas intermedias y los dos falsos positivos medidos, en `SDD/verification/feat-GEN-94-sicop-hardening-R0.md`.
- **Blockers**: ninguno.
- **Files changed en ronda 2**: `SDD/tests/secret-scan.sh` (mod — patrón AC6bis + exclusión `SDD/contracts/` + salida redactada), `SDD/tests/test_secret_scan.sh` (new — AC6bis), `SDD/tests/test_harness.sh` (mod — `disable=SC2329` inline), `SDD/tests/test_run_gates.sh` (mod — `disable=SC2329` inline), `SDD/tests/run.sh` (mutado y revertido para la corrida de AC2, sin diff neto), `SDD/docs/doc_quality_gates.md` (mod — notas AC3bis/AC6bis, timing), `SDD/verification/feat-GEN-94-sicop-hardening-R0.md` (mod — reescrito con la ronda 2), `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` (mod, regenerado por el runner), `SDD/briefs/R0-project-scaffold.md` (este archivo). Cero cambios en `plugins/` (verificado: `git diff origin/prod -- plugins/` vacío) y cero cambios en `SDD/contracts/`, `SDD/debt.md`, `.sdd/state.json`.
- **Final statement**: Done. Los ocho ACs (AC1-AC6, AC3bis, AC6bis) tienen test verde o gate-evidence, `SDD/tests/run.sh` sale 0 con 3 archivos de test, `sdd-run-gates.sh` termina `red: 0` apuntando a `SDD/verification/` sin `[SKIPPED]` por comando inexistente, verification report escrito y referenciado, binding completo, segundo commit `[FIX]` pendiente de crear sobre `feat-GEN-94-sicop-hardening`.
