# Task brief — R1 · infra: accesos de solo lectura en Postgres dev/qa y Dev SQL

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v2**, ACs **AC1–AC10** (el bump v1 → v2 no tocó ninguno de ellos)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya creada; **NO crear otra, NO commitear a `prod`**)
- **Proxima subtask**: `GEN-108.1`, id `cd0ed6b7-fde8-4381-9a69-e4e684498813` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
- **Depende de**: nada. Es el primero del orden de integración R1 → R2.

## Problema

Las dos identidades que el plugin `bisalta-db` va a usar **no existen todavía**, en ningún motor. Sin ellas el servidor MCP no tiene contra qué conectarse, y los ACs de conexión real de R2 no se pueden correr.

El aprovisionamiento no es un detalle de operación: es donde vive la garantía. El servidor puede tener la lista blanca perfecta y seguir siendo capaz de escribir si el rol de base está mal dado de alta. Por eso R1 va antes que R2 y no al revés.

## Decisiones de diseño (cerradas — no las re-abras)

> **Cómo citar esta lista**: los puntos numerados de abajo son de **este brief**, no del contract. Los archivos de `plugins/bisalta-db/` son distribuibles y los va a leer alguien que no tiene el brief a mano: citá la sección del contract por su **nombre** (ej. "Entrega de la credencial al cliente"), nunca "punto N del contract".

1. **Dos roles de Postgres, no uno**: `claude_lectura` y `neo_lectura`. `pg_stat_activity` distingue quién corrió qué, y se puede revocar a uno sin el otro.
2. **`GRANT pg_read_all_data`, y SIN `NOINHERIT`.** Con `NOINHERIT` el rol **no vería una sola tabla**: `pg_read_all_data` es una membresía, y las membresías no aplican sin `SET ROLE`. Esto ya está decidido; si lo escribís con `NOINHERIT` el rol queda inútil y el AC1 falla.
3. **Script en dos partes.** Parte A una vez **por cluster** (los roles son objetos de cluster). Parte B una vez **por base** (los `GRANT` son por base).
4. **Sólo en el cluster de dev/qa** (`sistemas-costruplaza-db.cluster-cfrl3owqzwof`). Nada toca `cluster-cr4rbgr7qlr6`: ahí viven los cinco pares `_prod`/`_stg` de la empresa, y un rol de login creado en cualquier `_stg` queda al lado de producción.
5. **SQL Server recorre `sys.databases` con un cursor explícito**, excluyendo `master`, `model`, `msdb` y `tempdb`. `db_datareader` es por base y son ~35. **No uses `sp_MSforeachdb`**: no está soportado y salta bases en algunos estados.
6. **La asimetría se documenta, no se compensa.** SQL Server no tiene equivalente de `default_transaction_read_only` ni réplica de lectura: el rol del login es la única barrera. No inventes un sustituto.

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

## Acceptance criteria (IDs del contract v2 — no los renumeres)

| AC | Qué afirma | Cómo se verifica |
|---|---|---|
| AC1 | Los dos roles existen, con `LOGIN` y `pg_read_all_data`, sin `NOINHERIT`; leen de `proveedores_dev` | `manual-only` — pasos exactos en el runbook |
| AC2 | Un `INSERT` con `claude_lectura` falla | `manual-only` + mutación declarada en el contract |
| AC3 | Parte A corrida dos veces → exit 0 las dos, mismo estado | `manual-only` |
| AC4 | Tras el inverso, `claude_lectura` no conecta | `manual-only` |
| AC5 | El login de Dev SQL lee de `EXACTUS` | `manual-only` |
| AC6 | Un `INSERT` con ese login falla | `manual-only` + mutación declarada |
| AC7 | El user existe en todas las bases de usuario y en ninguna de sistema | `manual-only` + mutación declarada |
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

## Cobertura del impact set

R1 **no modifica ningún archivo existente**: los siete archivos son nuevos y nadie los importa todavía. Sin filas de regresión que justificar.

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
