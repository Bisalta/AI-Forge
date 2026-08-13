# Verification Report — AGENT_r1 · R1-runner-tree-seal

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R1 del contract `SDD/contracts/2026-08-13-sicop-hardening.md` **v3**, sección R1 (AC7-AC13; los ACs de R1 no cambiaron entre v1 y v3 — las ratificaciones de v2/v3 fueron todas de R0).

- **Branch**: `feat-GEN-94-sicop-hardening` (creada desde `prod`, heredada de R0)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v3, sección R1
- **Commit evaluado (ronda 1)**: `44a0f0c` (fix) + `aa36684` (evidencia de gates regenerada)
- **Commit evaluado (ronda 2)**: el commit `[FIX] [GEN-94] [sdd-flow] ...` que se crea después de este reporte con los 3 MINOR corregidos (mismo razonamiento que ronda 1: el hash no puede conocerse antes de crearlo; queda en el `sdd.result` con su valor real)
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (sin cambios de contenido — R1 no toca comandos de la escalera)

---

## Ronda 2 — 3 MINOR de la ronda 1 (`APPROVED`, cero BLOCKER/MAJOR)

R1 quedó `APPROVED` en ronda 1. Lo que sigue son los 3 `MINOR` (≤3 líneas cada uno) que el reviewer pidió corregir antes del PR, más la tarea adicional de regenerar la evidencia de gates de R0 (arrastrada como `ADVISORY` desde su ronda 1, ahora cerrable de verdad porque el sellado ya funciona).

1. **`sdd-run-gates.sh` — el hash no dice qué excluye.** Con `--allow-dirty`, el encabezado listaba los archivos `??` (sin trackear) pero nunca decía que el hash de `Tree:` no los incluye — esa semántica vivía sólo en el comentario del script, invisible en el artefacto que alguien lee en el PR. Fix: cuando `DIRTY_FILES` tiene al menos una entrada `??`, `TREE_STATE` suma el sufijo `(el hash no incluye N archivo(s) sin trackear)`, así que aparece en el encabezado sin tocar el resto del bloque de sellado. Verificado a mano contra un repo con 1 archivo trackeado modificado + 2 sin trackear: `ARBOL SUCIO (el hash no incluye 2 archivo(s) sin trackear)` — ver sección "MINOR 1" abajo.
2. **`test_run_gates_tree.sh` — 6 `assert_eq` con los argumentos invertidos.** `SDD/tests/lib.sh:25` declara `assert_eq <actual> <esperado>`, pero mis 6 llamadas directas pasaban `<esperado>` primero (el mismo orden que `assert_exit`, que SÍ es `esperado, actual` — mezclé las dos convenciones). El veredicto no cambiaba (comparación simétrica), pero el mensaje de `FAIL` mentía sobre cuál valor era cuál. Las 6 líneas (103, 122, 126, 142, 156, 185) quedaron con el orden correcto.
3. **Números de línea stale en este mismo reporte.** La causa: pegué salidas de `grep`/`shellcheck` durante el trabajo, y el archivo siguió creciendo después de cada captura — retro `RT7` del coordinador, tercera vez que pasa en este contract. Recapturé AC13 y la nota de `SC2016` contra el árbol ya con los 3 fixes aplicados (ver esas secciones abajo, marcadas "Ronda 2"). Al recapturar encontré además una **cuarta** aparición de `SC2016` que mi propia verificación de ronda 1 nunca vio (`SDD/tests/test_run_gates_tree.sh:183`) — el detalle está en la nota de `SC2016` más abajo, no lo escondo acá.

---

## Causa raíz — verificada antes de arrancar

`plugins/sdd-flow/scripts/sdd-run-gates.sh:120` (versión pre-fix, v0.10.0) calculaba `COMMIT="$(git rev-parse --short HEAD)"` y lo estampaba como único identificador del código verificado. Verificación pedida por el brief, corrida real:

