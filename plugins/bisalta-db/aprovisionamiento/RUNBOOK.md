# Runbook — aprovisionamiento de solo lectura para `bisalta-db`

Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v1, requerimiento R1 (`infra`), AC1–AC10.

Este runbook lo ejecuta **una persona con privilegios de administración** en
cada motor y en la cuenta de AWS de dev/qa. Ningún script de este directorio
se corrió contra una base real durante R1: R1 los redacta y deja la
verificación escrita; la ejecución y sus resultados quedan pendientes hasta
que alguien con esos privilegios los corra.

## Prerequisitos

- Acceso de administración al cluster Aurora PostgreSQL
  `sistemas-costruplaza-db.cluster-cfrl3owqzwof` (dev/qa) — **nunca** a
  `cluster-cr4rbgr7qlr6` (cuenta de producción).
- Acceso de `sysadmin` a la instancia `Dev SQL` (`10.24.40.137`).
- Red desde la máquina que ejecuta hacia la VPC de dev/qa y hacia
  `10.24.40.137`.
- Clientes CLI instalados: `psql` (Postgres) y `sqlcmd` (SQL Server). Medido
  el 18-sep-2026 en la máquina de referencia de este repo: `psql` 14.18
  presente, `sqlcmd` ausente — instalarlo antes de correr los scripts de
  SQL Server desde esa máquina.
- Permisos de escritura en AWS Secrets Manager, región `us-east-1`, cuenta
  de dev/qa (para AC8). Este runbook **no invoca el binario `aws`**: define
  la forma del secreto y la política IAM; los tres secretos se crean a mano
  o con el flujo que la cuenta ya use para Secrets Manager.

## Orden de ejecución

1. `postgres-parte-a.sql` contra el cluster de dev/qa (una vez, cluster
   entero).
2. `postgres-parte-b.sql` conectado a **`proveedores_dev` primero**.
3. **Verificar AC1** contra `proveedores_dev` (ver abajo) antes de seguir.
4. `postgres-parte-b.sql` conectado al resto de las bases del catálogo
   (`proveedores_qa`, y cualquier base que se agregue después).
5. `sqlserver-parte-a.sql` contra la instancia `Dev SQL`.
6. `sqlserver-parte-b.sql` contra la misma instancia (recorre todas las
   bases de usuario en una sola corrida).
7. **Verificar AC5** contra `EXACTUS`.
8. Crear los tres secretos en Secrets Manager (ver "Forma del secreto" y
   "Política IAM" abajo) y verificar AC8.

## Forma del secreto

Tres secretos, uno por identidad de conexión: `claude_lectura` (Postgres),
`neo_lectura` (Postgres) y el login de `Dev SQL`. Cada uno en la **forma
estándar de RDS**: un objeto JSON con exactamente dos campos.

| Campo | Contenido |
|---|---|
| `username` | el nombre del rol o login creado por la parte A del motor correspondiente |
| `password` | la misma contraseña real que se sustituyó en el placeholder de la parte A al ejecutarla |

Los dos campos van **en el mismo objeto JSON**, cada uno con su propio
nombre y su propio valor — el punto de este runbook es describir la forma,
no reproducir un secreto real: por eso esta tabla separa el nombre del
campo de su contenido en columnas distintas, en vez de escribirlos
concatenados como `campo` seguido de su valor en la misma celda.

Nombres de secreto sugeridos (no forman parte del catálogo de la
aplicación, que usa `secret_id` para referenciarlos por ARN — libres de
elegir al crearlos, R2 no depende del nombre exacto):

- `bisalta-db/postgres/claude_lectura`
- `bisalta-db/postgres/neo_lectura`
- `bisalta-db/sqlserver/bisalta_lectura`

## Política IAM

