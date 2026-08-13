# Verification Report — AGENT_r5 · R5-doc-content-hash

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R5 del contract `SDD/contracts/2026-08-13-sicop-hardening.md`, sección R5 (AC29-AC35). Ronda 1.

- **Branch**: `feat-GEN-94-sicop-hardening` (heredada, ya creada; no creé otra)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v5, sección R5
- **Commit evaluado (código + tests + docs + este reporte, sin la evidencia de gates)**: `cd22425` — `[ADD] [GEN-94] [sdd-flow] R5 — hash de contenido de los docs que gobiernan`.
- **Commit evaluado (evidencia de gates regenerada)**: un segundo commit posterior que agrega `feat-GEN-94-sicop-hardening-R5-gates.md` — exigido por el exit 4 de R1 (`-o` fuera de `.sdd/` exige árbol limpio; se generó DESPUÉS de commitear `cd22425`, con el árbol ya limpio).
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (sin cambios de contenido — R5 no toca comandos de la escalera, sólo el runner que la corre y la reporta). Hash real en esta corrida: `sha256:e96c7d0f61963400` — verificado independiente con `shasum -a 256 SDD/docs/doc_quality_gates.md | awk '{print $1}' | cut -c1-16` → coincide byte a byte con el que estampó el runner (AC29 en producción, no sólo en el test).

---

## T1.1 — corrida ANTES del fix (rojo exigido por el brief)

El brief pide explícitamente correr `test_doc_hash.sh` antes de tocar `sdd-run-gates.sh` y registrar el rojo. Como ya había implementado el helper de hash al momento de escribir el archivo de test, reproduje el estado "antes del fix" de la forma honesta disponible: `git stash push -- plugins/sdd-flow/scripts/sdd-run-gates.sh` (revierte SOLO ese archivo a su estado pre-R5, `VERSION="0.11.0"`, sin `doc_hash()`), corrí el test real contra ese binario real, y recién después hice `git stash pop` para restaurar el fix.

```
$ git stash push -- plugins/sdd-flow/scripts/sdd-run-gates.sh
Saved working directory and index state WIP on feat-GEN-94-sicop-hardening: 70bd052 ...

$ bash SDD/tests/test_doc_hash.sh
  ok    AC29 arbol limpio - el runner sale 0 (exit 0)
  ok    AC29 el encabezado estampa la ruta del doc
  FAIL  AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo — no encontré [sha256:c0e94bdfa0e0f249] en la salida
  ok    AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash
  FAIL  AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas — esperado [si], obtenido [no]
  ok    AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta (exit 1)
  FAIL  AC31 sin shasum ni sha256sum en el PATH - estampa sha256:- — no encontré [sha256:-] en la salida
  FAIL  AC32 verification-report.md - registra el doc de gates con hash, no solo con ruta — no encontré [con hash, no sólo con ruta] en la salida
  FAIL  AC32 verification-report.md - menciona el formato sha256: del hash estampado — no encontré [sha256:] en la salida
  FAIL  AC33 sdd-init/SKILL.md - menciona SDD/docs/doc-manifest.md — no encontré [doc-manifest.md] en la salida
  FAIL  AC33 sdd-init/SKILL.md - exige no sobreescribir en silencio cuando el hash difiere — no encontré [No lo sobreescribas en silencio] en la salida
  FAIL  AC33 sdd-init/SKILL.md - exige mostrar el diff antes de sobreescribir — no encontré [mostrale el diff] en la salida
  FAIL  AC34 reviewer-agent.md - hashes iguales con evidencia que no reproduce es evidencia podrida — no encontré [evidencia podrida] en la salida
  FAIL  AC34 reviewer-agent.md - hashes distintos es un hallazgo propio, no evidencia podrida — no encontré [hallazgo propio] en la salida
  FAIL  AC34 reviewer-agent.md - el hallazgo de hashes distintos dice que los gates cambiaron durante el ciclo — no encontré [cambiaron durante el ciclo] en la salida
  FAIL  AC35 templates/doc-manifest.md existe — esperado [si], obtenido [no]
  FAIL  AC35 doc-manifest.md - tiene fila para doc_architecture.md — no encontré [doc_architecture.md] en la salida
  FAIL  AC35 doc-manifest.md - tiene fila para doc_verification_guide.md — no encontré [doc_verification_guide.md] en la salida
  FAIL  AC35 doc-manifest.md - tiene fila para doc_quality_gates.md — no encontré [doc_quality_gates.md] en la salida
FAIL — 15 assert(s) fallaron
$ echo "EXIT_CODE=$?"
EXIT_CODE=1

$ git stash pop
Dropped refs/stash@{0} ...
```

