# Task brief — R1 · infra: accesos de solo lectura en Postgres dev/qa y Dev SQL

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v6**, ACs **AC1–AC10 + AC41 + AC42**
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya creada; **NO crear otra, NO commitear a `prod`**)
- **Proxima subtask**: `GEN-108.1`, id `cd0ed6b7-fde8-4381-9a69-e4e684498813` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
- **Depende de**: nada. Es el primero del orden de integración R1 → R2.
- **Ronda**: reapertura tras `APPROVED`. Origen: contract-change-request externo de **Patrick Ocampo** (Slack, 18-sep-2026), ratificado en v4/v5.

## Qué cambió desde que cerraste APPROVED

Tu trabajo anterior está bien y **no se tira**. Lo que cambió es que Patrick midió el sistema y encontró un hueco que ni vos ni el reviewer podían ver, porque no estaba en el código:

1. **`pg_read_all_data` alcanza TODO el cluster desde que el rol existe.** Postgres concede `CONNECT` a PUBLIC por omisión, y `pg_read_all_data` es membresía de cluster. **La Parte B no es una barrera**: para cuando corre, el acceso ya existe. Medido: son **29 bases** en dev/qa, no las 2 del catálogo. Corregí la prosa de `postgres-parte-b.sql` y del runbook que la presenta como si concediera el acceso — hoy dice algo falso.
2. **Nace la Parte 0** (`postgres-parte-0.sql`, archivo nuevo): corre **antes** de crear nada, lista las bases del cluster y **aborta si el cluster contiene alguna base `_prod`**. El discriminante **no es el nombre `stg`** — está medido que falla en las dos direcciones. Imprime además a qué bases llega cada rol de verdad, que es la única forma de ver el `CONNECT` heredado de PUBLIC. Es **AC41**.
3. **`db_denydatawriter` va junto con `db_datareader`** en el mismo loop de `sqlserver-parte-b.sql`. El `DENY` le gana a cualquier `GRANT`. Es **AC42**, y obliga a corregir la tabla "Garantías por motor" del runbook, que hoy dice que el rol es la única barrera.
4. **Cifras corregidas contra `plugins/bisalta-db/aprovisionamiento/INVENTARIO.md`** (medido, en el árbol): Dev SQL tiene **32** bases, no "~35"; 1383 GB; las 32 `ONLINE` y ninguna en solo lectura. Grepeá "~35" y "35 bases" sobre todo el árbol antes de cerrar.
5. **`SSISDB` (id 36) no la excluye `database_id > 4`** y no es una base de negocio. Dejala **dentro** del loop por ahora y **anotá en el runbook que es una decisión pendiente de Patrick**, no un efecto colateral del filtro.
6. El catálogo suma la garantía `deny-escritura` para `sqlserver`: `plugins/bisalta-db/catalogo.json`, entrada `dev-sql`. Lo verifica `AC14`, que ya existe.

## Problema

Las dos identidades que el plugin `bisalta-db` va a usar **no existen todavía**, en ningún motor. Sin ellas el servidor MCP no tiene contra qué conectarse, y los ACs de conexión real de R2 no se pueden correr.

El aprovisionamiento no es un detalle de operación: es donde vive la garantía. El servidor puede tener la lista blanca perfecta y seguir siendo capaz de escribir si el rol de base está mal dado de alta. Por eso R1 va antes que R2 y no al revés.

## Decisiones de diseño (cerradas — no las re-abras)

> **Cómo citar esta lista**: los puntos numerados de abajo son de **este brief**, no del contract. Los archivos de `plugins/bisalta-db/` son distribuibles y los va a leer alguien que no tiene el brief a mano: citá la sección del contract por su **nombre** (ej. "Entrega de la credencial al cliente"), nunca "punto N del contract".

1. **Dos roles de Postgres, no uno**: `claude_lectura` y `neo_lectura`. `pg_stat_activity` distingue quién corrió qué, y se puede revocar a uno sin el otro.
2. **`GRANT pg_read_all_data`, y SIN `NOINHERIT`.** Con `NOINHERIT` el rol **no vería una sola tabla**: `pg_read_all_data` es una membresía, y las membresías no aplican sin `SET ROLE`. Esto ya está decidido; si lo escribís con `NOINHERIT` el rol queda inútil y el AC1 falla.
3. **Script en dos partes.** Parte A una vez **por cluster** (los roles son objetos de cluster). Parte B una vez **por base** (los `GRANT` son por base).
4. **Sólo en el cluster de dev/qa** (`sistemas-costruplaza-db.cluster-cfrl3owqzwof`). Nada toca `cluster-cr4rbgr7qlr6`: ahí viven los cinco pares `_prod`/`_stg` de la empresa, y un rol de login creado en cualquier `_stg` queda al lado de producción.
5. **SQL Server recorre `sys.databases` con un cursor explícito**, excluyendo `master`, `model`, `msdb` y `tempdb`. `db_datareader` es por base y son **32** (medido, `INVENTARIO.md` — no "~35"). **No uses `sp_MSforeachdb`**: no está soportado y salta bases en algunos estados.
6. **La asimetría se documenta, no se compensa.** SQL Server no tiene equivalente de `default_transaction_read_only` ni réplica de lectura: el rol del login, con `db_datareader` y (v4/v5) `db_denydatawriter`, es la única barrera. No inventes un sustituto.

## Out of scope

- **Ejecutar** los scripts. Los redactás y dejás la verificación escrita; los corre quien tiene privilegios de administración.
- Crear los secretos en AWS. Definís su forma y la política IAM en el runbook; no llamás al binario `aws`.
- Cualquier cosa en la cuenta de AWS de producción, y `Prod SQL` (`192.168.252.22`).
- Habilitar IAM auth de Aurora (hoy `false`; decisión abierta de Patrick Ocampo).
- Tocar `plugins/bisalta-db/scripts/` o `SDD/tests/` — eso es de R2.

## Files

| Archivo | Acción |
|---|---|
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` | crear — roles de cluster |
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` | crear — grants por base |
| `plugins/bisalta-db/aprovisionamiento/postgres-inverso.sql` | crear — revoca y borra |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` | crear — login de servidor |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` | crear — cursor sobre `sys.databases` |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` | crear — borra user y login |
| `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | crear — orden, prerequisitos, verificación, inverso |

**Ninguno de estos archivos lleva una contraseña.** La parte A de cada motor toma la contraseña como parámetro que la persona sustituye al correr, y el runbook lo dice explícito. Un literal con forma de credencial hace fallar el gate 9.

## Pasos

