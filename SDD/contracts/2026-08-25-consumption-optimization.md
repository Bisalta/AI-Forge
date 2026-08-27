# HLTC — sdd-flow · optimización de consumo (GEN-101)

**Versión**: v7 · **Fecha**: 2026-08-25 · **Planner**: Opus 5
**Estado**: auto-aprobado (modo multi-agente, `sdd-plan` Fase A)
**Branch**: `refactor-GEN-101-optimizacion-consumo` · base `origin/prod`

## Ratificaciones

- **v7** (revisión adversarial independiente, `reviewer-agent` Opus, ronda 1 de este ciclo —
  la primera revisión que no fui yo mismo): veredicto `REJECTED`, 4 `BLOCKER` · 8 `MAJOR` · 6
  `MINOR`. Los defectos no estaban en el código en ejecución — estaban en la **evidencia** (no
  existía verification report del agente para ningún requerimiento; AC19 tenía una pata de
  triple fabricada, reusando la variable de la primera corrida en vez de correr una tercera vez
  — el mismo defecto exacto que RT11/RT15 existen para prevenir, reproducido en el mismo ciclo
  que los escribió) y en el **plan** (R6 no llegaba a los otros 2 repos aunque se
  sincronizaran, porque el mecanismo nunca se canonizó en el plugin; el backfill de GEN-94
  contaba 3 eventos cuando eran 6, porque el método de búsqueda no podía ver eventos que no
  usaran el literal "ESCALATE"/"REJECTED"; la cifra insignia de R1 subestimaba el rol reviewer
  23,6% porque la lista de archivos estaba congelada en vez de derivada en vivo — exactamente lo
  que su propia cabecera afirmaba hacer). Corregido punto por punto en esta versión; detalle en
  cada sección (R1, R3, R4, R6) y en `SDD/retro.md` (RT18-RT21). Los 4 BLOCKER y 8 MAJOR quedan
  resueltos acá; los 6 MINOR también, salvo dos que se registraron como deuda por ser límites
  conocidos y angostos, no defectos a cerrar en este ciclo (`SDD/debt.md`).

- **v6** (ampliación tras segunda ronda de revisión externa de Esteban Fait, Slack, 26-ago-2026):
  agrega **R6** — el ciclo original prometía "volver con el número" de ESCALATEs de plan en
  ciclos futuros sin ningún mecanismo que no dependiera de que alguien se acordara de
  re-derivarlo a mano. Esteban lo señaló con dos preguntas: (1) ¿la clasificación plan-vs-decisión
  la hace el linter o hay que rehacer la arqueología cada vez? (2) ¿"un par de ciclos" tiene
  fecha, dado que sólo hay 3 repos con ciclos SDD completos (AI-Forge, Odoo-Addons,
  Documentos_Customer_Experience) y 3 personas usándolo? R6 responde con mecanismo, no con
  promesa: ledger + tally script + regla del orquestador ya existente ampliada.

- **v5** (durante la ejecución de R2, disparada por el propio AC10): el grep de AC10 devolvía
  dos hits, y los dos eran **la regla citando lo que prohíbe** — la sección Modelos de
  `base-standards.md` y la convención de `CLAUDE.md` nombran `claude-opus-4-8` para
  prohibirlo. Es la **tercera aparición** de la clase de `SDD/debt.md` D10/D11, y la primera
  en un AC en vez de en un script. Se resuelve con la técnica que `sdd-lint-contract.sh` ya
  usa (`grep -qiE 'prohibido|closure|banned'`): saltear la línea que lleva lenguaje de
  prohibición. **Por línea, nunca por archivo** — excluir archivos enteros ciega el chequeo,
  que es la lección de D6. El triple de mutación de AC10 prueba que no lo ciega: 0 hits
  limpio, 1 hit con una violación inyectada.
  **Límite declarado**: una violación escrita en la MISMA línea que lenguaje de prohibición
  se pierde. Es angosto y conocido; no se corrige.

- **v4** (self-review del planner, antes de ejecutar R3): la decisión de R3 nombraba tres
  artefactos para `haiku` pero el Architectural Delta listaba dos — `sdd-fixes` aparecía en la
  prosa y no en el Delta. Resuelto **sacándolo**, no agregándolo: su triage declara las
  mutaciones de los ACs de detección, que es una decisión de planner. Tercer defecto de plan
  del ciclo detectado antes de despachar.