```
$ git ls-tree -r e5ef90c -- SDD/
```
Salida: **vacía**, exit `0`. `e5ef90c` (el merge de `prod` que esta branch usa como base) no contiene ni un archivo bajo `SDD/`, y sin embargo `SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md:3` sella `Commit: e5ef90c` como si fuera evidencia del trabajo de R0. Causa raíz confirmada tal como la diagnosticó el brief, no reinvestigada.

---

## Test de reproducción (bugfix — DoD §1.5) — las dos corridas

`SDD/tests/test_run_gates_tree.sh` (NEW) cubre AC7-AC12, usando únicamente los helpers de `SDD/tests/lib.sh` (`assert_eq`, `assert_contains`, `assert_exit`, `test_summary` — ningún assert propio).

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — **roja**, antes del fix (T1.2) | `bash SDD/tests/test_run_gates_tree.sh` | `1` | `FAIL — 11 assert(s) fallaron` |
| 2 — **verde**, después del fix (T3.1) | `bash SDD/tests/test_run_gates_tree.sh` | `0` | `PASS` — 19/19 `ok` |

**Corrida 1 completa (roja), contra el `sdd-run-gates.sh` v0.10.0 sin modificar**, pegada tal cual:

```
  ok    AC7 arbol limpio - sale 0 (exit 0)
  FAIL  AC7 arbol limpio - encabezado tiene Tree: — no encontré [Tree:] en la salida
  FAIL  AC7 arbol limpio - Tree coincide con el hash de HEAD^{tree} — no encontré [871e9349f0bc9306fab17389c84f9f535d5eabba] en la salida
  ok    AC7 arbol limpio - el reporte se escribe
  ok    AC8 arbol sucio con -o dentro de .sdd - sale 0 (exit 0)
  ok    AC8 arbol sucio con -o dentro de .sdd - el reporte se escribe
  FAIL  AC8 arbol sucio con -o dentro de .sdd - encabezado marca el arbol sucio — no encontré [ARBOL SUCIO] en la salida
  FAIL  AC8 arbol sucio - Tree usa el hash de git stash create — no encontré [60c52e7f681a4c780a039e9b6ced42285d9c9675] en la salida
  ok    AC8 arbol sucio - Tree difiere del hash de HEAD^{tree} limpio
  FAIL  AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - sale 4 (exit 4) — esperado [4], obtenido [0]
  FAIL  AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - no crea el archivo — esperado [si], obtenido [no]
  FAIL  AC10 arbol sucio con --allow-dirty - sale 0 (exit 0) — esperado [0], obtenido [3]
  FAIL  AC10 arbol sucio con --allow-dirty - crea el archivo — esperado [no], obtenido [si]
  FAIL  AC10 arbol sucio con --allow-dirty - encabezado marca ARBOL SUCIO — no encontré [ARBOL SUCIO] en la salida
  ok    AC11 --version sale 0 (exit 0)
  FAIL  AC11 --version imprime 0.11.0 — no encontré [0.11.0] en la salida
  ok    AC12 sin repo git - sale con el exit code de los gates (hay un rojo) (exit 1)
  FAIL  AC12 sin repo git - Tree en guion — no encontré [Tree: `-`] en la salida
  ok    AC12 sin repo git - el reporte se escribe igual, sin abortar por el sellado
FAIL — 11 assert(s) fallaron
```

Nota sobre AC10 en la corrida roja: salió `obtenido [3]` en vez de `[0]` porque `--allow-dirty` todavía no existía en el parseo de argumentos — caía en la rama `*) echo "arg desconocido: $1" >&2; exit 3`. Confirma que el test detecta también la ausencia del flag, no sólo la ausencia de `Tree:`.