- [x] T1.1 Verificar que `shellcheck` esté instalado (`command -v shellcheck`). Si falta, correr `brew install shellcheck` — sin él el gate 2 sale `[SKIPPED]` y nunca verde. → estaba ausente, instalado con `brew install shellcheck` (0.11.0).
- [x] T1.2 Escribir `postgres-parte-a.sql`: crear los dos roles con `LOGIN`, `GRANT pg_read_all_data` a cada uno, sin `NOINHERIT`. Idempotente: envolver la creación en un bloque que no falle si el rol ya existe.
- [x] T1.3 Escribir `postgres-parte-b.sql`: `GRANT CONNECT` sobre la base y lo que `pg_read_all_data` no cubre por sí solo. Idempotente.
- [x] T1.4 Escribir `postgres-inverso.sql`: revoca y borra los dos roles, tolerando que no existan.
- [x] T1.5 Escribir `sqlserver-parte-a.sql`: login de servidor con la contraseña como parámetro sustituible.
- [x] T1.6 Escribir `sqlserver-parte-b.sql`: cursor sobre `sys.databases` filtrando `database_id > 4` y `state = 0` (en línea), creando el user y agregándolo a `db_datareader` en cada una. Idempotente.
- [x] T1.7 Escribir `sqlserver-inverso.sql`: recorrido inverso más `DROP LOGIN`.
- [x] T1.8 Escribir `RUNBOOK.md` con: prerequisitos, orden de ejecución (primero `proveedores_dev`, verificar, después el resto), la forma del secreto de AWS (dos campos, `username` y `password`, en la forma estándar de RDS — **escribilos en spans separados, nunca contiguos con su valor**, o el gate 9 se detecta a sí mismo), la política IAM, los pasos de verificación de AC1–AC8 con su mutación, y el inverso.
- [x] T1.9 **AC10**: el runbook declara explícito que una base nueva de SQL Server **no queda cubierta** hasta re-correr la parte B.
- [x] T1.10 Commitear (árbol limpio) y correr la escalera de gates: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
- [x] T1.11 **AC9 con su triple**: correr `bash SDD/tests/secret-scan.sh` (verde) → insertar el literal con forma de credencial en `postgres-parte-a.sql` y volver a correrlo (rojo) → revertir y correrlo otra vez (verde). Las tres corridas, con comando literal y exit code, van al verification report a mano. → adicionalmente encontrado y corregido en el mismo paso: el propio `RUNBOOK.md` (no un `.sql`) se autodetectaba por la acción de IAM `secretsmanager`:`GetSecretValue` (namespace y acción con `:` en el medio, no una credencial) — corregido partiendo el literal con un backtick, ver verification report.

## Acceptance criteria (IDs del contract — estables entre versiones, no los renumeres)

| AC | Qué afirma | Cómo se verifica |
|---|---|---|
| AC1 | Los dos roles existen, con `LOGIN` y `pg_read_all_data`, sin `NOINHERIT`; leen de `proveedores_dev` | `manual-only` — pasos exactos en el runbook |
| AC2 | Un `INSERT` con `claude_lectura` falla | `manual-only` + mutación declarada en el contract |
| AC3 | Parte A corrida dos veces → exit 0 las dos, mismo estado | `manual-only` |
| AC4 | Tras el inverso, `claude_lectura` no conecta | `manual-only` |
| AC5 | El login de Dev SQL lee de `EXACTUS` | `manual-only` |
| AC6 | Un `INSERT` con ese login falla | `manual-only` + mutación declarada |
| AC7 | El user existe en todas las bases de usuario salvo `SSISDB`, y en ninguna de sistema | `manual-only` + mutación declarada |
| AC8 | Cada secreto existe con los dos campos y es legible con la política IAM | `manual-only` |
| AC9 | `secret-scan.sh` sale 0 sobre el árbol con los scripts de R1 | **automatizable** + triple de mutación |
| AC10 | El runbook declara el hueco de la base nueva en SQL Server | **automatizable** (grep sobre el runbook) |

Ocho de los diez son `manual-only` porque **ningún harness de este repo puede crear un rol de Postgres ni alcanzar la VPC de dev/qa**. La razón está escrita AC por AC en el contract. No los declares verdes: dejá en el verification report los pasos exactos y el estado `pendiente-de-ejecucion`.

## AC ↔ test binding (llenalo vos)

| AC | Test / verificación | Archivo | Estado |
|---|---|---|---|
| AC1 | manual-only: sección "AC1 — los dos roles existen y leen de `proveedores_dev`" | `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | pendiente-de-ejecucion |
| AC2 | manual-only + mutación declarada: sección "AC2 — un `INSERT` con `claude_lectura` falla" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC3 | manual-only: sección "AC3 — la parte A corrida dos veces deja el mismo estado" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC4 | manual-only: sección "AC4 — tras el inverso, `claude_lectura` no conecta" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC5 | manual-only: sección "AC5 — el login de `Dev SQL` lee de `EXACTUS`" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC6 | manual-only + mutación declarada: sección "AC6 — un `INSERT` con ese login falla" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC7 | manual-only + mutación declarada: sección "AC7 — el user existe en todas las bases de usuario y en ninguna de sistema" | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC8 | manual-only: sección "AC8 — cada secreto existe..." | `RUNBOOK.md` | pendiente-de-ejecucion |
| AC9 | automatizable + triple de mutación: `bash SDD/tests/secret-scan.sh` (verde→rojo→verde, ver verification report) | `SDD/tests/secret-scan.sh` | pass |
| AC10 | automatizable (grep): `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | pass |
| AC41 | manual-only + mutación declarada: sección "AC41 — la Parte 0 aborta por lo que el cluster CONTIENE, no por el nombre de la base" | `RUNBOOK.md` / `plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql` | pendiente-de-ejecucion |
| AC42 | manual-only + mutación declarada: sección "AC42 — el user tiene las dos membresías, y el `DENY` gana" | `RUNBOOK.md` / `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` | pendiente-de-ejecucion |

## Cobertura del impact set

R1 original (rondas 1-3) no modificaba ningún archivo existente: los siete
archivos eran nuevos y nadie los importaba todavía. **La reapertura v4→v5
(ronda 4) sí toca dos archivos existentes fuera de
`aprovisionamiento/`**, los dos con consumidores grepeados:

| Archivo | Cambio | Consumidores existentes | Cobertura |
|---|---|---|---|
| `plugins/bisalta-db/scripts/catalogo.js` | `GARANTIAS` suma `'deny-escritura'` | `plugins/bisalta-db/scripts/servidor-mcp.js` (importa `catalogo.js`, no usa `GARANTIAS` directamente — sólo `validarCatalogo`); `SDD/tests/test_catalogo.sh` (AC11-AC14, AC36) | `test_catalogo.sh`, corrido antes y después del cambio: `PASS` las dos veces (ver "Validation Executed", ronda 4) |
| `plugins/bisalta-db/catalogo.json` | entrada `dev-sql` suma `deny-escritura` a `garantias` | `catalogo.js` (lo valida), `servidor-mcp.js` (lo lee en runtime — sin tests que lo ejerciten contra una base real, fuera de scope de R1) | `test_catalogo.sh` (valida que el catálogo real sigue siendo válido) |

