# Verification Report — AGENT_r4 · R4 · arquetipo `analysis` + guard de `.md` en la regla de supresores

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5) y de lo que el runner no puede saber. Lo escribe el implementing agent; lo audita el reviewer-agent.

- **Branch**: `feat-GEN-94-sicop-hardening`
- **Ronda**: **3/3** — la ronda 1 entregó `BLOCKED` sobre los ítems 5 y 6 del checklist estadístico; el planner ratificó **v8** con las dos redacciones corregidas y amplió AC42 a la regla `test-skipeado`; la ronda 2 ejecutó las tres tareas de v8. **La ronda 3 no cambia código ni tests**: regenera la evidencia con árbol limpio, ahora que el planner commiteó `SDD/retro.md` (`e643508`), que era lo único que forzaba `--allow-dirty`. El detalle de las rondas 1 y 2 queda abajo, sin editar.
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v8**, sección R4 (AC25-AC28 + AC42)
- **Brief**: `SDD/briefs/R4-analysis-archetype.md`
- **Commit evaluado**: `e643508` — sellado por el runner (R1) sobre **árbol limpio**. Commits de trabajo: `2d63f8e` (ronda 2, ítems 5-6 + AC42 ampliado) y `4f17172` (ronda 1). `e643508` es del planner (`RT10` + la fila del Delta), y es el tip sobre el que corrió la escalera. La evidencia se genera **después** del commit de trabajo, como en cada requerimiento de este ciclo.
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — el reporte generado lo registra con hash: `sha256:e96c7d0f61963400`. Copiado del encabezado del reporte, **no recalculado acá**. Mismo hash que en R3 y R5: el doc de gates **no cambió** durante el ciclo, así que ninguna fila de la escalera se movió.
- **Momento de captura** (`RT7`): todas las salidas pegadas abajo se capturaron **después** del último cambio a los archivos que describen. Las tres pruebas por mutación se corrieron después de la implementación, y sus reversiones están verificadas byte a byte contra el estado **commiteado** (los tres `shasum` de abajo se re-corrieron post-commit y coinciden).
- **Estado**: **completo** — el `BLOCKED` de la ronda 1 fue ratificado por el planner en v8 y está resuelto. Los cinco ACs verdes, cinco triples de mutación registrados, escalera en verde.

---

## Gates — evidencia GENERADA (no escrita a mano)

- **Reporte generado (ronda 3, el vigente)**: `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` — `sdd-run-gates.sh v0.12.0`, 2026-08-13T21:26:26Z, commit `e643508`, tree `4bc4d3b2fe3913acd664d4b1be8723d4bc625d54` **LIMPIO**. 4 gates con comando en verde, 7 `[SKIPPED]` declarados `N/A` en el doc, 0 rojos.
- **Comando y exit code**, pegados tal cual — **sin `--allow-dirty`**:

```
$ bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md
RUNNER_EXIT=0
{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md"}
```

- **Doc de gates**: `sha256:e96c7d0f61963400`, el mismo de las rondas 1 y 2 y el mismo de R3 y R5. La escalera no se movió en ningún momento del ciclo, así que las tres corridas de este requerimiento son comparables entre sí.

### Historia de las tres corridas (no se borra: es señal)

| Ronda | Commit | Árbol | Bandera | Exit | Resultado |
|---|---|---|---|---|---|
| 1 | `4f17172` | LIMPIO (`71c6678d…`) | — | `0` | 4 verdes · 0 rojos · 7 `[SKIPPED]` |
| 2 | `2d63f8e` | SUCIO (`55e2446c…`) | `--allow-dirty` | `0` | ídem, con `SDD/retro.md` estampado como no commiteado |
| 3 | `e643508` | LIMPIO (`4bc4d3b2…`) | — | `0` | ídem, **la vigente** |

**Por qué la ronda 2 necesitó la bandera, y por qué ya no**: el runner sin bandera había salido **4 sin escribir nada** (la estrictez derivada del destino de R1: `-o` fuera de `.sdd/` exige árbol limpio). Lo que ensuciaba el árbol era `SDD/retro.md` —la entrada `RT10`, del planner, sobre el hallazgo de mi ronda 1—, un archivo que el brief me prohíbe tocar. Descarté escribir a `.sdd/` (gitignoreado, no viaja en el PR) y stashear trabajo ajeno; usé el modo que el runner declara para esto, que **estampa él mismo qué quedó sin commitear**, de modo que la prueba de que ningún archivo mío faltaba la escribía el runner y no yo. El planner commiteó ese archivo en `e643508` y esta ronda regenera con árbol limpio. **La evidencia vigente no depende de ninguna bandera de degradación.**

- Los 7 `[SKIPPED]` son los gates que `SDD/docs/doc_quality_gates.md` declara `N/A` con razón (format, type-check, integration, build, e2e, cobertura, smoke). Ninguno es un gate existente que no se corrió.
- Corridas rojas intermedias del runner: ninguna. Los rojos de este trabajo son los del test — corrida previa al cambio y las tres pruebas por mutación —, cada uno con su comando y su exit code abajo.

---

## Test escrito antes del cambio — corrida roja registrada

El test se escribió **antes** de tocar los cinco archivos (T1.2 del brief) y se corrió contra el árbol sin el cambio.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| antes del cambio | `bash SDD/tests/test_analysis_archetype.sh` | `1` | 31 de 37 asserts en rojo |
| después del cambio | `bash SDD/tests/test_analysis_archetype.sh` | `0` | 37 de 37 `ok` |

