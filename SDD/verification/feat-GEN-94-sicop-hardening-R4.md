# Verification Report — AGENT_r4 · R4 · arquetipo `analysis` + guard de `.md` en la regla de supresores

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5) y de lo que el runner no puede saber. Lo escribe el implementing agent; lo audita el reviewer-agent.

- **Branch**: `feat-GEN-94-sicop-hardening`
- **Ronda**: 1/3
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v7**, sección R4 (AC25-AC28 + AC42)
- **Brief**: `SDD/briefs/R4-analysis-archetype.md` (v6 en su encabezado; los ACs no cambian en v7, que **agrega** AC42 y las dos `Mutación:` declaradas)
- **Commit evaluado**: `4f17172` — sellado por el runner (R1). La evidencia se genera **después** del commit de trabajo, como en cada requerimiento de este ciclo.
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — el reporte generado lo registra con hash: `sha256:e96c7d0f61963400`. Copiado del encabezado del reporte, **no recalculado acá**. Mismo hash que en R3 y R5: el doc de gates **no cambió** durante el ciclo, así que ninguna fila de la escalera se movió.
- **Momento de captura** (`RT7`): todas las salidas pegadas abajo se capturaron **después** del último cambio a los archivos que describen. Las tres pruebas por mutación se corrieron después de la implementación, y sus reversiones están verificadas byte a byte contra el estado **commiteado** (los tres `shasum` de abajo se re-corrieron post-commit y coinciden).
- **Estado**: **BLOCKED** — el trabajo está completo, verde y commiteado; el bloqueo es sobre **dos ítems del checklist normativo que el contract cierra** (ítems 5 y 6 de AC26). Ver la sección «BLOCKED» al final, que es la parte de este reporte que el planner tiene que leer primero.

---

## Gates — evidencia GENERADA (no escrita a mano)

- **Reporte generado**: `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` — `sdd-run-gates.sh v0.12.0`, 2026-08-13T21:01:30Z, commit `4f17172`, tree `71c6678d032817c254cdc58efe153cd01f040f9e` **LIMPIO**. 4 gates con comando en verde, 7 `[SKIPPED]` declarados `N/A` en el doc, 0 rojos.
- **Comando y exit code**, pegados tal cual:

```
$ bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md
RUNNER_EXIT=0
{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md"}
```

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
| regla de supresores (`scripts/sdd-check.sh:63-69`) | `standards/quality-gates.md` §7.1 y `agents/reviewer-agent.md` Fase 1 — corren el script y leen su salida | el guard **reduce** falsos positivos y no cambia la interfaz (mismo formato de línea, mismos exit codes). 7 asserts de AC42, incluidos los 4 que prueban que la detección real sigue viva |
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

### 1. `BLOCKED` — dos ítems del checklist de AC26 no se sostienen estadísticamente

Es el riesgo que el brief declara ("el planner que lo escribió no es estadístico"), y **está materializado en dos de los siete ítems**. Los escribí **textuales del contract** en `archetypes.md` —desviarme sería infidelidad al contract, que es `BLOCKER` de review— y los reporto acá para que el planner ratifique v8. Los cinco restantes (1, 2, 3, 4 y 7) se sostienen: son pre-especificación, anti-reporte-selectivo, trazabilidad de cifras y robustez a exclusiones, y ninguno se puede cumplir mientras se comete el error que ataca.

**Ítem 5 — «Unidad de análisis declarada, y el test a esa unidad cuando las observaciones se agrupan».**
`esa unidad` sólo puede referirse a la unidad de análisis declarada, y el ítem **no exige** que esa unidad sea aquella en la que las observaciones son independientes. En el incidente que lo motiva, la declaración natural es *"unidad de análisis = la oferta"* (19 ofertas), y entonces el ítem se cumple corriendo el test **a nivel de oferta** — que es exactamente el error que produjo la brecha de 0,215. El remedio que el propio incidente usó (permutación **a nivel de concurso**) es una de las dos lecturas posibles, no la que el texto obliga. Dos analistas lo implementarían distinto, que es el test que las closure rules imponen. Además no pide el dato que gobierna la inferencia agrupada: **cuántos grupos hay** (con 19 ofertas repartidas en pocos concursos, el conteo que sostiene el p-valor es el de concursos, no el de filas).
*Corrección mínima propuesta (la decide el planner, no yo)*: «**Unidad de análisis y unidad de agrupamiento declaradas, con el número de grupos. Cuando las observaciones se agrupan, la inferencia se hace a nivel del grupo, y el reporte nombra la técnica usada.**»

**Ítem 6 — «Tamaño de muestra y potencia declarados, con el número».**
La potencia no es una propiedad del dataset: es función del tamaño de efecto, de α y del test. "Potencia declarada, con el número" **sin decir contra qué tamaño de efecto** produce un número que no significa nada, y calculada después de ver el resultado se vuelve **potencia observada**, que es una transformación monótona del p-valor: no agrega información sobre la que ya da `p`. Aplicado al incidente (`p = 0,533`), el ítem se cumple escribiendo "potencia = 0,09" — una cifra que suena rigurosa y repite lo que `p` ya dijo. Lo que sí decide algo es el **efecto mínimo detectable**: *"con n filas en k grupos y α = 0,05, este diseño detecta con potencia 0,80 una brecha ≥ X"*, que es lo único que distingue **"no hay efecto"** de **"no hay datos"** — y esa distinción era justo la que el backtest necesitaba y no tuvo.
*Corrección mínima propuesta*: «**Tamaño de muestra (filas y grupos) y tamaño de efecto mínimo detectable declarados, con el número: contra qué efecto, a qué α y a qué potencia. La potencia calculada con el efecto observado no cuenta.**»

**Por qué esto es `BLOCKED` y no un `MINOR` que arreglo yo**: son ítems normativos que el contract cierra y que van a generar ACs en cada ciclo de análisis futuro. Reescribirlos por mi cuenta sería cerrar una decisión que el contract ya cerró —la misma prohibición que §10.2 pone sobre inventar una mutación—. El costo de dejarlos como están no lo paga este ciclo: lo paga el primer análisis real que los cumpla al pie de la letra y llegue igual a una conclusión falsa. Es, además, el único punto ciego del review adversarial de este ciclo, porque **un ítem estadístico mal formulado no se detecta midiendo el plugin**: los cuatro defectos de plan anteriores se atraparon con un grep, un payload y un `git ls-tree`; éste sólo aparece el día que alguien lo aplica a un dataset.

### 2. Defecto hermano de AC42, medido: la regla `test-skipeado` tiene el mismo hueco

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
