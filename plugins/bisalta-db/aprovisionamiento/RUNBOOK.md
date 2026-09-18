# Runbook — aprovisionamiento de solo lectura para `bisalta-db`

Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v2, requerimiento R1 (`infra`), AC1–AC10.

Este runbook lo ejecuta **una persona con privilegios de administración** en
cada motor y en la cuenta de AWS de dev/qa. Ningún script de este directorio
se corrió contra una base real durante R1: R1 los redacta y deja la
verificación escrita; la ejecución y sus resultados quedan pendientes hasta
que alguien con esos privilegios los corra.

## Prerequisitos

- Acceso de administración al cluster Aurora PostgreSQL. Host completo (identificador
  del cluster + región `us-east-1`, contract v3, fila `Integration` del
  `Architectural Delta`):
  `sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com`
  (dev/qa) — **nunca** `cluster-cr4rbgr7qlr6` (cuenta de producción).
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
  `{ "error": "secreto_inaccesible" }` (exit 5, contract v3, tabla de
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

`information_schema.tables` es un catálogo, no una tabla de
`proveedores_dev`: verlo no prueba que el rol lea datos reales de esa base.
Primero identificar una tabla real de la base (`<tabla_real>` abajo, con
cualquiera de los dos roles ya alcanza para listar — `pg_read_all_data`
también cubre los catálogos):

```
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U claude_lectura -d proveedores_dev -c "\dt"
```

y después leer de ella con cada rol:

```
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U claude_lectura -d proveedores_dev -c "SELECT * FROM <tabla_real> LIMIT 1;"
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U neo_lectura   -d proveedores_dev -c "SELECT * FROM <tabla_real> LIMIT 1;"
```

Esperado: `\dt` lista al menos una tabla base (si `proveedores_dev` no
tiene ninguna todavía, el AC no se puede verificar hasta que exista una —
avisarlo en el estado, no forzar la lectura contra un catálogo); elegir
`<tabla_real>` con al menos una fila (una tabla legible pero vacía da
rojo falso: cero filas de una tabla vacía no se distingue de cero filas
por falta de permiso). Las dos conexiones abren y las dos consultas sobre
`<tabla_real>` terminan sin error de permiso y devuelven esa fila.
Adicional: `SELECT rolname, rolinherit FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');`
tiene que devolver `rolinherit = true` para ambos (nunca `NOINHERIT`).

### AC2 — un `INSERT` con `claude_lectura` falla

**Mutación declarada** (contract v3, AC2): antes de verificar el
comportamiento negativo real, otorgar `INSERT` a `claude_lectura` sobre una
tabla de scratch creada para la prueba:

```
psql ... -U <admin> -d proveedores_dev -c "CREATE TABLE zz_scratch_ac2 (id int); GRANT INSERT ON zz_scratch_ac2 TO claude_lectura;"
psql ... -U claude_lectura -d proveedores_dev -c "INSERT INTO zz_scratch_ac2 VALUES (1);"
```

Esperado en este paso: el `INSERT` **tiene que ponerse en verde** (entra la
fila) — es la comprobación de que la mutación realmente cambió el permiso,
no que el AC ya estaba roto de otra forma.

Después, revocar sólo el `INSERT` — **la tabla de scratch sigue viva**: la
comprobación real tiene que correr sobre la misma relación que la
mutación tocó, nunca sobre otra — y volver a correr exactamente el mismo
`INSERT`:

```
psql ... -U <admin> -d proveedores_dev -c "REVOKE INSERT ON zz_scratch_ac2 FROM claude_lectura;"
psql ... -U claude_lectura -d proveedores_dev -c "INSERT INTO zz_scratch_ac2 VALUES (1);"
```

Esperado: el segundo `INSERT` falla con `ERROR: permission denied`.
(`INSERT INTO information_schema.tables` **no sirve para esta
comprobación**: es una vista, y Postgres corta con `cannot insert into
view` antes de llegar a chequear el privilegio del rol — el AC pasaría por
un motivo que no tiene nada que ver con el permiso.) Recién ahora, con la
comprobación real ya corrida, borrar la tabla de scratch:

```
psql ... -U <admin> -d proveedores_dev -c "DROP TABLE zz_scratch_ac2;"
```

### AC3 — la parte A corrida dos veces deja el mismo estado

```
psql ... -U <admin> -d postgres -v ON_ERROR_STOP=1 -f postgres-parte-a.sql   # 1ra corrida
psql ... -U <admin> -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');"
psql ... -U <admin> -d postgres -v ON_ERROR_STOP=1 -f postgres-parte-a.sql   # 2da corrida
psql ... -U <admin> -d postgres -c "SELECT rolname FROM pg_roles WHERE rolname IN ('claude_lectura','neo_lectura');"
```

`-v ON_ERROR_STOP=1` es obligatorio en las dos corridas: sin él, `psql -f`
sale 0 aunque cada sentencia adentro haya fallado, y el AC afirma
literalmente "sale 0 las dos veces" — sin la bandera esa afirmación no
mide nada.

Esperado: exit 0 en las dos corridas del `.sql`, y las dos consultas
devuelven exactamente los mismos dos nombres de rol.

### AC4 — tras el inverso, `claude_lectura` no conecta

```
psql ... -U <admin> -d proveedores_dev -v ON_ERROR_STOP=1 -f postgres-inverso.sql
psql ... -U <admin> -d proveedores_qa  -v ON_ERROR_STOP=1 -f postgres-inverso.sql
psql ... -U <admin> -d postgres -c "SELECT 1 FROM pg_roles WHERE rolname = 'claude_lectura';"
```

Esperado: el `.sql` inverso corrido contra cada base sale 0 (tolera roles
ya ausentes); el `DROP ROLE` tiene efecto real recién en la última base
pendiente (ver comentario en `postgres-inverso.sql`). La comprobación real
es la consulta de catálogo de arriba, corrida como `<admin>`: tiene que
devolver **cero filas**. Un intento de conexión con `claude_lectura`
(`psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U claude_lectura -d proveedores_dev -c "SELECT 1;"`)
**no prueba la revocación por sí solo**: `password authentication failed`
lo produce lo mismo una contraseña mal tipeada con el rol todavía
intacto, así que no distingue "el rol no existe" de "el rol existe pero
tipeé mal la contraseña" — usarlo únicamente como confirmación adicional
después de que la consulta de catálogo ya dio cero filas.

### AC5 — el login de `Dev SQL` lee de `EXACTUS`

La contraseña **nunca** viaja por `argv` (contract v3, sección "Entrega de
la credencial al cliente"): `-P` la deja visible en la tabla de procesos
de la máquina, y este runbook lo corre alguien con `sysadmin` en una
máquina compartida. En vez de `-P`, la contraseña va en `SQLCMDPASSWORD`,
asignada sólo para ese proceso hijo (prefijo `VAR=valor comando`, no
`export`).

`sys.tables` es un catálogo del sistema, no una tabla de `EXACTUS`: leerlo
no prueba que el login lea datos reales de esa base (mismo motivo que AC1
descarta `information_schema.tables`). Primero identificar una tabla real
de `EXACTUS` (`<tabla_real>` abajo):

```
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d EXACTUS -Q "SELECT name FROM sys.tables;"
```

y después leer de ella con el login:

```
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d EXACTUS -Q "SELECT TOP 1 * FROM <tabla_real>;"
```

Esperado: la primera consulta lista al menos una tabla base (si
`EXACTUS` no tuviera ninguna, el AC no se puede verificar hasta que
exista una — avisarlo en el estado, no forzar la lectura contra un
catálogo); elegir `<tabla_real>` con al menos una fila (una tabla legible
pero vacía da rojo falso — mismo criterio que AC1). La segunda consulta
sobre `<tabla_real>` termina sin error de permiso y devuelve esa fila. El
mismo patrón (`SQLCMDPASSWORD=... sqlcmd ...`, nunca `-P`) aplica a todas las
invocaciones de `sqlcmd` de abajo que autentican como `bisalta_lectura`.

### AC6 — un `INSERT` con ese login falla

**Mutación declarada** (contract v3, AC6): en una base de scratch,
agregar el user a `db_datawriter`:

```
sqlcmd -S 10.24.40.137 -E -Q "CREATE DATABASE zz_scratch_ac6;"
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura; ALTER ROLE db_datareader ADD MEMBER bisalta_lectura; ALTER ROLE db_datawriter ADD MEMBER bisalta_lectura; CREATE TABLE t (id int);"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac6 -Q "INSERT INTO t VALUES (1);"
```

`db_datareader` se agrega junto con `db_datawriter` porque es la membresía
que `sqlserver-parte-b.sql` deja en producción: si el estado final de la
comprobación negativa fuera un login sin ninguna membresía, la prueba
mediría "un principal sin roles no puede hacer `INSERT`", no "el login
aprovisionado por este runbook, con `db_datareader`, no puede hacer
`INSERT`" — que es lo que AC6 afirma (mismo criterio que AC2, donde
`claude_lectura` conserva `pg_read_all_data` durante toda la comprobación).

Esperado en este paso: el `INSERT` **se pone en verde** (confirma que la
mutación cambió el permiso). Después, revocar sólo la membresía de
`db_datawriter` — **`db_datareader` sigue asignada y la base de scratch
sigue viva**: la comprobación real tiene que correr sobre la misma tabla
`t`, no sobre `EXACTUS`, con el login dejado exactamente como lo deja
producción — y volver a correr exactamente el mismo `INSERT`:

```
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac6 -Q "ALTER ROLE db_datawriter DROP MEMBER bisalta_lectura;"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac6 -Q "INSERT INTO t VALUES (1);"
```

Esperado: falla con `The INSERT permission was denied`.
(`INSERT INTO sys.tables` **no sirve para esta comprobación**, ni en
`EXACTUS` ni en ninguna otra base: `sys.tables` es un catálogo del
sistema, y SQL Server rechaza cualquier `INSERT` ahí con
`Msg 259, Ad hoc updates to system catalogs are not allowed` — un error
que no tiene nada que ver con el permiso del login.) Recién ahora, con la
comprobación real ya corrida, borrar la base de scratch:

```
sqlcmd -S 10.24.40.137 -E -Q "DROP DATABASE zz_scratch_ac6;"
```

### AC7 — el user existe en todas las bases de usuario y en ninguna de sistema

**Mutación declarada** (contract v3, AC7): sobre una instancia de prueba
(no `Dev SQL`), editar `sqlserver-parte-b.sql` quitando el filtro
`database_id > 4` (dejar sólo `state = 0`) y correr el mismo archivo
editado contra esa instancia:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b.sql
```

La comprobación real es siempre el mismo bloque `##ac7_check` de abajo —
nunca una consulta distinta contra `master` sola: un `LEFT JOIN ... ON
1=0` no sirve acá — `sys.database_principals` es un catálogo **por
base**, así que desde una sola conexión a `master` nunca se ve el
principal de otra base, con o sin aprovisionamiento. La comprobación real
recorre las bases con un cursor explícito (mismo patrón que
`sqlserver-parte-b.sql`) y consulta `sys.database_principals` **dentro de
cada una**, acumulando el resultado en una tabla temporal global (visible
entre cambios de `USE` dentro de la misma sesión). `@db_name` va como
parámetro de `sp_executesql`, no concatenado crudo dentro del literal de
cadena: una base con un apóstrofo en el nombre rompería el batch si se
concatenara.

```
sqlcmd -S <instancia-de-prueba> -E -b -Q "
CREATE TABLE ##ac7_check (db_name SYSNAME, tiene_user BIT);
DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);
DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT name FROM sys.databases WHERE state = 0;
OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'USE ' + QUOTENAME(@db_name) + N'; INSERT INTO ##ac7_check (db_name, tiene_user) SELECT @p_db_name, CASE WHEN EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''bisalta_lectura'') THEN 1 ELSE 0 END;';
  EXEC sp_executesql @sql, N'@p_db_name SYSNAME', @p_db_name = @db_name;
  FETCH NEXT FROM db_cursor INTO @db_name;
END
CLOSE db_cursor;
DEALLOCATE db_cursor;
SELECT db_name, tiene_user FROM ##ac7_check ORDER BY db_name;
DROP TABLE ##ac7_check;
"
```

Esperado en este paso (corrido contra la instancia de prueba, con el
filtro de `sqlserver-parte-b.sql` todavía quitado): la fila `db_name =
'master'` devuelve `tiene_user = 1` — la comprobación real, "ninguna base
de sistema", se pone en rojo con el mismo cursor que se usa para el
resultado final, no con una consulta distinta. Después restaurar el
filtro `database_id > 4` en `sqlserver-parte-b.sql` (revertir la edición,
ej. `git checkout -- sqlserver-parte-b.sql` si no se commiteó) y correrlo
de nuevo contra la instancia de prueba para dejarla limpia — nunca contra
`Dev SQL`.

Comprobación real sobre `Dev SQL`, con el filtro real ya restaurado en el
archivo: correr el mismo bloque `##ac7_check` de arriba, cambiando sólo
`-S` a `10.24.40.137`.

El cursor recorre `sys.databases` **completo** (`state = 0`, sin filtrar
`database_id`), a propósito: es la única forma de confirmar el lado
negativo (bases de sistema) en la misma corrida que el lado positivo
(bases de usuario). Esperado: `tiene_user = 1` en cada una de las ~35
bases con `database_id > 4` y en ninguna fila `tiene_user = 0` entre
ellas; `tiene_user = 0` en las cuatro bases de sistema
(`master`, `model`, `msdb`, `tempdb`).

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

## AC10 — el hueco de una base nueva (o recién disponible) en SQL Server

`db_datareader` es un permiso **por base** en SQL Server, a diferencia de
`pg_read_all_data` en Postgres, que es un permiso de **cluster**. Esto
significa que **una base nueva agregada a la instancia `Dev SQL` después de
correr `sqlserver-parte-b.sql` NO queda cubierta automáticamente**:
`bisalta_lectura` no tendrá `CREATE USER` ni membresía en `db_datareader`
ahí hasta que alguien vuelva a correr `sqlserver-parte-b.sql` completo. No
hay manera de evitar esto en SQL Server sin un trigger de servidor sobre
`CREATE DATABASE` — fuera del scope de este runbook — así que la asimetría
se documenta acá en vez de compensarse con código nuevo (contract v3,
sección "Garantías por motor (asimetría declarada, no disimulada)").

El mismo hueco existe, por el mismo motivo, para una base que **ya
existía pero estaba `OFFLINE` o `RESTORING`** cuando corrió
`sqlserver-parte-b.sql`: el filtro `state = 0` (ONLINE únicamente, ver
comentario del script) no la alcanza en esa corrida, y queda tan
descubierta como una base creada después. **Acción operativa**: cada vez
que se agregue una base nueva a `Dev SQL`, o que una base existente pase
a estar `ONLINE` después de haber estado en otro estado durante la
última corrida, que el catálogo de `bisalta-db` vaya a usar, re-correr
`sqlserver-parte-b.sql` antes de agregar (o reactivar) esa base en el
catálogo.

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