Extracto de la corrida roja, pegado sin editar (5 de las 31 líneas `FAIL`, una por artefacto tocado, más el cierre):

```
  FAIL  AC25 archetypes.md - existe la seccion del arquetipo analysis — no encontré [## `analysis`] en la salida
  FAIL  AC26 archetypes.md - el checklist del arquetipo analysis tiene exactamente siete items — esperado [7], obtenido [0]
  FAIL  AC27 enrich-user-story - la dimension 7 lista el arquetipo analysis — no encontré [analysis] en la salida
  FAIL  T2.3 sdd-plan - la evidencia admite la salida de la consulta que re-deriva la cifra — no encontré [la salida de la consulta que re-deriva la cifra] en la salida
  FAIL  AC42 sdd-check.sh - sale 0 cuando el unico supresor del diff esta en un .md (exit 0) — esperado [0], obtenido [2]
FAIL — 31 assert(s) fallaron
```

**Los 6 asserts que ya estaban verdes antes del cambio son la evidencia directa de por qué AC28 y AC42 necesitan prueba por mutación.** Dos de ellos son los de coincidencia de AC28, y estaban verdes **con nueve arquetipos de cada lado**:

```
  ok    AC28 - el total de arquetipos coincide entre archetypes.md y enrich-user-story
  ok    AC28 - las dos listas nombran exactamente los mismos diez arquetipos
```

Es exactamente el modo de falla que el brief anticipa: un AC que afirma "los dos conteos coinciden" pasa con los dos conteos **mal**. Lo que lo vuelve falsable es el valor esperado `10` escrito fijo, y la mutación de abajo. Los otros 4 verdes previos son los casos positivos de AC42 (el supresor en código, y el guard que no ensancha a otras reglas), que también estaban verdes antes del fix por construcción: el fix sólo podía romperlos, no arreglarlos — y ese es su trabajo, ver T4.3.

**Un assert corregido antes del verde, declarado**: el assert de la línea «Tests exigidos» buscaba el literal `falsaría la conclusión` y el texto normativo del contract es `que **falsaría** la conclusión`, con el énfasis. Se corrigió **el assert al texto del contract**, no el texto al assert (`test_analysis_archetype.sh`, comentario en la misma línea). No es un ablandamiento: el assert quedó más estricto (ahora pide también el énfasis), y el comportamiento asserteado no cambió.

```
$ bash SDD/tests/test_analysis_archetype.sh | grep -c "^  ok"
37
$ bash SDD/tests/test_analysis_archetype.sh | tail -1
PASS
$ bash SDD/tests/test_analysis_archetype.sh >/dev/null 2>&1; echo "EXIT=$?"
EXIT=0
```

---

## Prueba por mutación (AC de detección)

Los dos ACs de detección de R4, con las mutaciones **declaradas en el contract v7** (no elegidas por mí). AC25, AC26 y AC27 afirman **presencia de contenido** en un archivo: caen en la lista de "no es de detección" de §10.1 (valor/artefacto producido) y quedan cubiertos por la corrida roja previa, que prueba que no pueden pasar vacíos.

### AC28 — dos conteos de arquetipos que coinciden (forma «sensibilidad» de §10.1)

- **Mutación declarada en el contract**: *«agregar un arquetipo falso a **uno solo** de los dos archivos · revertir después»*.

Se corrió **de los dos lados**, una vez cada uno, porque la mutación de un solo lado prueba la sensibilidad en una sola dirección y el AC afirma coincidencia en las dos.

**Mutación A — arquetipo falso sólo en `archetypes.md`:**

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |
| 2 | con la mutación aplicada | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — **exactamente los 3 asserts de AC28**, ninguno más |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |

```
  FAIL  AC28 archetypes.md - declara diez arquetipos — esperado [10], obtenido [11]
  FAIL  AC28 - el total de arquetipos coincide entre archetypes.md y enrich-user-story — esperado [10], obtenido [11]
  FAIL  AC28 - las dos listas nombran exactamente los mismos diez arquetipos — esperado [analysis api-endpoint background-job bugfix data-migration infra project-scaffold refactor third-party-integration ui-feature ], obtenido [analysis api-endpoint background-job bugfix data-migration fake-archetype infra project-scaffold refactor third-party-integration ui-feature ]
FAIL — 3 assert(s) fallaron
```

**Mutación B — arquetipo falso sólo en `enrich-user-story/SKILL.md`:**

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |
| 2 | con la mutación aplicada | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — los 3 asserts de AC28, con el conteo invertido |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |

```
  FAIL  AC28 enrich-user-story - la dimension 7 lista diez arquetipos — esperado [10], obtenido [11]
  FAIL  AC28 - el total de arquetipos coincide entre archetypes.md y enrich-user-story — esperado [11], obtenido [10]
  FAIL  AC28 - las dos listas nombran exactamente los mismos diez arquetipos — esperado [analysis api-endpoint background-job bugfix data-migration fake-archetype infra project-scaffold refactor third-party-integration ui-feature ], obtenido [analysis api-endpoint background-job bugfix data-migration infra project-scaffold refactor third-party-integration ui-feature ]
```

Que el rojo sea **el mismo conjunto de 3 asserts en las dos direcciones, con el `fake-archetype` cambiando de lado en el mensaje**, es lo que descarta que el control mire un solo archivo y adivine el otro.

