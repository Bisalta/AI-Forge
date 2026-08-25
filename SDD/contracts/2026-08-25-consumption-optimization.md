# HLTC — sdd-flow · optimización de consumo (GEN-101)

**Versión**: v3 · **Fecha**: 2026-08-25 · **Planner**: Opus 5
**Estado**: auto-aprobado (modo multi-agente, `sdd-plan` Fase A)
**Branch**: `refactor-GEN-101-optimizacion-consumo` · base `origin/prod`

## Ratificaciones

- **v3** (durante la ejecución de R4, disparada por AC6): el chequeo de `concerns:` sólo
  aceptaba la forma YAML, y el contract de GEN-94 declara sus concerns en prosa
  (`**Concerns** (...)`, línea 42). Con la regla de v2, un contract válido y ya aprobado
  habría salido `BLOCKER` — el defecto de `SDD/debt.md` D10/D11: una herramienta que se pone
  roja sobre lo que debe aceptar entrena a ignorar su exit code. Se aceptan ambas formas.
  **AC6 pagó su costo**: es el único AC que corre contra un artefacto real que nadie escribió
  para este test, y es el que encontró el falso positivo.

- **v2** (self-review del planner, antes de despachar): los tres archivos de test se
  nombraban `SDD/tests/<cosa>.sh`, pero `SDD/tests/run.sh:32` descubre por glob
  `test_*.sh`. Con el nombre original ningún test habría sido ejecutado por el gate 4
  y la suite habría salido verde sin correrlos — un verde falso, la clase de
  `SDD/retro.md` RT8. Renombrados a `test_lint_contract_sections.sh`,
  `test_model_tier_policy.sh` y `test_context_budget.sh`. Defecto de plan detectado
  antes de costar una ronda, que es exactamente lo que R4 automatiza.

## Objective

Bajar el consumo de tokens de un ciclo `/sdd` atacando las tres palancas medidas en
`docs/specs/2026-08-25-consumption-optimization-design.md`, en el orden en que pagan:
rondas evitadas (escalón), contexto no cargado (lineal × turnos) y tier de modelo
(lineal × tokens).

## Out of scope

- **Seccionar `quality-gates.md`, `archetypes.md` y `concerns.md`** (R5 del diseño). Bloqueado
  a la espera de revisión externa. Ningún AC de este contract se satisface tocando esos tres
  archivos, salvo `archetypes.md` para agregar una fila de tabla en R3.
- **Disciplina de sesiones en paralelo** (palanca D). Es workflow, no código.
- **Bajar el tier del reviewer-agent o del planner.** Decisión cerrada en contra: en GEN-94
  seis de ocho defectos fueron del plan, y ambos roles son el detector.
- **CI del repo** (deuda D1, dueño Gabriel). Los gates corren local.

## Source of truth

- `docs/specs/2026-08-25-consumption-optimization-design.md` — medición y jerarquía.
- `SDD/retro.md` RT1, RT2, RT9, RT11 — los defectos que R4 previene.
- `plugins/sdd-flow/standards/quality-gates.md` §10 — régimen de prueba por mutación.
- `SDD/docs/doc_quality_gates.md` — escalera de gates con los comandos reales del repo.

## Threat model

`N/A — no cambia superficie invocable.` Ningún requerimiento agrega endpoint, comando,
job ni webhook. `sdd-lint-contract.sh` gana un chequeo pero conserva su superficie actual
(argv: contract + repo-root opcional) y sigue sin escribir nada. No hay actor nuevo, no hay
dato de nadie en juego, y el peor input hostil es un contract mal formado — que es
precisamente lo que el script existe para reportar, no para ejecutar.

```
concerns:
  security:       n/a — no cambia superficie invocable ni toca datos (ver Threat model)
  observability:  n/a — script CLI síncrono, sin estado ni ejecución desatendida; su salida ES la observabilidad
  performance:    n/a — sin número declarado; el linter corre sobre un archivo de decenas de KB
  a11y:           n/a — sin UI
  design:         n/a — sin UI
  data-privacy:   n/a — no procesa datos personales
  api-compat:     blocking — sdd-lint-contract.sh y sdd-run-gates.sh son consumidos por CI de
                  terceros repos vía --version; la superficie de argv y los exit codes no se rompen
  i18n:           n/a — herramienta interna, un solo locale
  seo:            n/a — sin frontend
```

