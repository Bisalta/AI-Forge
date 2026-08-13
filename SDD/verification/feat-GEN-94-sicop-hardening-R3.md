# Verification Report — AGENT_r3 · R3 · prueba por mutación de todo AC que afirme detectar algo

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5) y de lo que el runner no puede saber. Lo escribe el implementing agent; lo audita el reviewer-agent.

- **Branch**: `feat-GEN-94-sicop-hardening`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v5**, sección R3 (AC19-AC24)
- **Brief**: `SDD/briefs/R3-mutation-rule.md`
- **Commit evaluado**: `aa4242c` — el commit del trabajo, sellado por el runner (R1)
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — el reporte generado lo registra con hash: `sha256:e96c7d0f61963400`. Copiado del encabezado del reporte, **no recalculado acá** (el reviewer lo recalcula por su cuenta, contract R5).
- **Momento de captura**: todas las salidas pegadas abajo se capturaron **después** del último cambio a los seis archivos que describen (`RT7`). El último cambio a un archivo del Delta fue la reversión de la mutación de AC23; después de eso sólo se tocaron este reporte y el brief.

---

## Gates — evidencia GENERADA (no escrita a mano)

- **Reporte generado**: `SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md` — 2026-08-13T20:09:27Z, `sdd-run-gates.sh v0.12.0`
- **Comando**: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md` · exit `0`
- **Resumen** (línea `sdd.gates` del runner, pegada tal cual):

```
{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md"}
```

- **Tree sellado**: `b2183cf004c81af123aa8e87628acc4ec70298b7` — LIMPIO. La evidencia se generó **después** del commit `aa4242c`, como exige el destino fuera de `.sdd/` (R1).
- Los 7 `[SKIPPED]` son los gates que `SDD/docs/doc_quality_gates.md` declara `N/A` con razón (format, type-check, integration, build, e2e, cobertura, smoke). Ninguno es un gate existente que no se corrió.
- Corridas rojas intermedias: no hubo corridas rojas del runner en este requerimiento; los rojos de este trabajo son los del test, registrados abajo con su comando y su exit code.

---

## Test escrito antes del cambio — corrida roja registrada

El test se escribió **antes** de tocar los cinco archivos normativos (T1.2 del brief), y se corrió contra el árbol sin el cambio.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| antes del cambio | `bash SDD/tests/test_mutation_rule.sh` | `1` | 33 de 41 asserts en rojo |
| después del cambio | `bash SDD/tests/test_mutation_rule.sh` | `0` | 41 de 41 `ok` |

Extracto de la corrida roja, pegado sin editar: las tres primeras líneas y la de cierre. La corrida completa son 41 líneas de assert (33 `FAIL` + 8 `ok`) más el cierre. El texto normativo aparece acá dentro del mensaje de falla del assert, que es evidencia de la corrida, no propagación de la norma:

```
  FAIL  AC19 quality-gates.md - existe la seccion 10 de prueba por mutacion — no encontré [## 10. Prueba por mutación (AC de detección)] en la salida
  FAIL  AC19 quality-gates.md - la seccion nombra el triple verde-rojo-verde — no encontré [verde → rojo → verde] en la salida
  FAIL  AC19 quality-gates.md - la seccion define las tres corridas del triple — no encontré [verde con el sistema intacto, rojo con la mutación aplicada, verde otra vez tras revertirla] en la salida
FAIL — 33 assert(s) fallaron
```

La corrida verde no imprime conteo: `test_summary` (`SDD/tests/lib.sh:71-78`) imprime `PASS` y devuelve 0. La cifra "41 asserts" se mide con su propio comando, y va con su salida:

```
$ bash SDD/tests/test_mutation_rule.sh | grep -c "^  ok"
41
$ bash SDD/tests/test_mutation_rule.sh | tail -1
PASS
$ bash SDD/tests/test_mutation_rule.sh >/dev/null 2>&1; echo "EXIT=$?"
EXIT=0
```

**Los 8 asserts que ya estaban verdes antes del cambio son exactamente los 8 de ausencia de AC23** — la evidencia directa de por qué AC23 necesita prueba por mutación: un chequeo de ausencia pasa mientras la frase que busca no exista en ningún lado. Es el control tautológico que este requerimiento existe para prohibir, medido sobre sí mismo.

---

## Prueba por mutación — AC23 (§10 de `quality-gates.md`, aplicada a este propio requerimiento)

**AC23 es el único AC de detección de R3**: su condición de aprobación es una ausencia ("ninguno de los cinco archivos recopia el texto normativo del triple"). Clasificación según el criterio de §10.1, forma 3 (ausencia). AC19, AC20, AC21, AC22 y AC24 afirman **presencia de contenido** en un archivo: caen en la lista de "no es de detección" (valor/artefacto producido) y quedan cubiertos por la corrida roja previa de arriba, que prueba que no pueden pasar vacíos.

**Mutación aplicada** (el contract no la declara literalmente; el brief sí, en su sección de AC — *"recopiá el texto normativo en uno de los cinco archivos, verificá el rojo, revertí"*): agregar el texto normativo del triple a `plugins/sdd-flow/agents/implementing-agent.md`, dentro de la viñeta del AC de detección.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_mutation_rule.sh` | `0` | 41/41 `ok` — verde |
| 2 | con la mutación aplicada | `bash SDD/tests/test_mutation_rule.sh` | `1` | 2 asserts en rojo |
| 3 | mutación revertida | `bash SDD/tests/test_mutation_rule.sh` | `0` | 41/41 `ok` — verde |

Salida de la corrida 2, pegada tal cual (las únicas dos líneas `FAIL` de esa corrida, más su cierre):

```
  FAIL  AC23 implementing-agent - no recopia el texto normativo del triple — esperado [no], obtenido [si]
  FAIL  AC23 implementing-agent - no recopia la forma corta del triple — esperado [no], obtenido [si]
FAIL — 2 assert(s) fallaron
```

Que el rojo sea **exactamente** de los dos asserts de ese archivo, y de ninguno más, es la parte que descarta que el rojo haya venido de otra cosa rota en el camino.

**Reversión verificada byte a byte** — el archivo mutado vuelve al mismo contenido, no a uno equivalente:

```
$ shasum -a 256 plugins/sdd-flow/agents/implementing-agent.md   # antes de la mutación
377ad222b0e3d283fb00267916883370508bd0efcfb9f2f88d12742417dde30c
$ shasum -a 256 plugins/sdd-flow/agents/implementing-agent.md   # después de revertir
377ad222b0e3d283fb00267916883370508bd0efcfb9f2f88d12742417dde30c
```

**Límite conocido de este control, declarado**: los asserts de ausencia de AC23 detectan la copia **literal** del texto normativo, no una paráfrasis. Está escrito en el encabezado del test. Una copia reescrita es un hallazgo de la Fase 2 del reviewer (criterio), no algo que un grep pueda decidir sin volverse ruidoso. La mutación probada es la copia literal, que es la forma en que el texto normativo se duplica en la práctica: alguien copia y pega.

---

## Cómo se midió cada cifra de este reporte

`RT8` — verificar cómo se mide antes de creerle a la medición. Las tres mediciones de este trabajo que dependen de cómo se enumeran los archivos:

| Cifra | Cómo se enumeró el conjunto | Límite |
|---|---|---|
| gate 2 (lint) verde sobre los `.sh` | **glob del gate**: `plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` — nunca `git ls-files` (`D8`) | el glob ve el archivo nuevo aunque no esté stageado; verificado: `for f in SDD/tests/*.sh; do echo "$f"; done \| grep -c test_mutation_rule.sh` → `1` |
| gate 9 (secret-scan) sobre 92 archivos | `git ls-files` (así lo hace `SDD/tests/secret-scan.sh:105`) | **no ve untracked**: la corrida previa al `git add` reportó `91 archivos` y **no** incluía `test_mutation_rule.sh`. Medido, no supuesto: se corrió antes (`91`) y después (`92`) de stagear |
| 41 asserts del test | conteo de líneas `ok` de la propia corrida (`grep -c '^  ok'`) | ninguno: es la salida del mismo proceso que se está midiendo |

Salida de las dos corridas del gate 9, pegadas tal cual:

```
$ bash SDD/tests/secret-scan.sh        # antes de git add
secret-scan: sin hallazgos sobre 91 archivos versionados (1 excluido: self)
$ git add … && bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 92 archivos versionados (1 excluido: self)
```

Gate 2, pegado tal cual (salida vacía = sin hallazgos):

```
$ shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh; echo "EXIT=$?"
EXIT=0
```

---

## Smoke manual

`N/A — ningún AC de R3 está declarado `manual-only` en el contract.`

---

## Impact set

El cambio es normativo (markdown) más un test. Los "callers" son los artefactos del plugin que consumen las reglas modificadas.

| Símbolo/regla cambiada | Caller | Cobertura |
|---|---|---|
| DoD ítem 5 (`quality-gates.md:19`) | `standards/archetypes.md:72` — el arquetipo `bugfix` exige la corrida roja citando §5 | sigue válido sin cambios: §5 conserva la viñeta de las dos corridas del bugfix, y §10.3 cierra explícito que **un bugfix no necesita una tercera corrida**. Verificado leyendo la línea, no supuesto |
| DoD ítem 5 | `commands/sdd-fixes.md:59` — mini-DoD de la vía corta (bugfix con corrida roja registrada) | sin cambios: la regla de bugfix que cita sigue vigente. **Hueco declarado abajo** (advisory 1) |
| §5 contrato de evidencia | `templates/verification-report.md:3` y `templates/coordination-README.md:119` | ambos referencian §4-§5 genéricamente, sin transcribir su contenido → no quedan desactualizados. **Hueco declarado abajo** (advisory 2) |
| §7.2 severidades | `agents/reviewer-agent.md:44` (tabla espejo de severidades) | actualizada en el mismo diff: las tres entradas nuevas (`BLOCKER` sin las tres corridas, `MAJOR` cifra sin salida, `MAJOR`/`MINOR` del hash del doc) están en las dos tablas, cubierto por 4 asserts del test |
| rama "hashes distintos" (`reviewer-agent.md:22`, R5) | ningún otro archivo la referencia (grep de `hallazgo propio` y `hashes distintos`: 1 sola aparición fuera de `SDD/`) | severidad nombrada + fila propia en §7.2; 4 asserts (`T3.2 …`) |
| sección `## Acceptance criteria` de `sdd-plan/SKILL.md` | `skills/sdd-plan/SKILL.md` self-review (mismo archivo) | agregado el chequeo `¿cada AC de detección tiene declarada su mutación…?`, cubierto por un assert |
| `SDD/tests/run.sh` (descubre `test_*.sh`) | el archivo nuevo entra a la suite | la suite completa corre 7 archivos, todos PASS (salida en el reporte generado) |

**Rojos preexistentes**: ninguno. Los 6 archivos de test que existían antes de este trabajo corren en mi propia corrida y salen los 6 `PASS` (bloque del gate 4 en el reporte generado) — es una medición de esta corrida, no una cita del reporte de R5.

---

## Hallazgos fuera de mi tabla de Files (advisory al planner — no los toqué)

Los tres salen del impact set y **ninguno se puede cerrar sin tocar archivos que el brief no me autoriza**. Los reporto en vez de resolverlos por mi cuenta, y en vez de omitirlos.

1. **`commands/sdd-fixes.md` (vía corta) no tiene quién declare la mutación.** §10.2 dice que la mutación la escribe el planner en el contract; `/sdd-fixes` es, por diseño, un carril sin contract ni reviewer. Un fix trivial con un AC de detección queda con la regla aplicable y sin el artefacto donde declararla. Decisión que no está en el contract: si la vía corta hereda la regla (y entonces el agente declara la mutación en el ítem del `fixes.md`), o si queda exceptuada explícitamente.
2. **`templates/verification-report.md` no tiene sección para el triple.** Tiene "Test de reproducción (sólo bugfix)"; el triple de un AC de detección no tiene fila. El template es archivo de R5, fuera de mi tabla de Files. Mientras tanto, este reporte agrega la sección a mano — que es exactamente la fricción que el template existe para evitar.
3. **`evals/golden-requirements.md` no chequea la mutación declarada.** Las propiedades universales U1-U8 no incluyen "cada AC de detección lleva su `Mutación:`", y varios goldens producen ACs de detección por definición (G1: 403/401/IDOR; G4: ítem veneno; G5: modos de falla). Con AC20 vigente, el eval del planner quedó corto. Candidato a `U9`.

---

## Decisiones que tomé dentro del contract (para el review)

Ninguna es una decisión nueva: son la aplicación de las cinco decisiones cerradas de R3. Las listo porque son las que un reviewer querría discutir.

1. **Ubicación de la sección**: `## 10` al final, sin renumerar nada. Renumerar hubiera roto las referencias `§4`, `§6`, `§7.1`, `§7.4` y `§9` repartidas por el plugin — **21 archivos**, incluidos dos ejecutables (`hooks/guard-git.sh`, `scripts/sdd-check.sh`):

```
$ grep -rlE "quality-gates\.md\`? §" plugins/ | wc -l
      21
```

   Verificado con grep antes de elegir la ubicación: no existía ninguna referencia a un `§10` previo (`grep -rn "§10" --include="*.md" .` sin resultados fuera de este trabajo).
2. **El criterio de §10.1 es enumerativo y cerrado** (4 formas que entran, 2 que no, desempate por partición del AC), en vez de una definición en prosa. Es la respuesta al riesgo declarado del brief: si el criterio admite dos lecturas, la regla triplica el costo de todos los ACs. El desempate ("un AC que cae en las dos listas se parte en dos") reusa la regla que §2 ya tenía, en vez de inventar una nueva.
3. **La regla de las cifras vive en §5** (contrato de evidencia), no en §10: aplica a toda cifra reportada, no sólo a las de una prueba por mutación. Los cuatro archivos propagados la referencian como §5 y referencian §10 por su título, que es lo que AC23 exige.
4. **En `write-pr-report/SKILL.md` había una colisión real**: la regla 3 prohíbe "listing raw commands" y la decisión 4 del contract exige adjuntar la salida de cada cifra. La resolví declarando la excepción explícita y su límite (cubre el bloque de salida que respalda una cifra, nunca la lista de comandos corridos) y sacando ese bloque del conteo de 150-300 palabras, para que el límite de largo no empuje a publicar un número pelado. Sin esa aclaración, dos personas leerían el archivo distinto.
5. **No importé los ajustes propuestos de `RT7` y `RT8` a `quality-gates.md`.** Son propuestas de la retro, no decisiones del contract v5, y el Delta de R3 enumera qué recibe §5. Los apliqué **a este reporte** (secciones "Momento de captura" y "Cómo se midió cada cifra"), que es donde sí me obligan.
