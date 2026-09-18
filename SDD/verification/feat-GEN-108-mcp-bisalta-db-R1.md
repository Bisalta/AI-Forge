# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `8cc326d` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-18T22:31:54Z
- Tree: `4f8cbf7cbfc5f2403f82008d196381aa958d048b` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-18T22:30:57Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-18T22:30:57Z | verde |
| 3 | type-check | — | — | 2026-09-18T22:30:58Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-18T22:30:58Z | verde |
| 5 | integration | — | — | 2026-09-18T22:31:26Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-18T22:31:26Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-18T22:31:26Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-18T22:31:26Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-18T22:31:26Z | verde |
| 10 | smoke manual | — | — | 2026-09-18T22:31:27Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-18T22:31:27Z | verde |

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
secret-scan: sin hallazgos sobre 163 archivos versionados (1 excluido: self)
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

# Addendum del agente `AGENT_r1` — lo que el runner no sabe

Esta sección del addendum (ronda 1) se escribió cuando el bloque superior del archivo era la salida de `sdd-run-gates.sh` sellada en el commit `aca2f8e`; no se editó nada de esa parte a mano. El runner volvió a correr en ronda 2 (ver "Corridas previas del runner", entradas 4 y 5) y resembró el bloque superior con un commit posterior — el commit y el hash de árbol **vigentes** son los del encabezado hasta arriba de este archivo, no `aca2f8e`. Lo que sigue lo agrega el agente, con `templates/verification-report.md` como guía, porque el brief nombra este mismo archivo como "Verification report" en vez de un archivo `AGENT_r1.md` separado.

## Corridas previas del runner sobre commits anteriores (no descartadas, registradas)

1. **Commit `8584ebf`** (primer commit de R1): el runner cortó en el **gate 9** (exit `1`), con estos tres hallazgos — todos en prosa de `SDD/briefs/R1-infra-accesos-lectura.md`, ninguno en los siete `.sql`/`.md` nuevos del producto:

   ```
   SDD/briefs/R1-infra-accesos-lectura.md:60: posible secreto (standards/security.md §3) — valor no impreso
   SDD/briefs/R1-infra-accesos-lectura.md:128: posible secreto (standards/security.md §3) — valor no impreso
   SDD/briefs/R1-infra-accesos-lectura.md:129: posible secreto (standards/security.md §3) — valor no impreso
   ```

   Causa: esas líneas documentaban la acción de IAM real `secretsmanager`:`GetSecretValue` (un `namespace` + `:` + `acción`, no una credencial) y la mutación de AC9 con clave `password`, separador `=` y valor de relleno, ambos contiguos y sin partir — mismo patrón autorreferencial que ya afecta a `secret-scan.sh` consigo mismo. Corregidas en el commit `aad6c58` partiendo los literales (backtick entre `secretsmanager` y `:GetSecretValue`; descripción en piezas del valor de relleno tipo access-key en vez del literal completo). **Ninguna exclusión se agregó a `secret-scan.sh`** — no se tocó ese archivo, no está en el Files de este brief.

2. **Commit `aad6c58`**: runner completo en verde (gates 2, 4, 9 y suite completa). Al agregar este mismo addendum a mano, dos literales nuevos (uno en la descripción de la corrida roja, uno en la fila de la tabla de mutación de AC9) repitieron el mismo problema de forma independiente — corregidos en el commit `aca2f8e`, junto con el `grep` case-sensitive de AC10 (el runbook usa `NO` en mayúsculas; el comando documentado originalmente sólo buscaba en minúscula y no matcheaba). Reverificado con `bash SDD/tests/secret-scan.sh` → `0` después de cada corrección.

3. **Commit `aca2f8e`**: corrida final de ronda 1, verde en los cuatro gates aplicables (2, 4, 9, suite completa), árbol limpio (`9b6cbf3ae20f0f952fceba973c56bdd800b8df56`).

4. **Commit `bc25273`** (ronda 2, fix de las citas de línea del triple AC9/AC10, antes de escribir el resto de este addendum): el runner cortó en el **gate 9** (exit `1`), nombrando `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md:166`. Causa: el borrador del addendum de ronda 2 reproducía, contiguo, el valor de relleno con forma de access key AWS usado en la mutación de AC9 — mismo patrón autorreferencial que el de la entrada 1 de esta lista, ahora en la evidencia en vez de en el runbook. Corregido describiendo el valor en piezas en la tabla de la sección "B1" de abajo, en vez de reproducirlo — no se tocó `secret-scan.sh`, ninguna exclusión nueva. Reverificado en el árbol local con `bash SDD/tests/secret-scan.sh` → `0` antes de volver a correr el runner completo.

5. **Commit siguiente** (ronda 2, éste): corrida final del runner de arriba, sellando el árbol con las correcciones de ronda 2 ya commiteadas.

## Prueba por mutación — AC9