## Orden de integración

Repo único. Orden por dependencia lógica, no por repo: **R4 → R2 → R3 → R1**. R1 mide el
efecto de los otros tres, así que va último aunque sea el primero en el diseño.

---

# R4 — El linter detecta secciones obligatorias ausentes

## Problema

`sdd-lint-contract.sh` v0.10.0 hace dos chequeos: frases abiertas y paths inexistentes.
Ninguno mira si el contract **tiene** las secciones que los standards declaran obligatorias.
Por eso, en GEN-94, un contract sin threat model se auto-aprobó (`SDD/retro.md` RT1) y el
defecto se descubrió recién en la ronda 1 del review — una ronda entera, del orden de los
300k tokens, por una sección ausente que un `grep` detecta.

## Decisión de diseño (cerrada)

**La lista de secciones obligatorias es cerrada y enumerativa**, con dos ámbitos:

| Ámbito | Sección | Fuente normativa |
|---|---|---|
| contract | `Objective` | `sdd-plan` Fase A |
| contract | `Out of scope` | `sdd-plan` Fase A |
| contract | `Threat model` | `standards/security.md` §6 |
| contract | bloque `concerns:` | `standards/concerns.md` |
| requerimiento | `Architectural Delta` | `sdd-plan` Fase A |
| requerimiento | `Acceptance criteria` | `sdd-plan` Fase A |
| requerimiento | `Checklist del arquetipo` | `standards/archetypes.md` |

**Un requerimiento** es un bloque que abre con un encabezado `# R<dígitos>` en nivel H1.
Si el contract no tiene ninguno, el documento entero cuenta como un requerimiento único y
las tres secciones de ámbito requerimiento se buscan a nivel de contract.

**Severidad `BLOCKER` y exit 2**, el mismo camino que las frases abiertas: una sección
obligatoria ausente es exactamente la clase de defecto que el exit 2 significa. No se
agrega un exit code nuevo — `api-compat` es blocking en este contract.

**El match del encabezado es por prefijo, case-insensitive, sobre el texto del encabezado
tras quitar `#` y espacios.** El contract real anota los encabezados (`## Threat model
(security.md §6)`), así que exigir igualdad exacta produciría un falso BLOCKER. `Checklist
del arquetipo` matchea por prefijo porque cada requerimiento lo sufija con su arquetipo.

**La declaración de concerns se detecta en sus dos formas reales**, sobre el archivo entero
(no sobre el stream que saltea cercas): el bloque `concerns:` YAML que produce
`enrich-user-story` —que vive dentro de una cerca— y la prosa `**Concerns** (...)` que usa un
contract escrito a mano. Se toleran los marcadores de lista y encabezado al principio de la
línea (`-`, `#`, `*`). El chequeo es de **presencia de la declaración, no de su sintaxis**.

**Los encabezados, en cambio, se acumulan sólo FUERA de cercas de código.** Si contaran
adentro, un contract podría declarar una sección obligatoria dentro de un ejemplo y pasar el
chequeo sin tenerla.

**`N/A` declarado cuenta como presente.** El chequeo es de presencia de la sección, no de su
contenido: `## Threat model` seguido de `N/A — no cambia superficie invocable` está bien y
así está escrito arriba en este mismo contract. Verificar que el `N/A` sea legítimo es
trabajo del reviewer, no del linter.

## Architectural Delta

`plugins/sdd-flow/scripts/sdd-lint-contract.sh` — versión `0.10.0` → `0.11.0`.

1. **Dos pasadas, no una.** El bucle actual es una pasada por línea que decide sobre esa
   línea sola. La presencia de una sección es una propiedad del archivo, no de una línea, así
   que se acumulan los encabezados vistos durante el bucle existente y **el veredicto se emite
   después del bucle**. No se agrega una segunda lectura del archivo.
