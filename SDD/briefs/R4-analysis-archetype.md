# Task brief — R4 · infra: arquetipo `analysis`

- **Agente**: `AGENT_r4` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v6**, sección `R4` (AC25-AC28)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening`
- **Proxima subtask id**: `2c091d58-67d3-49d6-88a6-26372bfc14ac` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R4.md`
- **Depende de**: R0, R1, R2, R5 y R3, los cinco `APPROVED`. Es el último requerimiento del ciclo.

## El problema, y por qué la causa es mecánica

Dos trabajos de SICOP no eran ciclos de código —un backtest sobre 19 ofertas y un barrido de consistencia documental— y los dos estuvieron a punto de mergearse sin review porque "no eran un ciclo". Los dos tenían conclusiones falsas.

El backtest concluía que *"el precio no es la palanca, la selección sí"*, apoyado en una brecha de 0,215 entre concursos ganados y perdidos. El review midió que la brecha **se invierte a −0,048** al excluir seis líneas con defecto de datos, **cuatro de ellas de un mismo concurso**. Y el test que la hubiera confirmado —permutación a nivel de concurso, que nunca se corrió— da **p = 0,533**. Nunca se distinguió del ruido, e iba a cambiar el diseño del producto.

**La causa no es cultural, es mecánica.** `plugins/sdd-flow/standards/archetypes.md` tiene nueve arquetipos y ninguno cubre trabajo cuyo producto es un número usado para decidir. `plugins/sdd-flow/skills/enrich-user-story/SKILL.md:92` fuerza exactamente uno y devuelve al refinement cualquier requerimiento sin arquetipo. Hoy un backtest **no puede entrar al pipeline aunque alguien quiera meterlo**.

El caso del barrido documental **no** necesita arquetipo: lo cubre AC24 de R3, que ya está escrito — corregir un artefacto aprobado es una corrección, no un tipo de trabajo nuevo.

## Decisión de diseño (cerrada en el contract — no la re-abras)

Décimo arquetipo `analysis`, con la misma estructura que los otros nueve: NFR obligatorias, tests exigidos, checklist→ACs. Cubre trabajo cuyo entregable es una conclusión o una cifra que alimenta una decisión, con producto en documentos o notebooks en vez de código de aplicación.

## Out of scope