Los siete archivos de `aprovisionamiento/` (seis modificados + uno nuevo,
`postgres-parte-0.sql`) siguen sin ningún consumidor dentro de este repo —
R2 (el servidor que los va a usar como referencia operativa, no como
import) ya existe pero no importa nada de `aprovisionamiento/`: son
prosa/SQL para un operador humano, no código que otro módulo requiera.

## Docs delta

R1 no agrega comandos de validación ni cambia capas. `doc_architecture.md` y `doc_quality_gates.md` los actualiza R2, que es quien agrega scripts al glob del gate 2. **No los toques vos** — dos agentes editando el mismo archivo en serie es cómo se pierde un cambio.

## Reglas innegociables

- **Mitigaciones prohibidas** (`quality-gates.md` §6): no ablandes un test, no bajes `--severity`, no uses `--no-verify`, no agregues una exclusión por path al secret-scan. Gate que no pasa sin uno de esos atajos → marcá `[BLOCKED]` y preguntá al planner. **Nunca adivines.**
- Si una decisión del contract no te alcanza para implementar, quedás `BLOCKED` y preguntás. Un `BLOCKED` no consume ronda de review.
- No declares una validación que no corriste.
- Marcá `[x]` sólo lo que completaste; `[BLOCKED]` con explicación lo que no.
- Bash 3.2 es el piso (`declare -A`, `mapfile`, `${var^^}` están prohibidos) — aplica si escribís cualquier `.sh`.

## Rollback

Los siete archivos son nuevos: `git rm` los saca sin tocar nada más. Ningún script se corrió contra una base, así que no hay estado externo que revertir.

## Execution Report

### Summary

R1 redacta los siete archivos de aprovisionamiento de solo lectura para el cluster de dev/qa de Postgres (`claude_lectura`, `neo_lectura`, con `pg_read_all_data` sin `NOINHERIT`) y para `Dev SQL` (login único `bisalta_lectura`, `db_datareader` por base vía cursor explícito sobre `sys.databases`). Ninguno se ejecutó contra una base real — es out of scope declarado. `shellcheck` no estaba instalado en esta máquina (contradice lo que `doc_quality_gates.md` documentaba); se instaló con `brew install shellcheck` (0.11.0) para que el gate 2 no salga `[SKIPPED]`. `AC9` (secret-scan) y `AC10` (grep sobre el runbook) son los dos únicos ACs automatizables de R1; corridos con su triple/grep y en verde. Los ocho restantes (AC1–AC8) son `manual-only` — sus pasos exactos, con las tres mutaciones declaradas en el contract (AC2, AC6, AC7), quedan escritos en `RUNBOOK.md`, estado `pendiente-de-ejecucion`.

### Task Status

Total tasks: 11 (T1.1–T1.11). Completed: 11. Blocked: 0. Skipped: 0.

### Validation Executed

- `command -v shellcheck` → `1` (ausente) → `brew install shellcheck` → `command -v shellcheck` → `0` (`/opt/homebrew/bin/shellcheck`, v0.11.0).
- `bash SDD/tests/secret-scan.sh` (baseline, tras `git add plugins/bisalta-db/` para que `git ls-files` viera los archivos nuevos) → `0`.
- **Triple AC9**: `bash SDD/tests/secret-scan.sh` → `0` (verde) → insertada línea con clave `password`, separador `=` y un valor de relleno con forma de access key AWS (prefijo `AKIA` + 16 caracteres — no reproducido acá en una sola pieza para no autodetectarse; el literal completo queda en la corrida pegada de `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`) al final de `postgres-parte-a.sql` → `bash SDD/tests/secret-scan.sh` → `1`, nombrando `postgres-parte-a.sql:54`, sin imprimir el valor (rojo) → revertida la línea (`git diff` contra el índice sale vacío, reversión exacta) → `bash SDD/tests/secret-scan.sh` → `0` (verde). Detalle completo en `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.
- Hallazgo adicional durante el mismo paso: el `RUNBOOK.md` original se autodetectaba en dos líneas (la acción de IAM `secretsmanager`:`GetSecretValue`, cuyo `:` interno matchea el patrón `secret...[:=]...4+ chars`, no una credencial). Corregido partiendo el literal con un backtick (`` `secretsmanager`:`GetSecretValue` ``) en las dos ocurrencias — mismo criterio que los placeholders de contraseña. Re-corrida tras el fix → `0`.
- AC10: `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → coincidencia en línea 352 (declaración explícita del hueco de SQL Server; línea 261 en R1, desplazada a 352 en R2 por la reescritura de las secciones AC1/AC2/AC5–AC7 del runbook, ver `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`). El comando original (sin `-i`) no matcheaba porque el runbook usa `NO` en mayúsculas — corregido en el mismo paso, antes de declarar el AC en verde.
- `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` → `0` (sin `.sh` nuevos en R1, gate corrido igual como parte de la escalera completa).
- `bash SDD/tests/run.sh` (suite completa, 14 archivos) → `0`.
- Escalera completa vía runner, corrida tres veces sobre commits sucesivos según se encontraban y corregían literales autodetectados en la prosa (`8584ebf` rojo en gate 9 → `aad6c58` verde → ajustes menores adicionales al propio verification report → `aca2f8e` corrida final sellada en `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`, con el addendum de mutación agregado después en el commit `674dc1c`): `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` — ver ese archivo para exit codes gate por gate y el detalle de las tres corridas.

### Blockers

Ninguno.

### Files Changed