2. **Ubicación del bloque nuevo**: el reporte de secciones ausentes se emite tras el `done <
   "$CONTRACT"` y **antes** del `[ "$BLOCKERS" -gt 0 ] && exit 2` final. La ubicación se declara
   por la condición que debe valer al ejecutarse — que el archivo esté leído entero y que
   `BLOCKERS` todavía no se haya consultado — y no por qué bloque tiene al lado (`SDD/retro.md` RT9).
3. **La acumulación de encabezados ocurre antes del `continue` de bloque de código**, para que
   un encabezado nunca se pierda; y la de `concerns:` antes del filtro de líneas-que-citan-la-regla.
4. El comentario de cabecera pasa a describir tres chequeos, no dos.

## Acceptance criteria

| # | Criterio |
|---|---|
| AC1 | Un contract sin `## Threat model` produce una línea `BLOCKER<TAB>0<TAB>seccion-ausente<TAB>Threat model` y exit 2. |
| AC2 | Un contract al que le falta cada una de las 4 secciones de ámbito contract produce 4 líneas `seccion-ausente`, una por sección, y exit 2. |
| AC3 | Un contract con dos bloques `# R<n>` donde el segundo no tiene `## Acceptance criteria` produce una línea `seccion-ausente` que nombra el requerimiento (`R1`) y la sección, y exit 2. |
| AC4 | Un contract sin ningún `# R<n>` al que le falta `## Architectural Delta` produce `seccion-ausente` — el documento entero cuenta como un requerimiento. |
| AC5 | Este mismo contract (`SDD/contracts/2026-08-25-consumption-optimization.md`) sale exit 0: cero `seccion-ausente`. Es el caso positivo que prueba que el chequeo no marca lo sano. |
| AC6 | El contract de GEN-94 (`SDD/contracts/2026-08-13-sicop-hardening.md`), que está completo, no produce ninguna línea `seccion-ausente`. Regresión sobre un artefacto real que nadie escribió para este test. |
| AC7 | `## Threat model (standards/security.md §6)` cuenta como presente — el sufijo anotado no produce falso BLOCKER. |
| AC8 | `sdd-lint-contract.sh --version` imprime `sdd-lint-contract 0.11.0` y sale 0. La superficie de argv no cambia (concern `api-compat`). |
| AC9 | Un contract con frase abierta **y** sección ausente reporta ambas y sale 2 una sola vez. |

**AC de detección** (`quality-gates.md` §10): AC1, AC2, AC3, AC4, AC6, AC9 afirman que el
linter **detecta** algo. Cada uno exige el triple verde → rojo → verde, con esta mutación
declarada por el planner:

> **Mutación (AC1, AC2, AC3, AC4, AC9)**: en `sdd-lint-contract.sh`, vaciar la lista de
> secciones obligatorias de ámbito contract y de ámbito requerimiento (dejar ambas cadenas
> vacías) · en el bloque nuevo, tras el bucle · queda revertida al valor completo.
> Las tres corridas del triple **deben distinguirse entre sí** en su salida o su exit code;
> tres corridas idénticas no son un triple sino una medición muerta (`SDD/retro.md` RT11).

> **Mutación (AC6)**: en el fixture de regresión, invertir el sentido — se corre el linter
> contra el contract de GEN-94 con la lista de secciones obligatorias **ampliada** con una
> sección inventada (`## Seccion Que No Existe`) · en la lista de ámbito contract · queda
> revertida. El rojo prueba que el chequeo mira de verdad ese archivo.