**Mutación declarada en el contract**: insertar en `postgres-parte-a.sql` un literal con forma de credencial (clave, separador y valor contiguos); el scan tiene que salir distinto de 0 nombrando el archivo y la línea sin imprimir el valor; revertir la línea.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/secret-scan.sh` | 0 | verde |
| 2 | con la mutación aplicada (línea con clave `password`, separador `=` y un valor de relleno con forma de access key AWS agregada al final de `postgres-parte-a.sql`) | `bash SDD/tests/secret-scan.sh` | 1 | rojo — nombra `postgres-parte-a.sql:54`, sin imprimir el valor |
| 3 | mutación revertida | `bash SDD/tests/secret-scan.sh` | 0 | verde |

Salida de la corrida 2 (rojo):

```
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:54: posible secreto (standards/security.md §3) — valor no impreso
secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo
```

Reversión verificada byte a byte: `git diff plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` contra el índice ya restaurado salió vacío (sin diferencia alguna) después de borrar la línea agregada.

## AC10 — verificación (grep)

```
grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
```

Resultado: línea 352 (`... NO queda cubierta automáticamente**:`) — coincidencia, exit 0. (El runbook usa `NO` en mayúsculas; el grep necesita `-i` para matchear — corregido tras un primer intento en minúscula estricta que no encontraba nada, ver punto 2 arriba. Número de línea actualizado en R2 tras la reescritura de las secciones AC1/AC2/AC5–AC7 del runbook — ver addendum de ronda 2 abajo.)

## Smoke manual (ACs `manual-only` — AC1–AC8)

Ninguno de estos ocho se ejecutó: ningún harness de este repo puede crear un rol de Postgres, alcanzar la VPC de dev/qa, ni alcanzar `10.24.40.137` (misma razón declarada AC por AC en el contract v2). Estado de los ocho: **pendiente-de-ejecucion**. Los pasos exactos — incluidas las tres mutaciones declaradas del contract para AC2, AC6 y AC7 — están escritos en `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`, sección "Verificación de AC1–AC8". No se declara ningún resultado observado porque no se corrió nada: declarar un "Observado" acá sin haber corrido el comando sería exactamente la validación no corrida que las reglas del ciclo prohíben.

## Impact set

R1 no modifica ningún archivo existente: los siete archivos de `plugins/bisalta-db/aprovisionamiento/` son nuevos y ningún script ni test de este repo los importa o los invoca todavía (el propio catálogo/servidor que los va a necesitar es de R2, que corre después). Sin filas de regresión que justificar — confirmado con:

```
grep -rl "aprovisionamiento" --include="*.sh" --include="*.js" SDD/ plugins/ 2>/dev/null
```

Sin coincidencias (además de la prosa de este mismo brief/runbook).

## Rojos preexistentes

Ninguno. La suite completa (14 archivos, incluidos los heredados de ciclos anteriores) está verde en la base y sigue verde después de este trabajo — R1 no tocó ningún archivo que esos tests ejerciten.

---

# Addendum de ronda 2 — correcciones del review

El review de ronda 1 encontró dos blockers y siete majors/minors, todos en
el runbook (el SQL no se tocó salvo donde un hallazgo lo pedía). Detalle
completo de qué cambió y por qué queda en `SDD/briefs/R1-infra-accesos-lectura.md`
(Execution Report) y en el diff de los commits de ronda 2. Acá sólo la
evidencia que el runner no puede generar por sí mismo. La corrida roja
autoinfligida sobre el propio borrador de este addendum (commit `bc25273`)
queda registrada como entrada 4 de "Corridas previas del runner" más
arriba, no repetida acá.

## B1 — re-corrida del triple de mutación AC9 (evidencia que no reproducía)

El reviewer reprodujo que `postgres-parte-a.sql` tiene 53 líneas y termina
con newline: la línea agregada al final es la **54**, no la 55 que la
tabla y el bloque "Salida de la corrida 2" de este archivo citaban antes
de esta ronda. Corregido en las dos citas (esta tabla más abajo y
`SDD/briefs/R1-infra-accesos-lectura.md:130`) y **re-corrido el triple
entero** contra el árbol real de ronda 2 (el archivo no cambió de tamaño
entre rondas: las correcciones de esta ronda fueron a `RUNBOOK.md` y a los
comentarios de los `.sql`, no a las sentencias SQL de `postgres-parte-a.sql`):

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/secret-scan.sh` | 0 | verde |
| 2 | con la mutación aplicada (línea con clave `password`, separador `=` y un valor de relleno con forma de access key AWS — prefijo `AKIA` + 16 caracteres, no reproducido acá en una sola pieza para no autodetectarse — agregada al final de `postgres-parte-a.sql`, línea 54 nueva) | `bash SDD/tests/secret-scan.sh` | 1 | rojo — nombra `postgres-parte-a.sql:54`, sin imprimir el valor |
| 3 | mutación revertida (`git checkout -- plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql`) | `bash SDD/tests/secret-scan.sh` | 0 | verde |

Salida real de la corrida 2 (rojo), pegada tal cual salió del comando,
contra un archivo verificado con `wc -l` inmediatamente antes y después de
la mutación (53 → 54 → 53 líneas):

```
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:54: posible secreto (standards/security.md §3) — valor no impreso
secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo
```

Reversión verificada byte a byte: `git diff plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` contra el índice salió vacío después de `git checkout --`.

## B2/M4 — AC7: cursor real en vez de `LEFT JOIN ... ON 1=0`