**Por qué el control no cuenta mal las dos listas de la misma forma** (el riesgo que el brief nombra): los dos conteos se miden con **mecanismos distintos** — `grep -c '^## \`'` sobre los encabezados de sección de `archetypes.md`, contra `awk -F' · ' '{print NF}'` sobre el span en línea de la dimensión 7 —, el esperado `10` está escrito fijo en los dos asserts (una forma equivocada compartida no da 10 en los dos lados), y además de los conteos se comparan los **nombres ordenados**, que atrapa el rename en un solo lado que la igualdad de conteos deja pasar.

**Reversión verificada byte a byte** (re-corrida post-commit, `RT7`):

```
$ shasum -a 256 plugins/sdd-flow/standards/archetypes.md            # antes de la mutación A
c95c906c76261371a3e90fedd00860b514bd4cd38cdf1d90746fb005e521d4a8
$ shasum -a 256 plugins/sdd-flow/standards/archetypes.md            # después de revertir (= estado commiteado)
c95c906c76261371a3e90fedd00860b514bd4cd38cdf1d90746fb005e521d4a8
$ shasum -a 256 plugins/sdd-flow/skills/enrich-user-story/SKILL.md  # antes de la mutación B
da7843ddb4358c6ab9124c712b5d4b303410f4df7269e38fcd4fcb2fc745419a
$ shasum -a 256 plugins/sdd-flow/skills/enrich-user-story/SKILL.md  # después de revertir (= estado commiteado)
da7843ddb4358c6ab9124c712b5d4b303410f4df7269e38fcd4fcb2fc745419a
```

### AC42 — `sdd-check.sh` no levanta `BLOCKER` de supresor sobre un `.md` (forma «rechazo» de §10.1)

- **Mutación declarada en el contract**: *«quitar el guard de `.md` recién agregado y verificar que el `BLOCKER` falso reaparece · revertir después»*.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |
| 2 | con la mutación aplicada (guard quitado de la línea 68) | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — **los 3 asserts de `.md` de AC42, y ninguno de los 4 positivos** |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 37/37 |

```
  FAIL  AC42 sdd-check.sh - no reporta supresor sobre un archivo .md — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 cuando el unico supresor del diff esta en un .md (exit 0) — esperado [0], obtenido [2]
  FAIL  AC42 sdd-check.sh - el .md sigue sin reportarse cuando el codigo si dispara — esperado [no], obtenido [si]
FAIL — 3 assert(s) fallaron
```

Que los 4 asserts positivos (supresor en `code.ts` = `BLOCKER`, exit 2, y el `test-skipeado` sobre `.md` que **sigue** disparando) hayan quedado **verdes durante la mutación** es la otra mitad de la prueba: el rojo vino del guard, no de haber roto la regla entera.

**T4.3 — el guard no apaga la detección real.** Es un caso propio del test, no una observación: `AC42 sdd-check.sh - un supresor en un archivo de codigo sigue siendo BLOCKER` (con su `assert_exit 2`). Sin ese caso, borrar la regla completa daría verde y el "fix" sería un ablandamiento disfrazado de guard.

**Reversión verificada byte a byte** (re-corrida post-commit):

```
$ shasum -a 256 plugins/sdd-flow/scripts/sdd-check.sh   # antes de la mutación
01c1a88d7fe12dc31dc7b74a8d99af1563d294af9ce1ab83d0f94ee657de3cba
$ shasum -a 256 plugins/sdd-flow/scripts/sdd-check.sh   # después de revertir (= estado commiteado)
01c1a88d7fe12dc31dc7b74a8d99af1563d294af9ce1ab83d0f94ee657de3cba
```

**Efecto medido sobre este repo** (el `BLOCKER` falso que el reviewer midió en `e5ef90c`). La corrida "sin guard" usa una **copia** del script en un directorio temporal, así que el árbol no se toca:

```
$ bash <copia-sin-guard>/sdd-check.sh | awk -F'\t' '$3=="supresor" && $2 ~ /\.md$/' | wc -l
16
$ bash plugins/sdd-flow/scripts/sdd-check.sh | awk -F'\t' '$3=="supresor" && $2 ~ /\.md$/' | wc -l
0
```

16 `BLOCKER` falsos sobre documentos `.md` pasan a 0. **`sdd-check.sh` sigue saliendo 2 sobre este repo**, y eso **no** es un fallo de AC42: los hallazgos que quedan son de otras reglas y de archivos que no son `.md` — los dos ejecutables que **describen los patrones que detectan** (`hooks/guard-git.sh` ×2 y `scripts/sdd-check.sh` ×3, autodetección) más dos `test-skipeado` sobre `.md`, que son el defecto hermano declarado abajo.

---

## Ronda 2 — contract v8

Tres tareas: la redacción nueva de los ítems 5 y 6, la ampliación de AC42 a la regla `test-skipeado`, y evidencia regenerada. **Los asserts se escribieron antes del cambio, igual que en la ronda 1.**

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| antes del cambio de la ronda 2 | `bash SDD/tests/test_analysis_archetype.sh` | `1` | 12 asserts en rojo (36 verdes: los de la ronda 1 que no cambiaron) |
| después del cambio | `bash SDD/tests/test_analysis_archetype.sh` | `0` | 48 de 48 `ok` |

Extracto de la corrida roja, pegado sin editar — las 4 líneas que prueban que **los dos asserts de ausencia no son tautológicos** (las frases viejas existían en el árbol) más las dos direcciones nuevas de AC42:

```
  FAIL  AC26 item 5 - la redaccion vieja autosatisfacible ya no esta — esperado [no], obtenido [si]
  FAIL  AC26 item 6 - la redaccion vieja sin tamano de efecto ya no esta — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - no reporta test-skipeado sobre un archivo .md — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 cuando el unico test skipeado del diff esta en un .md (exit 0) — esperado [0], obtenido [2]
FAIL — 12 assert(s) fallaron
```

Un chequeo de ausencia que busca una frase inexistente pasa siempre (es lo que R3 documenta en `AC23`). Estos dos **no** son de esa clase, y la corrida de arriba lo prueba: salieron rojos contra el árbol que todavía tenía la redacción vieja.

```
$ bash SDD/tests/test_analysis_archetype.sh | grep -c "^  ok"
48
$ bash SDD/tests/test_analysis_archetype.sh >/dev/null 2>&1; echo "EXIT=$?"
EXIT=0
```

### AC42 ampliado — efecto medido sobre este repo

```
$ bash <copia-con-el-guard-solo-en-supresores>/sdd-check.sh | awk -F'\t' '$1=="BLOCKER" && $2 ~ /\.md$/' | wc -l
2
$ bash plugins/sdd-flow/scripts/sdd-check.sh | awk -F'\t' '$1=="BLOCKER" && $2 ~ /\.md$/' | wc -l
0
```

Los 2 que quedaban eran `standards/quality-gates.md` §6.1 (la lista de mitigaciones prohibidas) y `templates/doc_quality_gates.md` (el placeholder de markers prohibidos) — los mismos que reporté en la ronda 1. **El diff de esta branch ya no levanta ningún `BLOCKER` sobre un archivo `.md`.** Lo que queda son 5 hallazgos sobre `.sh`, todos de los dos ejecutables que describen los patrones que detectan (`hooks/guard-git.sh`, `scripts/sdd-check.sh`): autodetección, fuera del alcance de AC42.

### Los cinco triples, re-medidos contra el test final (`RT7`)

**Importante**: las primeras corridas de los triples se hicieron **antes** de mi último cambio al archivo de test (el literal de `catch` armado en runtime, abajo). Como el test cambió, **volví a correr los cinco enteros** contra el archivo final, y son estos los que valen. Es la misma decisión que tomó R3 cuando su test cambió entre rondas.

Las dos mutaciones declaradas en el contract v8 se ejecutan tal cual. La tercera de AC42 está marcada **adicional**: no sustituye a ninguna declarada, agrega la dirección que las declaradas no cubren.

#### AC42-A — guard de `test-skipeado` quitado (mutación declarada; es el guard que v8 agrega)

- **Mutación declarada en el contract**: *«quitar el guard de `.md` recién agregado y verificar que el `BLOCKER` falso reaparece · revertir después»*.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |
| 2 | con la mutación aplicada | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — 4 asserts, todos de `.md` |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |

```
  FAIL  AC42 sdd-check.sh - no reporta test-skipeado sobre un archivo .md — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 cuando el unico test skipeado del diff esta en un .md (exit 0) — esperado [0], obtenido [2]
  FAIL  AC42 sdd-check.sh - la prosa que enumera las mitigaciones prohibidas no levanta ningun BLOCKER — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 sobre un .md que enumera supresores y tests skipeados (exit 0) — esperado [0], obtenido [2]
FAIL — 4 assert(s) fallaron
```

Los dos asserts de la **dirección 2** (un test realmente skipeado en un archivo de código sigue siendo `BLOCKER`) quedaron **verdes durante la mutación**: el rojo vino del guard, no de haber roto la regla.

#### AC42-B — guard de supresores quitado (mutación declarada, re-medida)

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |
| 2 | con la mutación aplicada | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — 4 asserts |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |

```
  FAIL  AC42 sdd-check.sh - no reporta supresor sobre un archivo .md — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 cuando el unico supresor del diff esta en un .md (exit 0) — esperado [0], obtenido [2]
  FAIL  AC42 sdd-check.sh - la prosa que enumera las mitigaciones prohibidas no levanta ningun BLOCKER — esperado [no], obtenido [si]
  FAIL  AC42 sdd-check.sh - sale 0 sobre un .md que enumera supresores y tests skipeados (exit 0) — esperado [0], obtenido [2]
```

#### AC42-EXTRA — el guard implementado como «saltear el `.md` entero» (adicional, no sustituye ninguna declarada)

La forma barata de hacer pasar AC42 es descartar los archivos `.md` **antes** de evaluar ninguna regla. Con eso, **todos los demás asserts de AC42 pasan igual** y el checker queda ciego a la prosa: es el ablandamiento disfrazado en su forma más difícil de ver. El caso 4 del test existe para distinguir las dos implementaciones, y esta corrida prueba que tiene poder — cae **exactamente él, y ninguno más**:

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |
| 2 | con la mutación aplicada (`if (file ~ /\.md$/) next` al tope del bloque) | `bash SDD/tests/test_analysis_archetype.sh` | `1` | rojo — **un solo assert** |
| 3 | mutación revertida | `bash SDD/tests/test_analysis_archetype.sh` | `0` | verde — 48/48 |

```
  FAIL  AC42 sdd-check.sh - el guard no saltea el archivo .md entero, solo las dos reglas — no encontré [WARN	doc.md	catch-silencioso	] en la salida
FAIL — 1 assert(s) fallaron
```

