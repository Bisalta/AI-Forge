# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `8093281` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:a8f010a76c4f561a`) · **Fecha**: 2026-09-18T18:46:26Z
- Tree: `d473492882905d6b10119938a3ff0536011fec76` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-18T18:45:38Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-18T18:45:38Z | verde |
| 3 | type-check | — | — | 2026-09-18T18:45:39Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-18T18:45:39Z | verde |
| 5 | integration | — | — | 2026-09-18T18:46:02Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-18T18:46:02Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-18T18:46:02Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-18T18:46:02Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-18T18:46:02Z | verde |
| 10 | smoke manual | — | — | 2026-09-18T18:46:03Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-18T18:46:03Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_check_self_scoping.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_usage_summary.sh
---
14 passed, 0 failed (14 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 148 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_check_self_scoping.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_usage_summary.sh
---
14 passed, 0 failed (14 total)
```

---

# Addendum de ronda 3 — la clase, no la instancia (RT21)

El review de ronda 3 encontró tres MAJOR (J1, J2, J3) y cinco minor, todos
en `RUNBOOK.md`/`sqlserver-parte-b.sql`/`postgres-parte-a.sql`. Los tres
MAJOR son la misma forma que M5 (ronda 2) ya había corregido en AC1,
reaparecida en AC5/AC6/AC7 porque la corrección de ronda 2 fue por
instancia señalada, no por forma. Corregidos en el commit `8093281`
(este es el commit que el runner selló arriba). Detalle completo en
`SDD/briefs/R1-infra-accesos-lectura.md` (Execution Report); acá sólo la
evidencia que el runner no genera.

## J1 — AC5 leía un catálogo, no una tabla de `EXACTUS`

`RUNBOOK.md:227` (antes de esta ronda) comprobaba con `SELECT TOP 1 1
FROM sys.tables` — catálogo del sistema, mismo defecto que M5 ya había
corregido en AC1 con `<tabla_real>`. Corregido con el mismo patrón:
`RUNBOOK.md:235` lista tablas reales de `EXACTUS`
(`SELECT name FROM sys.tables;` — sólo para *listar* nombres de tabla,
nunca para leer datos) y `RUNBOOK.md:241` lee de `<tabla_real>` con el
login. De paso, mismo rojo-falso de tabla-vacía que el minor de AC1 ya
señalaba: `RUNBOOK.md:246-249` ahora pide `<tabla_real>` con al menos una
fila, igual que `RUNBOOK.md:139-143` para AC1.

## J2 — AC6 dejaba el login de scratch sin `db_datareader`

`RUNBOOK.md:241,252-253` (antes de esta ronda) agregaba `db_datawriter`
solo; al revocarlo, el login de scratch quedaba con **cero** membresías,
así que la comprobación negativa medía "un principal sin roles no puede
`INSERT`", no "el login que este runbook aprovisiona, con
`db_datareader`, no puede `INSERT`" (AC6 literal). Corregido en
`RUNBOOK.md:260`: `ALTER ROLE db_datareader ADD MEMBER bisalta_lectura`
se agrega junto con `db_datawriter` y **no se revoca** — sólo
`db_datawriter` se revoca antes de la comprobación real (`RUNBOOK.md:280`
en el archivo actual). Mismo criterio que AC2 (`claude_lectura` conserva
`pg_read_all_data` toda la comprobación).

## J3 — AC7 verificaba la mutación con una consulta distinta del cursor real

`RUNBOOK.md:277` (antes de esta ronda) comprobaba la mutación con
`SELECT name FROM sys.database_principals WHERE name = 'bisalta_lectura'`
contra `master` sola — una consulta distinta del cursor `##ac7_check` que
es la comprobación real (líneas 297-314 de esa versión). Un defecto en el
cursor no se habría visto en esa mutación. Corregido: `RUNBOOK.md:304`
corre sólo la mutación (`sqlserver-parte-b.sql` editado sin el filtro
`database_id > 4`), y el mismo bloque `##ac7_check` (`RUNBOOK.md:320-339`)
se corre contra la instancia de prueba mutada, exigiendo `tiene_user = 1`
en la fila `master` (`RUNBOOK.md:341-349`). El bloque queda escrito una
sola vez y se reusa, cambiando sólo `-S`, para la comprobación final
contra `Dev SQL` (`RUNBOOK.md:351-353`) — nunca dos consultas distintas
para la misma afirmación.

Los tres siguen `manual-only` (AC5, AC6, AC7 — misma razón declarada en
el contract v2): no se corrieron contra una base real. El texto corregido
queda escrito y listo para ejecutar en `RUNBOOK.md`.

## Minors de ronda 3

- `RUNBOOK.md:304` — `-v ON_ERROR_STOP=1` (semántica de `psql`) retirado
  de la única invocación de `sqlcmd` que lo llevaba; `-b` (el equivalente
  real en `sqlcmd`) ya estaba y sigue.
- `RUNBOOK.md:330-331` — `@db_name` pasa como parámetro de
  `sp_executesql` (`N'@p_db_name SYSNAME', @p_db_name = @db_name`) en vez
  de concatenado crudo dentro del literal de cadena del dynamic SQL.
  `QUOTENAME(@db_name)` sigue igual para el identificador del `USE`.
- `sqlserver-parte-b.sql:9-22` — la justificación de descartar
  `sp_MSforeachdb` ahora nombra la diferencia real (el filtro del cursor
  es una condición explícita, visible y versionada en el `WHERE`; el
  salto de `sp_MSforeachdb` es interno, no documentado y no auditable),
  y la acción operativa de AC10 (`RUNBOOK.md:385-405`) se extiende a
  bases que estaban `OFFLINE`/`RESTORING` durante la última corrida, no
  sólo a bases nuevas.
- `RUNBOOK.md:139-143` — "devuelven una fila" corregido a "terminan sin
  error de permiso y devuelven esa fila", con la instrucción de elegir
  `<tabla_real>` con al menos una fila (rojo-falso de tabla vacía).
- `postgres-parte-a.sql:8-13` — el identificador de cluster
  `sistemas-costruplaza-db.cluster-cfrl3owqzwof` queda aclarado como
  identificador de cluster, no endpoint, con referencia al endpoint
  completo en `RUNBOOK.md`.

## Barrido de clase (grep, no memoria)

Comandos corridos sobre el árbol después de aplicar los ocho fixes,
resultado pegado tal cual:

**1. ¿Otra comprobación que lea un catálogo donde el AC afirma leer datos
de negocio?**

```
$ grep -n "sys\.\|information_schema\.\|pg_catalog\." plugins/bisalta-db/aprovisionamiento/RUNBOOK.md plugins/bisalta-db/aprovisionamiento/*.sql
```

Único uso de catálogo fuera de identidad/membresía (que sí es lo que esos
AC afirman: existencia de rol/user, no datos de negocio) son las dos
líneas de AC1/AC5 que explícitamente descartan leer el catálogo como
prueba de datos (`information_schema.tables`, `sys.tables`) y la línea de
listado de nombres de tabla (`SELECT name FROM sys.tables` en AC5, sólo
para identificar `<tabla_real>`, nunca como la comprobación en sí). Cero
coincidencias adicionales de un catálogo usado como si fuera dato de
negocio.

**2. ¿Otro procedimiento de mutación cuyo estado final no sea el que deja
el script de producción?**

```
$ grep -n "Mutación declarada" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
```

Tres resultados: AC2 (`claude_lectura` conserva `pg_read_all_data` toda la
comprobación — ya correcto desde ronda 1), AC6 (corregido esta ronda,
`db_datareader` ahora persiste), AC7 (no aplica el concepto de "estado
final del login" — es sobre existencia de user por base, y el script
editado se revierte explícitamente después de la comprobación). Cero
coincidencias adicionales.

**3. ¿Otra mutación verificada con una consulta distinta de la
comprobación real del AC?**

Revisadas las tres mutaciones (AC2, AC6, AC7) a mano contra su respectiva
comprobación real: AC2 y AC6 corren el mismo `INSERT` sobre la misma
relación antes y después de revocar (ya correcto desde ronda 2); AC7
corregido esta ronda para usar el mismo bloque `##ac7_check`. Cero
coincidencias adicionales — no hay una cuarta mutación en el runbook.

**4. ¿Otra bandera aplicada por patrón que no signifique nada en su
cliente?**

```
$ grep -n "sqlcmd -" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md | grep -v SQLCMDPASSWORD
```

Seis invocaciones de `sqlcmd` restantes, todas con `-S`/`-E`/`-d`/`-Q`/`-b`/`-i`
— banderas válidas y con efecto real en `sqlcmd`. Cero apariciones de
`-v ON_ERROR_STOP` en una línea de `sqlcmd` (única forma en que ese
patrón podía repetirse). Cotejado también contra las invocaciones de
`psql` (`grep -n "psql .*-v ON_ERROR_STOP"`): las cuatro que llevan esa
bandera van siempre con `-f` (ejecución de script), que es exactamente
donde `-v ON_ERROR_STOP=1` tiene efecto en `psql` — ninguna la lleva sin
`-f`. Cero coincidencias adicionales de bandera sin semántica.

**5. Patrón de concatenación cruda de una variable dentro de un literal
de cadena de SQL dinámico (la forma exacta del minor de `@db_name`):**

```
$ grep -rn "+ @db_name + N'''" plugins/bisalta-db/
```

Cero coincidencias — el único lugar donde existía ese patrón era el
bloque `##ac7_check` corregido esta ronda.

## AC1–AC10 — estado tras ronda 3 (sin cambio en la naturaleza de la evidencia)

AC1–AC8 y AC10 siguen `manual-only`, estado **pendiente-de-ejecucion**:
ningún harness de este repo puede crear un rol de Postgres, alcanzar la
VPC de dev/qa, o alcanzar `10.24.40.137` (misma razón declarada en el
contract v2, sin cambio respecto a rondas 1-2). Los pasos corregidos de
AC5, AC6 y AC7 quedan escritos y listos para ejecutar en `RUNBOOK.md`. AC9
(`secret-scan.sh`, único AC automatizable junto con AC10) sigue verde en
esta ronda (gate 9 de la tabla de arriba, exit 0) — ninguno de los ocho
fixes de esta ronda tocó `secret-scan.sh` ni agregó un literal con forma
de credencial; el triple completo (verde → rojo → verde) ya está
registrado en el addendum de ronda 1/2 de este mismo archivo y no se
repite acá porque el AC no cambió.

## Impact set — ronda 3

Los tres archivos tocados (`RUNBOOK.md`, `sqlserver-parte-b.sql`,
`postgres-parte-a.sql`) siguen sin ningún caller dentro de este repo — R2
(el catálogo/servidor que los va a usar) todavía no existe:

```
$ grep -rl "aprovisionamiento" --include="*.sh" --include="*.js" SDD/ plugins/ 2>/dev/null
```

Sin coincidencias (además de la prosa del propio brief/runbook/contract).

## Rojos preexistentes

Ninguno. La suite completa (14 archivos) está verde en la base y sigue
verde después de este trabajo — ronda 3 no tocó ningún script ni test que
esa suite ejercite (los tres archivos cambiados son prosa/comentarios de
`plugins/bisalta-db/aprovisionamiento/`, fuera del glob de `SDD/tests/`).