- **v4b** — R2 gana una excepción explícita a la regla de tier: el trailer `Co-Authored-By:`
  de un commit y el `CHANGELOG.md` **sí** llevan el modelo exacto. Registran un hecho pasado
  en vez de seleccionar un modelo futuro, y son las dos formas donde borrar la versión
  destruiría información en vez de evitar que envejezca.

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
  archivos, salvo `archetypes.md`, donde R3 agrega el criterio de brief trivial — una sección
  normativa completa, no "una fila de tabla" como decía v6 (contradecía la propia Decisión de
  diseño de R3 en el mismo contract; corregido en v7, hallazgo de revisión externa, MINOR 14).
- **Las otras dos clases de defecto de plan que el diseño original nombraba para R4** — AC que
  cruza su propio out-of-scope (self-review de `sdd-plan`), y Delta ubicado por vecindad en vez
  de por condición — **no se implementaron**. R4 sólo entregó el chequeo de secciones ausentes.
  La baja de scope no se había declarado en ningún lado (ni acá, ni en `SDD/debt.md`, ni en
  `retro.md`) hasta que revisión externa lo encontró (MAJOR 12). Quedan como dos ítems de
  `SDD/debt.md`, MAJOR, dueño Gabriel — no entran en este contract.
- **Propagar `escalations.md` y el tally a Odoo-Addons y Documentos_Customer_Experience** (R6).
  Esos repos tienen su propia copia de los scripts del plugin (`/sdd-init` los copia versionados,
  `--version` decide si actualiza) — no se editan desde acá. El checkpoint de R6 depende de que
  esos repos re-sincronicen el plugin antes de esa fecha; si no lo hicieron, el tally de esos
  dos repos sale vacío, no falso-cero — hay que decir "no propagado", no "0 eventos".
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
| AC27 | `concerns:` declarado como blockquote (`> **Concerns**: ...`) o como fila de tabla (`\| Concerns \| Estado \|`) no produce falso `BLOCKER` de `seccion-ausente`. **(v7 — hallazgo de revisión externa con fixtures propias, MINOR 19b: el strip-prefix sólo pelaba ' ', '-', '#', '*'; ahora también '\|' y '>'.)** |

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
| AC27 | `SDD/tests/test_lint_contract_sections.sh` → `test_concerns_formas_no_yaml` |

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
| AC10 | El grep de versiones pinneadas sobre `plugins/` y `CLAUDE.md`, **excluyendo las líneas que citan la regla** (las que llevan `defecto`, `prohibi`, `nunca versión` o `envejece`), no devuelve ninguna línea. La exclusión es por línea, no por archivo. |
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

**Dos artefactos pasan a `model: haiku` en frontmatter**: `write-pr-report` y `sdd-status`.
Leen poco, no deciden arquitectura y su salida es verificable de un vistazo.

**`sdd-fixes` queda en el default, y la razón importa**: su triage es el único momento en que
alguien mira un ítem antes de arreglarlo, y ahí es donde se llena el campo `Mutación:` de los
ACs de detección (`commands/sdd-fixes.md`). Declarar una mutación es una decisión de planner —
el contract lo dice explícito para la vía larga y la vía corta no cambia quién tiene la
autoridad, sólo dónde se ejerce. Bajarlo a `haiku` delegaría a un tier barato exactamente lo
que el resto del plugin prohíbe delegar.

**El criterio de «brief trivial» se escribe cerrado y enumerativo** en `standards/archetypes.md`.
Un brief es trivial cuando cumple **las cuatro** condiciones: toca ≤2 archivos · no agrega
dependencias · su arquetipo es `refactor`, `infra` o `bugfix` · y ninguno de sus ACs es de
detección. Si falla una, no es trivial. La duda resuelve a no-trivial.

**El reviewer no baja de Opus** y el planner tampoco. Cerrado en Out of scope.

## Architectural Delta

| Archivo | Cambio |
|---|---|
| `plugins/sdd-flow/skills/write-pr-report/SKILL.md` | `model: haiku` en frontmatter |
| `plugins/sdd-flow/commands/sdd-status.md` | `model: haiku` en frontmatter |
| `plugins/sdd-flow/standards/archetypes.md` | Fila nueva: criterio de brief trivial (4 condiciones) |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | Línea 83: apuntar al criterio en vez de decir «si trivial» |

## Acceptance criteria

| # | Criterio |
|---|---|
| AC13 | `write-pr-report/SKILL.md` y `commands/sdd-status.md` tienen `model: haiku` en frontmatter, parseable como YAML. |
| AC14 | `archetypes.md` contiene las cuatro condiciones de trivialidad, enumeradas. |
| AC15 | `sdd-plan/SKILL.md` línea del modelo asignado referencia el criterio de `archetypes.md` y no contiene la palabra suelta «trivial» sin su definición. |