#### AC28-A y AC28-B — re-medidas contra el test final

Mismo resultado que en la ronda 1, ahora contra las 48 asserts: `0` → `1` (3 asserts, con el `fake-archetype` cambiando de lado según el archivo mutado) → `0`. Salidas completas en la corrida de los cinco triples.

#### Reversiones verificadas byte a byte (los tres archivos mutados, post-commit)

```
  sha_antes   6fe144599f8fd806149d84bdfdb03112af567c51ef5a5121bc840377bb34ff6d  (sdd-check.sh)
  sha_despues 6fe144599f8fd806149d84bdfdb03112af567c51ef5a5121bc840377bb34ff6d
  sha_antes   9b4d616fce9746db9d3f538b212c51968063751894faa8a5a125a4e9708b0762  (archetypes.md)
  sha_despues 9b4d616fce9746db9d3f538b212c51968063751894faa8a5a125a4e9708b0762
  sha_antes   da7843ddb4358c6ab9124c712b5d4b303410f4df7269e38fcd4fcb2fc745419a  (enrich-user-story/SKILL.md)
  sha_despues da7843ddb4358c6ab9124c712b5d4b303410f4df7269e38fcd4fcb2fc745419a
```

### Dos cosas que salieron mal en esta ronda, y cómo las agarré

1. **Mi propio arnés de medición dio 127 en las 15 corridas de los triples** — puse el comando en una variable (`T="bash SDD/tests/…"`) y lo invoqué sin comillas dentro de una función; **la shell de esta máquina es `zsh`, que no hace word splitting**, así que buscó un ejecutable llamado literalmente `bash SDD/tests/test_analysis_archetype.sh`. Las tres corridas de cada triple salieron `127` — ni verde ni rojo, el test **nunca corrió**. Si pego esos exit codes, publico un triple entero inventado con cara de medición. Lo rehice con los comandos literales dentro de un script `bash` explícito, y esos son los números de arriba. Es `RT8` otra vez, en el instrumento en vez de en el objeto medido: **el arnés que mide el control también puede estar roto, y da un número igual**.
2. **Mi propio archivo de test disparaba una regla del checker que estoy arreglando**: el caso 4 necesita un `catch` silencioso literal, y contiguo en el fuente hacía que `sdd-check.sh` reportara `WARN  SDD/tests/test_analysis_archetype.sh  catch-silencioso`. Lo armé en runtime (`printf '%s%s' 'catch (e) {' '}'`), la misma convención que el archivo ya usaba para los supresores. Medido después: `bash plugins/sdd-flow/scripts/sdd-check.sh | awk -F'\t' '$2 ~ /test_analysis_archetype/' | wc -l` → `0`.

### Observación de plan (`MINOR`) — **CERRADA en `e643508`**

Reportado en la ronda 2: el **Architectural Delta de v8 no se había actualizado** — su fila de `scripts/sdd-check.sh` decía *"guard de `.md` en la regla de supresores (**agregado en v7**)"* mientras el texto de AC42 ya exigía las dos reglas. El AC manda y es inequívoco, así que implementé las dos y lo dejé anotado porque el reviewer contrasta el Delta contra el diff. El planner corrigió la fila; verificado sobre el árbol, no supuesto:

```
$ grep -n "sdd-check.sh" SDD/contracts/2026-08-13-sicop-hardening.md
322:| Script | `plugins/sdd-flow/scripts/sdd-check.sh` — guard de `.md` en la regla de supresores (**agregado en v7**) **y en la de `test-skipeado`** (**ampliado en v8**). …
```

Era la misma clase de desfase entre el Delta y los ACs que el ciclo ya había encontrado en R3 (cinco consumidores declarados, siete reales).

---

## Smoke manual

`N/A — ningún AC de R4 está declarado `manual-only` en el contract.`

---

## Impact set

El cambio es normativo (markdown) más una línea de `awk` en un script y un test nuevo. Los "callers" son los artefactos que consumen la lista de arquetipos o la regla modificada.

| Símbolo/regla cambiada | Caller | Cobertura |
|---|---|---|
| lista de arquetipos (`archetypes.md`) | `skills/enrich-user-story/SKILL.md:92` — la fuerza a "exactamente uno" | actualizada en el mismo diff; 2 asserts de AC27 + 4 de AC28 |
| lista de arquetipos | **`plugins/sdd-flow/README.md:39` — TERCERA declaración de la lista, con el total escrito con letra (`9 arquetipos`)** | **fuera de la tabla de Files del brief; actualizada igual** (ver «Archivos fuera de la tabla de Files»). 2 asserts `IMPACT` |
| lista de arquetipos | `commands/sdd.md:33,38`, `agents/reviewer-agent.md:33`, `standards/concerns.md:3` | referencian `archetypes.md` **sin enumerar** la lista → no quedan desactualizados. Verificado con `grep -rn "arquetipo\|archetype"` sobre los tres |
| lista de arquetipos | **`evals/golden-requirements.md` — "un requerimiento golden **por arquetipo**", G1-G9** | **queda incompleto: no hay golden para `analysis`.** Escribirlo es contenido normativo nuevo (y `G10` ya está tomado por el golden adversarial) → **no lo inventé**: va como hallazgo al planner, abajo |
| checklist del arquetipo → ACs | `skills/sdd-plan/SKILL.md:18` (inyecta el checklist como ACs) y `agents/reviewer-agent.md:33` (ítem sin AC ni `N/A` = `MAJOR` de contract) | el mecanismo es genérico sobre "el checklist del arquetipo": el arquetipo nuevo entra sin tocarlos. `sdd-plan` **sí** recibió la regla de evidencia del binding (T2.3), cubierta por 3 asserts |
| reglas `supresor` y `test-skipeado` (`scripts/sdd-check.sh`) | `standards/quality-gates.md` §7.1 y `agents/reviewer-agent.md` Fase 1 — corren el script y leen su salida | el guard **reduce** falsos positivos y no cambia la interfaz (mismo formato de línea, mismos exit codes). 11 asserts de AC42 tras la ronda 2, incluidos los 4 de detección real viva y el que distingue el guard de "saltear el `.md` entero" |
| regla `test-skipeado` (ronda 2) | `commands/sdd-fixes.md` y `standards/quality-gates.md` §6.1 enumeran los markers que la regla busca | son **prosa**, y son justamente los falsos positivos que el guard elimina: no hay caller que dependa de que el `.md` dispare. Verificado midiendo 2 → 0 |
| `SDD/tests/run.sh` (descubre `test_*.sh`) | el archivo nuevo entra a la suite | 8 archivos, los 8 `PASS` (gate 4 del reporte generado) |