- No toques los nueve arquetipos existentes. R4 es **aditivo**.
- No toques `scripts/`, `hooks/` ni `standards/quality-gates.md`.
- No reabras ningún AC de R0, R1, R2, R3 ni R5.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/standards/archetypes.md` | (mod) sección `analysis` entre `infra` y "Cómo lo usa el pipeline" |
| `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` | (mod) `analysis` entra a la lista de la dimensión 7 |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | (mod) el binding AC↔test admite la forma de evidencia de `analysis` |
| `SDD/tests/test_analysis_archetype.sh` | (NEW) |

## Contenido normativo del arquetipo

- **NFR obligatorias**: `observability` (la corrida que produce la cifra es reproducible por otro) y `data-privacy` cuando el dataset tiene PII.
- **Tests exigidos**: el test estadístico que **falsaría** la conclusión, corrido y reportado con su valor; más la re-derivación de cada cifra citada desde su fuente.
- **Checklist → ACs** (los siete, textuales del contract):
  1. Hipótesis nula declarada antes de mirar el resultado.
  2. El test que falsaría la conclusión, nombrado y corrido; su resultado se reporta gane o pierda.
  3. Toda cifra re-derivada desde la fuente, con la salida de la consulta adjunta.
  4. Sensibilidad declarada: qué pasa con la conclusión al excluir las filas defectuosas, y si las exclusiones se concentran en pocas unidades.
  5. Unidad de análisis declarada, y el test a esa unidad cuando las observaciones se agrupan.
  6. Tamaño de muestra y potencia declarados, con el número.
  7. La conclusión se escribe con su incertidumbre, no como afirmación categórica.

Cada ítem tiene que poder rastrearse al incidente que lo motiva. Los siete salen del backtest: el 2 es el test de permutación que nunca se corrió, el 4 son las seis líneas excluidas, el 5 son las cuatro de un mismo concurso, el 3 es la cifra citada sin re-derivar.

## Pasos

- [x] T1.1 Leer `archetypes.md` entero antes de tocarlo, y **respetar su forma**: los nueve existentes tienen exactamente NFR obligatorias · Tests exigidos · Checklist→ACs. El tuyo tiene que leerse como uno más, no como un anexo.
- [x] T1.2 Escribir `SDD/tests/test_analysis_archetype.sh` (AC25-AC28) con `SDD/tests/lib.sh`. **Corré el test antes del cambio**: tiene que salir ≠0. → corrida roja registrada: exit `1`, 31 de 37 asserts en rojo.
- [x] T2.1 La sección `analysis` en `archetypes.md`, entre `infra` y "Cómo lo usa el pipeline". → posición asserteada por número de línea, no a ojo.
- [x] T2.2 `enrich-user-story/SKILL.md`: `analysis` en la lista de arquetipos de la dimensión 7, y la rama de preguntas NFR que el arquetipo dispara.
- [x] T2.3 `sdd-plan/SKILL.md`: el binding AC↔test admite la forma de evidencia de `analysis` — un AC cuya evidencia es la salida de una consulta o un test estadístico, no un test unitario.
- [x] T3.1 Test verde. `bash SDD/tests/run.sh` completo (8 archivos). `shellcheck --severity=warning` en 0.
- [x] T3.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` — **commiteá primero, regenerá después**.
- [x] T3.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent`. → `4f17172`.

## Acceptance criteria (IDs del contract v6 — no los renumeres)

- **AC25** — `archetypes.md` contiene la sección `analysis` con las tres partes que tienen los otros nueve: NFR obligatorias, tests exigidos y checklist→ACs.
- **AC26** — La sección incluye los siete ítems de checklist del contenido normativo de arriba.
- **AC27** — `enrich-user-story/SKILL.md` incluye `analysis` en la lista de arquetipos de su dimensión 7.
- **AC28** — El total de arquetipos declarado en `archetypes.md` y en `enrich-user-story` coincide: **diez en ambos**. Verificable con grep.

**AC28 es el AC de detección de este requerimiento** — es de la forma "sensibilidad" de `quality-gates.md` §10.1: afirma que dos conteos coinciden. Un test que cuenta mal las **dos** listas de la misma forma equivocada da verde igual, y sigue dando verde el día que alguien agregue un arquetipo a un solo lado. Probalo por mutación: agregá un arquetipo falso a **uno** de los dos archivos, verificá el rojo, revertí. Registrá el triple con el formato nuevo de `templates/verification-report.md`.

## AC ↔ test binding (llenalo vos)

Todos los tests viven en `SDD/tests/test_analysis_archetype.sh`; el "nombre del caso" es el mensaje literal del assert (convención de `doc_quality_gates.md`).

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC25 | La sección `analysis` existe, con NFR obligatorias + tests exigidos + checklist→ACs, y en la posición que fija el Delta | `test_analysis_archetype.sh::"AC25 archetypes.md - existe la seccion del arquetipo analysis"` · `::"AC25 archetypes.md - la seccion analysis declara sus NFR obligatorias"` · `::"AC25 archetypes.md - la seccion analysis declara los tests exigidos"` · `::"AC25 archetypes.md - la seccion analysis tiene el checklist que entra como ACs"` · `::"AC25 archetypes.md - observability es NFR obligatoria del arquetipo analysis"` · `::"AC25 archetypes.md - data-privacy es NFR obligatoria cuando el dataset tiene PII"` · `::"AC25 archetypes.md - los tests exigidos incluyen el test que falsaria la conclusion"` · `::"AC25 archetypes.md - los tests exigidos incluyen la re-derivacion de cada cifra citada"` · `::"AC25 archetypes.md - la seccion analysis va entre infra y Como lo usa el pipeline"` | grep sobre el recorte de la sección (no sobre el archivo) | [x] |
| AC26 | El checklist tiene los siete ítems del contenido normativo, y exactamente siete | `test_analysis_archetype.sh::"AC26 archetypes.md - el checklist del arquetipo analysis tiene exactamente siete items"` · `::"AC26 item 1 - hipotesis nula declarada antes de mirar el resultado"` · `::"AC26 item 2 - el test que falsaria la conclusion nombrado y corrido"` · `::"AC26 item 2 - el resultado se reporta gane o pierda"` · `::"AC26 item 3 - toda cifra re-derivada desde la fuente con la salida adjunta"` · `::"AC26 item 4 - sensibilidad al excluir las filas defectuosas"` · `::"AC26 item 4 - si las exclusiones se concentran en pocas unidades"` · **(v8)** `::"AC26 item 5 - unidad de analisis Y unidad de agrupamiento declaradas con el numero de grupos"` · `::"AC26 item 5 - cuando las observaciones se agrupan la inferencia va a nivel del grupo"` · `::"AC26 item 5 - el reporte nombra la tecnica usada"` · `::"AC26 item 5 - la redaccion vieja autosatisfacible ya no esta"` · `::"AC26 item 6 - tamano de muestra en filas y grupos y efecto minimo detectable"` · `::"AC26 item 6 - el numero se declara contra un efecto, un alfa y una potencia"` · `::"AC26 item 6 - la potencia observada no cuenta"` · `::"AC26 item 6 - la redaccion vieja sin tamano de efecto ya no esta"` · `::"AC26 item 7 - la conclusion se escribe con su incertidumbre"` | grep sobre el bloque de checklist + conteo exacto + ausencia de la redacción vieja | [x] — ítems 5 y 6 en la redacción de v8; el `BLOCKED` de la ronda 1 quedó cerrado |
| AC27 | `enrich-user-story` lista `analysis` en la dimensión 7, con la rama de NFR que dispara | `test_analysis_archetype.sh::"AC27 enrich-user-story - la dimension 7 lista el arquetipo analysis"` · `::"AC27 enrich-user-story - observability del arquetipo analysis es que la corrida sea reproducible por otro"` | grep sobre la línea de la dimensión, no sobre el archivo | [x] |
| AC28 | Los dos totales coinciden en diez, y las dos listas nombran los mismos arquetipos | `test_analysis_archetype.sh::"AC28 archetypes.md - declara diez arquetipos"` · `::"AC28 enrich-user-story - la dimension 7 lista diez arquetipos"` · `::"AC28 - el total de arquetipos coincide entre archetypes.md y enrich-user-story"` · `::"AC28 - las dos listas nombran exactamente los mismos diez arquetipos"` | **AC de detección** (sensibilidad §10.1) — triple registrado, dos mutaciones (una por lado) | [x] |
| AC42 (v8) | `sdd-check.sh` no levanta `BLOCKER` de supresor **ni de `test-skipeado`** sobre un `.md`, y sigue levantando los dos sobre código | `test_analysis_archetype.sh::"AC42 sdd-check.sh - no reporta supresor sobre un archivo .md"` · `::"AC42 sdd-check.sh - sale 0 cuando el unico supresor del diff esta en un .md"` · `::"AC42 sdd-check.sh - un supresor en un archivo de codigo sigue siendo BLOCKER"` · `::"AC42 sdd-check.sh - sale 2 cuando hay un supresor en un archivo de codigo"` · **(v8)** `::"AC42 sdd-check.sh - no reporta test-skipeado sobre un archivo .md"` · `::"AC42 sdd-check.sh - sale 0 cuando el unico test skipeado del diff esta en un .md"` · `::"AC42 sdd-check.sh - un test skipeado en un archivo de codigo sigue siendo BLOCKER"` · `::"AC42 sdd-check.sh - sale 2 cuando hay un test skipeado en un archivo de codigo"` · `::"AC42 sdd-check.sh - el guard no saltea el archivo .md entero, solo las dos reglas"` · `::"AC42 sdd-check.sh - un WARN sobre .md no cambia el exit code"` · `::"AC42 sdd-check.sh - la prosa que enumera las mitigaciones prohibidas no levanta ningun BLOCKER"` · `::"AC42 sdd-check.sh - sale 0 sobre un .md que enumera supresores y tests skipeados"` | **AC de detección** (rechazo §10.1) — 3 triples registrados (los 2 declarados + 1 adicional contra el guard sobre-ensanchado); las dos direcciones probadas | [x] |
| (impact set) | El README del plugin —tercera declaración de la lista— no queda desactualizado | `test_analysis_archetype.sh::"IMPACT plugin README - el total de arquetipos declarado es diez"` · `::"IMPACT plugin README - la lista de arquetipos incluye analysis"` | grep; fuera de AC28, que nombra dos archivos | [x] |
| (T2.3) | El binding AC↔test admite la evidencia del arquetipo `analysis` | `test_analysis_archetype.sh::"T2.3 sdd-plan - la regla habla del binding AC-test del arquetipo analysis"` · `::"T2.3 sdd-plan - la evidencia admite la salida de la consulta que re-deriva la cifra"` · `::"T2.3 sdd-plan - la evidencia admite la corrida del test estadistico"` | grep | [x] |

## Reglas innegociables

Las de siempre, y ahora **son norma escrita** gracias a R3: leé `plugins/sdd-flow/standards/quality-gates.md` §10 antes de arrancar, porque es la regla que acabás de heredar y te aplica.

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe** (`RT7`).
- **Verificá cómo se mide antes de creerle a la medición** (`RT8`; cuatro incidentes en este ciclo, uno del planner).
- **No verifiques lint con `git ls-files`** (`D8`). Usá el glob del gate.
- Literales con forma clave-valor, **partidos**, o el gate 9 se pone rojo.
- Ninguna exclusión por path para hacer pasar un gate.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner. Cuatro de los cinco requerimientos anteriores encontraron un defecto de plan; si ves uno, decilo.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Riesgo declarado

Este arquetipo es el único del plugin cuyo checklist es **estadístico**, y el planner que lo escribió no es estadístico. Si un ítem está mal formulado —por ejemplo si el 5 confunde unidad de análisis con unidad de muestreo— el arquetipo va a producir ACs que suenan rigurosos y no lo son, que es el modo de falla exacto que el ciclo entero ataca. Leé los siete con esa desconfianza y **marcá BLOCKED** si alguno no se sostiene.

## Rollback

`git revert`. Aditivo: los nueve arquetipos existentes no cambian.

## Execution Report

- **Summary**: décimo arquetipo `analysis` agregado a `archetypes.md` con la misma forma que los otros nueve (NFR obligatorias · Tests exigidos · Checklist→ACs, los siete ítems textuales del contract), propagado a `enrich-user-story` (dimensión 7 + rama NFR), a `sdd-plan` (evidencia admitida en el binding AC↔test) y al README del plugin (tercera declaración de la lista, fuera de la tabla de Files, declarada en el reporte). Tarea extra AC42: la regla de supresores de `sdd-check.sh` gana el guard de `.md` que la regla de al lado ya tenía — 16 `BLOCKER` falsos sobre `.md` en el diff de esta branch pasan a 0, con la detección real sobre código intacta. Test nuevo con 37 asserts, corrida roja previa registrada, y los tres triples de mutación (AC28 por los dos lados, AC42).
- **Task status**: 11 de 11 tareas `[x]` (T1.1-T1.2, T2.1-T2.3, T3.1-T3.3, T4.1-T4.3). 0 `[BLOCKED]` a nivel tarea; el `BLOCKED` es de **contenido normativo**, ver Blockers.
- **Validation executed** (comando · exit code): ver `SDD/verification/feat-GEN-94-sicop-hardening-R4.md`, que referencia el reporte generado `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` (`sdd-run-gates.sh --full`, exit `0`, `{"green":4,"red":0,"skipped":7}`, commit `4f17172`, árbol LIMPIO). No lo duplico acá.
- **Blockers**: **los ítems 5 y 6 del checklist del arquetipo no se sostienen estadísticamente** — el ítem 5 no obliga a que la unidad declarada sea aquella en la que las observaciones son independientes (se cumple corriendo el test al nivel equivocado, que es el error del incidente), y el ítem 6 pide "potencia con el número" sin decir contra qué tamaño de efecto (invita a la potencia observada, que es una transformación monótona del p-valor). Los escribí **textuales del contract** —desviarme sería infidelidad, `BLOCKER` de review— con la corrección mínima propuesta para v8 en el verification report. También quedan para el planner: el defecto hermano de AC42 en la regla `test-skipeado` (medido: 2 hits sobre documentos del propio plugin) y `evals/golden-requirements.md`, que queda con diez arquetipos y nueve goldens.
- **Files changed**: `plugins/sdd-flow/standards/archetypes.md` · `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` · `plugins/sdd-flow/skills/sdd-plan/SKILL.md` · `plugins/sdd-flow/README.md` · `plugins/sdd-flow/scripts/sdd-check.sh` · `SDD/tests/test_analysis_archetype.sh` (NEW) · `SDD/verification/feat-GEN-94-sicop-hardening-R4.md` (NEW) · `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` (NEW, generado) · este brief.
- **Final statement**: los cinco ACs (AC25-AC28 + AC42) tienen test y están verdes; los dos de detección tienen sus tres corridas registradas con exit codes y reversión verificada byte a byte. La escalera corrió completa en verde sobre el árbol limpio del commit `4f17172`. Entrego **`blocked`** y no `done` porque el brief pide explícitamente marcar BLOCKED si un ítem del checklist no se sostiene, y dos no se sostienen: prefiero devolver el arquetipo con dos cláusulas por ratificar antes que publicar un checklist que suene riguroso y no lo sea, que es el modo de falla que este ciclo entero ataca.

## Tarea extra — estado

- [x] T4.1 Guard de `.md` en la regla de supresores (única línea tocada de `scripts/`).
- [x] T4.2 AC42 probado por mutación: triple registrado (verde `0` → rojo `1` con el guard quitado → verde `0` revertido), con `shasum` idéntico antes y después.
- [x] T4.3 La detección real sigue viva: caso propio con `assert_exit 2` sobre un supresor en un archivo de código, más el caso de que el guard no ensancha a otras reglas.

## Ronda 2 — contract v8

- [x] T5.1 Ítems 5 y 6 de `archetypes.md` en la redacción de v8, con la razón medida escrita al lado (por qué la redacción anterior era autosatisfacible). Asserts nuevos **más** la ausencia de la redacción vieja, con la corrida roja que prueba que esa ausencia no es tautológica.
- [x] T5.2 AC42 ampliado: el guard de `.md` también en la regla `test-skipeado`. **Las dos direcciones probadas** — el falso positivo sobre `.md` desaparece (2 → 0 medido sobre este repo) y un test realmente skipeado en un archivo de código sigue siendo `BLOCKER`. Caso extra que distingue el guard de dos reglas de "saltear el `.md` entero", con su propia mutación.
- [x] T5.3 Evidencia regenerada (commit `2d63f8e` primero) y binding actualizado. Los cinco triples se **re-corrieron enteros** contra el archivo de test final (`RT7`).
- [x] T6.1 (ronda 3) Evidencia **regenerada con árbol limpio**, sin `--allow-dirty`, tras el commit `e643508` del planner: exit `0`, commit `e643508`, tree `4bc4d3b2…` LIMPIO. Sin cambios de código ni de tests en esta ronda.
- [x] T5.4 `evals/golden-requirements.md` **no tocado** — queda como deuda `D9` por instrucción del planner.

**Execution Report de la ronda 2** — Summary: los dos ítems estadísticos quedan en la redacción de v8 y AC42 cubre las dos reglas con el mismo hueco; 48 asserts, 12 rojos previos al cambio, 5 triples de mutación. Task status: 4/4. Validation executed: `sdd-run-gates.sh --full --allow-dirty` exit `0`, `{"green":4,"red":0,"skipped":7}`, commit `2d63f8e` (la bandera fue por `SDD/retro.md`, modificado sin commitear **por el planner**, que el brief me prohíbe tocar; el runner estampó él mismo cuál era el archivo). Blockers: ninguno — el de la ronda 1 quedó cerrado por v8. Observación `MINOR`: el Architectural Delta de v8 describía de menos la fila de `sdd-check.sh`.

**Execution Report de la ronda 3** — Summary: sin cambios de código ni de tests; se regenera la evidencia con **árbol limpio** tras el commit `e643508` del planner, que cerró las dos cosas que la ronda 2 dejó abiertas (el `SDD/retro.md` sin commitear y la fila del Delta). Task status: 1/1. Validation executed: reporte generado `…-R4-gates.md`, `sdd-run-gates.sh --full` **sin banderas de degradación**, exit `0`, `{"green":4,"red":0,"skipped":7}`, commit `e643508`, tree `4bc4d3b2fe3913acd664d4b1be8723d4bc625d54` LIMPIO, doc de gates `sha256:e96c7d0f61963400` (el mismo de las tres rondas). Blockers: ninguno. Files changed: sólo evidencia y este brief.

---

## Tarea extra — AC42 (agregada en contract v7, del review de R3)

`plugins/sdd-flow/scripts/sdd-check.sh` levanta un `BLOCKER` falso sobre archivos `.md`: la regla de supresores no tiene el guard `file !~ /\.md$/` que **sí** tiene la regla del flag de bypass de hooks, en el mismo script. Resultado medido por el reviewer: `sdd-check.sh e5ef90c` sale 2 porque el `@ts-ignore` que enumera las mitigaciones **prohibidas** en `commands/sdd-fixes.md` dispara la regla — sobre un texto que existía desde antes del diff.

Un checker que se pone rojo sobre la prosa que describe lo que prohíbe entrena al equipo a ignorarlo, y va a reaparecer en cada diff futuro que toque esa línea.

- [ ] T4.1 Agregar el mismo guard de `.md` a la regla de supresores. **Es la única línea que tocás de `scripts/`** — el resto del out-of-scope sigue en pie.
- [ ] T4.2 **AC42 es de detección** (forma "rechazo" de §10.1): probalo por mutación. Quitá el guard recién agregado, verificá que el `BLOCKER` falso reaparece, revertí. Registrá el triple con el formato de `templates/verification-report.md`.
- [ ] T4.3 Verificá que el guard **no** apague la detección real: un supresor en un archivo de código sigue siendo `BLOCKER`. Sin eso, el fix es un ablandamiento disfrazado de guard.

**Aviso operativo**: `guard-git.sh` rechaza cualquier comando cuyo texto contenga el literal del flag de bypass de hooks, aunque esté en prosa. Al escribir el mensaje de commit de esta tarea, evitá el literal o construilo en runtime. Es la misma clase que AC42, en la otra herramienta mecánica del plugin, y ya mordió al planner y al reviewer.