**Comando**: `bash SDD/tests/test_doc_hash.sh` · **Exit code**: `1` · **15 de 19 asserts fallaron** (AC29/AC30/AC31 fallan por falta del fix en `sdd-run-gates.sh`; AC32-AC35 fallan porque los cuatro artefactos normativos todavía no existían — coherente, ya que ninguna pieza de R5 estaba implementada en ese punto).

### Corrida DESPUÉS del fix de `sdd-run-gates.sh` (T2.1/T2.2), antes de T3.1-T4.1

```
$ bash SDD/tests/test_doc_hash.sh
  ok    AC29 arbol limpio - el runner sale 0 (exit 0)
  ok    AC29 el encabezado estampa la ruta del doc
  ok    AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo
  ok    AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash
  ok    AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas
  ok    AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta (exit 1)
  ok    AC31 sin shasum ni sha256sum en el PATH - estampa sha256:-
  FAIL  AC32 ... (x2)
  FAIL  AC33 ... (x3)
  FAIL  AC34 ... (x3)
  FAIL  AC35 ... (x4)
FAIL — 12 assert(s) fallaron
```
**Exit code**: `1`. Confirma que el fix del runner (AC29-AC31) es correcto de forma aislada, independiente de T3.1-T4.1.

### Corrida final, con T3.1-T4.1 aplicados

```
$ bash SDD/tests/test_doc_hash.sh
  ok    AC29 arbol limpio - el runner sale 0 (exit 0)
  ok    AC29 el encabezado estampa la ruta del doc
  ok    AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo
  ok    AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash
  ok    AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas
  ok    AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta (exit 1)
  ok    AC31 sin shasum ni sha256sum en el PATH - estampa sha256:-
  ok    AC32 verification-report.md - registra el doc de gates con hash, no solo con ruta
  ok    AC32 verification-report.md - menciona el formato sha256: del hash estampado
  ok    AC33 sdd-init/SKILL.md - menciona SDD/docs/doc-manifest.md
  ok    AC33 sdd-init/SKILL.md - exige no sobreescribir en silencio cuando el hash difiere
  ok    AC33 sdd-init/SKILL.md - exige mostrar el diff antes de sobreescribir
  ok    AC34 reviewer-agent.md - hashes iguales con evidencia que no reproduce es evidencia podrida
  ok    AC34 reviewer-agent.md - hashes distintos es un hallazgo propio, no evidencia podrida
  ok    AC34 reviewer-agent.md - el hallazgo de hashes distintos dice que los gates cambiaron durante el ciclo
  ok    AC35 templates/doc-manifest.md existe
  ok    AC35 doc-manifest.md - tiene fila para doc_architecture.md
  ok    AC35 doc-manifest.md - tiene fila para doc_verification_guide.md
  ok    AC35 doc-manifest.md - tiene fila para doc_quality_gates.md
PASS
```
**Comando**: `bash SDD/tests/test_doc_hash.sh` · **Exit code**: `0` · **19/19 `ok`**.

**Cómo se armó el test** (por qué AC29/AC31 no son triviales): AC31 exige un `PATH` donde NI `shasum` NI `sha256sum` existan — en esta máquina (macOS) los dos están presentes (`/usr/bin/shasum` y, sorprendentemente, `/sbin/sha256sum`, verificado con `command -v` antes de escribir el test), así que un `PATH` vacío no alcanza: rompería `sdd-run-gates.sh` entero (necesita `git`, `awk`, `grep`, `mkdir`, `dirname`, `date`, `mktemp`, `tail`, `rm`, `cat`, `bash`) y el test probaría un crash, no AC31. `minbin_without_hash_tools()` resuelve cada binario necesario con `command -v` **contra el `PATH` real, antes de overridear nada**, y symlinkea todo salvo esos dos — medido y confirmado a mano antes de escribirlo en el test (ver sección "Verificación cómo se mide" abajo).

---

## AC30 — prueba por mutación (AC de detección, triple verde→rojo→verde ×2)

AC30 es el AC de detección de R5. El contract nombra DOS modos de falla indistinguibles en una sola corrida: "un hash constante" y "uno que se recalcula mal y siempre difiere". El test tiene dos sub-checks (estabilidad + sensibilidad) diseñados para que cada modo de falla rompa exactamente uno y no el otro — probado con dos mutaciones aisladas contra la implementación real de `doc_hash()` en `plugins/sdd-flow/scripts/sdd-run-gates.sh`.