**Nota (ronda 2, MINOR 2)**: las líneas 56 y 58 de arriba (`AC9 ... no crea el archivo` y `AC10 ... crea el archivo`) vienen de `assert_eq`, y en el momento de esta corrida esa llamada todavía tenía los argumentos invertidos (ver "Ronda 2" al inicio de este archivo). El veredicto `FAIL` es correcto — la comparación es simétrica, así que el test detectó el fallo igual — pero el texto `esperado [X], obtenido [Y]` de esas dos líneas puntuales está al revés de la semántica real (línea 56: la verdad era "esperado [no], obtenido [si]"; línea 58: "esperado [si], obtenido [no]"). No reescribo la transcripción pegada — es el registro fiel de lo que esa corrida imprimió — sólo dejo esta nota para que no se lea con el rótulo viejo. El fix de `assert_eq` ya está aplicado en el archivo actual (ver binding y "Ronda 2 — validación final").

**Corrida 2 completa (verde), después del fix**, pegada tal cual:

```
  ok    AC7 arbol limpio - sale 0 (exit 0)
  ok    AC7 arbol limpio - encabezado tiene Tree:
  ok    AC7 arbol limpio - Tree coincide con el hash de HEAD^{tree}
  ok    AC7 arbol limpio - el reporte se escribe
  ok    AC8 arbol sucio con -o dentro de .sdd - sale 0 (exit 0)
  ok    AC8 arbol sucio con -o dentro de .sdd - el reporte se escribe
  ok    AC8 arbol sucio con -o dentro de .sdd - encabezado marca el arbol sucio
  ok    AC8 arbol sucio - Tree usa el hash de git stash create
  ok    AC8 arbol sucio - Tree difiere del hash de HEAD^{tree} limpio
  ok    AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - sale 4 (exit 4)
  ok    AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - no crea el archivo
  ok    AC10 arbol sucio con --allow-dirty - sale 0 (exit 0)
  ok    AC10 arbol sucio con --allow-dirty - crea el archivo
  ok    AC10 arbol sucio con --allow-dirty - encabezado marca ARBOL SUCIO
  ok    AC11 --version sale 0 (exit 0)
  ok    AC11 --version imprime 0.11.0
  ok    AC12 sin repo git - sale con el exit code de los gates (hay un rojo) (exit 1)
  ok    AC12 sin repo git - Tree en guion
  ok    AC12 sin repo git - el reporte se escribe igual, sin abortar por el sellado
PASS
```

---

## AC9 — prueba por mutación (verde → rojo → verde)

AC9 es un AC de detección ("el runner se niega cuando el árbol está sucio y el destino es evidencia que se commitea"). No alcanza con verlo verde: un runner que nunca refusa, o que siempre refusa, puede producir el mismo verde en el caso feliz. Se rompió el chequeo a propósito, se corrió el test, se confirmó rojo, y se revirtió.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar, `sdd-run-gates.sh` real) | `bash SDD/tests/test_run_gates_tree.sh` | `0` | `PASS` — 19/19 `ok`, incluidas las 2 líneas de AC9 |
| 2 — rojo (con el `exit 4` removido) | `bash SDD/tests/test_run_gates_tree.sh` | `1` | `FAIL — 2 assert(s) fallaron` — fallan **exactamente** los 2 asserts de AC9; los otros 17 siguen `ok` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_run_gates_tree.sh` | `0` | `PASS` — 19/19 `ok` de nuevo |

**Mutación aplicada** (`plugins/sdd-flow/scripts/sdd-run-gates.sh`, bloque de estrictez): se comentó el `exit 4` dejando sólo el mensaje de error por `stderr`, de modo que el script cae al `fi` y sigue de largo — el defecto exacto que AC9 existe para prevenir:

```diff
   } >&2
-  exit 4
+  # MUTACION-AC9-TEMPORAL-R1: exit 4 removido a proposito para la corrida
+  # roja fresca exigida por quality-gates.md (AC de deteccion) -- se
+  # revierte enseguida.
 fi
