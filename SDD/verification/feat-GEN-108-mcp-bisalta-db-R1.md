# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `27029e3` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-21T17:57:30Z
- Tree: `487e219f3474db9c2c7ab330337b1f09e127ea3f` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-21T17:56:25Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-21T17:56:25Z | verde |
| 3 | type-check | — | — | 2026-09-21T17:56:26Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:56:26Z | verde |
| 5 | integration | — | — | 2026-09-21T17:56:57Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-21T17:56:57Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-21T17:56:57Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-21T17:56:57Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-21T17:56:57Z | verde |
| 10 | smoke manual | — | — | 2026-09-21T17:56:58Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:56:58Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

---

# Addendum del agente `AGENT_r1` — ronda 3 de review (última antes de `ESCALATE`), contract v9 (sin cambio)

**Nota sobre continuidad**: el bloque de arriba lo generó `sdd-run-gates.sh`
sobre el commit `27029e3` y **trunca lo que hubiera antes en este archivo**
(mismo aviso que las rondas anteriores). El addendum de la ronda 2 (commit
`dd73de9`/`aedd8b2`) no se retranscribe acá: recuperable con
`git show aedd8b2:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`. Esta
ronda **no cambió el alcance del contract** (sigue v9): un MAJOR de prosa
de procedimiento sobre el mismo par `sqlserver-inverso.sql` / `RUNBOOK.md`
que las rondas 1 y 2 ya habían tocado, más dos MINOR.

## El MAJOR de esta ronda, y por qué la ronda 2 no lo agarró

| MAJOR | Archivo(s) | Qué estaba mal | Fix aplicado |
|---|---|---|---|
| 1 | `RUNBOOK.md` (AC7, "Limpiar antes de dar por cerrado el rojo") | La copia de trabajo `sqlserver-inverso-mutada-v8.sql` sólo cambiaba el cursor respecto del inverso real, y se quedaba con el `DROP LOGIN` incondicional del final (`sqlserver-inverso.sql:136-139`). El paso siguiente corre `sqlserver-parte-b.sql` real, que hace `CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura` — sin login eso falla con `Msg 15007`, y el `##ac7_check` de cierre daría `0` en todo, no el verde declarado. El verde de cierre del triple de mutación de AC7 (exigido por `quality-gates.md` §10) era inalcanzable | Agregado el mismo segundo cambio que ya lleva la copia de baja: quitar por completo el bloque final `IF EXISTS (... sys.server_principals ...) DROP LOGIN bisalta_lectura; GO` de `sqlserver-inverso-mutada-v8.sql` |

Es la misma clase de defecto que el "Hallazgo propio" de la ronda 2 (un
`DROP LOGIN` incondicional heredado sin condición) — pero en la **otra**
copia de trabajo del mismo script: la ronda 2 lo corrigió en
`sqlserver-inverso-baja-ecommerce_qa.sql` (Procedimiento de baja) y no en
`sqlserver-inverso-mutada-v8.sql` (limpieza de la mutación de AC7), porque
el barrido de esa ronda preguntó *"¿produce un resultado distinto del que
declara?"* — la descripción del síntoma, no de la causa — y ese grep
(`grep -n "sin ninguna fila\|sin filas\|VALUES sin" ...`) no tenía forma de
tocar una instrucción sobre copiar un script y heredarle un bloque
incondicional, porque no menciona `VALUES`.

## MINOR aplicados

- `RUNBOOK.md`, sección "AC7" (línea de apertura, antes del párrafo
  "`AC7` (contract v9) ya no habla de..."): agregado el estado de arranque
  de la instancia de prueba que ni "Lista vacía" ni "Mutación declarada"
  declaraban — la mutación sólo da rojo si el login ya existe ahí
  (`sqlserver-parte-b-mutada-v8.sql` sólo hace `CREATE USER ... FOR LOGIN`,
  nunca crea el login), y la lista vacía sólo da `tiene_user = 0` en todo
  si esa instancia no fue aprovisionada antes con `bisalta_lectura`.
- `RUNBOOK.md`, sección "Procedimiento de baja": agregado el paso **0**
  (sacar la entrada de `plugins/bisalta-db/catalogo.json` antes de
  revocar, documentado, **sin editar el archivo** como parte de esta
  tarea) — la baja no cerraba el lado del catálogo, y el ejemplo del
  procedimiento (`Ecommerce_qa`) corresponde a una entrada que sí está en
  el catálogo (`"nombre": "ecommerce-qa"`), confirmado antes del fix con
  `grep -n "ecommerce-qa\|Ecommerce_qa" plugins/bisalta-db/catalogo.json`.

## Barrido de clase — la propiedad, no el síntoma

**Propiedad grepeada**: *toda receta del runbook que manda hacer una copia
de trabajo de un script declara TODOS los cambios que esa copia necesita
— no sólo el que motiva la copia.* Comando (busca todo lugar que manda
copiar/derivar un `.sql`):

```
$ grep -n -i "copia de trabajo\|a partir de\|-mutada-\|-lista-vacia\|-baja-\|-mas-scratch\|-sin-denydatawriter" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
```