### Mutación 1 — hash constante

```diff
 doc_hash() { # $1=path del doc de gates
+  # MUTACION-AC30-TEMPORAL-R2-CONSTANTE: hash siempre igual sin mirar el
+  # contenido, para la corrida roja exigida por quality-gates.md (AC de
+  # deteccion). Se revierte enseguida.
+  printf 'sha256:0000000000000000'; return 0
   local f="$1" raw
```

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar) | `bash SDD/tests/test_doc_hash.sh` | `0` | `PASS` — 19/19 `ok` |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_doc_hash.sh` | `1` | `FAIL — 3 assert(s) fallaron`: **AC30 sensibilidad** (la que corresponde: un hash constante no cambia con el contenido), más AC29 y AC31 (que comparan contra el `shasum` real) — `AC30 estabilidad` sigue `ok` correctamente (un valor constante ES estable, por definición) |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_doc_hash.sh` | `0` | `PASS` — 19/19 `ok` de nuevo |

Salida real de la corrida 2 (rojo), completa:
```
  ok    AC29 arbol limpio - el runner sale 0 (exit 0)
  ok    AC29 el encabezado estampa la ruta del doc
  FAIL  AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo — no encontré [sha256:c0e94bdfa0e0f249] en la salida
  ok    AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash
  FAIL  AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas — esperado [si], obtenido [no]
  ok    AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta (exit 1)
  FAIL  AC31 sin shasum ni sha256sum en el PATH - estampa sha256:- — no encontré [sha256:-] en la salida
  ok    AC32 ... (x2)
  ok    AC33 ... (x3)
  ok    AC34 ... (x3)
  ok    AC35 ... (x4)
FAIL — 3 assert(s) fallaron
```
Revertido y confirmado sin rastro: `grep -n "MUTACION" plugins/sdd-flow/scripts/sdd-run-gates.sh` → sin salida, exit `1`.

### Mutación 2 — hash que siempre difiere (mezcla el PID)

```diff
   if [ -n "$raw" ]; then
-    printf 'sha256:%s' "${raw:0:16}"
+    # MUTACION-AC30-TEMPORAL-R2-SIEMPRE-DIFIERE: se recalcula mal, mezclando
+    # el PID en el hash -- dos corridas del MISMO contenido dan resultados
+    # distintos. Para la corrida roja exigida por quality-gates.md (AC de
+    # deteccion). Se revierte enseguida.
+    printf 'sha256:%s' "${raw:0:12}$$"
   else
```

Cada invocación de `sdd-run-gates.sh` es un proceso `bash` nuevo con su propio PID, así que dos corridas del MISMO doc producen hashes distintos bajo esta mutación — el modo de falla exacto que "estabilidad" existe para atrapar.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar) | `bash SDD/tests/test_doc_hash.sh` | `0` | `PASS` — 19/19 `ok` |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_doc_hash.sh` | `1` | `FAIL — 2 assert(s) fallaron`: **AC30 estabilidad** (la que corresponde) + AC29 (compara contra `shasum` real) — `AC30 sensibilidad` sigue `ok`, **trivialmente y por la razón equivocada** (dos hashes cualquiera con PID distinto también "difieren", aunque no sea por el byte cambiado): esto confirma que "sensibilidad" sola NO alcanza para probar AC30, y es la razón de tener las dos sub-condiciones |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_doc_hash.sh` | `0` | `PASS` — 19/19 `ok` de nuevo |

Salida real de la corrida 2 (rojo), líneas relevantes:
```
  FAIL  AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo — no encontré [sha256:c0e94bdfa0e0f249] en la salida
  FAIL  AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash — esperado [sha256:c0e94bdfa0e015083], obtenido [sha256:c0e94bdfa0e015128]
  ok    AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas
FAIL — 2 assert(s) fallaron
```
Revertido y confirmado: `diff <(git show :plugins/sdd-flow/scripts/sdd-run-gates.sh) plugins/sdd-flow/scripts/sdd-run-gates.sh` → sin diferencias, exit `0` (el archivo vuelve a ser byte-idéntico al que ya estaba en el índice antes de mutar).

---

## Impacto de sibling: AC11 de R1 (`test_run_gates_tree.sh`)

`T2.2` bumpea `VERSION` de `sdd-run-gates.sh` de `0.11.0` a `0.12.0`, decisión explícita del brief (no del contract R5, que no menciona números de versión — pero sí es la misma práctica que el propio R1 estableció: bumpear `VERSION` cuando el script cambia). Esto impacta AC11 de R1, ya `APPROVED`, que assertea el literal `0.11.0` en `test_run_gates_tree.sh`.