```

Salida completa y real de la corrida 2 (roja, con la mutación), pegada tal cual:

```
  ok    AC7 arbol limpio - sale 0 (exit 0)
  ok    AC7 arbol limpio - encabezado tiene Tree:
  ok    AC7 arbol limpio - Tree coincide con el hash de HEAD^{tree}
  ok    AC7 arbol limpio - el reporte se escribe
  ok    AC8 arbol sucio con -o dentro de .sdd - sale 0 (exit 0)
  ok    AC8 arbol sucio con -o dentro de .sdd - el reporte se escribe
  ok    AC8 arbol sucio con -o dentro de .sdd - encabezado marca el arbol sucio
  ok    AC8 arbol sucio - Tree usa el hash de git stash create
  ok    AC8 arbol sucio - Tree difiere del hash de HEAD^{tree} limpio
  FAIL  AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - sale 4 (exit 4) — esperado [4], obtenido [0]
  FAIL  AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - no crea el archivo — esperado [si], obtenido [no]
  ok    AC10 arbol sucio con --allow-dirty - sale 0 (exit 0)
  ok    AC10 arbol sucio con --allow-dirty - crea el archivo
  ok    AC10 arbol sucio con --allow-dirty - encabezado marca ARBOL SUCIO
  ok    AC11 --version sale 0 (exit 0)
  ok    AC11 --version imprime 0.11.0
  ok    AC12 sin repo git - sale con el exit code de los gates (hay un rojo) (exit 1)
  ok    AC12 sin repo git - Tree en guion
  ok    AC12 sin repo git - el reporte se escribe igual, sin abortar por el sellado
FAIL — 2 assert(s) fallaron
```

Revertido, confirmado sin rastro (`grep -n "MUTACION" plugins/sdd-flow/scripts/sdd-run-gates.sh` → exit `1`, sin resultados) y corrida 3 verde (idéntica a la corrida 1, ver bloque "Test de reproducción" arriba, corrida 2 de esa tabla).

**Nota (ronda 2, MINOR 2)**: igual que en la corrida roja de reproducción, la línea `no crea el archivo — esperado [si], obtenido [no]` de la corrida 2 de arriba viene de `assert_eq` con los argumentos todavía invertidos en el momento de esa corrida — el veredicto (`FAIL`) es correcto, la verdad era "esperado [no], obtenido [si]". Transcripción sin alterar; el fix ya está aplicado en el archivo actual.

Conclusión: el test que respalda AC9 tiene poder de detección real — no es tautológico. `plugins/sdd-flow/scripts/sdd-run-gates.sh` en el repo, al momento de este commit, es la versión sin la mutación (con `exit 4` presente).

---

## AC13 — búsqueda de hermanos (checklist del arquetipo `bugfix`)

Comando exacto del brief, corrida real:

**Ronda 2 — recapturado tras los 3 fixes MINOR** (los números de línea de la ronda 1 quedaron stale apenas el diff creció; ver sección "Ronda 2" al final de este archivo). Comando y salida reales, contra el árbol con los 3 MINOR ya aplicados:

```
$ grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/
plugins/sdd-flow/scripts/sdd-run-gates.sh:36:#   - árbol limpio  → Tree: hash de `git rev-parse HEAD^{tree}`.
plugins/sdd-flow/scripts/sdd-run-gates.sh:86:COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"
```
Exit `0` (grep encontró coincidencias). Dos apariciones, ambas en el archivo que este mismo diff modifica — no aparecieron hermanos en otro script ni en `plugins/sdd-flow/hooks/` (`guard-git.sh` usa `rev-parse --abbrev-ref HEAD` y `rev-parse --git-dir`, ninguno de los dos matchea el patrón literal del brief; confirmado con el mismo comando, cero líneas de `guard-git.sh` en la salida de arriba).

Clasificación de cada aparición:

1. **`sdd-run-gates.sh:36`** — comentario del bloque de documentación del sellado, agregado por este mismo diff (`# árbol limpio → Tree: hash de \`git rev-parse HEAD^{tree}\`.`). No es la evidencia sellada del bug: es prosa que documenta la fórmula correcta (`HEAD^{tree}`, no `HEAD` desnudo) que el propio fix introduce. **Uso legítimo** — es exactamente lo que R1 quiere que se use para el caso limpio.
2. **`sdd-run-gates.sh:86`** — `COMMIT="$(git rev-parse --short HEAD ...)"`. Es la línea original de la causa raíz. **Ya corregida por este mismo diff**, no por reescritura de la línea sino por contexto: el contract (punto 1 de la Decisión de diseño) exige que el reporte muestre el commit **además del** árbol, no en su lugar — `Commit:` sigue siendo información de contexto (qué branch/HEAD había al momento de la corrida), pero ya **no es la única** afirmación sobre qué código corrió: `TREE`/`TREE_STATE` (líneas 85-127, calculadas antes de este `COMMIT`) son las que ahora cargan esa responsabilidad y aparecen siempre junto a `Commit:` en el encabezado (AC7, AC8, AC12). No queda ninguna otra ocurrencia de este patrón en `plugins/sdd-flow/scripts/` ni `plugins/sdd-flow/hooks/` fuera de este archivo — no hay deuda ni scope adicional que registrar.

