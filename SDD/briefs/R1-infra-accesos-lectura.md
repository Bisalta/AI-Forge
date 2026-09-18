# Task brief — R1 · infra: accesos de solo lectura en Postgres dev/qa y Dev SQL

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v1**, ACs **AC1–AC10**
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya creada; **NO crear otra, NO commitear a `prod`**)
- **Proxima subtask**: `GEN-108.1`, id `cd0ed6b7-fde8-4381-9a69-e4e684498813` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
- **Depende de**: nada. Es el primero del orden de integración R1 → R2.

## Problema

Las dos identidades que el plugin `bisalta-db` va a usar **no existen todavía**, en ningún motor. Sin ellas el servidor MCP no tiene contra qué conectarse, y los ACs de conexión real de R2 no se pueden correr.

El aprovisionamiento no es un detalle de operación: es donde vive la garantía. El servidor puede tener la lista blanca perfecta y seguir siendo capaz de escribir si el rol de base está mal dado de alta. Por eso R1 va antes que R2 y no al revés.

## Decisión de diseño (cerrada en el contract — no la re-abras)

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

- [ ] T1.1 Verificar que `shellcheck` esté instalado (`command -v shellcheck`). Si falta, correr `brew install shellcheck` — sin él el gate 2 sale `[SKIPPED]` y nunca verde.
- [ ] T1.2 Escribir `postgres-parte-a.sql`: crear los dos roles con `LOGIN`, `GRANT pg_read_all_data` a cada uno, sin `NOINHERIT`. Idempotente: envolver la creación en un bloque que no falle si el rol ya existe.
- [ ] T1.3 Escribir `postgres-parte-b.sql`: `GRANT CONNECT` sobre la base y lo que `pg_read_all_data` no cubre por sí solo. Idempotente.
- [ ] T1.4 Escribir `postgres-inverso.sql`: revoca y borra los dos roles, tolerando que no existan.
- [ ] T1.5 Escribir `sqlserver-parte-a.sql`: login de servidor con la contraseña como parámetro sustituible.
- [ ] T1.6 Escribir `sqlserver-parte-b.sql`: cursor sobre `sys.databases` filtrando `database_id > 4` y `state = 0` (en línea), creando el user y agregándolo a `db_datareader` en cada una. Idempotente.
- [ ] T1.7 Escribir `sqlserver-inverso.sql`: recorrido inverso más `DROP LOGIN`.
- [ ] T1.8 Escribir `RUNBOOK.md` con: prerequisitos, orden de ejecución (primero `proveedores_dev`, verificar, después el resto), la forma del secreto de AWS (dos campos, `username` y `password`, en la forma estándar de RDS — **escribilos en spans separados, nunca contiguos con su valor**, o el gate 9 se detecta a sí mismo), la política IAM, los pasos de verificación de AC1–AC8 con su mutación, y el inverso.
- [ ] T1.9 **AC10**: el runbook declara explícito que una base nueva de SQL Server **no queda cubierta** hasta re-correr la parte B.
- [ ] T1.10 Commitear (árbol limpio) y correr la escalera de gates: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
- [ ] T1.11 **AC9 con su triple**: correr `bash SDD/tests/secret-scan.sh` (verde) → insertar el literal con forma de credencial en `postgres-parte-a.sql` y volver a correrlo (rojo) → revertir y correrlo otra vez (verde). Las tres corridas, con comando literal y exit code, van al verification report a mano.

## Acceptance criteria (IDs del contract v1 — no los renumeres)

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
| AC1 | | `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | |
| AC2 | | `RUNBOOK.md` | |
| AC3 | | `RUNBOOK.md` | |
| AC4 | | `RUNBOOK.md` | |
| AC5 | | `RUNBOOK.md` | |
| AC6 | | `RUNBOOK.md` | |
| AC7 | | `RUNBOOK.md` | |
| AC8 | | `RUNBOOK.md` | |
| AC9 | | `SDD/tests/secret-scan.sh` | |
| AC10 | | | |

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

### Task Status

### Validation Executed

### Blockers

### Files Changed

### Final Statement