**AC16 se eliminó en v7** (hallazgo de revisión externa, MINOR 18): duplicaba AC12 palabra por
palabra («`reviewer-agent.md` sigue en `model: opus`») y encima le declaraba mutación —
`quality-gates.md` §10.1 reserva la mutación para ACs de detección, no para aserciones de
contenido estático. AC12 (sección R2) ya cubre esta regresión, sin mutación, igual que
AC21/AC22/AC25. Además: `write-pr-report/SKILL.md` invoca al harness de forma indirecta vía
`/sdd-pr` — nada en este ciclo verificaba que `model:` en frontmatter de skill se herede a
través de esa composición (MAJOR 11). Fix: `commands/sdd-pr.md` declara `model: haiku`
directamente (nuevo en el Delta), sin asumir la herencia.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC13 | `SDD/tests/test_model_tier_policy.sh` → `test_skills_mecanicos_en_haiku` (incluye la verificación de `commands/sdd-pr.md`) |
| AC14 | `SDD/tests/test_model_tier_policy.sh` → `test_criterio_trivial_enumerado` |
| AC15 | `SDD/tests/test_model_tier_policy.sh` → `test_sdd_plan_referencia_criterio` |

## Checklist del arquetipo `refactor`

| Ítem | Estado |
|---|---|
| El comportamiento observable no cambia | **No cumplido, y es intencional** — tres artefactos cambian de modelo. El comportamiento que no cambia es el del reviewer y el planner (AC12) |
| Cobertura previa al cambio | Cumplido — AC12 fija lo que no se mueve |
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

| Archivo | Cambio |
|---|---|
| `plugins/sdd-flow/scripts/sdd-context-budget.sh` | **NEW** (canónico, v0.2.0 tras v7 — v0.1.0 vivía sólo en `SDD/scripts/`, sin propagar). Deriva `FILES` en vivo grepeando `standards/` de los puntos de entrada de cada rol, no de una lista congelada — v0.1.0 tenía la lista hardcodeada y le faltaban `archetypes.md` y `seo-frontend.md` en el rol reviewer (23,6% de subestimación, hallazgo de revisión externa, MAJOR 10). |
| `SDD/scripts/sdd-context-budget.sh` | Copia instalada, idéntica a la canónica — mismo patrón que `sdd-check.sh`/`sdd-lint-contract.sh`/`sdd-run-gates.sh` |
| `SDD/docs/doc_quality_gates.md` | Gate 2 amplía su glob a `SDD/scripts/*.sh` (agregado durante la ejecución de R1 para que el linter cubra el script nuevo; no estaba declarado en ningún Delta hasta ahora — hallazgo de revisión externa, MAJOR 5). Dirección más estricta, no un ablandamiento. |

## Acceptance criteria

| # | Criterio |
|---|---|
| AC17 | `sdd-context-budget.sh planner` emite una línea por archivo con su peso en bytes y tokens aproximados, y una línea `TOTAL`, y sale 0. |
| AC18 | La salida declara literalmente que la cifra de tokens es aproximada y cómo se deriva (`bytes / 3.6`). |
| AC19 | Un rol desconocido sale 2 con un mensaje que enumera los tres roles válidos. |
| AC20 | El total que reporta para el rol `implementing` coincide con la suma de los pesos que él mismo lista, re-derivada con `awk` en el propio test. |
| AC27bis | La lista de archivos que reporta cada rol coincide con una re-derivación **independiente** (grep propio del test, no la lógica del script) de las referencias `standards/` en los puntos de entrada de ese rol. **(v7 — hallazgo de revisión externa, MAJOR 10: AC20 sólo validaba aritmética sobre lo que el script ya había impreso, autosatisfacible por el mismo error que pretendía detectar — misma clase que RT10.)** |

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
| AC27bis | `SDD/tests/test_context_budget.sh` → `test_poblacion_no_congelada` |

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

---

# R6 — Ledger y tally de clasificación de ESCALATE

## Problema

El plan original para decidir R5 era "corré A, medí cuánto queda". Pero "cuánto queda" depende
de saber cuántos `ESCALATE`/`REJECTED` de ciclos futuros son defecto de plan — y esa
clasificación, hoy, no la produce nada mecánico. El "3 de GEN-94" salió de releer el contract y
la retro a mano, después del hecho. Sin un mecanismo que no dependa de memoria, "vuelvo con el
número" es una promesa sin dueño: nadie tiene el pendiente escrito en ningún lado que se revise
solo.

Segunda pregunta de Esteban: con sólo 3 repos con ciclos SDD completos (verificado por él
mismo contra permisos de escritura: AI-Forge, Odoo-Addons, Documentos_Customer_Experience —
`bisalta-implementaciones` tiene el doc de gates pero cero verification reports, no cuenta) y 3
personas usando el plugin, "un par de ciclos" sin fecha puede no ocurrir en semanas sin que
nadie lo note.