El `LEFT JOIN ... ON 1=0` nunca podía matchear (`dp.name` sale `NULL` para
las ~35 bases con o sin aprovisionamiento) y `sqlserver-parte-b-sin-filtro.sql`
no existe. `RUNBOOK.md`, sección AC7, ahora instruye editar
`sqlserver-parte-b.sql` directamente para la mutación, y la comprobación
real es un cursor T-SQL (`##ac7_check`, ver el bloque en el runbook) que
recorre `sys.databases` completo y consulta `sys.database_principals`
dentro de cada base vía `USE` + SQL dinámico — mismo patrón que
`sqlserver-parte-b.sql` ya usa para aprovisionar, ahora reusado para leer.
No se pudo correr contra `Dev SQL` real (mismo motivo `manual-only` de
siempre); el bloque queda escrito y listo para ejecutar.

## M1/M2/M3 — AC2 y AC6: mutación y comprobación real sobre el mismo objeto

- AC2: la comprobación real dejó de apuntar a `INSERT INTO
  information_schema.tables` (una vista; falla con `cannot insert into
  view`, nunca con el error de permiso). Ahora corre sobre `zz_scratch_ac2`,
  la misma tabla que la mutación usó, y el `DROP TABLE` pasó a ser el
  último paso, después de la comprobación real, no antes.
- AC6: mismo defecto en SQL Server: la comprobación real dejó de apuntar a
  `INSERT INTO sys.tables` (catálogo del sistema; falla con `Msg 259, Ad
  hoc updates to system catalogs are not allowed`). Ahora corre sobre la
  tabla `t` de `zz_scratch_ac6`, y `DROP DATABASE zz_scratch_ac6` pasó a
  ser el último paso.

Los dos siguen `manual-only` — no se corrieron contra una base real; el
texto corregido queda en `RUNBOOK.md`.

## M6 — exit codes que antes no podían ser otra cosa que 0

`psql -f` sin `-v ON_ERROR_STOP=1` sale 0 aunque cada sentencia adentro
falle. Agregado a las cuatro invocaciones `-f` de `RUNBOOK.md` (AC3 ×2,
AC4 ×2). `sqlcmd -i` sin `-b` tiene el mismo problema; agregado (junto con
`-v ON_ERROR_STOP=1`) a la invocación de AC7.

## M7 — la contraseña dejó de viajar por `-P`

Las tres invocaciones de `sqlcmd` que autenticaban como `bisalta_lectura`
(`AC5`, dos en `AC6`) usaban `-P <contraseña real>`, visible en la tabla de
procesos — invariante cerrada del contract, sección "Entrega de la
credencial al cliente". Reemplazado por `SQLCMDPASSWORD='<contraseña
real>' sqlcmd ...`: el valor va en el entorno del proceso hijo, nunca en
`argv`.

## Minor — v1 → v2, citado por nombre, host completo, AC4

- Seis citas de contract `v1` corregidas a `v2` en `RUNBOOK.md` (líneas 3,
  100 y las tres cabeceras de mutación AC2/AC6/AC7, más la de AC10) y en
  los `.sql` (`postgres-parte-a.sql`, `postgres-parte-b.sql`,
  `sqlserver-parte-a.sql`).
- Los `.sql` y el runbook dejaron de citar "Decisión de diseño punto N del
  contract" (esa lista vive en el brief, no en el contract): ahora citan
  la sección o el AC del contract por nombre (`AC1`, `AC7`, "Out of
  scope", "Garantías por motor (asimetría declarada, no disimulada)",
  "Entrega de la credencial al cliente").
- El host de Aurora quedó completo en las cuatro ubicaciones truncadas con
  `...`: `sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com`
  (identificador del contract + región `us-east-1`, ya declarada en la fila
  `Integration` del `Architectural Delta`).
- AC4: la comprobación real pasó a ser `SELECT 1 FROM pg_roles WHERE
  rolname = 'claude_lectura'` (cero filas esperadas) en vez de depender
  únicamente del mensaje de error de un intento de conexión —
  `password authentication failed` no distingue "el rol no existe" de
  "el rol existe pero la contraseña está mal tipeada". El intento de
  conexión queda como confirmación adicional, no como la prueba.

## Re-verificación tras los fixes