**Búsqueda de hermanos** (mismo patrón que AC13 de R1): `grep -rn "0.11.0" plugins/ SDD/docs/ SDD/briefs/` — únicos hits vivos: la propia línea `VERSION=` (que yo cambio) y las dos líneas de `test_run_gates_tree.sh` (comentario de sección + assert). El resto de apariciones de `0.11.0` en el repo son texto histórico de otros agentes (briefs de R0/R1/R2, ya cerrados) o coinciden por casualidad con la versión de `shellcheck` en `doc_quality_gates.md` — ninguno de esos se toca.

Confirmé el rojo real ANTES de tocar el test (no lo asumí):
```
$ bash SDD/tests/test_run_gates_tree.sh
  ...
  ok    AC11 --version sale 0 (exit 0)
  FAIL  AC11 --version imprime 0.11.0 — no encontré [0.11.0] en la salida
  ok    AC12 ... (x3)
FAIL — 1 assert(s) fallaron
$ echo "EXIT_CODE=$?"
EXIT_CODE=1
```
Actualicé únicamente el literal esperado (mismo `assert_contains`, mismo poder de detección — sigue siendo un exact-match contra el `VERSION` real del script) a `0.12.0`, y el comentario de sección. **No es un ablandamiento** (quality-gates.md §6.1-.2): ningún caso se borró, ninguna aserción se debilitó, sólo el valor esperado pasó a ser el valor correcto tras un cambio de versión legítimo y explícito.
```
$ bash SDD/tests/test_run_gates_tree.sh
  ok    AC7 ... (x4)
  ok    AC8 ... (x5)
  ok    AC9 ... (x2)
  ok    AC10 ... (x3)
  ok    AC11 --version sale 0 (exit 0)
  ok    AC11 --version imprime 0.12.0
  ok    AC12 ... (x3)
PASS
$ echo "EXIT_CODE=$?"
EXIT_CODE=0
```
19/19 `ok`, exit `0`.

---

## Verificación de cómo se mide (antes de creerle a la medición)

Dos veces en este ciclo un chequeo dio "todo igual" porque medía la señal equivocada (`D8`, `RT8`). Verifiqué explícitamente antes de confiar:

1. **`secret-scan.sh` usa `git ls-files` internamente** (`D8`, conocido y aceptado — no lo arreglo, está fuera de scope de R5): corrí `bash SDD/tests/secret-scan.sh` ANTES de `git add` y reportó `86 archivos` (sin mis 2 archivos nuevos todavía trackeados — un verde que no había escaneado nada nuevo). Después de `git add` de todo el diff, reportó `88 archivos` (85 + brief de R5 ya commiteado + mis 2 archivos nuevos = el conteo correcto). El resultado final (`sin hallazgos`) es sobre el conjunto real, no sobre uno parcial.
2. **`shellcheck` a `--severity=warning` (comando real del gate 2) da exit `0`** — pero medí también a severidad default (`style`) para no asumir que mi cambio no agregó un `SC2016` nuevo (la deuda `D4` documenta 3 preexistentes en `plugins/`, y quería confirmar que seguían siendo 3, no 4). `shellcheck` sin `--severity` sobre el glob del gate: 3 hallazgos `SC2016` (info) — `sdd-lint-contract.sh:54` (ajeno), y DOS en `sdd-run-gates.sh` (la línea de `FULL_CMD`, ajena, y la línea del encabezado que yo modifiqué). Confirmé contra el estado PRE-R5 (`git stash` sólo de ese archivo + `shellcheck` sin `--severity`) que esa MISMA línea de encabezado YA producía ese hallazgo antes de mi cambio (backticks literales para markdown, ya presentes en `**Branch**`/`**Commit**`/`**Doc**` antes de que yo agregara el cuarto par de backticks para el hash) — mi diff extiende una línea ya contada en `D4`, no agrega una nueva. Total: 3 antes, 3 después.
3. **`minbin_without_hash_tools()` de AC31 depende de `command -v`**: medí explícitamente que la sesión interactiva de esta máquina tiene `grep`/`true`/`false` redefinidos como funciones de shell (snapshot de zsh de esta herramienta), lo que hacía que `command -v grep` devolviera el string `"grep"` en vez de una ruta real — un `ln -sf` con eso produce un symlink roto y el runner falla con `command not found`, ajeno al hash. Confirmé que un `bash -c 'command -v grep'` GENUINO (como el que ejecuta `test_doc_hash.sh` al correr vía `bash archivo.sh`) resuelve la ruta real (`/usr/bin/grep`), y descarté `true`/`false` de la lista curada (son builtins de bash, `bash -c "true"` nunca los busca en `PATH`).