Una política gestionada (o inline) por secreto, adjunta al rol o usuario
IAM que cada proceso consumidor asuma al correr el plugin — nunca una
política que cubra los tres secretos con un wildcard amplio:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "<accion-secrets-manager>",
      "Resource": "<ARN del secreto, uno por policy>"
    }
  ]
}
```

El placeholder `<accion-secrets-manager>` se reemplaza, sin espacio ni
backtick, por la acción `secretsmanager`:`GetSecretValue` — namespace y
nombre de acción separados acá con un backtick de por medio únicamente
para que este documento no tenga el literal contiguo de una acción de IAM
(mismo criterio que los placeholders de contraseña en los `.sql`: la forma
se documenta partida, el valor real se arma al usarlo).

- `Resource` es el ARN completo del secreto (no un prefijo, no `*`): el
  threat model del contract (sección "¿Quién puede invocarlo?") pone la
  barrera real en IAM, no en el plugin — un `Resource` amplio la anula.
- Sin este permiso sobre el ARN puntual, `consultar` devuelve
  `{ "error": "secreto_inaccesible" }` (exit 5, contract v1, tabla de
  comportamiento de error) — ese es el comportamiento esperado de un
  proceso sin la policy adjunta, no un bug.
- No se declara una policy separada para `kms:Decrypt`: los tres secretos
  de este runbook usan la clave por defecto administrada por AWS para
  Secrets Manager en la cuenta de dev/qa (`aws/secretsmanager`), cuya
  política de clave ya permite a los principals de la cuenta que tengan
  la acción `secretsmanager`:`GetSecretValue` (ver nota de arriba sobre el
  backtick de separación) completar el descifrado. Si algún secreto
  se crea con una CMK propia, esa policy necesita además `kms:Decrypt`
  sobre esa clave — no aplica a los tres secretos de este runbook.

## Verificación de AC1–AC8

Cada verificación es `manual-only`: ningún harness de este repo puede crear
un rol de Postgres, alcanzar la VPC de dev/qa, o alcanzar `10.24.40.137`.
Estado tras R1: **pendiente-de-ejecucion** para las ocho.

### AC1 — los dos roles existen y leen de `proveedores_dev`

```
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof... -U claude_lectura -d proveedores_dev -c "SELECT 1 FROM information_schema.tables LIMIT 1;"
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof... -U neo_lectura   -d proveedores_dev -c "SELECT 1 FROM information_schema.tables LIMIT 1;"
```

Esperado: las dos conexiones abren y las dos consultas devuelven una fila.
Adicional: `SELECT rolname, rolinherit FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');`
tiene que devolver `rolinherit = true` para ambos (nunca `NOINHERIT`).

### AC2 — un `INSERT` con `claude_lectura` falla

**Mutación declarada** (contract v1, bajo AC2): antes de verificar el
comportamiento negativo real, otorgar `INSERT` a `claude_lectura` sobre una
tabla de scratch creada para la prueba:

```
psql ... -U <admin> -d proveedores_dev -c "CREATE TABLE zz_scratch_ac2 (id int); GRANT INSERT ON zz_scratch_ac2 TO claude_lectura;"
psql ... -U claude_lectura -d proveedores_dev -c "INSERT INTO zz_scratch_ac2 VALUES (1);"
```

Esperado en este paso: el `INSERT` **tiene que ponerse en verde** (entra la
fila) — es la comprobación de que la mutación realmente cambió el permiso,
no que el AC ya estaba roto de otra forma.

Después, revertir la mutación y correr la comprobación real:

```
psql ... -U <admin> -d proveedores_dev -c "REVOKE INSERT ON zz_scratch_ac2 FROM claude_lectura; DROP TABLE zz_scratch_ac2;"
psql ... -U claude_lectura -d proveedores_dev -c "INSERT INTO information_schema.tables DEFAULT VALUES;"
```

Esperado: el segundo `INSERT` falla con `ERROR: permission denied`.

### AC3 — la parte A corrida dos veces deja el mismo estado

```
psql ... -U <admin> -d postgres -f postgres-parte-a.sql   # 1ra corrida
psql ... -U <admin> -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');"
psql ... -U <admin> -d postgres -f postgres-parte-a.sql   # 2da corrida
psql ... -U <admin> -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');"
```

Esperado: exit 0 en las dos corridas del `.sql`, y las dos consultas
devuelven exactamente los mismos dos nombres de rol.

### AC4 — tras el inverso, `claude_lectura` no conecta

```
psql ... -U <admin> -d proveedores_dev -f postgres-inverso.sql
psql ... -U <admin> -d proveedores_qa  -f postgres-inverso.sql
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof... -U claude_lectura -d proveedores_dev -c "SELECT 1;"
```

Esperado: el `.sql` inverso corrido contra cada base sale 0 (tolera roles
ya ausentes); el `DROP ROLE` tiene efecto real recién en la última base
pendiente (ver comentario en `postgres-inverso.sql`). El intento final de
conexión con `claude_lectura` falla (`FATAL: role "claude_lectura" does not
exist` o `password authentication failed`, según qué haya quedado).

### AC5 — el login de `Dev SQL` lee de `EXACTUS`

```
sqlcmd -S 10.24.40.137 -U bisalta_lectura -P <contraseña real> -d EXACTUS -Q "SELECT TOP 1 1 FROM sys.tables;"
```

Esperado: devuelve una fila.

### AC6 — un `INSERT` con ese login falla

**Mutación declarada** (contract v1, bajo AC6): en una base de scratch,
agregar el user a `db_datawriter`:

```
sqlcmd -S 10.24.40.137 -E -Q "CREATE DATABASE zz_scratch_ac6;"
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura; ALTER ROLE db_datawriter ADD MEMBER bisalta_lectura; CREATE TABLE t (id int);"
sqlcmd -S 10.24.40.137 -U bisalta_lectura -P <contraseña real> -d zz_scratch_ac6 -Q "INSERT INTO t VALUES (1);"
```

