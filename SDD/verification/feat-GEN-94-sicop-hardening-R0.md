# Verification Report — AGENT_r0 · R0-project-scaffold

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R0 del contract `SDD/contracts/2026-08-13-sicop-hardening.md` **v3** (última ronda antes del cap de `quality-gates.md` §7.4; ver "Ronda 3" abajo).

- **Branch**: `feat-GEN-94-sicop-hardening` (creada desde `prod`)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v3, sección R0 (AC1-AC6, AC3bis, AC6bis)
- **HEAD al momento de las corridas de ronda 3**: `c516902` (commit del planner con el contract v3 — fixtures de AC6bis partidas en spans separados — ya integrado a esta branch antes de este tercer commit de R0) — el sellado de `sdd-run-gates.sh` sigue estampando `HEAD` en vez del árbol trabajado (bug de R1, no se toca acá, ver nota de ronda 1 abajo).
- **Commit evaluado**: el tercer commit de R0 (`[FIX] [GEN-94] [sdd-flow] ...`), creado después de este reporte — mismo razonamiento que en rondas anteriores: el hash no puede conocerse antes de crearlo; queda en el `sdd.result` con `"round":3`.
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (sin cambios de contenido en ronda 3 — el fix es enteramente de `secret-scan.sh` y `test_secret_scan.sh`)

---

## Ronda 3 — la exclusión de ronda 2 era la mitigación en el lugar equivocado

El reviewer midió, sobre un repo git de prueba, que la exclusión de `SDD/contracts/` de ronda 2 dejaba el gate 9 **ciego a todo un directorio**: un secreto real plantado en `SDD/contracts/2026-09-01-nueva-feature.md` salía `exit 0` (no detectado), mientras el mismo contenido en `src/config.md` salía `exit 1` (detectado). El razonamiento de ronda 2 (el contract disparaba el detector) era correcto, pero la causa raíz era del **plan**, no del código: los cuatro literales de `AC6bis` en el contract v2 tenían clave y valor contiguos. El planner ya lo corrigió en v3 (`SDD/contracts/2026-08-13-sicop-hardening.md`, sección R0, ratificación v3 de `AC6bis`): los cuatro literales ahora van con clave y valor en spans separados, y **v3 prohíbe cualquier exclusión por path en `secret-scan.sh`** — la única admitida es la del propio script sobre sí mismo.

Lo que corresponde a este agente en esta ronda:

1. **Borrar la exclusión por path.** `EXCLUDE_PATH_PREFIXES` y `is_excluded_path()` eliminados de `SDD/tests/secret-scan.sh`; el `if` del loop principal vuelve a comparar sólo contra `$SELF_ABS`. Mensaje de salida actualizado (ya no dice "2 excluidos").
2. **Verificación obligatoria, corrida antes de tocar nada más**: `bash SDD/tests/secret-scan.sh` sobre el repo real, con la exclusión ya borrada:
   ```
   $ bash SDD/tests/secret-scan.sh
   secret-scan: sin hallazgos sobre 77 archivos versionados (1 excluido: self)
   ```
   Exit `0`. El fix del planner en el contract v3 fue suficiente — no quedó otro literal de credencial contiguo en el repo real que disparara el detector. No hubo que reportar `BLOCKED`.
3. **Nuevo caso de detección (forma 6)** en `SDD/tests/test_secret_scan.sh`: planta un secreto en un archivo bajo `SDD/contracts/` **dentro del repo git temporal** (nunca toca el `SDD/contracts/` real) y exige rojo. Es el AC de detección aplicado a la exclusión misma — probado por mutación (ver sección "AC6bis" abajo): se reintrodujo temporalmente la exclusión por path en `secret-scan.sh`, se confirmó que el caso se pone rojo, se revirtió.
4. **MINOR — comentario del punto ciego del charset (deuda `D6`, ya registrada por el planner)**: `secret-scan.sh:59-75` ahora documenta que el valor exige 4 caracteres del charset arrancando justo después del separador, así que `password = "p@ssw0rd!"` y `SMTP_PASSWORD=$ecret123` no se detectan. No se cambia el charset (el trade-off contra el falso positivo de `sdd-agents.md:12` está aceptado) — sólo se documenta.
5. **MINOR — Impact set desactualizado**: la fila de `lib.sh` decía "los dos únicos `test_*.sh` a la fecha"; corregida a los tres (`test_harness.sh`, `test_run_gates.sh`, `test_secret_scan.sh`) — ver Impact set abajo.