---

## Gates — evidencia GENERADA por `sdd-run-gates.sh`

Por la decisión de R1, `-o` fuera de `.sdd/` exige árbol limpio — así que esta sección se completa DESPUÉS de commitear el código (T5.2 lo exige explícito: "commiteá primero, regenerá después").

```bash
git -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com commit -m "..."
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-94-sicop-hardening-R5-gates.md
```

- **Reporte generado**: `SDD/verification/feat-GEN-94-sicop-hardening-R5-gates.md` (mismo directorio que este archivo, path commiteado).
- **Resumen** (línea `sdd.gates` del runner, real): `{"green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R5-gates.md"}` — exit `0`. Los 7 `[SKIPPED]` son todos `N/A` con razón declarada en `doc_quality_gates.md` (gates 1, 3, 5, 6, 7, 8, 10 — ninguno aplica a este repo, ver ese doc), no gates omitidos sin explicación.
- El encabezado del reporte generado estampa `**Doc**: \`SDD/docs/doc_quality_gates.md\` (\`sha256:e96c7d0f61963400\`)` — la ruta y el hash juntos, exactamente lo que exige AC29, ahora en una corrida de producción real (no sólo en el harness de test).

---

## Impact set

| Símbolo/archivo cambiado | Caller / referencia | Cobertura |
|---|---|---|
| `doc_hash()` (nueva función, `sdd-run-gates.sh`) | única invocación: `DOC_HASH="$(doc_hash "$DOC")"`, misma línea de abajo | AC29, AC30, AC31 (`test_doc_hash.sh`) |
| Línea del encabezado (`printf` con `Doc:`) | ningún otro caller — es la escritura del reporte | AC29 (ruta+hash), AC30 (estabilidad/sensibilidad) |
| `VERSION` (`0.11.0` → `0.12.0`) | `--version`, y `test_run_gates_tree.sh::"AC11 --version imprime 0.11.0"` | actualizado y verde (`"AC11 --version imprime 0.12.0"`), ver sección de sibling arriba |
| `plugins/sdd-flow/templates/verification-report.md` | ningún script lo parsea (es prosa para el implementing-agent); sin caller de código | AC32 (`test_doc_hash.sh`, grep de contenido) |
| `plugins/sdd-flow/skills/sdd-init/SKILL.md` | invocado por el skill `sdd-init` (Claude lo lee como prompt, no hay caller de código) | AC33 (`test_doc_hash.sh`, grep de contenido) |
| `plugins/sdd-flow/agents/reviewer-agent.md` | invocado por el subagente `reviewer-agent` (prompt, no hay caller de código) | AC34 (`test_doc_hash.sh`, grep de contenido) |
| `plugins/sdd-flow/templates/doc-manifest.md` (NEW) | lo consumirá `/sdd-init` en un repo que instale el plugin; sin caller en ESTE repo (R5 no corre `sdd-init` sobre AI-Forge) | AC35 (`test_doc_hash.sh`, existencia + contenido) |
| `plugins/sdd-flow/hooks/guard-git.sh` (sólo header) | ningún cambio de comportamiento — comentario puro; `test_guard_identity.sh` (AC14-AC18, AC36-AC38) sigue verde sin modificarlo | smoke: `bash SDD/tests/test_guard_identity.sh` → `PASS`, 15/15 `ok`, sin tocar ese archivo |
| `SDD/docs/doc_architecture.md` | listado de `templates/` en Project Layout — actualizado para incluir `doc-manifest.md` | `test_guard_identity.sh::AC38` sigue verde (no toqué las líneas que esos asserts leen) |

Ningún caller de código real quedó sin cubrir: los cinco archivos markdown normativos no tienen "caller" en sentido de programa — su cobertura es el grep de contenido (AC32-AC35), que es la forma de regresión que les corresponde.

---

## Rojos preexistentes

Verificado corriendo la suite en la base, ANTES de mis cambios (`git stash` completo, sin `--include-untracked`, dejando el árbol en el commit `70bd052`):

```
$ bash SDD/tests/run.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
5 passed, 0 failed (5 total)
$ echo "EXIT_CODE=$?"
EXIT_CODE=0
```

Ninguno. La base estaba 5/5 verde antes de este trabajo (R0, R1 y R2 `APPROVED`).

---

## Smoke manual

No hay ACs `manual-only` declarados en R5 — N/A.