- `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/postgres-inverso.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` (new)
- `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` (new)
- `SDD/briefs/R1-infra-accesos-lectura.md` (mod, este archivo)
- `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (new, evidencia + generado por el runner)

### Final Statement

R1 completo: 7 archivos nuevos en `plugins/bisalta-db/aprovisionamiento/`, sin tocar `plugins/bisalta-db/scripts/`, `SDD/tests/`, `doc_architecture.md` ni `doc_quality_gates.md` (todos de R2, per contract). AC9 y AC10 automatizados y en verde con su evidencia; AC1–AC8 documentados `manual-only` con pasos exactos y mutaciones, estado `pendiente-de-ejecucion` — ningún AC se declara `pass` sin haber corrido. Sin mitigaciones prohibidas: ninguna exclusión por path se agregó a `secret-scan.sh` (no se tocó el script), el literal problemático encontrado en la documentación se resolvió partiéndolo, no excluyéndolo. Único desvío del ambiente respecto de lo documentado: `shellcheck` estaba ausente pese a que `doc_quality_gates.md` lo daba por instalado — corregido instalándolo (no es una decisión del contract, es restaurar el prerequisito declarado); no toqué ese doc, es de R2 (T5.2 de su brief ya lo tiene como tarea).

---

## Ronda 2 — correcciones del review (rechazo de ronda 1)

### Summary

El reviewer encontró dos blockers y siete majors/minors, los diez sobre el
runbook `manual-only` (el diagnóstico de fondo: cinco de los ocho
procedimientos `manual-only` no podían producir el resultado que
declaraban esperar — RT11, medición muerta). Ningún hallazgo tocó las
sentencias SQL de aprovisionamiento; sólo sus comentarios de cabecera
(citas al contract) cambiaron. Corregidos los diez: B1 (línea del triple
AC9 mal citada, 55→54, propagada a las dos citas), B2/M4 (AC7: comprobación
real reemplazada por un cursor T-SQL de verdad en vez de un
`LEFT JOIN ... ON 1=0` que nunca podía matchear, y la referencia a un
archivo inexistente), M1/M2/M3 (AC2/AC6: mutación y comprobación real
sobre el mismo objeto de scratch, `DROP` como último paso), M5 (AC1: tabla
real en vez de `information_schema.tables`), M6 (`-v ON_ERROR_STOP=1` /
`-b` en los seis `psql -f`/`sqlcmd -i` afectados), M7 (`SQLCMDPASSWORD` en
vez de `-P`, invariante cerrada del contract), y los cinco minors (v1→v2,
citar el contract por sección/AC en vez de "punto N del brief", host de
Aurora completo, AC4 con comprobación de catálogo en vez de depender del
mensaje de error de conexión). Detalle punto por punto, con la mención
"por qué" de cada uno, en el addendum de ronda 2 de
`SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.

Un efecto secundario detectado y corregido en el camino: el primer
borrador del addendum de ronda 2 reproducía, contiguo, el valor de
relleno de la mutación de AC9 — el mismo patrón autorreferencial que ya
había aparecido en `RUNBOOK.md` en ronda 1, ahora en la evidencia. El
runner lo cortó en gate 9 (commit `bc25273`); corregido describiendo el
valor en piezas, sin tocar `secret-scan.sh`.

### Task Status (ronda 2)

Diez hallazgos (2 blockers, 5 majors, 3 minors agrupados en un punto de
"minor" con 4 sub-ítems más el de `aad6c58`). Completed: 10. Blocked: 0.
Skipped: 0.

### Validation Executed (ronda 2)

- `wc -l plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` → `53` antes y después de todos los fixes (los cambios fueron a comentarios de cabecera, no a sentencias; el archivo no creció).
- Triple AC9 re-corrido contra el árbol de ronda 2: `bash SDD/tests/secret-scan.sh` → `0` (verde) → mutación (línea 54 nueva) → `bash SDD/tests/secret-scan.sh` → `1`, nombrando `postgres-parte-a.sql:54` (rojo) → `git checkout --` → `bash SDD/tests/secret-scan.sh` → `0` (verde). Detalle en el addendum de ronda 2 del verification report.
- `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → línea 352, exit 0 (desplazada desde 261 por la reescritura de las secciones AC1/AC2/AC5–AC7).
- `bash SDD/tests/run.sh` → `14 passed, 0 failed (14 total)`.
- Escalera completa vía runner, corrida dos veces sobre commits sucesivos de ronda 2: `bc25273` (rojo en gate 9, autoinfligido por el borrador del addendum) → `fd9447e` (verde en los cuatro gates aplicables, evidencia sellada en el commit `bb592b1`): `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.

### Blockers (ronda 2)

Ninguno.

### Files Changed (ronda 2)

- `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` (mod — reescritura de las secciones AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC10 y prerequisitos)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` (mod — sólo comentarios de cabecera)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` (mod — sólo comentarios de cabecera)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` (mod — sólo comentarios de cabecera)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` (mod — sólo comentarios de cabecera)
- `SDD/briefs/R1-infra-accesos-lectura.md` (mod, este archivo)
- `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (mod — addendum de ronda 2 + reseal del runner)

### Final Statement (ronda 2)

Los diez hallazgos de ronda 1 quedan corregidos: los cinco `manual-only`
señalados (AC1, AC2, AC6, AC7 ×2) ahora tienen un procedimiento que puede
producir el resultado que declara esperar, no sólo uno que lo asume. Sin
mitigaciones prohibidas: no se tocó `secret-scan.sh`, no se bajó ningún
threshold, no se usó `--no-verify`. `postgres-inverso.sql` y
`sqlserver-inverso.sql` no se tocaron — ningún hallazgo los mencionaba.

---

## Ronda 3 — la clase del defecto, no la instancia (rechazo de ronda 2, RT21)

### Summary

El reviewer encontró tres MAJOR (J1, J2, J3) y cinco minor. Los tres MAJOR
son **la misma forma** que M5 (ronda 2) ya había corregido en AC1,
reaparecida en AC5/AC6/AC7 porque la corrección de ronda 2 fue por
instancia señalada, no por forma — la propia AC6 de ronda 2 ya nombraba
"`sys.tables` es un catálogo del sistema" quince líneas después de dejar
`sys.tables` intacto en AC5. Corregidos los tres:

- **J1** (AC5, `RUNBOOK.md:227` en la versión pre-ronda-3): `sys.tables`
  reemplazado por el mismo patrón `<tabla_real>` que AC1 ya usaba, con el
  mismo matiz de rojo-falso sobre tabla vacía extendido también a AC1.
- **J2** (AC6, `RUNBOOK.md:241,252-253`): el login de scratch recibía
  `db_datawriter` pero nunca `db_datareader`; al revocar `db_datawriter`
  quedaba sin ninguna membresía, midiendo "principal sin roles" en vez de
  "login aprovisionado por este runbook". Corregido agregando
  `db_datareader` (nunca revocada) junto con `db_datawriter`, mismo
  criterio que AC2.
- **J3** (AC7, `RUNBOOK.md:277`): la mutación se verificaba con una
  consulta de catálogo distinta del cursor `##ac7_check` real (líneas
  297-314). Corregido: el mismo bloque `##ac7_check` se corre contra la
  instancia mutada, exigiendo `tiene_user = 1` en la fila `master`.