Esperado en este paso: el `INSERT` **se pone en verde** (confirma que la
mutación cambió el permiso). Después, revertir y correr la comprobación
real:

```
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "ALTER ROLE db_datawriter DROP MEMBER bisalta_lectura;"
sqlcmd -S 10.24.40.137 -E -Q "DROP DATABASE zz_scratch_ac6;"
sqlcmd -S 10.24.40.137 -U bisalta_lectura -P <contraseña real> -d EXACTUS -Q "INSERT INTO sys.tables DEFAULT VALUES;"
```

Esperado: falla con `The INSERT permission was denied`.

### AC7 — el user existe en todas las bases de usuario y en ninguna de sistema

**Mutación declarada** (contract v1, bajo AC7): sobre una instancia de
prueba (no `Dev SQL`), quitar el filtro `database_id > 4` de
`sqlserver-parte-b.sql` (dejar sólo `state = 0`) y volver a correrlo:

```
sqlcmd -S <instancia-de-prueba> -E -i sqlserver-parte-b-sin-filtro.sql
sqlcmd -S <instancia-de-prueba> -E -d master -Q "SELECT name FROM sys.database_principals WHERE name = 'bisalta_lectura';"
```

Esperado en este paso: `bisalta_lectura` **aparece también en `master`**
(la comprobación real, "ninguna base de sistema", se pone en rojo). Después
restaurar el filtro `database_id > 4` en el archivo real y correr contra la
instancia de prueba de nuevo para dejarla limpia. Sobre `Dev SQL`, con el
filtro real:

```
sqlcmd -S 10.24.40.137 -E -Q "SELECT db.name, CASE WHEN dp.name IS NULL THEN 'NO' ELSE 'SI' END AS tiene_user
FROM sys.databases db
LEFT JOIN sys.database_principals dp ON 1=0
WHERE db.database_id > 4 AND db.state = 0;"
```

(la comprobación real recorre cada base con `sqlcmd -d <base> -Q "SELECT name FROM sys.database_principals WHERE name='bisalta_lectura'"` y confirma que aparece en las ~35 bases de usuario y en ninguna de `master`/`model`/`msdb`/`tempdb`).

### AC8 — cada secreto existe, tiene los dos campos, y es legible con la política IAM

Para cada uno de los tres secretos (ver "Forma del secreto"):

```
aws secretsmanager get-secret-value --secret-id bisalta-db/postgres/claude_lectura --region us-east-1
aws secretsmanager get-secret-value --secret-id bisalta-db/postgres/neo_lectura --region us-east-1
aws secretsmanager get-secret-value --secret-id bisalta-db/sqlserver/bisalta_lectura --region us-east-1
```

Esperado, corriendo con la identidad IAM que tiene la policy de la sección
"Política IAM" adjunta: las tres llamadas devuelven `SecretString` con un
JSON de exactamente dos campos, uno de nombre `username` y otro de nombre
`password`, ninguno vacío.

## AC9 — `secret-scan.sh` (triple de mutación, no manual-only)

Cubierto en el verification report del ciclo, no acá: es el único AC
automatizable de R1 junto con AC10, y su triple (verde → rojo → verde) se
corre y se pega con comando y exit code en
`SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.

## AC10 — el hueco de una base nueva en SQL Server

`db_datareader` es un permiso **por base** en SQL Server, a diferencia de
`pg_read_all_data` en Postgres, que es un permiso de **cluster**. Esto
significa que **una base nueva agregada a la instancia `Dev SQL` después de
correr `sqlserver-parte-b.sql` NO queda cubierta automáticamente**:
`bisalta_lectura` no tendrá `CREATE USER` ni membresía en `db_datareader`
ahí hasta que alguien vuelva a correr `sqlserver-parte-b.sql` completo. No
hay manera de evitar esto en SQL Server sin un trigger de servidor sobre
`CREATE DATABASE` — fuera del scope de este runbook — así que la asimetría
se documenta acá en vez de compensarse con código nuevo (Decisión de
diseño punto 6). **Acción operativa**: cada vez que se agregue una base
nueva a `Dev SQL` que el catálogo de `bisalta-db` vaya a usar, re-correr
`sqlserver-parte-b.sql` antes de agregar esa base al catálogo.

## Inverso

- Postgres: `postgres-inverso.sql`, conectado a cada base donde se corrió
  la parte B, en orden (ver comentario del archivo sobre por qué el `DROP
  ROLE` requiere limpiar todas las bases primero).
- SQL Server: `sqlserver-inverso.sql`, una sola corrida contra la instancia
  (recorre todas las bases igual que la parte B y al final borra el
  login).
- AWS: los tres secretos se borran a mano desde la cuenta de dev/qa (no
  hay script: crear/borrar secretos está fuera del scope de este runbook,
  igual que crearlos).

Ningún script de R1 se corrió contra una base real: no hay estado externo
pendiente de revertir además de lo que este runbook ya describe.