## Decisión de diseño (cerrada)

**Ledger dedicado, no una columna nueva en `SDD/retro.md`.** `retro.md` ya tiene 16 filas con
celdas largas mezclando ESCALATEs, BLOCKEDs y hallazgos generales — retrofitear una columna
ahí exige tocar las 16 filas existentes con una clasificación que hoy nadie verificó fila por
fila, que es exactamente la falsa precisión que este mismo R6 existe para evitar. `SDD/escalations.md`
es un archivo nuevo, de un solo propósito: un evento por fila, sólo `ESCALATE`/`REJECTED`/
`blocked`-repetido, con `Clase` como campo cerrado y grepeable.

**La clasificación GEN-94 se backfillea una vez, con el método declarado adentro del archivo**
(grep de `ESCALATE|REJECTED` contra el historial de versiones del contract, cruzado contra las
filas de retro que ya nombraban la causa raíz) — no se inventa ni se deja en blanco. A partir de
ahí, **toda fila nueva la escribe el planner en el mismo acto de resolver el evento** (regla ya
agregada a `commands/sdd.md`, sección Retro) — igual que `Mutación:` en quality-gates.md §10.

**El tally es un conteo, no un clasificador.** `sdd-escalation-tally.sh` suma lo que la tabla ya
dice; no infiere causa. Si una fila no tiene `Clase` reconocida, el script sale con código
distinto de 0 y la nombra — silenciarla en el conteo sería el mismo defecto que `D6`
(`secret-scan.sh`): un charset que deja pasar la forma que no anticipó.

**No se propaga a los otros dos repos desde acá.** Cada repo tiene su propia copia versionada de
los scripts del plugin. Este contract sólo puede tocar `AI-Forge`. El checkpoint (abajo) verifica
si Odoo-Addons y Documentos_Customer_Experience ya la tienen antes de tallarlos — si no,
reporta "no propagado", nunca "0 eventos" (0 eventos y "no tengo el mecanismo todavía" no son
el mismo hecho, y confundirlos es otra forma de medición que no mide lo que dice medir).

**Checkpoint con fecha real, no orgánico.** Tarea en Proxima (proyecto `GEN`, fase `Análisis`)
con `startAt`/`endAt` fijos — visible en el tablero, no dependiente de que alguien recuerde este
hilo de Slack.

## Architectural Delta

| Archivo | Cambio |
|---|---|
| `SDD/escalations.md` | **NEW** — ledger, formato y clase cerrados, backfill de GEN-94. **Recontado en v7**: 6 filas (no 3 — el backfill original grepeaba sólo el literal `ESCALATE\|REJECTED` y no veía eventos que llegaron por "review APPROVED con gaps" o "re-review"; hallazgo de revisión externa, MAJOR 9), las 6 `plan` |
| `plugins/sdd-flow/scripts/sdd-escalation-tally.sh` | **NEW, canónico** (v7 — v0.1.0 vivía sólo en `SDD/scripts/`, así que ningún repo consumidor podía obtenerlo vía `/sdd-init`; el propio Out of scope de v6 apoyaba el checkpoint de R6 en "re-sincronizar el plugin", premisa falsa si el plugin nunca lo distribuye — hallazgo de revisión externa, MAJOR 7) |
| `SDD/scripts/sdd-escalation-tally.sh` | Copia instalada, idéntica a la canónica |
| `plugins/sdd-flow/templates/escalations-ledger.md` | **NEW** — template para que `/sdd-init` seedee `SDD/escalations.md` en un repo sin el backfill de GEN-94 (tabla vacía) |
| `plugins/sdd-flow/skills/sdd-init/SKILL.md` | Paso 8 amplía la lista de scripts a copiar (+ `sdd-context-budget.sh`, `sdd-escalation-tally.sh`); paso 8bis nuevo: seedear `escalations.md` desde el template si no existe |
| `plugins/sdd-flow/standards/orchestration.md` | §6.1 nueva — definición cerrada de "evento contable", de la que `escalations.md` y `commands/sdd.md` ahora citan en vez de restatear cada uno la suya (v6 tenía tres definiciones distintas en tres documentos; hallazgo de revisión externa, MAJOR 8) |
| `plugins/sdd-flow/commands/sdd.md` | Regla de Retro ampliada: `ESCALATE`/`REJECTED`/`BLOCKED`-que-ratifica también escriben una fila en `escalations.md`, citando `orchestration.md` §6.1 |
| Proxima (proyecto `GEN`) | Tarea nueva: checkpoint con fecha para tallar los 3 repos |