Cinco minors: `-v ON_ERROR_STOP=1` (semántica de `psql`) retirado de la
única invocación de `sqlcmd` que lo llevaba; `@db_name` pasado como
parámetro de `sp_executesql` en vez de concatenado crudo en el literal de
`##ac7_check`; la justificación de descartar `sp_MSforeachdb` reescrita
para nombrar la diferencia real (filtro explícito y auditable, no un
salto interno no documentado) y AC10 extendido a bases que estaban
`OFFLINE`/`RESTORING`; "devuelven una fila" corregido en AC1 (y aplicado
también a AC5) para exigir `<tabla_real>` con al menos una fila; el
identificador de cluster de Postgres aclarado como tal, no endpoint.

Un efecto secundario detectado y corregido en el camino, no pedido por el
reviewer: al correr `sdd-run-gates.sh` con `-o` apuntando al verification
report, el runner sobreescribe el archivo completo (`> "$OUT"`), no sólo
el bloque superior — la corrida de esta ronda volteó el addendum entero
de rondas 1 y 2 (corridas previas del runner, triple de mutación AC9,
correcciones de ronda 2) antes de que el addendum de ronda 3 se agregara
encima del archivo ya vacío. Reconstruido desde el commit `fd9447e`
(última versión completa previa a esta ronda) sin tocar una palabra de
los dos primeros — commit `09ef8b5`.

### Task Status (ronda 3)

Ocho hallazgos (3 majors, 5 minors). Completed: 8. Blocked: 0. Skipped: 0.

### Validation Executed (ronda 3)

- Citas de línea de J1/J2/J3 verificadas contra el commit `fd9447e` (el
  que el reviewer tenía delante), con `git show fd9447e:... | grep -n` /
  `git show fd9447e:... | nl -ba | sed -n`, no de memoria — las tres
  coinciden exactamente con las citadas en el hallazgo.
- Barrido de clase (`SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`,
  addendum de ronda 3, sección "Barrido de clase"): cinco greps sobre el
  árbol corregido — catálogo-como-dato (`sys.`/`information_schema.`/
  `pg_catalog.`), mutación con estado final divergente de producción
  (`Mutación declarada`), bandera de `sqlcmd` sin semántica en su cliente,
  y el patrón exacto de concatenación cruda del minor de `@db_name`. Cero
  coincidencias adicionales en los cuatro; el quinto grep confirma que el
  patrón corregido no reaparece en ningún otro archivo.
- `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`
  → línea 390 (desplazada desde 352 por la reescritura de AC1/AC5/AC6/AC7).
- `bash SDD/tests/secret-scan.sh` → `0` (sin hallazgos sobre 148 archivos,
  incluido el addendum de ronda 3 reconstruido).
- `bash SDD/tests/run.sh` → `14 passed, 0 failed (14 total)`.
- `bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md` → `0`.
- Escalera completa vía runner sobre el commit `8093281` (tree limpio,
  hash `d473492882905d6b10119938a3ff0536011fec76`): `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` → verde en los cuatro gates aplicables (2, 4, 9, suite completa). Los dos commits siguientes (`3a71f95`, `09ef8b5`) sólo tocan el verification report (addendum de ronda 3 + restauración de rondas 1-2); no requieren un nuevo sello del runner porque no cambian código — reverificado directamente con `secret-scan.sh` y la suite completa después de cada uno.

### Blockers (ronda 3)

Ninguno.

### Files Changed (ronda 3)