**AC5 y AC7 no son de detección**: afirman ausencia de falso positivo, y su condición de
aprobación es un exit 0 observable. AC8 tampoco: afirma una cadena de salida.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC1 | `SDD/tests/test_lint_contract_sections.sh` → `test_falta_threat_model` |
| AC2 | `SDD/tests/test_lint_contract_sections.sh` → `test_faltan_las_cuatro_de_contract` |
| AC3 | `SDD/tests/test_lint_contract_sections.sh` → `test_requerimiento_sin_acceptance_criteria` |
| AC4 | `SDD/tests/test_lint_contract_sections.sh` → `test_sin_bloques_R_documento_entero` |
| AC5 | `SDD/tests/test_lint_contract_sections.sh` → `test_este_contract_sale_limpio` |
| AC6 | `SDD/tests/test_lint_contract_sections.sh` → `test_regresion_contract_gen94` |
| AC7 | `SDD/tests/test_lint_contract_sections.sh` → `test_encabezado_anotado_no_falsea` |
| AC8 | `SDD/tests/test_lint_contract_sections.sh` → `test_version_bump_y_argv` |
| AC9 | `SDD/tests/test_lint_contract_sections.sh` → `test_frase_abierta_y_seccion_ausente` |

## Checklist del arquetipo `infra`

| Ítem | Estado |
|---|---|
| Cambio idempotente / re-ejecutable | Cumplido — el script es de solo lectura, sin estado |
| Rollback declarado | Cumplido — `git revert` del commit; ningún consumidor persiste su salida |
| Efecto sobre consumidores existentes declarado | Cumplido — concern `api-compat` blocking; AC8 fija argv y `--version` |
| Config nueva documentada | `N/A` — no agrega variables de entorno ni flags |
| Corre en el entorno destino | Cumplido — `bash`/`zsh` en macOS y Linux; sin dependencias nuevas |

---

# R2 — El plugin declara tier, nunca versión

## Problema

La prosa del plugin nombra `Opus 4.8` y `claude-opus-4-8` en cinco lugares. En runtime no
tiene efecto — los agents usan alias de tier (`model: opus`) que resuelven al último de cada
tier — pero le enseña a todo lector que el plugin corre en un modelo que ya no es el último.
`skills/sdd-plan/SKILL.md:8` es el peor caso: escribe el ID pinneado a mano.

## Decisión de diseño (cerrada)

**Se borran los identificadores de versión de modelo de la prosa y no se reemplazan por otros.**
Escribir `claude-opus-5` reproduce el defecto con otra versión encima. Donde la prosa hoy dice
"Opus 4.8" pasa a decir "Opus"; donde dice "Sonnet 4.6", "Sonnet". El alias de tier en el
frontmatter de los agents queda **exactamente como está** — es el mecanismo correcto y ya
funciona.

**La regla se escribe una vez**, en `plugins/sdd-flow/standards/base-standards.md`, con esta
forma: *el plugin declara tier (`opus` · `sonnet` · `haiku`), nunca versión. Un ID de modelo
con número de versión en cualquier archivo del plugin es un defecto.*

**`CLAUDE.md` del repo entra en el scope.** Su sección Convenciones fija los tres IDs pinneados
y la línea `Co-Authored-By: Claude Opus 4.8`, que es la misma clase de defecto.

## Architectural Delta

| Archivo | Cambio |
|---|---|
| `plugins/sdd-flow/standards/base-standards.md` | Sección nueva «Modelos» con la regla tier-nunca-versión |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | Línea 8: quitar `Opus 4.8` y `claude-opus-4-8` |
| `plugins/sdd-flow/commands/sdd.md` | Línea 8: «planner Opus 4.8» → «planner Opus» |
| `plugins/sdd-flow/README.md` | Líneas 5 y 59: quitar la versión |
| `plugins/sdd-flow/.claude-plugin/plugin.json` | `description`: quitar la versión |
| `CLAUDE.md` | Convenciones: la regla de tier y el `Co-Authored-By` sin versión |

## Acceptance criteria

| # | Criterio |
|---|---|
| AC10 | `grep -rniE 'opus 4\.8\|sonnet 4\.6\|claude-opus-4-8\|claude-sonnet-4-6' plugins/ CLAUDE.md` no devuelve ninguna línea fuera de `CHANGELOG.md` y `docs/specs/`. |
| AC11 | `base-standards.md` contiene la regla tier-nunca-versión en una sección propia. |
| AC12 | El frontmatter de `implementing-agent.md` sigue siendo `model: sonnet` y el de `reviewer-agent.md` `model: opus`, sin cambios. |