No se encontraron hermanos que requieran corrección fuera del archivo que R1 ya modifica.

---

## MINOR 1 (ronda 2) — el encabezado ahora dice qué archivos excluye el hash

Antes de este fix, `--allow-dirty` listaba los archivos sin trackear (`??`) en "Archivos sin commitear" pero no decía en ningún lado del artefacto que el hash de `Tree:` no los incluye — esa semántica sólo vivía en el comentario del script (líneas 105-114), invisible para quien lee el reporte en el PR sin abrir el código. Fix: `TREE_STATE` suma el sufijo `(el hash no incluye N archivo(s) sin trackear)` cuando `DIRTY_FILES` tiene al menos una línea `^??` — ninguna otra parte del bloque de sellado cambia.

Verificación manual, repo temporal con 1 archivo trackeado modificado + 2 archivos nuevos sin trackear (fuera de `SDD/tests/.tmp/`, descartado al terminar):

```
$ git status --porcelain
 M tracked.txt
?? sin-trackear-1.txt
?? sin-trackear-2.txt

$ bash sdd-run-gates.sh -d SDD/docs/doc_quality_gates.md -o SDD/verification/x.md --allow-dirty | head -6
# Gates run — generado por sdd-run-gates.sh v0.11.0

- **Branch**: `main` · **Commit**: `ca3e6d8` · **Doc**: `SDD/docs/doc_quality_gates.md` · **Fecha**: 2026-08-13T17:20:36Z
- Tree: `d83dd0c73e61476ea4e2d0143535df8800c677d2` — ARBOL SUCIO (el hash no incluye 2 archivo(s) sin trackear). Archivos sin commitear:
  - ` M tracked.txt`
  - `?? sin-trackear-1.txt`
```

`2 archivo(s) sin trackear` coincide exactamente con los 2 `??` reales del `git status --porcelain` de arriba. No es un caso cubierto por `test_run_gates_tree.sh` (ningún AC del contract lo exige — el brief cierra la lista en AC7-AC12) y no agrego un AC nuevo sin ratificación del planner; queda como verificación manual de este MINOR, no como test automatizado nuevo.

Suite completa y `shellcheck --severity=warning` re-verificados después de este fix — sin regresión (ver "Ronda 2 — validación final" al pie de este archivo).

---

## Gates — evidencia GENERADA (no escrita a mano)

**Con el propio fix ya aplicado, `-o SDD/verification/...` exige árbol limpio (AC9) — exactamente el comportamiento que este mismo R1 fuerza.** Por eso la secuencia real de esta tarea es: (1) terminar el diff completo (código + test + docs + este reporte + binding del brief), (2) commitear, (3) recién ahí correr el runner apuntando a `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md` — con el árbol ya limpio, el propio gate 9 (AC9) que este reporte documenta arriba se lo permite. El resultado de esa corrida queda en un segundo commit sobre esta misma branch (el reporte de gates es, por definición, posterior al commit que certifica), referenciado abajo con su exit code real.