Siete recetas encontradas (nombre del archivo de copia, script del que
parte, qué hereda que no debería):

| Copia de trabajo | Parte de | ¿Hereda algo destructivo/incondicional que no debería? |
|---|---|---|
| `postgres-parte-0-mutado.sql` (línea 194, AC41) | `postgres-parte-0.sql` | No — el original es sólo `SELECT` + `RAISE EXCEPTION`, read-only por definición; nada que revertir ni ningún bloque incondicional que recortar |
| `sqlserver-parte-b-lista-vacia.sql` (línea 477, AC7) | `sqlserver-parte-b.sql` | No — el original no tiene bloque final incondicional, es idempotente (`IF NOT EXISTS` antes de cada `CREATE`/`ALTER ROLE ADD MEMBER`) |
| `sqlserver-parte-b-mutada-v8.sql` (línea 498, AC7) | `sqlserver-parte-b.sql` | No — mismo motivo que la anterior |
| `sqlserver-inverso-mutada-v8.sql` (línea 525, AC7) | `sqlserver-inverso.sql` | **Sí, tenía** — el `DROP LOGIN` incondicional del final (línea 136-139 del original). **Corregido esta ronda** (MAJOR de arriba) |
| `sqlserver-parte-b-mas-scratch.sql` (línea 599, AC42) | `sqlserver-parte-b.sql` | No — mismo motivo, sin bloque final |
| `sqlserver-parte-b-sin-denydatawriter-mas-scratch.sql` (línea 630, AC42) | `sqlserver-parte-b-mas-scratch.sql` (a su vez de `sqlserver-parte-b.sql`) | No — mismo motivo, y el cambio que motiva esta segunda copia (quitar el bloque de `db_denydatawriter`) es exactamente el único cambio declarado, sin nada más que recortar |
| `sqlserver-inverso-baja-ecommerce_qa.sql` (línea 816, Procedimiento de baja) | `sqlserver-inverso.sql` | No — ya declaraba, desde la ronda 2, el segundo cambio (quitar el `DROP LOGIN`) |

Única instancia con el defecto: `sqlserver-inverso-mutada-v8.sql`, ahora
corregida. Las dos copias que parten de `sqlserver-inverso.sql` (la única
fuente que tiene un bloque final incondicional) son las dos únicas que
podían tener este problema — y las dos lo declaran correctamente después
de este fix.

## AC ↔ test binding (esta ronda: sin cambio de universo, corrección de prosa)

| AC | Estado esta ronda | Evidencia |
|---|---|---|
| AC7 | `manual-only`, procedimiento corregido (MAJOR: la limpieza de la mutación ahora deja el verde de cierre alcanzable; MINOR: estado de arranque declarado) | `RUNBOOK.md`, sección "AC7", subsecciones "Limpiar antes de dar por cerrado el rojo" y línea de apertura de la sección |

El resto de los ACs (AC1-AC6, AC8, AC9, AC10, AC41, AC42) no se tocaron
esta ronda: el único MAJOR y los dos MINOR son procedimiento de AC7 y del
Procedimiento de baja (este último no es un AC numerado, es documentación
operativa de "Inverso"). Ver la tabla completa de rondas anteriores
(`git show aedd8b2:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`)
para su estado, sin cambios.

## Impact set (re-corrido esta ronda, sin cambios respecto de rondas anteriores)

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/'
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
SDD/debt.md
SDD/briefs/R1-infra-accesos-lectura.md
```

Mismo conjunto que rondas anteriores: `sqlserver-parte-a.sql` sólo
menciona a `sqlserver-parte-b.sql` en su comentario de cabecera, sin
necesitar cambio; `SDD/debt.md` y `SDD/briefs/R1-infra-accesos-lectura.md`
son históricos, no se editan. `plugins/bisalta-db/catalogo.json` no
aparece en este grep porque el fix de esta ronda no lo edita (sólo lo
menciona en prosa, como pide el brief); confirmado que sigue sin tocar:

```
$ git diff --stat HEAD~1 -- plugins/bisalta-db/catalogo.json plugins/bisalta-db/aprovisionamiento/APROBACIONES.md
```

(sin salida — ninguno de los dos archivos cambió en el commit de esta
ronda). Ningún archivo `.js` de runtime referencia estos `.sql` — sin
regresión de callers en el servidor MCP; la suite de `SDD/tests/` (17
archivos) sigue verde sin cambios (ver gate 4/suite completa de arriba).

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`27029e3`, ver escalera de arriba).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verification queda fuera del árbol que el runner
selló (el `Tree:` de la cabecera es anterior a este addendum). Corrida
sobre el árbol final, **después** de commitear el addendum de arriba
(commit `9db961a`, árbol limpio confirmado con `git status --short` antes
de correr):

```
$ git status --short
$ git rev-parse HEAD
9db961ae955bf25f2bbf0923dd00c3f633251827
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Este párrafo final se agrega en un commit posterior a `9db961a`, ya que
el propio archivo de evidencia no puede documentar su propio hash de
commit sin haberse commiteado primero — mismo patrón en cascada que
`D34`/`D35` describen para este runner.
