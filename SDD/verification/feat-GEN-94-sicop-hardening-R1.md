# Verification Report — AGENT_r1 · R1-runner-tree-seal

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R1 del contract `SDD/contracts/2026-08-13-sicop-hardening.md` **v3**, sección R1 (AC7-AC13; los ACs de R1 no cambiaron entre v1 y v3 — las ratificaciones de v2/v3 fueron todas de R0).

- **Branch**: `feat-GEN-94-sicop-hardening` (creada desde `prod`, heredada de R0)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v3, sección R1
- **Commit evaluado**: el commit `[FIX] [GEN-94] [sdd-flow] ...` que se crea después de este reporte (mismo razonamiento que R0: el hash no puede conocerse antes de crearlo; queda en el `sdd.result` con su valor real)
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (sin cambios de contenido — R1 no toca comandos de la escalera)

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

Conclusión: el test que respalda AC9 tiene poder de detección real — no es tautológico. `plugins/sdd-flow/scripts/sdd-run-gates.sh` en el repo, al momento de este commit, es la versión sin la mutación (con `exit 4` presente).

---

## AC13 — búsqueda de hermanos (checklist del arquetipo `bugfix`)

Comando exacto del brief, corrida real:

```
$ grep -rn "rev-parse HEAD\|rev-parse --short HEAD" plugins/sdd-flow/scripts/ plugins/sdd-flow/hooks/
plugins/sdd-flow/scripts/sdd-run-gates.sh:36:#   - árbol limpio  → Tree: hash de `git rev-parse HEAD^{tree}`.
plugins/sdd-flow/scripts/sdd-run-gates.sh:83:COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"
```
Exit `0` (grep encontró coincidencias). Dos apariciones, ambas en el archivo que este mismo diff modifica — no aparecieron hermanos en otro script ni en `plugins/sdd-flow/hooks/` (`guard-git.sh` usa `rev-parse --abbrev-ref HEAD` y `rev-parse --git-dir`, ninguno de los dos matchea el patrón literal del brief; confirmado con el mismo comando, cero líneas de `guard-git.sh` en la salida de arriba).

Clasificación de cada aparición:

1. **`sdd-run-gates.sh:36`** — comentario del bloque de documentación del sellado, agregado por este mismo diff (`# árbol limpio → Tree: hash de \`git rev-parse HEAD^{tree}\`.`). No es la evidencia sellada del bug: es prosa que documenta la fórmula correcta (`HEAD^{tree}`, no `HEAD` desnudo) que el propio fix introduce. **Uso legítimo** — es exactamente lo que R1 quiere que se use para el caso limpio.
2. **`sdd-run-gates.sh:83`** — `COMMIT="$(git rev-parse --short HEAD ...)"`. Es la línea original de la causa raíz. **Ya corregida por este mismo diff**, no por reescritura de la línea sino por contexto: el contract (punto 1 de la Decisión de diseño) exige que el reporte muestre el commit **además del** árbol, no en su lugar — `Commit:` sigue siendo información de contexto (qué branch/HEAD había al momento de la corrida), pero ya **no es la única** afirmación sobre qué código corrió: `TREE`/`TREE_STATE` (líneas 84-113, calculadas antes de este `COMMIT`) son las que ahora cargan esa responsabilidad y aparecen siempre junto a `Commit:` en el encabezado (AC7, AC8, AC12). No queda ninguna otra ocurrencia de este patrón en `plugins/sdd-flow/scripts/` ni `plugins/sdd-flow/hooks/` fuera de este archivo — no hay deuda ni scope adicional que registrar.

No se encontraron hermanos que requieran corrección fuera del archivo que R1 ya modifica.

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

Mis líneas nuevas del encabezado del reporte (`Tree: ...`) repiten el mismo patrón que la línea preexistente de `Branch`/`Commit`/`Doc` (backtick literal dentro de un string de una comilla, para que el markdown del reporte muestre el backtick sin que bash lo interprete como sustitución de comando) — a severidad default (`style`) eso dispara `SC2016` (info), igual que la línea preexistente. Como `sdd-run-gates.sh` SÍ está en mi scope (a diferencia de los `SC2016` de R0 que son de archivos que R1 tiene prohibido tocar), apliqué la misma disciplina que AC3bis de R0: `# shellcheck disable=SC2016` inline con comentario, en las 3 líneas nuevas. Verificado, comando y salida reales:

```
$ git ls-files -z -- '*.sh' | xargs -0 shellcheck 2>&1 | grep "SC2016\|SC2329"
                                              ^------------------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
                                                             ^-------^ SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
            ^-- SC2016 (info): Expressions don't expand in single quotes, use double quotes for that.
  https://www.shellcheck.net/wiki/SC2016 -- Expressions don't expand in singl...
```
Exactamente 3 hallazgos reales (la 4ta línea es el link de ayuda, no un hallazgo nuevo) — el mismo total que dejó R0 (`D4`, `plugins/sdd-lint-contract.sh:54` + `sdd-run-gates.sh:158`, preexistentes) más la línea preexistente `sdd-run-gates.sh:124` (ahora en la línea 206 tras mis inserciones arriba), sin agregar ninguno nuevo sin justificar. `--severity=warning` (el piso real del gate 2) sigue en `0` de todos modos, porque `SC2016` es `info`.

---

## Smoke manual (sólo ACs `manual-only`)

N/A — R1 no declara ningún AC `manual-only`.