**Vista previa (NO es la evidencia oficial)**, corrida ad-hoc a `.sdd/` (gitignoreado, uso permitido con árbol sucio) sólo para confirmar que la escalera sigue en verde antes de comprometerme al commit:

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o .sdd/gates-run-preview.md
```
- Exit `0` — `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":".sdd/gates-run-preview.md"}`
- Encabezado de esa corrida: `Tree: 5671eded86e15270315001379c9bbd4edf368bb3 — ARBOL SUCIO`, con la lista real de los 4 archivos modificados + 1 sin trackear (ver "Límite conocido" abajo) — es la primera vez que este runner, corriendo sobre este mismo repo, deja de mentir sobre el estado del árbol.

**Evidencia oficial (post-commit, árbol limpio)**: `SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md` — generada y commiteada en un segundo commit sobre `feat-GEN-94-sicop-hardening`, después del commit `[FIX]` de este trabajo. Comando:

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md
```

Su exit code y su línea `{"type":"sdd.gates",...}` quedan en ese archivo (generado por el runner, no transcripto acá) y en el `sdd.result` de este agente.

**Resultado real de esa corrida** (post-commit `44a0f0c`, árbol limpio): exit `0` — `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md"}`. Encabezado: `**Commit**: \`44a0f0c\`` (el commit real que contiene este trabajo, no un commit anterior) y `Tree: \`81f51f839efa0eb89589688efd58180baeaa642f\` — LIMPIO`. Verificado que coincide exactamente con el árbol real de ese commit:
```
$ git rev-parse HEAD^{tree}
81f51f839efa0eb89589688efd58180baeaa642f
```
Es la primera vez en este repo que un reporte de gates sella el commit que efectivamente contiene el trabajo certificado — el bug que motivó R1, cerrado con evidencia real, no sólo con el test.

**Límite conocido, encontrado en la vista previa de arriba (no algo hipotético)**: `git stash create` sólo ve contenido que alguna vez pasó por `git add` — el archivo nuevo `SDD/tests/test_run_gates_tree.sh` (sin trackear en el momento de la vista previa) aparece listado en "Archivos sin commitear" pero **no** queda representado en el hash de `Tree:` de esa corrida (verificado: `git ls-tree -r 5671eded86e15270315001379c9bbd4edf368bb3 -- SDD/tests/ | grep test_run_gates_tree` → sin resultados, exit `1`), aunque el archivo modificado `sdd-run-gates.sh` sí quedó representado (mismo comando contra ese path → el blob correcto, confirmado con `git diff`). Es una limitación heredada de la decisión cerrada del contract (`git stash create`, no `git write-tree`), documentada en el script (comentario del bloque de sellado) y en `quality-gates.md` §5. No aplica a la evidencia oficial de arriba porque ahí el árbol está limpio (todo commiteado, sin archivos sin trackear) — pero es una recomendación para que el planner evalúe si amerita una entrada en `SDD/debt.md` (no lo agrego yo: está fuera de mi scope tocar ese archivo).

---

## Impact set

`sdd-run-gates.sh` es un script existente que R1 modifica (no crea). Callers/consumidores documentados de la ruta `-o <path-commiteado>` (la que ahora exige árbol limpio):