---

## Ronda 2 — qué cambió y por qué (ESCALATE del reviewer sobre la ronda 1)

El reviewer emitió `ESCALATE` con dos defectos de plan (ya cerrados por el planner en el contract v2: threat model + concerns, y AC3/AC5 reescritos — no son trabajo de este agente) y cuatro hallazgos sobre la implementación, los cuatro corregidos en esta ronda:

1. **AC6bis (nuevo) — `secret-scan.sh` no detectaba 4 de 5 formas reales.** La ronda 1 exigía comillas alrededor del valor y sólo matcheaba la palabra disparadora exacta en minúscula. Corregido: patrón case-insensitive, con o sin comillas, `SCREAMING_SNAKE` (prefijo/sufijo de identificador), separador `:` o `=`. Nuevo `SDD/tests/test_secret_scan.sh` con las cinco formas, cada una probada por mutación (plantar → rojo → remover → verde). Ver sección "AC6bis" abajo.
2. **MAJOR — evidencia de mutación de AC2 estaba stale.** El report de ronda 1 mostraba 4 líneas de salida contra una versión de `test_harness.sh` que ya tenía 6 asserts al momento del commit. Re-corrida la mutación contra el `test_harness.sh` real (6 asserts) — ver sección "AC2" abajo, reemplazada con la salida fresca.
3. **AC3bis (nuevo) — los `SC2329` propios de R0 quedan justificados inline.** `# shellcheck disable=SC2329  # invocada por trap EXIT` agregado en los tres `cleanup()` de `SDD/tests/` (`test_harness.sh`, `test_run_gates.sh`, y el nuevo `test_secret_scan.sh`). Verificado: a severidad default sólo quedan los 3 `SC2016` preexistentes de `plugins/` (debt `D4`) — ver sección "AC3bis" abajo.
4. **MINOR — cifra "69, luego 71" sin corrida que la respalde.** Reemplazada por conteos frescos, cada uno con su comando — ver Impact set abajo.

**Efecto colateral medido al ampliar el patrón de AC6bis** (no pedido explícitamente, pero necesario para que AC5 siguiera en `red:0`): el patrón más amplio generó dos falsos positivos nuevos:
- `plugins/sdd-flow/commands/sdd-agents.md:12` ("Primer token: `<task-slug>`", un placeholder de documentación) — corregido acotando el charset del valor a lo que un token/credencial real usa (`[A-Za-z0-9_./+=-]`, sin backtick ni `<`/`>`). **Este fix se mantiene en ronda 3.**
- `SDD/contracts/2026-08-13-sicop-hardening.md:77-80` (el propio AC6bis citaba las cinco formas con clave y valor contiguos) — la mitigación de ronda 2 fue excluir `SDD/contracts/` del alcance del scan. **Revertido en ronda 3**: era la mitigación en el lugar equivocado (dejaba el gate ciego a todo el directorio, medido por el reviewer). La causa raíz correcta era del contract, no del scanner — el planner partió los literales en v3 y esta ronda borra la exclusión. Ver sección "Ronda 3" arriba y "AC6bis" abajo.

---

## Nota sobre el sellado HEAD-vs-árbol (para que quede registrado, no para arreglarlo)