**Rojos preexistentes**: ninguno. Los 7 archivos de test que existían antes de este trabajo corren en mi propia corrida y salen los 7 `PASS` — medición de esta corrida (bloque del gate 4 del reporte generado), no una cita del reporte de R3.

---

## Cómo se midió cada cifra de este reporte

`RT8` — verificar cómo se mide antes de creerle a la medición.

| Cifra | Cómo se midió | Límite / trampa evitada |
|---|---|---|
| gate 2 (lint) verde | **glob del gate**: `plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` — nunca `git ls-files` (`D8`). Verificado que el archivo nuevo entra al glob: `for f in SDD/tests/*.sh; do echo "$f"; done \| grep -c test_analysis_archetype.sh` → `1` | el glob ve el archivo aunque no esté stageado |
| 37 asserts | conteo de líneas `ok` de la propia corrida (`grep -c '^  ok'`) | ninguno: es la salida del mismo proceso que se mide |
| 16 → 0 `BLOCKER` falsos | dos corridas del **mismo** diff (base `merge-base` → árbol), una con una copia del script sin el guard y otra con el del árbol, filtrando `$3=="supresor" && $2 ~ /\.md$/` | comparar exit codes no servía: el script sale 2 por otras reglas en los dos casos. Se cuenta la **línea de hallazgo**, no el exit |
| 14 `SC2016` a severidad `info` | `shellcheck -f gcc ... \| grep -c SC2016`, y por archivo con `cut -d: -f1 \| sort \| uniq -c` | **el formato tty da 15**: agrega una línea de pie con el link del wiki por cada código único. La cifra buena es la de `-f gcc`, una línea por hallazgo. Es la trampa de `RT8` en su forma más chica, y me mordió en la primera medición |
| 8 archivos de test, 8 `PASS` | salida de `bash SDD/tests/run.sh`, que es también el gate 4 del reporte generado | ninguno |
| **48 asserts** (ronda 2) | `grep -c '^  ok'` de la propia corrida | ninguno |
| **2 → 0 `BLOCKER` sobre `.md`** (ronda 2) | mismo método que la fila de 16 → 0, filtrando ahora por `$1=="BLOCKER" && $2 ~ /\.md$/` (las dos reglas, no sólo `supresor`) | ídem: el exit code sigue siendo 2 por los `.sh` autodetectados, así que la cifra sale del conteo de líneas |
| **exit codes de los 5 triples** (ronda 2) | script `bash` explícito con los comandos literales | **la primera versión del arnés devolvió `127` en las 15 corridas** porque puso el comando en una variable y esta shell es `zsh`, que no hace word splitting: el test nunca corrió. Ver "Dos cosas que salieron mal" |

Gate 2, pegado tal cual (salida vacía = sin hallazgos):

```
$ shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh; echo "EXIT=$?"
EXIT=0
```

Gate 9, pegado tal cual. **Corrección de mi propia medición, declarada**: la primera corrida que hice reportó `95 archivos` y la anoté como "post-`git add`" — era **pre-commit**, con `test_analysis_archetype.sh` todavía sin trackear, y `secret-scan.sh` enumera con `git ls-files`, que no ve untracked (`D8`, la misma trampa que dio el verde falso de la ronda 1 de R1). La cifra válida es la de la corrida del runner sobre el árbol limpio del commit `4f17172`, que es además la que quedó en la evidencia generada:

```
$ grep "archivos versionados" SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md
secret-scan: sin hallazgos sobre 96 archivos versionados (1 excluido: self)
$ bash SDD/tests/secret-scan.sh     # re-corrida a mano, mismo árbol
secret-scan: sin hallazgos sobre 96 archivos versionados (1 excluido: self)
```

Los dos archivos de evidencia de este reporte quedan **fuera** de esas 96: se commitean después de la corrida, como en cada requerimiento de este ciclo.

**Nota sobre `SC2016` (info, por debajo del piso del gate)**: mi test agrega **8** hallazgos `SC2016` en `SDD/tests/`, por los programas `awk` entre comillas simples (`$0`, `$2`, `NF` son de `awk`, no del shell — uso correcto, misma clase que `D4`). El gate corre a `--severity=warning` y sale 0.