## Acceptance criteria

| # | Criterio |
|---|---|
| AC21 | `SDD/escalations.md` existe, tiene exactamente 6 filas de evento (`E1`-`E6`), las 6 del ciclo `sicop-hardening`, las 6 con `Clase: plan`. **(v7 — recontado tras hallazgo de revisión externa, MAJOR 9; era 3 en v6.)** |
| AC22 | `sdd-escalation-tally.sh --version` imprime `sdd-escalation-tally 0.1.0` y sale 0. |
| AC23 | `sdd-escalation-tally.sh` contra `SDD/escalations.md` imprime `TOTAL 3` y `plan 3` (`decisión`/`medición`/`otro` en 0), exit 0. |
| AC24 | Una fila del ledger con `Clase` vacía o fuera del enum cerrado hace que el script salga con código 3 y nombre esa fila — no la cuenta en silencio como ninguna categoría. |
| AC25 | `commands/sdd.md`, regla de Retro, referencia `SDD/escalations.md` y `sdd-escalation-tally.sh`. |
| AC26 | Existe una tarea en Proxima (proyecto `GEN`) con `startAt` en el futuro, cuyo título nombra el checkpoint de R6. **Satisfecho**: `GEN-102`, `startAt` 2026-09-22T14:00:00-06:00, título "Checkpoint R6 — tallar ESCALATE de plan en AI-Forge, Odoo-Addons y Documentos_Customer_Experience". |

**AC de detección** (`quality-gates.md` §10): AC23 y AC24 afirman que el tally **cuenta
correctamente** y **detecta** clasificación ausente, respectivamente.

> **Mutación (AC23)**: sobre una copia del ledger, agregar una séptima fila `E7` con
> `Clase: decisión` · antes del backfill note · queda revertida. El triple prueba que el
> conteo responde a lo que el archivo dice, no a un `6` fijo en el script.

> **Mutación (AC24)**: sobre una copia del ledger, vaciar el campo `Clase` de la fila `E2`
> (dejarlo `|  |`) · en la fila de `E2` · queda revertida. El triple prueba que una fila sin
> clasificar se reporta, no se pierde en el total.

AC21, AC22, AC25 y AC26 no son de detección: afirman un estado observable (contenido de un
archivo, una cadena de versión, una referencia presente, una tarea creada), no una condición que
el sistema deba fallar bajo mutación.

## AC ↔ test binding

| AC | Test |
|---|---|
| AC21 | `SDD/tests/test_escalation_ledger.sh` → `test_backfill_gen94_completo` |
| AC22 | `SDD/tests/test_escalation_ledger.sh` → `test_version` |
| AC23 | `SDD/tests/test_escalation_ledger.sh` → `test_tally_cuenta_correcto` |
| AC24 | `SDD/tests/test_escalation_ledger.sh` → `test_tally_detecta_clase_ausente` |
| AC25 | `SDD/tests/test_escalation_ledger.sh` → `test_regla_retro_ampliada` |
| AC26 | Verificación manual contra la respuesta de `proxima_create_task` (arquetipo `infra`; Proxima no tiene test de repo — el binding es el `id`/`key` devuelto, pegado en `SDD/verification/refactor-GEN-101-optimizacion-consumo-R6.md`, no sólo en este contract — v6 sólo lo pegó acá, que es donde vive el propio planner, no evidencia independiente; hallazgo de revisión externa, BLOCKER 4) |

## Checklist del arquetipo `infra`

**Corregido en v7** (hallazgo de revisión externa, MINOR 17): el binding de AC26 ya decía
`infra`; el checklist de acá decía `refactor`. `archetypes.md` exige exactamente uno, y el ítem
definitorio de `refactor` ("el comportamiento observable no cambia") no calzaba — R6 agrega
archivos y amplía una regla existente de forma aditiva, que es la forma del arquetipo `infra`.

| Ítem | Estado |
|---|---|
| Cambio idempotente / re-ejecutable | Cumplido — el ledger es append-only, el tally es de solo lectura |
| Rollback declarado | Cumplido — `git revert`; ningún consumidor externo depende todavía de `escalations.md` |
| Efecto sobre consumidores existentes declarado | Cumplido — Odoo-Addons y Documentos_Customer_Experience reciben el mecanismo recién ahora que se canonizó (ver Delta); antes de v7 no podían tenerlo aunque re-sincronizaran |
| Config nueva documentada | `N/A` — no agrega variables de entorno ni flags |
| Corre en el entorno destino | Cumplido — mismo runtime que el resto de `SDD/scripts/` |