La corrida de `sdd-run-gates.sh` de la sección siguiente estampa `Commit: c516902` en su encabezado — el `HEAD` de la branch en el momento de la corrida (el commit del planner con el contract v3, ya integrado) — aunque los gates se ejecutaron contra el árbol de trabajo con los cambios de la ronda 3 todavía sin commitear. Rondas 1 y 2 mostraron el mismo síntoma contra `e5ef90c` y `83c8bb2` respectivamente. Es el bug descrito en la sección R1 del contract (`sdd-run-gates.sh:120`, sella `HEAD` en vez del árbol verificado). **No lo arreglo acá**: es scope de R1 y su test de reproducción tiene que correr rojo primero contra el script actual. Lo dejo señalado porque es la ilustración más directa posible del problema que R1 ataca, repetida en tres rondas seguidas: este mismo reporte es, otra vez, evidencia sellada contra el código equivocado.

---

## Gates — evidencia GENERADA (no escrita a mano)

Corrida real de ronda 3, en esta máquina (macOS, bash 3.2.57(1), shellcheck 0.11.0, git 2.50.1), después de borrar la exclusión por path y agregar la forma 6:

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md
```
- Exit: `0` — `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md"}`
- **Reporte generado y commiteado**: [`SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md`](./feat-GEN-94-sicop-hardening-R0-gates.md) — mismo directorio que este archivo, no `.sdd/` (sobreescribe el de ronda 2, que también era `red:0`; no hay historia de rojos que preservar, `quality-gates.md` §5 pide preservar rojos, no verdes intermedios). **Esta es la evidencia oficial de AC5**: `red: 0`, y los 7 `[SKIPPED]` son las filas `N/A — <razón>` declaradas a propósito en `doc_quality_gates.md` (gates 1, 3, 5, 6, 7, 8, 10), **ninguno por comando inexistente o placeholder olvidado** (los 3 gates con comando real — lint, unit tests, security — corren y salen verdes; `--full` corre además la "suite completa", 4to verde). El gate 9 (security) corrió `secret-scan.sh` **sin exclusión por path** — la escalera completa confirma `red:0` con el fix real, no sólo el test unitario.
- Suite sola, para referencia de tiempo: `bash SDD/tests/run.sh` → exit `0`, `3 passed, 0 failed (3 total)` (sigue siendo 3 archivos — `test_secret_scan.sh` ganó un caso más, no un archivo nuevo).

No hubo corridas rojas de la escalera completa en ningún momento de R0 (los 3 gates reales corren verdes porque los archivos que ejercitan se escribieron y probaron de forma incremental — ver mutaciones de AC2 y AC6bis abajo, que sí generan rojos reales, pero en los tests unitarios, no en la escalera).

---

## AC2 — prueba por mutación (verde → rojo → verde) — **re-corrida en ronda 2**

AC2 es un AC de detección ("`run.sh` sale 1 cuando un test falla") — no alcanza con verlo verde. Se rompió `SDD/tests/run.sh` a propósito, se corrió el test que lo cubre, se confirmó rojo, y se revirtió.

**Corrección sobre la ronda 1**: el report anterior pegaba una salida de 4 líneas de `test_harness.sh` que ya tenía 6 asserts al momento del commit — evidencia sellada contra una versión anterior del archivo (el mismo modo de falla que ataca R1, aplicado acá a un test en vez de a un commit). Esta es la corrida real contra el `test_harness.sh` commiteado (6 asserts: 2 por caso × 3 casos).

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar) | `bash SDD/tests/test_harness.sh` | `0` | `PASS` — las 6 líneas `ok` |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_harness.sh` | `1` | `FAIL — 1 assert(s) fallaron` — falla exactamente el assert de AC2, las otras 5 líneas siguen `ok` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_harness.sh` | `0` | `PASS` — las 6 líneas `ok` de nuevo |

**Mutación aplicada** (`SDD/tests/run.sh`, bloque final): se quitó el `exit 1` del branch `if [ "$FAIL_COUNT" -gt 0 ]`, dejando que el script siempre llegue al `exit 0` final aunque haya fallos — el defecto exacto que AC2 existe para prevenir. Diff aplicado durante la corrida 2 (revertido antes de la corrida 3):