```
$ shellcheck -f gcc plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh | grep SC2016 | cut -d: -f1 | sort | uniq -c
   8 SDD/tests/test_analysis_archetype.sh
   3 SDD/tests/test_mutation_rule.sh
   1 plugins/sdd-flow/scripts/sdd-lint-contract.sh
   2 plugins/sdd-flow/scripts/sdd-run-gates.sh
```

La nota de `doc_quality_gates.md` que dice *"a severidad default sólo quedan los 3 `SC2016` preexistentes de `plugins/`"* sigue siendo exacta **en su alcance escrito** (`plugins/sdd-flow/scripts/` mide 3, medido arriba), pero su lectura literal ya no describe el glob completo: la divergencia empezó en R3 (3 hallazgos) y este trabajo la lleva a 11 en `SDD/tests/`. **No toqué `doc_quality_gates.md`**: cambiarlo movería su `sha256` y dispararía el hallazgo de "el doc de gates cambió durante el ciclo" (R5) por una nota informativa que no mueve ninguna fila de la escalera. Queda declarado acá para el planner.

---

## Archivos fuera de la tabla de Files del brief

Uno solo, y lo declaro explícito porque la tabla de Files del brief no lo lista:

- **`plugins/sdd-flow/README.md:39`** — decía `9 arquetipos (…lista de nueve…)`. Es la **tercera** declaración de la lista (el Delta del contract enumera dos) y la única que escribe el total con letra. Dejarla intacta publicaba el defecto exacto que AC28 existe para prevenir —dos listas que no coinciden— en el archivo que un dev lee primero. Lo actualicé a `10 arquetipos` con `analysis` en la lista, y agregué 2 asserts con prefijo `IMPACT` (no `AC28`: el contract nombra dos archivos, no tres). Es propagación de una decisión ya cerrada, no una decisión nueva.

---

## Hallazgos para el planner (no los resolví por mi cuenta)

### 1. `BLOCKED` de la ronda 1 — **CERRADO en v8**

El planner ratificó las dos redacciones **tal cual las propuse** y las escribió en el contract con su razón medida al lado. Aplicadas en `archetypes.md` en la ronda 2 (asserts nuevos + ausencia de la redacción vieja, con la corrida roja que prueba que la ausencia no es tautológica). Dejo el diagnóstico original abajo sin editar, porque es la parte que el ciclo va a querer releer: es el único defecto de plan del ciclo que no se detectaba midiendo.

**Diagnóstico original (ronda 1):**

Es el riesgo que el brief declara ("el planner que lo escribió no es estadístico"), y **está materializado en dos de los siete ítems**. Los escribí **textuales del contract** en `archetypes.md` —desviarme sería infidelidad al contract, que es `BLOCKER` de review— y los reporto acá para que el planner ratifique v8. Los cinco restantes (1, 2, 3, 4 y 7) se sostienen: son pre-especificación, anti-reporte-selectivo, trazabilidad de cifras y robustez a exclusiones, y ninguno se puede cumplir mientras se comete el error que ataca.

**Ítem 5 — «Unidad de análisis declarada, y el test a esa unidad cuando las observaciones se agrupan».**
`esa unidad` sólo puede referirse a la unidad de análisis declarada, y el ítem **no exige** que esa unidad sea aquella en la que las observaciones son independientes. En el incidente que lo motiva, la declaración natural es *"unidad de análisis = la oferta"* (19 ofertas), y entonces el ítem se cumple corriendo el test **a nivel de oferta** — que es exactamente el error que produjo la brecha de 0,215. El remedio que el propio incidente usó (permutación **a nivel de concurso**) es una de las dos lecturas posibles, no la que el texto obliga. Dos analistas lo implementarían distinto, que es el test que las closure rules imponen. Además no pide el dato que gobierna la inferencia agrupada: **cuántos grupos hay** (con 19 ofertas repartidas en pocos concursos, el conteo que sostiene el p-valor es el de concursos, no el de filas).
*Corrección mínima propuesta (la decide el planner, no yo)*: «**Unidad de análisis y unidad de agrupamiento declaradas, con el número de grupos. Cuando las observaciones se agrupan, la inferencia se hace a nivel del grupo, y el reporte nombra la técnica usada.**»

**Ítem 6 — «Tamaño de muestra y potencia declarados, con el número».**
La potencia no es una propiedad del dataset: es función del tamaño de efecto, de α y del test. "Potencia declarada, con el número" **sin decir contra qué tamaño de efecto** produce un número que no significa nada, y calculada después de ver el resultado se vuelve **potencia observada**, que es una transformación monótona del p-valor: no agrega información sobre la que ya da `p`. Aplicado al incidente (`p = 0,533`), el ítem se cumple escribiendo "potencia = 0,09" — una cifra que suena rigurosa y repite lo que `p` ya dijo. Lo que sí decide algo es el **efecto mínimo detectable**: *"con n filas en k grupos y α = 0,05, este diseño detecta con potencia 0,80 una brecha ≥ X"*, que es lo único que distingue **"no hay efecto"** de **"no hay datos"** — y esa distinción era justo la que el backtest necesitaba y no tuvo.
*Corrección mínima propuesta*: «**Tamaño de muestra (filas y grupos) y tamaño de efecto mínimo detectable declarados, con el número: contra qué efecto, a qué α y a qué potencia. La potencia calculada con el efecto observado no cuenta.**»