- `bash SDD/tests/secret-scan.sh` → `0` (ver triple de arriba).
- `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → línea 352, exit 0 (desplazada desde 261 por la reescritura de las secciones AC1/AC2/AC5–AC7; ver `SDD/briefs/R1-infra-accesos-lectura.md:132`).
- `bash SDD/tests/run.sh` → `14 passed, 0 failed (14 total)`.
- Ningún `.sh` nuevo se agregó en esta ronda — el gate 2 (`shellcheck`) no tiene superficie nueva que cubrir.

La corrida final del runner que sella el árbol de ronda 2 es la que
escribió la sección de arriba de todo ("Gates run — generado por
sdd-run-gates.sh"), commit citado en la entrada 5 de "Corridas previas
del runner" — ver esa sección.


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


---

# Addendum de ronda 4 — reapertura v4→v5 (CCR de Patrick Ocampo, no rechazo de review)

Este addendum se escribió cuando el bloque superior del archivo era la
salida de `sdd-run-gates.sh` sellada en el commit `768f6f5` (tree
`f0b977396b20f79cb2e3b1310e976eb8dc2f3a9a`, ver encabezado hasta arriba de
este archivo). El runner **sobreescribe el archivo completo** (`> "$OUT"`,
trampa conocida D34/D35) — este addendum, igual que los de rondas 1-3, se
pega DESPUÉS de la última corrida del runner, sobre el árbol ya
commiteado.

## Por qué se reabrió esta ronda

No es un rechazo de review: Patrick Ocampo (Slack, 18-sep-2026) midió el
cluster de dev/qa y encontró que `pg_read_all_data` es una membresía de
CLUSTER, y que Postgres concede `CONNECT` a PUBLIC por omisión en toda
base. Consecuencia medida: un rol con esa membresía alcanza las **29**
bases del cluster de dev/qa desde que existe, no las 2 que declara el
catálogo de la aplicación. `postgres-parte-b.sql` nunca fue la barrera de
acceso — contrario a lo que su prosa original afirmaba. Contract v4→v5
(ratificado) pidió seis correcciones; las seis quedan implementadas en
esta ronda, con AC41 y AC42 como los ACs nuevos que las verifican.

## Prueba por mutación — AC9, re-corrida sobre el árbol de ronda 4

`postgres-parte-a.sql` cambió de contenido en esta ronda (nueva cita a
`postgres-parte-0.sql` en su encabezado), así que el triple se re-corre
completo en vez de asumirse heredado de rondas 1-3.

**Mutación declarada en el contract (AC9)**: insertar en
`postgres-parte-a.sql` un literal con forma de credencial (clave,
separador y valor contiguos); el scan tiene que salir distinto de 0
nombrando el archivo y la línea sin imprimir el valor; revertir la línea.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto (163 archivos versionados, tras `git add -A` de esta ronda) | `bash SDD/tests/secret-scan.sh` | 0 | verde — `sin hallazgos sobre 163 archivos versionados (1 excluido: self)` |
| 2 | mutado — línea agregada al final de `postgres-parte-a.sql`: clave `password`, separador ` = `, valor de relleno con forma de access key de AWS (prefijo `AKIA` + 16 caracteres alfanuméricos, construido en dos variables de shell para no quedar contiguo ni en el archivo ni en la transcripción de la sesión) | `bash SDD/tests/secret-scan.sh` | 1 | rojo — `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:62: posible secreto (standards/security.md §3) — valor no impreso` seguido de `secret-scan: hallazgos arriba — BLOCKER`. El valor detectado no se imprimió en ningún momento. |
| 3 | revertido (`sed -i '' '$ d' postgres-parte-a.sql`, última línea eliminada) | `git diff -- plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` → vacío (reversión exacta contra el índice, que ya tenía el archivo sin mutar por el `git add -A` previo) · luego `bash SDD/tests/secret-scan.sh` | 0 | verde — `sin hallazgos sobre 163 archivos versionados (1 excluido: self)` |

Ningún fix de esta ronda tocó `secret-scan.sh` ni le agregó una exclusión
por path. El literal de la mutación nunca se commiteó: se agregó, se
corrió el scan, se revirtió con `sed`, todo dentro del mismo tramo de
trabajo, antes de este commit final.

## Verificación del gate 9 sobre el árbol final ya commiteado (trampa D34/D35)

El runner sella el árbol en el commit `768f6f5` pero este mismo addendum
se agrega DESPUÉS de esa corrida — por diseño del runner (trunca `-o`),
el archivo de evidencia queda fuera del árbol que el runner selló. Por
eso, después de pegar este addendum y comittear el resultado, se vuelve a
correr `bash SDD/tests/secret-scan.sh` sobre el árbol final ya
commiteado — ese es el único verde que cuenta para esta ronda, y su
comando + exit code van citados en la sección "Validation Executed
(ronda 4)" del brief (`SDD/briefs/R1-infra-accesos-lectura.md`), no acá,
para no duplicar la misma corrida en dos archivos con riesgo de que uno
quede desactualizado si el otro se corrige.

## AC41 y AC42 — nuevos, `manual-only`, estado tras esta ronda

Los dos requieren infraestructura real (un cluster Postgres para AC41, la
instancia `Dev SQL` para AC42) que ningún harness de este repo levanta.
Sus pasos exactos, con la mutación declarada del contract, quedan
escritos en `RUNBOOK.md` (secciones "AC41 — la Parte 0 aborta por lo que
el cluster CONTIENE, no por el nombre de la base" y "AC42 — el user tiene
las dos membresías, y el `DENY` gana"). Estado: **pendiente-de-ejecucion**
para las dos — no se declaran en verde sin haber corrido contra
infraestructura real, mismo criterio que AC1–AC8 y AC10 desde ronda 1.

## AC1–AC10 — sin cambio en la naturaleza de la evidencia

AC1–AC8 y AC10 siguen `manual-only`/automatizable respectivamente, sin
cambios de fondo en esta ronda más que la corrección de cifras (AC7,
AC10: 32 en vez de "~35") y la inserción del paso de Parte 0 antes del
paso 1 en "Orden de ejecución". AC9 re-verificado arriba con su triple
completo. AC10 (`grep -ni "no queda cubierta" RUNBOOK.md`) re-corrido
tras la reescritura del párrafo: `bash -c 'grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md'` → exit 0, línea 514 en la versión final de esta ronda (desplazada por las secciones AC41/AC42 nuevas insertadas antes).

## Impact set — ronda 4

Dos archivos existentes cambiaron de contenido semántico (no sólo
comentarios) por primera vez en R1: `plugins/bisalta-db/scripts/catalogo.js`
(enum `GARANTIAS` suma `'deny-escritura'`) y `plugins/bisalta-db/catalogo.json`
(entrada `dev-sql` suma esa garantía). Consumidores grepeados:

```
$ grep -rn "require(.\./catalogo\|require('./catalogo" plugins/bisalta-db/scripts/*.js
plugins/bisalta-db/scripts/servidor-mcp.js:35:const catalogo = require('./catalogo.js');
```

`servidor-mcp.js` importa el módulo pero no referencia `GARANTIAS`
directamente (grepeado: sin coincidencias de `GARANTIAS` fuera de
`catalogo.js`) — el símbolo que cambió es sólo consumido por la propia
función de validación del mismo archivo y por `SDD/tests/test_catalogo.sh`
(AC11–AC14, AC36), corrido antes y después del cambio con resultado `PASS`
las dos veces (ver brief, "Validation Executed (ronda 4)").

Los siete archivos de `aprovisionamiento/` (seis modificados + uno nuevo)
siguen sin ningún caller dentro del repo:

```
$ grep -rl "aprovisionamiento" --include="*.sh" --include="*.js" SDD/ plugins/ 2>/dev/null
```

Sin coincidencias (además de la prosa del propio brief/runbook/contract).

## Rojos preexistentes

Ninguno. La suite completa (17 archivos — creció de 14 a 17 entre rondas
por trabajo de otros ciclos del propio plugin `sdd-flow`, no de este
brief; `AC40`/`AC38` de este contract exigen derivar la cifra, no
citarla) está verde en la base y sigue verde después de esta ronda.


---

# Addendum de ronda 5 — un BLOCKER de la misma forma tres veces, y decisiones nuevas (contract v6)

Este addendum se escribió cuando el bloque superior del archivo era la
salida de `sdd-run-gates.sh` sellada en el commit `8cc326d` (tree
`4f8cbf7cbfc5f2403f82008d196381aa958d048b`, ver encabezado hasta arriba de
este archivo). El runner **sobreescribe el archivo completo** (trampa
D34/D35, ya conocida de rondas 1-4): este addendum, igual que los
anteriores, se pega DESPUÉS de esa corrida, sobre el árbol ya commiteado.
Los addenda de rondas 1-4 quedan preservados íntegros arriba de éste, sin
tocar una palabra — recuperados con `git show 8cc326d~1:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
contra el commit inmediatamente anterior a la corrida de esta ronda.

## Por qué se reabrió esta ronda

Reviewer de ronda 5: un BLOCKER (tercera vez de la misma forma que J2 de
ronda 3 y M5 de ronda 2 — una comprobación corrida sobre un objeto cuyo
estado no es el que el AC afirma), cuatro MAJOR, y contract v6 con tres
decisiones nuevas de Patrick Ocampo (Slack 2026-09-18 15:52 CST): `SSISDB`
fuera del loop, Postgres seguimos escribiéndolo nosotros, aprobación de
Dev SQL pendiente de reemplazo íntegro (sin acción en R1 todavía — el
texto corregido no llegó).

## BLOCKER — AC42, la segunda mitad corría sobre `zz_scratch_ac6`

`RUNBOOK.md` (versión pre-ronda-5, commit `8cc326d~1`) comprobaba "el
`INSERT` sigue fallando pese al `GRANT` explícito" contra la base de
scratch que el procedimiento de AC6 arma con `CREATE USER` + `ALTER ROLE
db_datareader ADD MEMBER` **únicamente** (nunca corre
`sqlserver-parte-b.sql`). Verificado contra el commit anterior:

```
$ git show 8cc326d~1:plugins/bisalta-db/aprovisionamiento/RUNBOOK.md | sed -n '452,462p'
```

Confirma que `bisalta_lectura` en `zz_scratch_ac6` nunca tiene
`db_denydatawriter` — un `GRANT INSERT` ahí pasa con o sin el `DENY` real,
así que la comprobación no probaba lo que el AC afirma.

**Fix** (`RUNBOOK.md:445-539`, sección "AC42 — el user tiene las dos
membresías, y el `DENY` gana", actual): la segunda mitad ahora corre sobre
`zz_scratch_ac42`, aprovisionada por una corrida real de
`sqlserver-parte-b.sql` (`-b -i sqlserver-parte-b.sql`, sin `-d`, procesa
el servidor completo — idempotente sobre las 31 ya provistas, agrega las
dos membresías a la base nueva). Ahí `CREATE TABLE t` + `GRANT INSERT` +
`INSERT` sí falla con `The INSERT permission was denied`.
`zz_scratch_ac6` y `zz_scratch_ac42` quedan completamente desacopladas:

```
$ grep -n "zz_scratch_ac6" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
335:sqlcmd -S 10.24.40.137 -E -Q "CREATE DATABASE zz_scratch_ac6;"
336:sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura; ALTER ROLE db_datareader ADD MEMBER bisalta_lectura; ALTER ROLE db_datawriter ADD MEMBER bisalta_lectura; CREATE TABLE t (id int);"
337:SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac6 -Q "INSERT INTO t VALUES (1);"
356:sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "ALTER ROLE db_datawriter DROP MEMBER bisalta_lectura;"
357:SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac6 -Q "INSERT INTO t VALUES (1);"
369:sqlcmd -S 10.24.40.137 -E -Q "DROP DATABASE zz_scratch_ac6;"
463:**La segunda mitad del AC no se corrobora sobre `zz_scratch_ac6`** (hallazgo
```

Las seis primeras coincidencias son la sección propia de AC6 (sin cambios,
ya correcta desde ronda 3); la séptima es la explicación, dentro de la
sección de AC42, de por qué esa base dejó de usarse ahí. Cero apariciones
de `zz_scratch_ac6` dentro del cuerpo de la comprobación de AC42.

## MAJOR 1 — el triple de AC42 no cerraba en verde

El contract exige literal "Restaurar el loop y revocar el `INSERT`: el
`DENY` vuelve a ganar" — no sólo limpiar. La versión pre-ronda-5 saltaba
de la mutación (rojo) directo a `REVOKE` + `DROP DATABASE`, sin observar
el `INSERT` fallando de nuevo. **Fix** (`RUNBOOK.md:519-535`): tras
restaurar `sqlserver-parte-b.sql` real, se corre otra vez el mismo
`INSERT` sobre la misma tabla `t` y el mismo `GRANT` que la mutación había
dejado pasar — recién ahí, con el verde de cierre observado, se revoca y
se borra. `ALTER ROLE ... ADD MEMBER` es aditivo (no hay `DROP MEMBER`
implícito al re-correr el script), así que el paso de mutación
(`RUNBOOK.md:505-513`) recrea `zz_scratch_ac42` fresca (`DROP DATABASE` +
`CREATE DATABASE`) en vez de asumir que alcanza con re-correr el script
sobre la base que la comprobación real ya dejó con las dos membresías.

## MAJOR 2 — la Parte 0 de Postgres medía algo que no discrimina

`has_database_privilege(rolname, datname, 'CONNECT')` ve el `CONNECT`
heredado de PUBLIC — eso sí lo prueba — pero Postgres lo concede a PUBLIC
por omisión en TODA base, así que esa columna sale `true` para cualquier
rol en cualquier base, **con o sin** `pg_read_all_data`. Sola, no
discrimina: un `GRANT pg_read_all_data` omitido habría pasado igual de
verde. **Fix** (`postgres-parte-0.sql:83-94`): agregada
`pg_has_role(rolname, 'pg_read_all_data', 'MEMBER') AS lee_todo_el_cluster`
como segunda columna del PASO 1 — membresía de cluster, la misma en las
29 bases porque no depende de en cuál se consulta. Prosa reescrita
(`postgres-parte-0.sql:31-50`) para afirmar sólo lo que cada columna
prueba por separado, y lo que las dos juntas permiten afirmar. Mismo fix
propagado a `RUNBOOK.md:151-164` (sección AC41). Diff real de la consulta:

```
$ git diff 8cc326d~1 8cc326d -- plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql | grep '^[+-]SELECT\|^[+-]       '
-SELECT r.rolname AS rol,
-       d.datname AS base,
-       has_database_privilege(r.rolname, d.datname, 'CONNECT') AS puede_conectar
+SELECT r.rolname AS rol,
+       d.datname AS base,
+       has_database_privilege(r.rolname, d.datname, 'CONNECT') AS puede_conectar,
+       pg_has_role(r.rolname, 'pg_read_all_data', 'MEMBER') AS lee_todo_el_cluster
```

Contract v6 pide este mismo fix para el script que Patrick mande (todavía
no llegó): el comentario de `postgres-parte-0.sql:8-16` deja escrito que
este archivo es implementación de referencia hasta entonces, con el fix
ya aplicado — "vale para los dos scripts".

## MAJOR 3/4 — el README contradecía el catálogo y el contract v6

`README.md:161` (pre-ronda-5) listaba el enum de `garantias` sin
`deny-escritura`, que `catalogo.js:38` y la entrada `dev-sql` de
`catalogo.json:33` ya usan desde ronda 4:

```
$ git diff 8cc326d~1 8cc326d -- plugins/bisalta-db/README.md | grep -A1 -B1 "garantias.*al menos"
 | `region` | cadena no vacía |
-| `garantias` | al menos un elemento de `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura` |
+| `garantias` | al menos un elemento de `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura`, `deny-escritura` |
```

`README.md:131-139` ("Garantías por motor") seguía diciendo que en SQL
Server el rol "es la única barrera" y no tenía fila para el `DENY`.
Reescrita para que coincida con la tabla homónima del contract
(`SDD/contracts/2026-09-18-bisalta-db-mcp.md:238-242`, las cinco filas de
datos): agregada la fila `DENY de escritura sobre el rol` y actualizada
`Alcance del permiso` para nombrar las dos membresías.

Salida real de `diff <(sed -n '238,242p' SDD/contracts/2026-09-18-bisalta-db-mcp.md) <(sed -n '135,139p' plugins/bisalta-db/README.md)`:

```diff
3,5c3,5
< | `DENY` de escritura sobre el rol | no aplica | sí, `db_denydatawriter` — el `DENY` le gana a cualquier `GRANT` (v4) |
< | Motor que rechaza escrituras | sí, endpoint `cluster-ro-` de Aurora | **no hay réplica** |
< | Alcance del permiso | `pg_read_all_data`, de cluster | `db_datareader`, **por base**: una base nueva no queda cubierta sola |
---
> | `DENY` de escritura sobre el rol | no aplica | sí, `db_denydatawriter` — el `DENY` le gana a cualquier `GRANT` |
> | Motor que rechaza escrituras | sí (endpoint `cluster-ro-`) | **no hay réplica** |
> | Alcance del permiso | `pg_read_all_data`, de cluster — alcanza las 29 bases del cluster de dev/qa desde que el rol existe, no sólo las del catálogo | `db_datareader` + `db_denydatawriter`, **por base**: una base nueva no queda cubierta sola |
```

Las dos primeras filas de datos (`Rol de solo lectura`, `Sesión abierta en
solo lectura`) salen idénticas y no aparecen en el diff. Las tres
restantes difieren sólo en fraseo (el contract cita "(v4)" y el endpoint
de Aurora con más detalle; el README agrega la cifra de 29 bases), nunca
en el hecho que afirman — ninguna contradicción de contenido entre las
dos, sólo prosa distinta para el mismo dato.

## `SSISDB` queda fuera del loop (contract v6, punto 1)

Decisión de Patrick Ocampo, textual: *"guarda los proyectos desplegados
con sus parámetros y connection managers, o sea que es un lugar donde
viven cadenas de conexión, más los logs de ejecución. Cero dato de
negocio y sí credenciales."* `sqlserver-parte-b.sql:63` agrega
`AND name <> 'SSISDB'` al `WHERE` del cursor (`database_id > 4` no la
agarra: su `database_id` es 36). El script pasa de cubrir 32 bases a
cubrir **31** — comentario de cabecera actualizado
(`sqlserver-parte-b.sql:23-34`). `sqlserver-inverso.sql:37` suma la misma
exclusión por nombre, explícita — no cambia el comportamiento (el
`IF EXISTS` ya la saltaba sola, `SSISDB` nunca tuvo el user) pero deja la
misma condición visible en los dos scripts, mismo criterio por el que el
filtro de la parte B es una condición del `WHERE` y no un salto implícito.
`RUNBOOK.md` reemplaza la sección "Decisión pendiente: SSISDB" (título y
contenido, `RUNBOOK.md:588-619`) por "`SSISDB` queda fuera del loop", con
la decisión y su razón; AC7 (`RUNBOOK.md:431-443`) actualizado: `tiene_user
= 1` esperado en 31 bases, `tiene_user = 0` en las cuatro de sistema y en
`SSISDB`.

```
$ grep -c "AND name <> 'SSISDB'" plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:1
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql:1
$ grep -c "SSISDB" plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:4
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql:2
```

## Postgres sigue siendo nuestro (contract v6, punto 2)

Patrick avisó que su Parte 0 ya existe, con condición equivalente
(`datname ILIKE '%prod%'`), pero todavía no la mandó. `postgres-parte-0.sql`
de R1 queda como implementación de referencia hasta que llegue —
`postgres-parte-0.sql:8-16` lo deja escrito — con el fix de MAJOR 2 ya
incorporado, porque el contract dice explícitamente que vale para los dos
scripts, el propio y el que llegue.

## Hallazgo propio del barrido de cierre — `APROBACIONES.md`

No nombrado por el review. `APROBACIONES.md:46` (pre-ronda-5) afirmaba
"`db_datareader` sobre el servidor alcanza las 32" — cifra que la
exclusión de `SSISDB` deja desactualizada: ahora son 31. Corregido en el
mismo commit, citando el contract v6:

Salida real de `git diff 8cc326d~1 8cc326d -- plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`,
pegada tal cual:

```diff
-Esto **no invalida la aprobación**: `db_datareader` sobre el servidor alcanza las 32 con
-o sin esa enumeración, y el texto dice "las bases de Dev SQL", no una lista cerrada. Se
-deja escrito porque la diferencia entre lo enumerado y lo medido es exactamente el tipo
-de cosa que después nadie puede reconstruir. Comunicado a Patrick el mismo día.
+Esto **no invalida la aprobación**: `db_datareader` sobre el servidor alcanza 31 de las 32
+con o sin esa enumeración (`SSISDB` queda fuera del loop por decisión de Patrick, contract
+v6, "Cambios v5 → v6" punto 1 — no guarda dato de negocio y sí credenciales), y el texto
+dice "las bases de Dev SQL", no una lista cerrada. Se deja escrito porque la diferencia
+entre lo enumerado y lo medido es exactamente el tipo de cosa que después nadie puede
+reconstruir. Comunicado a Patrick el mismo día.
```

## Barrido de clase (grep, no memoria) — pedido explícito del brief de ronda 5

**1. ¿Otra comprobación que corra sobre un objeto cuyo estado no sea el
que el AC afirma (la forma exacta del BLOCKER)?**

```
$ grep -n "Mutación declarada" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
171:**Mutación declarada** (contract v5, AC41): en una copia de trabajo de
225:**Mutación declarada** (contract v3, AC2): antes de verificar el
331:**Mutación declarada** (contract v3, AC6): en una base de scratch,
374:**Mutación declarada** (contract v3, AC7): sobre una instancia de prueba
499:**Mutación declarada** (contract v5, AC42): en una copia de trabajo de
```

Revisadas las cinco: AC41 corre contra el cluster real de dev/qa, sin
objeto de scratch (no aplica la forma). AC2 y AC6 ya corregidas en rondas
2-3 (mutación y comprobación real sobre el mismo objeto, `DROP` como
último paso — sin cambios esta ronda). AC7 corregida en ronda 3 (mismo
cursor `##ac7_check` para la mutación y la comprobación final). AC42
corregida esta ronda (BLOCKER de arriba). Cero coincidencias adicionales.

**2. ¿Otra medición que devuelva lo mismo con el sistema bien y mal (la
forma exacta de MAJOR 2)?**

```
$ grep -rn "has_database_privilege\|pg_has_role" plugins/bisalta-db/aprovisionamiento/*.sql plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql:35:--     - has_database_privilege(..., 'CONNECT'): ve el CONNECT heredado de
plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql:41:--     - pg_has_role(rolname, 'pg_read_all_data', 'MEMBER'): membresía DE
plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql:88:       has_database_privilege(r.rolname, d.datname, 'CONNECT') AS puede_conectar,
plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql:89:       pg_has_role(r.rolname, 'pg_read_all_data', 'MEMBER') AS lee_todo_el_cluster
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:153:conectar (`has_database_privilege(...,'CONNECT')`, cierta para **cualquier**
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:157:`pg_read_all_data` (`pg_has_role(...,'MEMBER')`, membresía de cluster, la
```

Única medición de este tipo en todo el árbol es la de la Parte 0, ya con
las dos columnas. Las comprobaciones de identidad/membresía de SQL Server
(`sys.database_role_members`, AC1, AC42) no comparten el patrón: ahí
`EXISTS`/`IN` sobre una junta de tres tablas sí distingue presente de
ausente sin depender de un default heredado. Cero coincidencias
adicionales del patrón "columna que siempre da lo mismo".

**3. ¿Otra tabla del README o del runbook que contradiga el catálogo o el
contract v6?**

```
$ grep -n "GARANTIAS = \[" plugins/bisalta-db/scripts/catalogo.js
38:const GARANTIAS = ['rol-solo-lectura', 'sesion-read-only', 'endpoint-replica-lectura', 'deny-escritura'];
$ grep -n "garantias.*al menos un elemento" plugins/bisalta-db/README.md
162:| `garantias` | al menos un elemento de `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura`, `deny-escritura` |
$ grep -n "garantias.*rol-solo-lectura.*sesion-read-only.*endpoint-replica-lectura.*deny-escritura" SDD/contracts/2026-09-18-bisalta-db-mcp.md
194:| `garantias` | requerido | arreglo de al menos un elemento, cada uno exactamente `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura` o `deny-escritura` (v4) | el catálogo entero se rechaza |
```

Los tres listan los mismos cuatro valores. `grep -rn "32 bases\|las 32\b"
plugins/bisalta-db/` (ver "Hallazgo propio" arriba) fue el único punto
adicional que encontró una cifra vieja no propagada — ya corregido. Sin
más tablas divergentes encontradas.

## AC41/AC42 — estado tras ronda 5

Siguen `manual-only`, `pendiente-de-ejecucion`: ningún harness de este
repo levanta un cluster Postgres real ni alcanza `10.24.40.137` (misma
razón declarada desde ronda 1). Los procedimientos corregidos de AC42
(BLOCKER + MAJOR 1) y AC41 (MAJOR 2) quedan escritos y listos para
ejecutar en `RUNBOOK.md`; no se declara ningún AC en verde sin haberlo
corrido.

## Prueba por mutación — AC9, sin cambios esta ronda

`postgres-parte-a.sql` (el único archivo al que la mutación declarada de
AC9 aplica) no cambió de contenido en esta ronda — verificado:

```
$ git diff 8cc326d~1 8cc326d -- plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql
(sin salida — sin diferencias)
```

Mismo criterio que ronda 3 ("AC9 sin cambios... su triple ya está en el
addendum, no se repite porque el AC no cambió"): el triple completo más
reciente sigue en el addendum de ronda 4 de este archivo, sin repetirse
acá. Confirmado en verde sobre el árbol de esta ronda (ver tabla de gates
al principio del archivo, gate 9, exit 0, y la re-verificación post-commit
más abajo).

## Impact set — ronda 5

Los seis archivos modificados (`postgres-parte-0.sql`, `sqlserver-parte-b.sql`,
`sqlserver-inverso.sql`, `RUNBOOK.md`, `APROBACIONES.md`, `README.md`)
siguen sin ningún consumidor de código dentro de este repo — son
prosa/SQL para un operador humano, no módulos que otro script importe:

```
$ grep -rl "aprovisionamiento" --include="*.sh" --include="*.js" SDD/ plugins/ 2>/dev/null
(sin coincidencias, además de la prosa del propio brief/runbook/contract)
```

`README.md` tampoco tiene callers de código (es documentación); su tabla
de garantías la lee `catalogo.js` como fuente de verdad del enum
(`GARANTIAS`), no al revés — el README describe, no valida.

## Rojos preexistentes

Ninguno. La suite completa (17 archivos, sin cambio desde ronda 4) está
verde en la base y sigue verde después de esta ronda — ningún fix de
ronda 5 tocó un `.sh` de `SDD/tests/`.

## Re-verificación tras pegar este addendum (trampa D34/D35)

El runner selló el árbol en el commit `8cc326d`, pero este addendum se
agrega DESPUÉS de esa corrida. Por eso, después de comittear este
addendum, se vuelve a correr `bash SDD/tests/secret-scan.sh` sobre el
árbol final ya commiteado — ese es el único verde que cuenta para esta
ronda. Comando y exit code de esa corrida final quedan en el "Validation
Executed (ronda 5)" del brief (`SDD/briefs/R1-infra-accesos-lectura.md`),
no acá, para no duplicar la misma corrida en dos archivos con riesgo de
que uno quede desactualizado si el otro se corrige.