```diff
 if [ "$FAIL_COUNT" -gt 0 ]; then
   printf 'Archivos con fallos: %s\n' "$FAILED_FILES"
-  exit 1
+  # MUTACION-AC2-TEMPORAL-RONDA2: exit 1 removido a propósito para la
+  # corrida roja fresca exigida por el reviewer — se revierte enseguida.
 fi
```

Salida completa y real de la corrida 1 (verde, `test_harness.sh` de 6 asserts sin mutar):
```
  ok    run.sh sale 0 cuando todos los test_*.sh pasan (exit 0)
  ok    run.sh sale 0 cuando todos los test_*.sh pasan
  ok    run.sh sale 1 y nombra el archivo que falló (exit 1)
  ok    run.sh sale 1 y nombra el archivo que falló
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh (exit 1)
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh
PASS
```

Salida completa y real de la corrida 2 (roja, con la mutación), pegada tal cual — 6 líneas, no 4:
```
  ok    run.sh sale 0 cuando todos los test_*.sh pasan (exit 0)
  ok    run.sh sale 0 cuando todos los test_*.sh pasan
  FAIL  run.sh sale 1 y nombra el archivo que falló (exit 1) — esperado [1], obtenido [0]
  ok    run.sh sale 1 y nombra el archivo que falló
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh (exit 1)
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh
FAIL — 1 assert(s) fallaron
```

Salida completa y real de la corrida 3 (verde, mutación revertida) — idéntica a la corrida 1, confirmado con `grep -n "MUTACION" SDD/tests/run.sh` sin resultados tras revertir:
```
  ok    run.sh sale 0 cuando todos los test_*.sh pasan (exit 0)
  ok    run.sh sale 0 cuando todos los test_*.sh pasan
  ok    run.sh sale 1 y nombra el archivo que falló (exit 1)
  ok    run.sh sale 1 y nombra el archivo que falló
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh (exit 1)
  ok    run.sh sale 1 cuando no encuentra ningun test_*.sh
PASS
```

Conclusión: el test que respalda AC2 tiene poder de detección real — no es tautológico. `SDD/tests/run.sh` en el repo, al momento de este commit, es la versión sin mutar (verde).

---

## AC6bis — `secret-scan.sh` detecta las cinco formas reales + no puede excluir paths (ronda 2 + ronda 3)

La ronda 1 midió, sobre un repo git temporal, que la implementación sólo detectaba la forma 5 (PEM). Corregido el patrón (case-insensitive, con/sin comillas, `SCREAMING_SNAKE`, separador `:` o `=`) y agregado `SDD/tests/test_secret_scan.sh`, que prueba las cinco formas del contract v2/v3, cada una con su propio triple verde→rojo→verde, más una sexta forma agregada en ronda 3 (ver más abajo). Salida real de `bash SDD/tests/test_secret_scan.sh` (exit `0`, **26** asserts):

```
  ok    secret-scan.sh sale limpio sobre un arbol sin secretos (exit 0)
  ok    secret-scan.sh sale limpio sobre un arbol sin secretos
  ok    forma1 api_key sin comillas - verde antes de plantar (exit 0)
  ok    forma1 api_key sin comillas - rojo al plantar (exit 1)
  ok    forma1 api_key sin comillas - rojo al plantar
  ok    forma1 api_key sin comillas - verde tras remover (exit 0)
  ok    forma2 PASSWORD screaming-snake con comillas - verde antes de plantar (exit 0)
  ok    forma2 PASSWORD screaming-snake con comillas - rojo al plantar (exit 1)
  ok    forma2 PASSWORD screaming-snake con comillas - rojo al plantar
  ok    forma2 PASSWORD screaming-snake con comillas - verde tras remover (exit 0)
  ok    forma3 AWS_SECRET_ACCESS_KEY sin comillas - verde antes de plantar (exit 0)
  ok    forma3 AWS_SECRET_ACCESS_KEY sin comillas - rojo al plantar (exit 1)
  ok    forma3 AWS_SECRET_ACCESS_KEY sin comillas - rojo al plantar
  ok    forma3 AWS_SECRET_ACCESS_KEY sin comillas - verde tras remover (exit 0)
  ok    forma4 GITHUB_TOKEN separador dos puntos - verde antes de plantar (exit 0)
  ok    forma4 GITHUB_TOKEN separador dos puntos - rojo al plantar (exit 1)
  ok    forma4 GITHUB_TOKEN separador dos puntos - rojo al plantar
  ok    forma4 GITHUB_TOKEN separador dos puntos - verde tras remover (exit 0)
  ok    forma5 clave privada PEM - verde antes de plantar (exit 0)
  ok    forma5 clave privada PEM - rojo al plantar (exit 1)
  ok    forma5 clave privada PEM - rojo al plantar
  ok    forma5 clave privada PEM - verde tras remover (exit 0)
  ok    forma6 secreto bajo SDD-contracts - verde antes de plantar (exit 0)
  ok    forma6 secreto bajo SDD-contracts - rojo al plantar (exit 1)
  ok    forma6 secreto bajo SDD-contracts - rojo al plantar
  ok    forma6 secreto bajo SDD-contracts - verde tras remover (exit 0)
PASS
```