**Mutación (AC10)**: reintroducir el literal `Opus 4.8` en `plugins/sdd-flow/README.md` ·
línea 5 · queda revertido.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC10 | `SDD/tests/test_model_tier_policy.sh` → `test_sin_versiones_pinneadas` |
| AC11 | `SDD/tests/test_model_tier_policy.sh` → `test_regla_documentada` |
| AC12 | `SDD/tests/test_model_tier_policy.sh` → `test_alias_de_tier_intactos` |

## Checklist del arquetipo `refactor`

| Ítem | Estado |
|---|---|
| El comportamiento observable no cambia | Cumplido — la prosa no tiene efecto en runtime; los alias no se tocan (AC12) |
| Cobertura previa al cambio | Cumplido — AC12 fija el estado que no debe moverse |
| Sin cambio de interfaz pública | Cumplido — `plugin.json` cambia solo `description` |
| Alcance acotado y declarado | Cumplido — los 6 archivos del Delta |

---

# R3 — Haiku entra donde el contexto es chico

## Problema

El slot `haiku si trivial` existe en `sdd-plan` desde v0.1 y **nunca se usó**: en GEN-94 los
seis agentes fueron `sonnet`×4 y `opus`×2. El criterio de «trivial» no está escrito, así que
el planner no tiene con qué decidir y cae al default. Y ningún skill declara `model:` en su
frontmatter, aunque tres de ellos son mecánicos y de contexto acotado.

## Decisión de diseño (cerrada)

**Tres skills pasan a `model: haiku` en frontmatter**: `write-pr-report`, `sdd-status` y el
triage de `sdd-fixes`. Los tres leen poco, no deciden arquitectura y su salida es verificable
de un vistazo.

**El criterio de «brief trivial» se escribe cerrado y enumerativo** en `standards/archetypes.md`.
Un brief es trivial cuando cumple **las cuatro** condiciones: toca ≤2 archivos · no agrega
dependencias · su arquetipo es `refactor`, `infra` o `bugfix` · y ninguno de sus ACs es de
detección. Si falla una, no es trivial. La duda resuelve a no-trivial.

**El reviewer no baja de Opus** y el planner tampoco. Cerrado en Out of scope.

## Architectural Delta

| Archivo | Cambio |
|---|---|
| `plugins/sdd-flow/skills/write-pr-report/SKILL.md` | `model: haiku` en frontmatter |
| `plugins/sdd-flow/skills/sdd-seo/SKILL.md` | sin cambio — audita, no reporta |
| `plugins/sdd-flow/commands/sdd-status.md` | `model: haiku` en frontmatter |
| `plugins/sdd-flow/standards/archetypes.md` | Fila nueva: criterio de brief trivial (4 condiciones) |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | Línea 83: apuntar al criterio en vez de decir «si trivial» |

## Acceptance criteria

| # | Criterio |
|---|---|
| AC13 | `write-pr-report/SKILL.md` y `commands/sdd-status.md` tienen `model: haiku` en frontmatter, parseable como YAML. |
| AC14 | `archetypes.md` contiene las cuatro condiciones de trivialidad, enumeradas. |
| AC15 | `sdd-plan/SKILL.md` línea del modelo asignado referencia el criterio de `archetypes.md` y no contiene la palabra suelta «trivial» sin su definición. |
| AC16 | `reviewer-agent.md` sigue en `model: opus`. Regresión sobre la decisión cerrada en contra. |

**Mutación (AC16)**: cambiar `model: opus` a `model: haiku` en `reviewer-agent.md` ·
frontmatter línea 4 · queda revertido.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC13 | `SDD/tests/test_model_tier_policy.sh` → `test_skills_mecanicos_en_haiku` |
| AC14 | `SDD/tests/test_model_tier_policy.sh` → `test_criterio_trivial_enumerado` |
| AC15 | `SDD/tests/test_model_tier_policy.sh` → `test_sdd_plan_referencia_criterio` |
| AC16 | `SDD/tests/test_model_tier_policy.sh` → `test_reviewer_sigue_en_opus` |