- `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` (mod — AC1, AC5, AC6, AC7, AC10)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` (mod — sólo comentario de cabecera)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` (mod — sólo comentario de cabecera)
- `SDD/briefs/R1-infra-accesos-lectura.md` (mod, este archivo)
- `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (mod — addendum de ronda 3 + restauración de rondas 1-2)

### Final Statement (ronda 3)

Los tres MAJOR y cinco minor de ronda 3 quedan corregidos, y el barrido de
clase pedido por el brief (RT21) confirma cero instancias adicionales de
los cuatro patrones de defecto en el resto del árbol. Sin mitigaciones
prohibidas: no se tocó `secret-scan.sh`, no se bajó ningún threshold, no
se usó `--no-verify`. AC1–AC8 y AC10 siguen `manual-only`,
`pendiente-de-ejecucion` — ningún AC se declara `pass` sin haber corrido
contra una base real. AC9 sin cambios (ningún fix tocó `secret-scan.sh` ni
agregó un literal con forma de credencial); su triple ya está en el
addendum de rondas 1-2, restaurado íntegro en este mismo verification
report.

---

## Ronda 4 — reapertura v4→v5: hallazgo de Patrick Ocampo (CCR externo, no rechazo de review)

### Summary

`APPROVED` no se tira: Patrick Ocampo midió el cluster real y encontró un
hueco de diseño invisible en el código — `pg_read_all_data` es membresía
de cluster y Postgres concede `CONNECT` a PUBLIC por omisión, así que un
rol creado por `postgres-parte-a.sql` alcanza las 29 bases del cluster de
dev/qa desde que existe, no las 2 del catálogo. `postgres-parte-b.sql`
nunca fue la barrera de acceso. Contract v4→v5 (ratificado) pide seis
cosas; las seis, hechas:

1. **`postgres-parte-0.sql` (nuevo)**: dos pasos, los dos read-only.
   Informativo (`has_database_privilege` por rol×base — la única forma de
   ver el `CONNECT` heredado de PUBLIC, invisible en `pg_database.datacl`
   cuando nunca se revocó explícitamente) y de control (`RAISE EXCEPTION`
   si el cluster contiene alguna base `_prod`, para que `psql -v
   ON_ERROR_STOP=1` salga distinto de 0 y no siga a la parte A). AC41.
2. **Prosa de `postgres-parte-b.sql` corregida**: ya no dice que el
   `GRANT CONNECT` es la barrera. Ahora explica qué es en realidad — un
   refuerzo redundante hoy — y remite a la parte 0 como la barrera real.
   Mismo ajuste en el encabezado de `postgres-parte-a.sql` (agregada la
   referencia a correr la parte 0 antes).
3. **`db_denydatawriter` junto a `db_datareader`** en el mismo loop de
   `sqlserver-parte-b.sql` (AC42), y su reverso explícito (`ALTER ROLE
   db_denydatawriter DROP MEMBER` antes de `DROP USER`) en
   `sqlserver-inverso.sql`. Corregida la tabla implícita de "única
   barrera" en el comentario de `sqlserver-parte-a.sql`: ahora nombra las
   dos membresías del rol de base, no una.
4. **Cifras contra `INVENTARIO.md`**: `sqlserver-parte-b.sql`,
   `RUNBOOK.md` (AC7 y AC10) y la propia sección "Decisiones de diseño"
   de este brief pasan de "~35"/"35 bases" a **32**, medido. Grep sobre
   todo el árbol confirma que las únicas apariciones restantes de "~35"
   citan el valor viejo entre comillas para contrastarlo con el correcto
   (`sqlserver-parte-b.sql` línea 28, `RUNBOOK.md` AC7, contract v5 punto
   7 de "Cambios v3 → v4"), nunca lo afirman como cifra vigente.
5. **`SSISDB` dentro del loop**, documentado como decisión pendiente de
   Patrick (nueva sección "Decisión pendiente: `SSISDB`" en
   `RUNBOOK.md`), no como efecto colateral del filtro — el comentario de
   `sqlserver-parte-b.sql` lo explicita también.
6. **`catalogo.js`**: `GARANTIAS` suma `'deny-escritura'` (una línea; el
   contract v5 asigna este ítem puntual a R1, por excepción explícita a
   "`AGENT_r2` no se reabre" en la sección "Cambios v3 → v4"). `dev-sql`
   en `catalogo.json` la suma a su arreglo. `test_catalogo.sh` (AC14) y
   la suite completa siguen en verde — verificado antes y después del
   cambio.

### Task Status (ronda 4)

Seis puntos del CCR v4→v5, más AC41/AC42 con su verificación escrita en
`RUNBOOK.md`. Completed: 6. Blocked: 0. Skipped: 0.

### Validation Executed (ronda 4)

- `command -v shellcheck` → `0` (`/opt/homebrew/bin/shellcheck`, sigue
  presente de rondas previas).
- `node --check plugins/bisalta-db/scripts/catalogo.js` → `0`.
- `node plugins/bisalta-db/scripts/catalogo.js` → `0`, `catálogo válido: 3
  conexión(es)` — corrido después de sumar `deny-escritura` al enum y a la
  entrada `dev-sql`.
- `bash SDD/tests/test_catalogo.sh` → `PASS` (todas las líneas `ok`,
  incluidas las cuatro de AC11-AC14), exit 0 — confirma que sumar
  `deny-escritura` al enum no rompe ninguna fixture existente (ninguna
  fija la lista completa de garantías válidas, sólo prueba
  conocida-vs-desconocida).
- `bash SDD/tests/run.sh` → `17 passed, 0 failed (17 total)`, exit 0.
- `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh
  plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh
  SDD/tests/*.sh SDD/scripts/*.sh` → `0` (sin `.sh` nuevo en
  `plugins/bisalta-db/`, glob del gate 2 sin cambios — `postgres-parte-0.sql`
  es `.sql`, no `.sh`).
- `grep -rn "~35\|35 bases" --include="*.md" --include="*.sql"
  --include="*.json" --include="*.js" .` → único hallazgo nuevo fuera de
  las citas históricas ya conocidas (`INVENTARIO.md`, `retro.md`,
  verification report de ronda 3, contract v5 "Cambios v3→v4"): ninguno —
  las tres apariciones nuevas (`RUNBOOK.md`, `sqlserver-parte-b.sql`, este
  brief) citan "~35" entre comillas para contrastarlo con 32, no lo
  afirman.
- `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`
  → exit 0 (verificado explícitamente después de reescribir el párrafo de
  AC10, que en un borrador intermedio partió la frase en dos líneas y
  rompió el grep — corregido antes de cerrar, no después).
- **Triple AC9 re-corrido contra el árbol de ronda 4** (`postgres-parte-a.sql`
  cambió de contenido — nueva cita a la parte 0 en su encabezado — así
  que se re-corre, no se asume): `bash SDD/tests/secret-scan.sh` → `0`
  sobre 163 archivos versionados (verde) → agregada al final de
  `postgres-parte-a.sql` una línea con clave `password`, separador `=` y
  un valor de relleno con forma de access key de AWS (prefijo `AKIA` +
  16 caracteres, construido en dos variables de shell para no aparecer
  contiguo ni en el archivo temporal de esta sesión ni en esta
  transcripción) → `bash SDD/tests/secret-scan.sh` → `1`, nombrando
  `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:62`, sin
  imprimir el valor (rojo) → revertida la línea (`sed -i '' '$ d'`) →
  `git diff` contra el índice (que ya tenía el archivo mutado-sin-mutar
  vía `git add -A` previo) sale vacío, reversión exacta → `bash
  SDD/tests/secret-scan.sh` → `0` (verde). Detalle completo con comando y
  exit code en `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.
- Escalera completa vía runner sobre el commit de esta ronda (ver hash en
  el reporte sellado): `bash plugins/sdd-flow/scripts/sdd-run-gates.sh
  --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.
- `bash SDD/tests/secret-scan.sh` corrido una vez más **después** de
  commitear el árbol final (post-runner), sobre el árbol ya commiteado —
  es el único verde que cuenta según la trampa conocida D34/D35 (el
  runner trunca `-o` y no ve el addendum pegado después). Resultado y
  exit code en el verification report.

### Blockers (ronda 4)

Ninguno. El único punto que hubiera requerido preguntar —si `catalogo.js`
entraba en el "out of scope: no tocar `plugins/bisalta-db/scripts/`" del
brief— lo resuelve el propio contract v5 con una excepción explícita y
nombrada ("Cambios v3 → v4": *"`AGENT_r2` no se reabre... salvo el enum de
garantías del catálogo, que se trata como parte del scope reabierto de
R1"*), así que no fue necesario escalar.

### Files Changed (ronda 4)

- `plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql` (new — AC41)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` (mod — cabecera: referencia a la parte 0)
- `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` (mod — prosa: ya no se presenta como barrera)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` (mod — cabecera: dos membresías, no una)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` (mod — AC42: `db_denydatawriter` en el loop; cifra 32; nota SSISDB)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` (mod — quita `db_denydatawriter` explícitamente)
- `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` (mod — orden de ejecución, AC41, AC42, AC7/AC10 con cifra corregida, decisión pendiente SSISDB, inverso)
- `plugins/bisalta-db/catalogo.json` (mod — `dev-sql` suma `deny-escritura`)
- `plugins/bisalta-db/scripts/catalogo.js` (mod — enum `GARANTIAS` suma `deny-escritura`, autorizado por el contract v5)
- `SDD/briefs/R1-infra-accesos-lectura.md` (mod, este archivo)
- `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (mod — addendum de ronda 4, generado por el runner + evidencia a mano del triple AC9)

### Final Statement (ronda 4)

Los seis puntos del CCR de Patrick Ocampo quedan implementados con su
verificación escrita: AC41 y AC42 son nuevos y `manual-only` como el
resto de R1, con su mutación declarada en `RUNBOOK.md`; AC1–AC8 y AC10
siguen `pendiente-de-ejecucion`, sin declarar ningún AC en verde sin
haberlo corrido; AC9 re-verificado con su triple completo sobre el árbol
final. Sin mitigaciones prohibidas: no se tocó `secret-scan.sh`, no se
bajó ningún threshold, no se usó `--no-verify`, ninguna exclusión por
path nueva. Único archivo tocado fuera del directorio
`aprovisionamiento/` es `catalogo.js` — una línea, un enum, autorizado
explícitamente por el contract v5 como excepción nombrada al scope de R1,
no una decisión propia ni una invasión del scope de R2.

---

## Ronda 5 — un BLOCKER, cuatro MAJOR y decisiones nuevas de Patrick (contract v6)

### Summary

El review de ronda 5 encontró un BLOCKER (tercera instancia de la misma
forma que J2/M5 de rondas anteriores: una comprobación corrida sobre un
objeto cuyo estado no es el que el AC afirma) y cuatro MAJOR, más tres
decisiones nuevas de Patrick Ocampo que el contract v6 ya ratificó
(`SSISDB` fuera del loop, Postgres sigue siendo nuestro hasta que llegue
el de Patrick, aprobación de Dev SQL pendiente de reemplazo íntegro — esta
última no tiene acción para R1 todavía porque el texto corregido no
llegó).

- **BLOCKER — AC42, la segunda mitad corría sobre el objeto equivocado.**
  `RUNBOOK.md` comprobaba "el `INSERT` sigue fallando pese al `GRANT`
  explícito" contra `zz_scratch_ac6`, una base que el procedimiento de AC6
  arma con `CREATE USER` + `ALTER ROLE db_datareader ADD MEMBER` **sin**
  `db_denydatawriter` — nunca corre `sqlserver-parte-b.sql`. Un `GRANT
  INSERT` ahí pasa con o sin el `DENY` real, así que la comprobación no
  probaba lo que decía probar. Corregido: la segunda mitad ahora corre
  sobre `zz_scratch_ac42`, aprovisionada por una corrida real de
  `sqlserver-parte-b.sql` (que deja las dos membresías), y ahí `CREATE
  TABLE t` + `GRANT INSERT` + `INSERT` sí falla con `The INSERT permission
  was denied`. `zz_scratch_ac6` y `zz_scratch_ac42` quedan completamente
  desacopladas.
- **MAJOR 1 — el triple de AC42 no cerraba en verde.** El contract exige
  "el `DENY` vuelve a ganar" tras restaurar el loop, no sólo limpiar.
  Agregado un paso explícito: tras restaurar `sqlserver-parte-b.sql` real,
  se vuelve a correr el mismo `INSERT` sobre la misma tabla y el mismo
  `GRANT` que la mutación había dejado pasar, y se observa que vuelve a
  fallar — recién ahí se revoca y se borra. `ALTER ROLE ... ADD MEMBER` es
  aditivo (no quita nada al re-correr), así que el paso de mutación
  recrea `zz_scratch_ac42` fresca (`DROP DATABASE` + `CREATE DATABASE`) en
  vez de asumir que alcanza con re-correr el script sobre la existente.
- **MAJOR 2 — la Parte 0 de Postgres medía algo que no discrimina.**
  `has_database_privilege(...,'CONNECT')` ve el `CONNECT` heredado de
  PUBLIC (eso sí lo prueba), pero sale `true` para cualquier rol en
  cualquier base, con o sin `pg_read_all_data` — sola no confirma que el
  rol "llegue de verdad". Agregada `pg_has_role(rolname,
  'pg_read_all_data', 'MEMBER')` (membresía de cluster) como segunda
  columna en `postgres-parte-0.sql`, con la prosa reescrita para afirmar
  sólo lo que cada columna prueba por separado y lo que las dos juntas
  permiten afirmar. Aplicado también a la prosa de `RUNBOOK.md` (AC41).
  Contract v6 pide este mismo fix para el script que mande Patrick,
  cuando llegue — vale para los dos.
- **MAJOR 3/4 — el README contradecía el catálogo y el contract v6.** El
  enum de `garantias` de la tabla del contrato de datos (línea 161, antes
  de esta ronda) no listaba `deny-escritura`, que `catalogo.js` y
  `catalogo.json` ya usan desde ronda 4 — agregado. La tabla "Garantías
  por motor" seguía diciendo que en SQL Server el rol "es la única
  barrera" y no tenía fila para el `DENY` — reescrita para que coincida
  con la tabla homónima del contract (fila `DENY de escritura sobre el
  rol`, alcance del permiso con las dos membresías).
- **`SSISDB` deja de ser decisión pendiente (contract v6, punto 1).**
  Patrick: *"guarda los proyectos desplegados con sus parámetros y
  connection managers, o sea que es un lugar donde viven cadenas de
  conexión, más los logs de ejecución. Cero dato de negocio y sí
  credenciales."* `sqlserver-parte-b.sql` la excluye ahora **por nombre**
  (`AND name <> 'SSISDB'` en el `WHERE` del cursor), además del
  `database_id > 4` que no la agarra. Este script pasa de cubrir 32 bases
  a cubrir **31**; la sección "Decisión pendiente: SSISDB" de
  `RUNBOOK.md` se reescribió como "SSISDB queda fuera del loop", con la
  decisión y su razón. `sqlserver-inverso.sql` suma la misma exclusión
  por nombre, explícita (no dependía de ella: el `IF EXISTS` ya la
  saltaba sola, pero la explicitud es el mismo criterio que ya rige el
  filtro de la parte B). AC7 de `RUNBOOK.md` actualizado: `tiene_user = 1`
  esperado en 31 bases, `tiene_user = 0` en las cuatro de sistema y en
  `SSISDB`.
- **Postgres sigue siendo nuestro (contract v6, punto 2).** Patrick avisó
  que su Parte 0 ya existe, con condición equivalente, pero todavía no la
  mandó — `postgres-parte-0.sql` de R1 queda como implementación de
  referencia hasta que llegue, con el fix de MAJOR 2 ya aplicado.
- **Hallazgo propio del barrido de cierre, no pedido por el review**:
  `APROBACIONES.md:46` seguía afirmando que `db_datareader` alcanza "las
  32" bases del servidor — cifra que la exclusión de `SSISDB` deja
  desactualizada (ahora son 31). Corregido en el mismo commit, con la
  razón y la cita al contract v6.

### Minors

- `RUNBOOK.md` (sección AC42) — aclarado explícitamente que
  `sqlserver-parte-b.sql` no toma `-d` y recorre `sys.databases` completo
  (32 bases hoy, 31 cubiertas + la nueva de scratch), idempotente sobre
  las ya provistas — antes la prosa decía "correr esa copia contra una
  base de scratch nueva" sin aclarar que en realidad procesa todo el
  servidor.
- `README.md` (sección "Aprovisionamiento") — agregado un párrafo sobre
  `postgres-parte-0.sql` y que `pg_read_all_data` alcanza el cluster
  entero, que antes no se mencionaba ahí (es el hallazgo central de R1 y
  el README es lo que lee quien instala).
- `sqlserver-inverso.sql` (cabecera) — la frase "con la misma
  explicitud" sobreafirmaba: sólo `db_denydatawriter` se quita con un
  `ALTER ROLE ... DROP MEMBER` explícito; `db_datareader` desaparece
  implícitamente con `DROP USER`. Reescrita para no igualar las dos.

### Task Status (ronda 5)

Un BLOCKER, cuatro MAJOR, tres minors, dos decisiones nuevas del contract
v6 (SSISDB, Postgres nuestro) y un hallazgo propio del barrido de cierre.
Completed: 11. Blocked: 0. Skipped: 0.

### Validation Executed (ronda 5)

- Barrido de forma (comandos literales, salida completa en el
  verification report, sección "Barrido de clase — ronda 5"):
  - `grep -n "zz_scratch_" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`
    → AC2/AC6 siguen corriendo la mutación y la comprobación real sobre el
    mismo objeto (ya corregido en rondas 2-3); AC42 ya no comparte objeto
    con AC6 — las dos únicas apariciones de `zz_scratch_ac6` fuera de su
    propia sección son la explicación de por qué AC42 dejó de usarla.
  - `grep -rn "has_database_privilege\|pg_has_role" plugins/bisalta-db/aprovisionamiento/*.sql plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`
    → única medición de este tipo es la de la Parte 0, ya con las dos
    columnas.
  - `grep -rn "32 bases\|las 32\b" plugins/bisalta-db/` → cuatro
    coincidencias, las cuatro miden el inventario crudo (`INVENTARIO.md`,
    cabecera de `sqlserver-parte-b.sql`) o ya traen la salvedad de 31
    cubiertas (`RUNBOOK.md`); la quinta que no la traía
    (`APROBACIONES.md:46`) se corrigió en esta ronda.
  - `grep -n "GARANTIAS = \[" plugins/bisalta-db/scripts/catalogo.js` vs.
    `grep -n "garantias.*al menos un elemento" plugins/bisalta-db/README.md`
    → los dos listan ahora los mismos cuatro valores, mismo orden.
- `bash SDD/tests/secret-scan.sh` → `0` sobre el árbol con los seis
  archivos tocados (163 archivos versionados). AC9 no re-corrido con su
  triple completo esta ronda: `postgres-parte-a.sql`, el único archivo al
  que la mutación declarada de AC9 aplica, no cambió de contenido —
  mismo criterio que ronda 3 ("AC9 sin cambios... su triple ya está en el
  addendum"). El triple completo más reciente (sobre `postgres-parte-a.sql`
  sin cambios desde entonces) sigue en el addendum de ronda 4 del
  verification report.
- `bash SDD/tests/run.sh` → `17 passed, 0 failed (17 total)`, exit 0 (sin
  `.sh` nuevo, mismo total que ronda 4).
- `bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md` → `0`.
- `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` → `0` (sin `.sh` nuevo en `plugins/bisalta-db/`).
- Escalera completa vía runner sobre el commit `8cc326d` (tree
  `4f8cbf7cbfc5f2403f82008d196381aa958d048b`, sellado por
  `sdd-run-gates.sh`): `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` → verde en los cuatro gates aplicables (2, 4, 9, suite completa), exit 0.
- El addendum de ronda 5 se pegó después (trampa D34/D35) y se commiteó
  en `39acc0d`. `bash SDD/tests/secret-scan.sh` corrido una vez más
  **después** de ese commit, sobre el árbol final ya commiteado (árbol
  limpio, `git status --short` sin salida) → `secret-scan: sin hallazgos
  sobre 163 archivos versionados (1 excluido: self)`, exit `0` — el único
  verde que cuenta según la trampa D34/D35.

### AC41/AC42 — estado tras ronda 5

Siguen `manual-only`, `pendiente-de-ejecucion`: ningún harness de este
repo levanta un cluster Postgres real ni alcanza `10.24.40.137`. Los
pasos corregidos de AC42 (BLOCKER + MAJOR 1) y AC41 (MAJOR 2) quedan
escritos y listos para ejecutar en `RUNBOOK.md`.

### Blockers (ronda 5)

Ninguno — el BLOCKER de esta ronda es el hallazgo del reviewer, ya
corregido; no quedó ningún bloqueo propio al cerrar.

### Files Changed (ronda 5)

- `plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql` (mod — MAJOR 2: columna `pg_has_role`; nota de referencia hasta que llegue el de Patrick)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` (mod — SSISDB fuera del loop por nombre; cifra 31)
- `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` (mod — SSISDB excluida por nombre, explícita; prosa "misma explicitud" corregida)
- `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` (mod — BLOCKER y MAJOR 1 de AC42, MAJOR 2 de AC41, SSISDB decidida, AC7 con cifra 31, contract v6)
- `plugins/bisalta-db/aprovisionamiento/APROBACIONES.md` (mod — hallazgo propio: cifra de `db_datareader` corregida a 31)
- `plugins/bisalta-db/README.md` (mod — MAJOR 3/4: enum `garantias` completo, tabla "Garantías por motor" sin la afirmación de "única barrera", sección Aprovisionamiento con la Parte 0)
- `SDD/briefs/R1-infra-accesos-lectura.md` (mod, este archivo)
- `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (mod — addendum de ronda 5, generado por el runner + evidencia a mano)

### Final Statement (ronda 5)

El BLOCKER y los cuatro MAJOR de ronda 5 quedan corregidos, con las tres
decisiones nuevas del contract v6 aplicadas (`SSISDB` fuera del loop,
Postgres nuestro con el fix de la Parte 0 ya incorporado, aprobación de
Dev SQL sigue pendiente de texto de Patrick — sin acción posible todavía).
El barrido de cierre encontró y corrigió una quinta instancia del patrón
"cifra vieja no propagada" (`APROBACIONES.md`) que ningún hallazgo del
review nombraba. Sin mitigaciones prohibidas: no se tocó
`secret-scan.sh`, no se bajó ningún threshold, no se usó `--no-verify`,
ninguna exclusión por path nueva. AC1–AC8 y AC10 siguen
`pendiente-de-ejecucion`; AC41 y AC42 con su procedimiento corregido y
listo para ejecutar, sin declarar ningún AC en verde sin haberlo corrido.