**Nota sobre el valor detectado**: por el threat model del contract v2 (punto 3), la salida de `secret-scan.sh` nunca imprime el valor — sólo `archivo:línea: posible secreto ... — valor no impreso` (visible arriba en las líneas `rojo al plantar`). Ningún artefacto de evidencia de este reporte contiene los valores de las fixtures plantadas.

**Cómo se construyeron las fixtures sin autodetectarse**: cada forma se arma con `printf '%s%s%s' "$clave" "$separador" "$valor"` — tres argumentos bash separados — para que la cadena completa `clave<separador>valor` nunca quede contigua y literal en `test_secret_scan.sh` (si lo estuviera, `secret-scan.sh` se detectaría a sí mismo al escanear ese archivo, porque no está en su lista de exclusión — desde ronda 3, la única exclusión que existe es la del propio script). Verificado con el propio gate 9 sobre el repo real: `bash SDD/tests/secret-scan.sh` → `0` incluyendo `test_secret_scan.sh` entre los archivos versionados escaneados.

### Forma 6 (ronda 3) — secreto bajo `SDD/contracts/` tiene que dar rojo, probado por mutación

El reviewer midió, sobre un repo de prueba, que la exclusión de `SDD/contracts/` de ronda 2 dejaba pasar un secreto real ahí (`exit 0`) mientras el mismo contenido en `src/config.md` daba `exit 1`. La causa raíz era del contract (literales de `AC6bis` contiguos en v2), ya corregida por el planner en v3. La responsabilidad de este agente era **borrar la exclusión** y agregar un caso que la reintroducción de cualquier exclusión por path vuelva a poner rojo.

`SDD/tests/test_secret_scan.sh` gana la forma 6: planta la misma variable `api_key` de la forma 1 (sin comillas) en `SDD/contracts/2026-09-01-nueva-feature.md` **dentro del repo git temporal** (nunca toca el `SDD/contracts/` real) y exige rojo. Triple verde→rojo→verde (líneas 22-25 de la salida de arriba).