## Checklist del arquetipo `refactor`

| Ítem | Estado |
|---|---|
| El comportamiento observable no cambia | **No cumplido, y es intencional** — tres skills cambian de modelo. El comportamiento que no cambia es el del reviewer y el planner (AC16) |
| Cobertura previa al cambio | Cumplido — AC16 fija lo que no se mueve |
| Sin cambio de interfaz pública | Cumplido — el frontmatter no es superficie de invocación |
| Alcance acotado y declarado | Cumplido — los 5 archivos del Delta |

---

# R1 — Instrumentar el consumo

## Problema

Los ratios de desperdicio están medidos; el ahorro no. Nadie sabe cuántos turnos vive cada
contexto, así que el efecto de R2, R3 y R4 no se puede afirmar — sólo estimar. Un ciclo que
existe para bajar el consumo y no lo mide reproduce exactamente la clase de defecto que
GEN-94 encontró cinco veces: la medición que no mide lo que dice medir.

## Decisión de diseño (cerrada)

**El entregable es un script que cuenta tokens de contexto estático por rol**, no una
integración con el panel de uso. `SDD/scripts/sdd-context-budget.sh` recibe un rol
(`planner` · `implementing` · `reviewer`) y emite qué archivos entran en su contexto, cuántos
tokens pesa cada uno y el total. La aproximación de tokens es **bytes ÷ 3.6**, declarada como
aproximación en la salida — no se agrega una dependencia para tokenizar.

**El arquetipo es `analysis`** y su evidencia se rige por `sdd-plan` Fase A: el AC que afirma
una cifra se bindea a la salida de la consulta que la re-deriva.

## Architectural Delta

`SDD/scripts/sdd-context-budget.sh` — **NEW**. Lee las referencias a `standards/` de los
artefactos de cada rol y suma el peso de los archivos citados.

## Acceptance criteria

| # | Criterio |
|---|---|
| AC17 | `sdd-context-budget.sh planner` emite una línea por archivo con su peso en bytes y tokens aproximados, y una línea `TOTAL`, y sale 0. |
| AC18 | La salida declara literalmente que la cifra de tokens es aproximada y cómo se deriva (`bytes / 3.6`). |
| AC19 | Un rol desconocido sale 2 con un mensaje que enumera los tres roles válidos. |
| AC20 | El total que reporta para el rol `implementing` coincide con la suma de los pesos que él mismo lista, re-derivada con `awk` en el propio test. |

**Mutación (AC19)**: quitar la validación de rol · en el bloque de argv · queda revertida.
**Mutación (AC20)**: alterar el acumulador del total (sumar el peso dos veces para el primer
archivo) · en el bucle de suma · queda revertido.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC17 | `SDD/tests/test_context_budget.sh` → `test_salida_por_rol` |
| AC18 | `SDD/tests/test_context_budget.sh` → `test_declara_aproximacion` |
| AC19 | `SDD/tests/test_context_budget.sh` → `test_rol_invalido` |
| AC20 | `SDD/tests/test_context_budget.sh` → `test_total_rederivado` |

## Checklist del arquetipo `analysis`

| Ítem | Estado |
|---|---|
| La fuente del dato está declarada | Cumplido — los archivos del plugin, enumerados en la salida |
| La unidad está declarada y es la correcta | Cumplido — bytes medidos; tokens **aproximados** y así etiquetados (AC18) |
| La cifra se puede re-derivar desde la fuente | Cumplido — AC20 la re-deriva con `awk` independiente |
| El método de agregación está escrito | Cumplido — suma simple sobre los archivos listados |
| Las limitaciones están declaradas | Cumplido — mide contexto **estático**; no mide turnos ni contexto acumulado. Escrito en la cabecera del script |
| La conclusión no excede lo que el dato sostiene | Cumplido — el script no concluye, reporta |
| Potencia / significancia | `N/A` — no hay inferencia estadística; es un conteo exhaustivo, no una muestra |