| Símbolo cambiado | Caller / consumidor | Cobertura |
|---|---|---|
| `sdd-run-gates.sh` (bloque de sellado + exit 4 + `--allow-dirty` + `VERSION`) | `SDD/tests/test_run_gates.sh` (R0, sin modificar) — sigue invocando el runner con `-o "$TMP_DIR/.sdd/gates-run.md"` (dentro de `.sdd/`, repo temporal siempre limpio recién creado) | Regresión verificada: `bash SDD/tests/run.sh` → `PASS test_run_gates.sh`, sin cambios en su comportamiento (AC6 de R0 sigue verde) |
| `sdd-run-gates.sh` | `SDD/tests/test_run_gates_tree.sh` (NEW, este mismo diff) | AC7-AC12, ver binding |
| `sdd-run-gates.sh` | `plugins/sdd-flow/agents/implementing-agent.md:26` — instruye `-o tasks/<slug>/verification/AGENT_<vos>-gates.md` (path commiteado) | Sin romper: ese path ya está fuera de `.sdd/` y la instrucción ya dice "commiteá tu trabajo" implícitamente (regla de branching); el único cambio de comportamiento es que ahora el runner **hace cumplir** árbol limpio ahí en vez de sellar en silencio el commit equivocado — es la mejora que R1 existe para forzar, no una regresión. No requiere edición de ese archivo (fuera del Architectural Delta de R1). |
| `sdd-run-gates.sh` | `plugins/sdd-flow/templates/verification-report.md:17`, `plugins/sdd-flow/templates/coordination-README.md:15`, `plugins/sdd-flow/commands/sdd-fixes.md:59` — mencionan/instruyen el mismo patrón de invocación | Mismo razonamiento que la fila de arriba: ninguno asume un exit code específico del runner más allá de "verde", así que siguen siendo instrucciones válidas; el comportamiento nuevo (exit 4 si el árbol está sucio) es aditivo |
| `sdd-run-gates.sh` | `plugins/sdd-flow/skills/sdd-init/SKILL.md:80` — CI generado corre `sdd-run-gates.sh --keep-going` **sin `-o`** (default `.sdd/gates-run.md`) | Sin impacto: el default cae dentro de `.sdd/`, la estrictez nueva nunca aplica ahí |
| `sdd-run-gates.sh --version` | Ningún caller programático encontrado (`grep -rn -- "--version" plugins/ SDD/` sólo devuelve la documentación del propio script y AC11) | AC11 |

Ningún caller de `plugins/sdd-flow/scripts/sdd-run-gates.sh` quedó sin cubrir: el único consumidor con test automatizado (`test_run_gates.sh` de R0) se re-corrió y sigue verde; los consumidores documentales (skills/agentes/templates) no rompen porque ninguno asume el comportamiento viejo como contrato, y el cambio es aditivo (nueva bandera, nuevo exit code que antes no existía) salvo por el propio propósito del fix.

---

## Rojos preexistentes

- Ninguno. `bash SDD/tests/run.sh` sobre esta branch, antes de este trabajo (commit `45da837`, cierre de R0), ya estaba en verde (4/4... en realidad 3/4 archivos existían entonces: `test_harness.sh`, `test_run_gates.sh`, `test_secret_scan.sh` — los tres seguían pasando). Este trabajo sólo agrega un cuarto archivo de test; no hay ningún gate que fallara antes y siga fallando ahora.
- `shellcheck --severity=warning` sigue en `0` (los 3 `SC2016` preexistentes de `plugins/` — deuda `D4` de R0 — no cambian; ver sección "Markers prohibidos" más abajo).

---

## Nota — `SC2016` nuevos, justificados inline (no es un rojo, pero es un hallazgo que declaro)

Mis líneas nuevas del encabezado del reporte (`Tree: ...`) repiten el mismo patrón que la línea preexistente de `Branch`/`Commit`/`Doc` (backtick literal dentro de un string de una comilla, para que el markdown del reporte muestre el backtick sin que bash lo interprete como sustitución de comando) — a severidad default (`style`) eso dispara `SC2016` (info), igual que la línea preexistente. Como `sdd-run-gates.sh` SÍ está en mi scope (a diferencia de los `SC2016` de R0 que son de archivos que R1 tiene prohibido tocar), apliqué la misma disciplina que AC3bis de R0: `# shellcheck disable=SC2016` inline con comentario, en las 3 líneas nuevas.

**Ronda 2 — corrección propia, no pedida por el review**: al recapturar la salida para esta misma nota (MINOR 3, ver "Ronda 2" al inicio de este archivo) encontré una CUARTA aparición que mi verificación de ronda 1 nunca vio: `SDD/tests/test_run_gates_tree.sh:183` (el `assert_contains "$out12" 'Tree: `-`' ...` de AC12) tiene el mismo backtick literal dentro de comillas simples. No es un hallazgo nuevo de esta ronda — estaba desde que escribí el archivo en Fase 1 — sino un hallazgo que mi propio comando de verificación de ronda 1 no podía ver: corrí `git ls-files -z -- '*.sh' | xargs -0 shellcheck` **antes** de hacer `git add` de ese archivo, y `git ls-files` sólo lista lo trackeado — el mismo tipo de desfasaje de timing que motivó el MINOR 3 de esta ronda, aplicado a mi propio proceso de verificación en vez de a un número de línea. Corregido con la misma disciplina (`# shellcheck disable=SC2016` inline, línea 183, justo arriba de la línea 184 que dispara el hallazgo).