**Prueba por mutación del caso mismo** (no alcanza con que hoy pase — hay que probar que detectaría la regresión si volviera):

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (`secret-scan.sh` actual, sin exclusión por path) | `bash SDD/tests/test_secret_scan.sh` | `0` | `PASS` — las 26 líneas `ok` |
| 2 — rojo (con la exclusión por path reintroducida) | `bash SDD/tests/test_secret_scan.sh` | `1` | `FAIL — 2 assert(s) fallaron` — fallan exactamente los 2 asserts de la forma 6 "rojo al plantar"; los otros 24 siguen `ok` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_secret_scan.sh` | `0` | `PASS` — las 26 líneas `ok` de nuevo |

**Mutación aplicada** (`SDD/tests/secret-scan.sh`, loop principal): se reintrodujo un `case "$f" in SDD/contracts/*) ... continue ;; esac` antes del chequeo de auto-exclusión — exactamente el patrón que v3 prohíbe. Revertido antes de la corrida 3.

**Extracto** de las líneas de la forma 6 en la corrida 2 (roja, con la exclusión reintroducida). La corrida completa emite 26 asserts: 24 `ok` y 2 `FAIL`, ambos de la forma 6 — las formas 1-5, que no pasan por `SDD/contracts/`, siguen verdes. *(Etiqueta corregida por el planner al cerrar el review de la ronda 3: decía "pegada tal cual" sobre lo que es un extracto. El reparto 24/2 declarado en la tabla de arriba fue verificado exacto por el reviewer; no había nada falso, sólo la etiqueta.)*
```
  ok    forma6 secreto bajo SDD-contracts - verde antes de plantar (exit 0)
  FAIL  forma6 secreto bajo SDD-contracts - rojo al plantar (exit 1) — esperado [1], obtenido [0]
  FAIL  forma6 secreto bajo SDD-contracts - rojo al plantar — no encontré [SDD/contracts/2026-09-01-nueva-feature.md] en la salida
  ok    forma6 secreto bajo SDD-contracts - verde tras remover (exit 0)
FAIL — 2 assert(s) fallaron
```

Conclusión: el caso tiene poder de detección real contra la regresión exacta que motivó esta ronda — no es tautológico. `SDD/tests/secret-scan.sh` en el repo, al momento de este commit, no tiene ninguna exclusión por path (`grep -n "EXCLUDE_PATH\|is_excluded_path" SDD/tests/secret-scan.sh` sin resultados).

**Efecto colateral del patrón más amplio, medido y corregido en la misma ronda** (no era parte del pedido explícito, pero sin esto AC5 no podía seguir en `red:0`):

1. Falso positivo en `plugins/sdd-flow/commands/sdd-agents.md:12` ("Primer token: `` `<task-slug>` ``"). Comando y salida ANTES del fix:
   ```
   $ grep -inEo "AKIA[0-9A-Z]{16}|-----BEGIN [A-Za-z ]*PRIVATE KEY-----|[A-Za-z0-9_]*(password|secret|token|api[_-]?key)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[\"']?[^\"'[:space:]]{4,}[\"']?" plugins/sdd-flow/commands/sdd-agents.md
   12:token: `<task-slug>`
   ```
   Fix: el charset del valor pasó de "cualquier cosa menos comilla/espacio" a `[A-Za-z0-9_./+=-]` (el charset real de un token/credencial — sin backtick, sin `<`/`>`). Un valor real de credencial nunca lleva esos caracteres. Después del fix, `bash SDD/tests/secret-scan.sh` ya no marca ese archivo — confirmado en la corrida limpia de más abajo (Impact set tiene el detalle de conteos).
2. Falso positivo en `SDD/contracts/2026-08-13-sicop-hardening.md:77-80` (v2) — el propio `AC6bis` citaba las cinco formas con clave y valor contiguos. **Historial de la mitigación, las dos rondas:**
   - **Ronda 2** (mitigación incorrecta, ya revertida): excluir el path `SDD/contracts/` del scan completo. Funcionaba para este caso puntual, pero el reviewer midió que dejaba el gate ciego a **cualquier** secreto real en ese directorio — el "riesgo residual" que ronda 2 declaró aceptado no era aceptable.
   - **Ronda 3** (causa raíz real, corregida por el planner): los cuatro literales de `AC6bis` en el contract ahora tienen clave y valor en spans separados — el mismo patrón `plant_kv` que este propio `test_secret_scan.sh` usa para poder escanearse a sí mismo. Con la causa raíz resuelta, la exclusión por path deja de hacer falta: se borra por completo. Verificación obligatoria (comando y salida reales, exclusión ya borrada):
     ```
     $ bash SDD/tests/secret-scan.sh
     secret-scan: sin hallazgos sobre 77 archivos versionados (1 excluido: self)
     ```
     Exit `0` — el contract real, con los literales ya partidos, no dispara el detector. Ya no hay riesgo residual declarado: `SDD/contracts/` se escanea igual que cualquier otro directorio.

---

## AC3bis — los `SC2329` propios de R0 quedan justificados inline (nuevo en ronda 2)

`# shellcheck disable=SC2329  # invocada por trap EXIT` agregado, en la misma línea que el `cleanup()` que justifica, en los tres archivos de `SDD/tests/` donde `cleanup()` sólo se invoca vía `trap`:

- `SDD/tests/test_harness.sh:20`
- `SDD/tests/test_run_gates.sh:21`
- `SDD/tests/test_secret_scan.sh:29`

Verificación (comando y salida reales, severidad default = `style`, la más estricta):

```
$ git ls-files -z -- '*.sh' | xargs -0 shellcheck 2>&1 | grep -c "SC2329"
0
$ git ls-files -z -- '*.sh' | xargs -0 shellcheck 2>&1 | grep "SC2016\|SC2329"
                                              ^------------------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
                                                             ^-------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
            ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
  https://www.shellcheck.net/wiki/SC2016 -- Expressions don't expand in singl...
```

Cero `SC2329` sobre el total de `.sh` versionados. Los únicos hallazgos de severidad `style`/`info` que quedan son los 3 `SC2016` de `plugins/sdd-flow/scripts/` (debt `D4`, preexistentes, fuera de scope de R0). El piso `--severity=warning` del gate 2 queda justificado **únicamente** por hallazgos que R0 no puede tocar, tal como pide AC3bis — no por hallazgos propios sin resolver.

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
| `SDD/tests/lib.sh` (NEW, único lugar con `assert_*`) | `SDD/tests/test_harness.sh`, `SDD/tests/test_run_gates.sh`, `SDD/tests/test_secret_scan.sh` (los tres `test_*.sh` a la fecha — corregido en ronda 3, decía "los dos únicos") | ejercitado indirectamente por los tres — ver binding AC1/AC2/AC6/AC6bis |
| `SDD/tests/run.sh` (NEW) | Gate 4 y "suite completa" de `doc_quality_gates.md` | AC1, AC2 (`test_harness.sh`) |
| `plugins/sdd-flow/scripts/sdd-run-gates.sh` (existente, NO modificado) | Invocado por `SDD/tests/test_run_gates.sh` y por la escalera de arriba | AC6 lo ejercita end-to-end contra un repo temporal, sin tocar su código |
| `.gitignore` (MOD — se agregó `SDD/tests/.tmp/`) | `git status`/`git add`/`git ls-files` de todo el repo | Verificado con comando real, no de memoria (ver medición abajo): `SDD/tests/.tmp/` nunca aparece en `git ls-files` |
| `SDD/tests/secret-scan.sh` (MOD ronda 3 — exclusión por path borrada, D6 documentado) | Gate 9 de `doc_quality_gates.md`, `SDD/tests/test_secret_scan.sh` | AC6bis — 26 asserts, triple por forma (6 formas) |
| `SDD/tests/test_secret_scan.sh` (MOD ronda 3 — forma 6) | Gate 4 y "suite completa" de `doc_quality_gates.md` | AC6bis forma 6, probada por mutación (sección AC6bis arriba) |

**Medición fresca de conteos de `git ls-files`** (ronda 3; reemplaza los conteos de ronda 2, que incluían la exclusión ya borrada):

```
$ git ls-files | wc -l
78
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 77 archivos versionados (1 excluido: self)
$ git ls-files | grep -c "SDD/tests/.tmp" || echo "0 (ninguno, correcto)"
0
0 (ninguno, correcto)
```

78 archivos versionados en total (77 de ronda 2 + `SDD/briefs/R1-runner-tree-seal.md`, commiteado por el planner junto con el contract v3); `secret-scan.sh` escanea 77 (excluye 1: a sí mismo — ninguna otra exclusión existe desde ronda 3); cero coincidencias de `SDD/tests/.tmp/` en `git ls-files`, confirmando que `.gitignore` cumple su función.

Ningún caller de `plugins/` quedó sin cubrir porque R0 no modifica ningún archivo de `plugins/` (`git diff origin/prod -- plugins/` da vacío, verificado de nuevo en esta ronda).

---

## Rojos preexistentes

- No hay corridas previas de esta escalera contra `prod`: `SDD/docs/doc_quality_gates.md` y `SDD/tests/` no existían antes de R0 (los crea esta misma tarea), así que no hay un baseline de gates previo con el cual comparar.
- **Hallazgo preexistente que motiva el piso del gate de lint — ya registrado en `SDD/debt.md` como `D4`** (el planner lo agregó al ratificar el contract v2; no lo edito, sólo referencio): `shellcheck` (severidad default, `style`) sobre los 5 scripts que YA existían en `plugins/sdd-flow/` antes de este branch reporta 3 hallazgos `SC2016` (info) — backticks literales dentro de strings de una comilla en plantillas markdown, uso correcto y preexistente en `prod`, no introducido por R0 (`git diff origin/prod -- plugins/` confirma cero cambios, medido arriba). Comando y salida, re-verificados en esta ronda:

  ```
  $ git ls-files -z -- '*.sh' | xargs -0 shellcheck 2>&1 | grep "SC2016"
                                                ^------------------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
                                                               ^-------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
              ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
    https://www.shellcheck.net/wiki/SC2016 -- Expressions don't expand in singl...
  ```
  Exactamente 3 hallazgos reales (la 4ta línea es el link de ayuda, no un hallazgo nuevo). Es la razón medida de declarar el gate 2 con `--severity=warning` — a esa severidad, `shellcheck --severity=warning $(git ls-files -- '*.sh')` sale `0` (ver sección "Gates"). No es un ablandamiento de un threshold ya configurado — este repo no tenía shellcheck antes de R0.
- **`SC2329` de `SDD/tests/` — ya NO es un rojo tolerado, se resolvió en la ronda 2 (AC3bis)**: en la ronda 1 estos hallazgos se toleraban vía el piso `--severity=warning`, igual que los `SC2016` de `plugins/`. Desde AC3bis cada uno lleva su `# shellcheck disable=SC2329` inline justificado — ver sección "AC3bis" arriba, con el comando que confirma cero `SC2329` restantes. El piso `--severity=warning` ya no necesita tolerar nada propio de R0, sólo lo preexistente de `plugins/` (`D4`).
- **Punto ciego del charset de `secret-scan.sh` — ya registrado en `SDD/debt.md` como `D6`** (el planner lo agregó al revisar la ronda 2; no lo edito, sólo referencio, y no cambio el charset — el trade-off contra el falso positivo de `sdd-agents.md:12` está aceptado): el valor exige 4 caracteres del charset `[A-Za-z0-9_./+=-]` **arrancando justo después del separador**, así que un valor cuyo primer carácter cae fuera del charset no se detecta aunque el resto sí sea un secreto real — `password = "p@ssw0rd!"` (el `@` corta el charset antes de los 4 caracteres) y `SMTP_PASSWORD=$ecret123` (arranca con `$`) pasan sin detectarse. Ronda 3 sólo documenta esto en `secret-scan.sh:59-75` (ver comentario del script); no corrige el charset, según lo instruido.

---

## Prerequisitos verificados en esta máquina

- `shellcheck --version` → `0.11.0` (`/opt/homebrew/bin/shellcheck`).
- `bash --version` → `GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)` — piso 3.2 confirmado, ningún script de R0 usa `declare -A`, `mapfile`, `readarray`, `${var^^}` ni `&>>` (verificado a ojo y por el hecho de que todo corrió sin error de sintaxis en esta misma bash).
- `git --version` → `2.50.1`.
- `shfmt`, `timeout`, `gtimeout`: no instalados — de ahí el `N/A` del gate 1 (format) en `doc_quality_gates.md`, y la nota de que `sdd-run-gates.sh` corre sin límite de tiempo por gate en esta máquina.