**Por qué esto es `BLOCKED` y no un `MINOR` que arreglo yo**: son ítems normativos que el contract cierra y que van a generar ACs en cada ciclo de análisis futuro. Reescribirlos por mi cuenta sería cerrar una decisión que el contract ya cerró —la misma prohibición que §10.2 pone sobre inventar una mutación—. El costo de dejarlos como están no lo paga este ciclo: lo paga el primer análisis real que los cumpla al pie de la letra y llegue igual a una conclusión falsa. Es, además, el único punto ciego del review adversarial de este ciclo, porque **un ítem estadístico mal formulado no se detecta midiendo el plugin**: los cuatro defectos de plan anteriores se atraparon con un grep, un payload y un `git ls-tree`; éste sólo aparece el día que alguien lo aplica a un dataset.

### 2. Defecto hermano de AC42 — **CERRADO en v8** (AC42 ampliado, implementado en la ronda 2)

El planner amplió AC42 a la regla `test-skipeado`. Implementado con las **dos direcciones** probadas y con el caso que distingue el guard de dos reglas de "saltear el `.md` entero". Medición post-fix: 2 → 0 `BLOCKER` sobre `.md`. Diagnóstico original de la ronda 1:

Búsqueda de hermanos (checklist del arquetipo `bugfix`) aplicada al fix de AC42: **la regla de al lado tiene el defecto idéntico** y pega sobre los documentos normativos del propio plugin.

```
$ bash plugins/sdd-flow/scripts/sdd-check.sh | awk -F'\t' '$2 ~ /\.md$/ {print $1"\t"$2"\t"$3}'
BLOCKER	plugins/sdd-flow/standards/quality-gates.md	test-skipeado
BLOCKER	plugins/sdd-flow/templates/doc_quality_gates.md	test-skipeado
```

Las dos líneas son **prosa que enumera lo prohibido**: `quality-gates.md` §6.1 (la lista de mitigaciones prohibidas) y el placeholder de "markers prohibidos" del template. Idéntico al `@ts-`+`ignore` de `commands/sdd-fixes.md` que motivó AC42. **No lo arreglé**: AC42 acota el guard a la regla de supresores (`"Es la única línea que tocás de scripts/"`), y ensancharlo es una decisión nueva — el `test_analysis_archetype.sh` incluso **fija** la conducta actual en un caso propio (`el guard no apaga las otras reglas sobre .md`), que se pondrá rojo el día que el planner decida ensancharlo, y ahí se actualiza con su contract.

### 3. `evals/golden-requirements.md` queda con un arquetipo sin golden

El archivo declara "un requerimiento golden **por arquetipo**" y tiene G1-G9 para los nueve. Con `analysis` son diez arquetipos y nueve goldens. Escribir el golden es contenido normativo nuevo (qué requerimiento de ejemplo, qué propiedades específicas), y además `G10` ya está tomado por el golden adversarial, así que la numeración es una decisión del planner. Candidato a deuda, en la misma familia que `D9` (que R3 dejó registrado sobre este mismo archivo).

---

## Decisiones que tomé dentro del contract (para el review)

Ninguna es nueva: son la aplicación de lo que R4 cierra. Las listo porque son las que un reviewer querría discutir.

1. **AC42 vive en `test_analysis_archetype.sh`**, no en un archivo propio: el contract v7 lo agrega a la sección R4 y la tabla de Files del brief declara **un** test nuevo. Su verificación no es un grep — monta un repo git de usar y tirar y corre el `sdd-check.sh` real contra un diff sintético, que es la única forma de medir el script sin depender del diff de esta branch (que tiene hallazgos de otras reglas y saldría 2 igual).
2. **Los literales de supresor del test se arman en runtime** (`printf '%s%s' '@ts-' 'ignore'`), misma convención que `plant_kv` en `test_secret_scan.sh`: contiguos en el fuente harían que `sdd-check.sh` levante un `BLOCKER` sobre el propio test, que es un `.sh` y por lo tanto **fuera** del guard que AC42 agrega.
3. **Los asserts de AC25/AC26 corren sobre un recorte de la sección**, no sobre el archivo entero: los otros nueve arquetipos ya contienen "NFR obligatorias", "Tests exigidos" y "Checklist → ACs", así que un assert sobre todo el archivo daría verde **sin la sección nueva**. Es la misma clase de control tautológico que AC28 ataca, evitada en el mismo archivo.
4. **La posición de la sección se assertea con números de línea** (`infra` < `analysis` < "Cómo lo usa el pipeline"), porque el Delta del contract la fija y "está en el archivo" no es lo mismo que "está donde el contract dice".
5. **No toqué `plugin.json` ni `CHANGELOG.md`**: ningún commit de este ciclo (R0-R5) los tocó — el bump y el `[REL]` son del planner al cerrar, no de un requerimiento. Por la misma razón **no bumpeé `VERSION` en `sdd-check.sh`** (sigue en `0.10.0`): el Delta de R4 declara el guard y nada más, y el bump de `sdd-run-gates.sh` de R5 sí estaba declarado explícito en su Delta. Ningún test assertea esa constante (verificado con `grep -rn "sdd-check" SDD/tests/*.sh`: sólo mi archivo la menciona, y por ruta, no por versión). Si el planner quiere el bump, es una línea.
6. **El límite del guard queda escrito** en el encabezado del test: un supresor real dentro de un bloque de código embebido en un `.md` deja de detectarse. Es el trade-off que la regla de al lado ya tomaba desde antes, y que el contract ratifica para ésta.