Verificado, comando y salida reales, **después** de los 3 fixes MINOR (incluida esta cuarta justificación):

```
$ git ls-files -z -- '*.sh' | xargs -0 shellcheck 2>&1 | grep "SC2016\|SC2329"
                                              ^------------------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
                                                             ^-------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
            ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
  https://www.shellcheck.net/wiki/SC2016 -- Expressions don't expand in singl...
```
Exactamente 3 hallazgos reales (la 4ta línea es el link de ayuda, no un hallazgo nuevo), y los 3 son preexistentes de `plugins/` — cero en `SDD/tests/`, cero sin justificar. Line refs exactos (`shellcheck -f gcc`, recapturados contra el árbol con los 3 MINOR aplicados):

```
plugins/sdd-flow/scripts/sdd-lint-contract.sh:54:47: note: ... [SC2016]
plugins/sdd-flow/scripts/sdd-run-gates.sh:172:62: note: ... [SC2016]
plugins/sdd-flow/scripts/sdd-run-gates.sh:220:13: note: ... [SC2016]
```
`sdd-lint-contract.sh:54` es `D4` de R0 (preexistente, fuera de scope de R1). `sdd-run-gates.sh:172` es el `grep -oE` preexistente de antes de R1 (era la línea 158 en ronda 1, se corrió por mis inserciones). `sdd-run-gates.sh:220` es la línea preexistente de `Branch`/`Commit`/`Doc` (era la línea 206 en ronda 1, se corrió por el fix del MINOR 1 de esta ronda, que agregó líneas arriba). `--severity=warning` (el piso real del gate 2) sigue en `0` de todos modos, porque `SC2016` es `info` — esto nunca fue un rojo, es la contabilidad exacta que declaro para que no quede una cifra vieja dando vueltas.

---

## Ronda 2 — validación final (los 3 MINOR + la corrección propia, todos juntos)

Corridas reales, en esta máquina, contra el árbol con los 3 fixes de ronda 2 aplicados (antes de commitear):

| Comando | Exit code | Resultado |
|---|---|---|
| `bash SDD/tests/test_run_gates_tree.sh` | `0` | `PASS` — 19/19 `ok` (mismo conteo que ronda 1; el fix del MINOR 2 no cambia qué pasa, sólo la verdad del mensaje si algo falla) |
| `bash SDD/tests/run.sh` | `0` | `PASS` los 4 archivos — `4 passed, 0 failed (4 total)` |
| `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | `0` | limpio |

Sin regresión: los mismos 19 asserts siguen en `ok`, la suite completa sigue en verde, el gate de lint real (`--severity=warning`) sigue en `0`. Los 3 MINOR (más la corrección propia del `SC2016` #4) son cambios de **calidad de la evidencia y del mensaje de fallo**, no de comportamiento — ningún AC cambia de estado.

Commiteados estos 3 fixes (ver `sdd.result` de esta ronda para el hash), regeneré — con el árbol ya limpio — **las dos** evidencias de gates que el coordinador pidió:

```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R1-gates.md
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md
```

Exit codes, la línea `{"type":"sdd.gates",...}` de cada corrida, y el `Tree:`/`Commit:` resultantes quedan en esos dos archivos (generados por el runner) y en el `sdd.result` de esta ronda — no los transcribo acá para no duplicar evidencia que el runner ya dejó por escrito.

---

## Smoke manual (sólo ACs `manual-only`)

N/A — R1 no declara ningún AC `manual-only`.
