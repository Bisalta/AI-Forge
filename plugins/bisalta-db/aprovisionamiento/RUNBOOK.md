# Runbook — aprovisionamiento de solo lectura para `bisalta-db`

Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v9, requerimiento R1 (`infra`), AC1–AC10, AC41, AC42.

Este runbook lo ejecuta **una persona con privilegios de administración** en
cada motor y en la cuenta de AWS de dev/qa. Ningún script de este directorio
se corrió contra una base real durante R1: R1 los redacta y deja la
verificación escrita; la ejecución y sus resultados quedan pendientes hasta
que alguien con esos privilegios los corra.

**Reapertura v4→v5 (hallazgo de Patrick Ocampo, 18-sep-2026)**: `pg_read_all_data`
es una membresía DE CLUSTER y Postgres concede `CONNECT` a PUBLIC por
omisión — un rol creado por `postgres-parte-a.sql` alcanza las **29** bases
del cluster de dev/qa desde que existe, no las 2 del catálogo de la
aplicación. `postgres-parte-b.sql` **nunca fue la barrera de acceso**; la
barrera real es qué cluster es (`postgres-parte-0.sql`, nuevo, corre
primero — ver "Orden de ejecución" y AC41 abajo). Del lado de SQL Server,
`db_denydatawriter` se suma a `db_datareader` como segunda red (AC42): el
`DENY` le gana a cualquier `GRANT` posterior.

**v6 (respuestas de Patrick Ocampo, Slack 2026-09-18 15:52 CST)**: `SSISDB`
queda **fuera** del loop de SQL Server, por nombre — ver sección "`SSISDB`
queda fuera del loop" más abajo, ya no es una decisión pendiente. El
aprovisionamiento de Postgres lo sigue escribiendo este runbook —
`postgres-parte-0.sql` es implementación de referencia hasta que llegue el
de Patrick — con el hallazgo de la ronda 5 de review ya corregido (PASO 1
de `postgres-parte-0.sql` ahora discrimina de verdad, ver su comentario).

**v9 (regla de Patrick Ocampo, Slack 21-sep-2026 10:31; lista de Ian
Vargas, 21-sep-2026)**: el freno de SQL Server se levanta con una regla,
no con una lista de exclusiones. El alcance de Dev SQL arranca en **cero**
y se agrega **a pedido nombrado**: `sqlserver-parte-b.sql` deja de
recorrer `sys.databases` filtrando exclusiones y pasa a recorrer una
**lista explícita** declarada al principio del script
(`@bases_permitidas`) — su `INSERT` es la fuente de verdad de qué está
concedido hoy; este runbook no la retranscribe para no mantener dos
copias del mismo valor que puedan desincronizarse (el historial de
pedidos, con fecha y solicitante, vive en `APROBACIONES.md`). `AC7` y
`AC42` cambian
de universo con esto: dejan de hablar de "todas las bases de usuario en
línea salvo `SSISDB`" y pasan a hablar de la lista. Las guardas contra
`SSISDB`, `master`, `model`, `msdb` y `tempdb` **se mantienen como defensa
en profundidad**, no como el criterio de alcance: si alguien las escribe
en la lista por error, el script las rechaza igual y avisa por qué (ver
`AC7` abajo). La aprobación completa está en `APROBACIONES.md`, que este
runbook no reemplaza ni resume.

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

1. `postgres-parte-0.sql` contra el cluster de dev/qa
   (`sistemas-costruplaza-db.cluster-cfrl3owqzwof`), **antes de crear
   nada**. **Verificar AC41**: sale 0 y continúa (ver abajo). Si aborta,
   PARAR — no correr `postgres-parte-a.sql` contra ese cluster bajo
   ninguna circunstancia.
2. `postgres-parte-a.sql` contra el mismo cluster (una vez, cluster
   entero).
3. `postgres-parte-b.sql` conectado a **`proveedores_dev` primero**.
4. **Verificar AC1** contra `proveedores_dev` (ver abajo) antes de seguir.
5. `postgres-parte-b.sql` conectado al resto de las bases del catálogo
   (`proveedores_qa`, y cualquier base que se agregue después).
6. `sqlserver-parte-a.sql` contra la instancia `Dev SQL`.
7. `sqlserver-parte-b.sql` contra la misma instancia (recorre la lista
   explícita declarada al principio del script, otorgando `db_datareader`
   y `db_denydatawriter` a cada base nombrada ahí). El script sale `0`
   aunque alguna base nombrada no se haya podido cubrir — **revisar la
   salida por líneas `AUSENTE:` / `NO ONLINE:` / `RECHAZADA` antes de
   seguir**: cada una nombra una base de la lista que quedó sin el user
   en esta corrida.
8. **Verificar AC5** contra `EXACTUS` y **AC42** (ver abajo).
9. Crear los tres secretos en Secrets Manager (ver "Forma del secreto" y
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

## Verificación de AC1–AC8, AC41 y AC42

Cada verificación es `manual-only`: ningún harness de este repo puede crear
un rol de Postgres, alcanzar la VPC de dev/qa, o alcanzar `10.24.40.137`.
Estado tras esta ronda: **pendiente-de-ejecucion** para las diez.

### AC41 — la Parte 0 aborta por lo que el cluster CONTIENE, no por el nombre de la base

Corrida esperada, contra el cluster de dev/qa (contiene `controlactivos_stg`
y ninguna `_prod`, `INVENTARIO.md`):

```
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U <admin> -d postgres -v ON_ERROR_STOP=1 -f postgres-parte-0.sql
```

Esperado: exit 0. La consulta del paso 1 imprime, para cada rol con
`LOGIN` que ya exista en el cluster, dos columnas por base: si puede
conectar (`has_database_privilege(...,'CONNECT')`, cierta para **cualquier**
rol en cualquier base por el default de `CONNECT` a PUBLIC, con o sin
`pg_read_all_data` — sola no discrimina, ver el comentario corregido de
`postgres-parte-0.sql`, ronda 5 de review, MAJOR 2) y si es miembro de
`pg_read_all_data` (`pg_has_role(...,'MEMBER')`, membresía de cluster, la
misma en las 29 bases). Antes de que existan `claude_lectura` y
`neo_lectura` esto sólo muestra los roles administrativos que ya haya, pero
es la misma consulta que se vuelve a correr después de `postgres-parte-a.sql`:
ahí las **dos columnas juntas** confirman que los dos roles nuevos llegan
de verdad a las 29 bases del cluster, no a 2 — `puede_conectar` en `true`
sin la membresía no probaría lectura, y la membresía sin `puede_conectar`
no podría ni abrir la conexión. El paso 2 (el `DO $$ ... $$` de control)
no lanza excepción, así que `psql -v ON_ERROR_STOP=1` no corta el script:
`-v ON_ERROR_STOP=1` es obligatorio en esta corrida por el mismo motivo
que en el resto de los `.sql` de este runbook (ver AC3) — sin la bandera,
un `RAISE EXCEPTION` adentro de un `DO` no necesariamente hace que `psql`
salga distinto de 0.

**Mutación declarada** (contract v5, AC41): en una copia de trabajo de
`postgres-parte-0.sql` (nunca el archivo que se corre contra un cluster
real sin revertir antes), cambiar la condición de aborto de `_prod` a
`_stg` (`LIKE '%\_stg' ESCAPE '\'`) y correr esa copia contra el mismo
cluster de dev/qa:

```
psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U <admin> -d postgres -v ON_ERROR_STOP=1 -f postgres-parte-0-mutado.sql
```

Esperado en este paso: el script **aborta** (exit distinto de 0,
nombrando `controlactivos_stg`) — es la comprobación de que "sale 0 y
continúa" se pone roja con la condición equivocada, sobre el mismo
cluster que con la condición correcta (`_prod`) sale 0. Restaurar la
condición a `_prod` (o simplemente descartar la copia mutada) y volver a
correr la corrida esperada de arriba para confirmar que vuelve a salir 0.

**Nunca correr ninguna versión de `postgres-parte-0.sql`, mutada o no,
contra `cluster-cr4rbgr7qlr6`** (cuenta de producción): ese cluster sí
tiene bases `_prod`, así que la corrida esperada ahí sería abortar — pero
la Parte 0 no es la forma de comprobar eso, es la salvaguarda que impide
seguir si alguien la corre ahí por error.

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

### AC7 — el user existe exactamente en las bases de la lista y en ninguna otra

`AC7` (contract v9) ya no habla de "todas las bases de usuario en línea
salvo `SSISDB`": habla de la lista explícita que declara
`sqlserver-parte-b.sql` (`@bases_permitidas`). La comprobación real tiene
dos mitades y las dos se leen del mismo bloque `##ac7_check` de abajo —
nunca una consulta distinta contra `master` sola: un `LEFT JOIN ... ON
1=0` no sirve acá — `sys.database_principals` es un catálogo **por
base**, así que desde una sola conexión a `master` nunca se ve el
principal de otra base, con o sin aprovisionamiento. La comprobación
recorre las bases con un cursor explícito y consulta
`sys.database_principals` **dentro de cada una**, acumulando el resultado
en una tabla temporal global (visible entre cambios de `USE` dentro de la
misma sesión). `@db_name` va como parámetro de `sp_executesql`, no
concatenado crudo dentro del literal de cadena: una base con un apóstrofo
en el nombre rompería el batch si se concatenara.

El cursor de esta comprobación filtra `state = 0` (`ONLINE`): al momento
de esta ronda eso alcanza para ver el universo negativo entero (todo lo
que no está en la lista, más `SSISDB` y las cuatro de sistema) en la
misma corrida que el universo positivo, porque **las 32 bases de la
instancia están `ONLINE`** (`INVENTARIO.md:146`) — no hay ninguna
`OFFLINE`/`RESTORING` que el filtro deje afuera hoy. Si en el futuro
existiera una base fuera de la lista que no esté `ONLINE`, este filtro
no la mide: listarla aparte (con el mismo `SELECT name, state FROM
sys.databases WHERE state <> 0`) y declararla explícitamente **no
medida** por esta comprobación, en vez de asumir que su ausencia de la
tabla `##ac7_check` es un verde.

```
sqlcmd -S <instancia> -E -b -Q "
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

Qué contar como "está en la lista" al leer el resultado: la lista misma,
tal como la declara `sqlserver-parte-b.sql` al momento de la corrida —
este runbook no retranscribe una copia independiente de esos nombres para
no mantener el mismo valor en dos lugares que puedan desincronizarse
(ver la nota de cabecera sobre `@bases_permitidas`). Abrir el archivo,
mirar su bloque `INSERT INTO @bases_permitidas`, y usar esos nombres
exactos como el universo positivo esperado.

**Comprobación real (verde), contra `Dev SQL`**, con `sqlserver-parte-b.sql`
real ya corrido: correr el bloque de arriba con `-S 10.24.40.137`.
Esperado: `tiene_user = 1` en cada fila cuyo `db_name` esté en
`@bases_permitidas` del script vigente, y `tiene_user = 0` en absolutamente
cualquier otra fila — incluidas `SSISDB`, `master`, `model`, `msdb`,
`tempdb`, y cualquier base de usuario que no haya sido pedida por nombre.

**Lista vacía, parte del mismo AC** (contract v9: *"con la lista vacía, el
script no crea ningún user y sale 0"*): sobre una instancia de prueba, en
una copia de trabajo `sqlserver-parte-b-lista-vacia.sql`, borrar el
statement `INSERT INTO @bases_permitidas (nombre) VALUES (...);`
**completo**, dejando sólo el `DECLARE @bases_permitidas TABLE (nombre
SYSNAME PRIMARY KEY);` — un `INSERT ... VALUES` sin ninguna fila (ya sea
`VALUES;` o `VALUES` seguido de nada) **no es T-SQL válido**: `sqlcmd`
sale con `Msg 102, Level 15` (error de sintaxis) antes de llegar siquiera
a abrir el cursor, que es lo contrario del `exit 0` que este paso espera.
Correrla:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b-lista-vacia.sql
echo $?
```

Esperado: exit `0`. Correr después el bloque `##ac7_check` contra esa
misma instancia: `tiene_user = 0` en absolutamente todas las filas —
ningún `bisalta_lectura` en ninguna base. Es el estado de arranque que
`APROBACIONES.md` describe (punto 1: "el login arranca sin acceso a
ninguna base de negocio").

**Mutación declarada** (contract v9, AC7): sobre una instancia de prueba
(no `Dev SQL`), en una copia de trabajo `sqlserver-parte-b-mutada-v8.sql`,
reemplazar el cursor sobre `@bases_permitidas` por el cursor que el
script tenía hasta v8 — un recorrido de `sys.databases` con el filtro de
exclusión de esa época (`database_id > 4 AND name <> 'SSISDB' AND state =
0`), sin tocar el resto del script (las guardas de `@bases_prohibidas`
siguen ahí, ya sin efecto porque ya no se filtra por lista). Correr esa
copia contra la instancia de prueba:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b-mutada-v8.sql
```

Correr el mismo bloque `##ac7_check` de arriba contra esa instancia.
Esperado en este paso: aparecen filas con `tiene_user = 1` en bases de
usuario de esa instancia que **no** están en `@bases_permitidas` — es la
comprobación de "en ninguna otra" poniéndose roja, porque el cursor
mutado concede a todo salvo las exclusiones (`database_id > 4`, no
`SSISDB`), exactamente la forma que v9 dejó atrás.

**Limpiar antes de dar por cerrado el rojo**: correr de nuevo
`sqlserver-parte-b.sql` real (el que usa la lista) sobre esa instancia
**no alcanza** para volver al verde — es aditivo e idempotente sobre las
bases de su propia lista, pero nunca toca ni revierte una base que la
corrida mutada haya tocado fuera de la lista (mismo motivo de fondo que
`SDD/debt.md` D40, ya registrado para el AC7 de versiones anteriores: un
script que sólo agrega no limpia lo que otro agregó de más). Por eso el
cierre real necesita un paso de reversión explícito: en una copia de
trabajo `sqlserver-inverso-mutada-v8.sql`, aplicar al inverso el mismo
cursor de exclusión que se usó para la mutación (`database_id > 4 AND
name <> 'SSISDB' AND state = 0`) y correrla contra la instancia de
prueba — esto quita `bisalta_lectura` (y su `db_denydatawriter`) de
**todas** las bases de usuario que la corrida mutada tocó, incluidas las
de la lista real:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-inverso-mutada-v8.sql
```

Recién ahora correr `sqlserver-parte-b.sql` real (por lista) para dejar
la instancia de prueba en el estado que el script real produce, y volver
a correr el bloque `##ac7_check` para confirmar el verde de cierre —
`tiene_user = 1` sólo en las bases de `@bases_permitidas`, `0` en todo lo
demás — antes de tocar `Dev SQL` con el archivo real. Descartar las tres
copias de trabajo (`sqlserver-parte-b-lista-vacia.sql`,
`sqlserver-parte-b-mutada-v8.sql`, `sqlserver-inverso-mutada-v8.sql`):
ninguna se commitea.

`SSISDB` sigue sin ser una decisión pendiente (contract v6, "Cambios v5 →
v6", punto 1, decisión de Patrick Ocampo): en v9 queda fuera porque nunca
está en `@bases_permitidas`, y si alguien la agregara por error,
`@bases_prohibidas` la rechaza igual (ver comentario de
`sqlserver-parte-b.sql` y sección "`SSISDB` queda fuera del loop" más
abajo).

### AC42 — el user tiene las dos membresías en cada base de la lista, y el `DENY` gana

`AC42` (contract v9) verifica las dos membresías **en cada base de la
lista explícita** de `sqlserver-parte-b.sql`. Comprobación real, sobre
`EXACTUS` en `Dev SQL` — una de las bases nombradas en `@bases_permitidas`,
ya aprovisionada por `sqlserver-parte-b.sql` real con las dos membresías:

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "
SELECT r.name AS rol
FROM sys.database_role_members drm
JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
WHERE m.name = 'bisalta_lectura' AND r.name IN ('db_datareader','db_denydatawriter')
ORDER BY r.name;
"
```

Esperado: dos filas, `db_datareader` y `db_denydatawriter`. Repetir la
misma consulta cambiando `-d EXACTUS` por cada una de las demás bases que
declare `@bases_permitidas` en `sqlserver-parte-b.sql` vigente (abrir el
script para ver cuáles son, no retranscribirlas acá): dos filas en cada
una.

**La segunda mitad del AC no se corrobora sobre `zz_scratch_ac6`** (hallazgo
de la ronda 5 de review, BLOCKER, sigue vigente en v9): esa base la arma el
procedimiento de AC6 (sección de arriba) con `CREATE USER` + `ALTER ROLE
db_datareader ADD MEMBER` únicamente — nunca corre `sqlserver-parte-b.sql`,
así que `bisalta_lectura` ahí **nunca tiene** `db_denydatawriter`. Un
`GRANT INSERT` sobre esa base pasaría igual con o sin el `DENY` real, así
que no prueba nada sobre el `DENY`.

**Con la lista explícita (v9), una base de scratch no queda cubierta
sólo por correr `sqlserver-parte-b.sql` real** — a diferencia de hasta v8,
donde el cursor recorría `sys.databases` entero y una base nueva entraba
sola. Para corroborar sobre una base de scratch hace falta agregarla,
igual que se agregaría una base real: en una **copia de trabajo**
`sqlserver-parte-b-mas-scratch.sql` (nunca el archivo real, que sólo
declara las bases con pedido y fecha registrados en `APROBACIONES.md`),
agregar una fila más al `INSERT INTO @bases_permitidas` con
`(N'zz_scratch_ac42')`, sin tocar nada más del script:

```
sqlcmd -S 10.24.40.137 -E -Q "CREATE DATABASE zz_scratch_ac42;"
sqlcmd -S 10.24.40.137 -E -b -i sqlserver-parte-b-mas-scratch.sql
```

Esta corrida re-procesa también las bases reales de la lista — idempotente ahí
(comentario "Idempotente" del script, `IF NOT EXISTS` antes de cada
`ALTER ROLE ADD MEMBER`, ninguna fila cambia) — y de paso agrega a
`bisalta_lectura`, con **las dos** membresías, en `zz_scratch_ac42`, que
es nueva y todavía no lo tenía. Confirmar con la misma consulta de
arriba, cambiando `-d EXACTUS` por `-d zz_scratch_ac42`: dos filas.

Ahora sí, sobre esa base con las dos membresías reales:

```
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac42 -Q "CREATE TABLE t (id int); GRANT INSERT ON t TO bisalta_lectura;"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac42 -Q "INSERT INTO t VALUES (1);"
```

Esperado: el `INSERT` falla con `The INSERT permission was denied`, a
pesar del `GRANT` explícito — ahora sí es la comprobación de que
`db_denydatawriter` es lo que lo bloquea, porque el estado de la base
contra la que corre lo tiene de verdad.

**Mutación declarada** (contract v5/v9, AC42): partiendo de
`sqlserver-parte-b-mas-scratch.sql`, hacer una segunda copia
`sqlserver-parte-b-sin-denydatawriter-mas-scratch.sql` quitando el bloque
que agrega `db_denydatawriter` (dejar sólo `db_datareader`), con la fila
de `zz_scratch_ac42` todavía en la lista. Para el rojo hace falta una
base sin ninguna de las dos membresías todavía — `zz_scratch_ac42` ya las
tiene las dos por el paso de arriba, y `ALTER ROLE ... ADD MEMBER` es
aditivo: volver a correr un script sobre ella no las quita. Recrearla
fresca:

```
sqlcmd -S 10.24.40.137 -E -Q "DROP DATABASE zz_scratch_ac42;"
sqlcmd -S 10.24.40.137 -E -Q "CREATE DATABASE zz_scratch_ac42;"
sqlcmd -S 10.24.40.137 -E -b -i sqlserver-parte-b-sin-denydatawriter-mas-scratch.sql
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac42 -Q "CREATE TABLE t (id int); GRANT INSERT ON t TO bisalta_lectura;"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac42 -Q "INSERT INTO t VALUES (1);"
```

Esperado en este paso: el `INSERT` **pasa** — es la comprobación de que
"falla" se pone roja sin `db_denydatawriter` en el loop, sobre una base
que nunca tuvo esa membresía.

Restaurar el loop confirmando el **verde de cierre** —el contract exige
literalmente que "el `DENY` vuelve a ganar", no sólo que se limpie—
corriendo `sqlserver-parte-b-mas-scratch.sql` (la copia **con** DENY, no
el archivo real): el archivo real nunca declaró `zz_scratch_ac42` en su
lista y no debería — agregar ahí una base de scratch sería agregar una
base a la lista de producción sin pedido ni fecha registrados, que es
justo lo que la regla de Patrick prohíbe (contract v9, "Cambios v8 →
v9", punto 1). El mismo `INSERT` corre sobre la misma tabla y el mismo
`GRANT` que acaban de dejarlo pasar, sin borrar nada todavía:

```
sqlcmd -S 10.24.40.137 -E -b -i sqlserver-parte-b-mas-scratch.sql
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d zz_scratch_ac42 -Q "INSERT INTO t VALUES (1);"
```

Esperado: el `INSERT` **vuelve a fallar** con `The INSERT permission was
denied` — la copia con DENY intacto lo agrega de nuevo (que la corrida
mutada nunca agregó) y el `DENY` gana sobre el mismo `GRANT` que sigue
vivo. Recién ahora, con el triple completo (verde real → rojo de
mutación → verde de cierre) corrido, limpiar — incluidas las dos copias
de trabajo, que nunca se commitean:

```
sqlcmd -S 10.24.40.137 -E -d zz_scratch_ac42 -Q "REVOKE INSERT ON t FROM bisalta_lectura;"
sqlcmd -S 10.24.40.137 -E -Q "DROP DATABASE zz_scratch_ac42;"
rm -f sqlserver-parte-b-mas-scratch.sql sqlserver-parte-b-sin-denydatawriter-mas-scratch.sql
```

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

`db_datareader` y `db_denydatawriter` son permisos **por base** en SQL
Server, a diferencia de `pg_read_all_data` en Postgres, que es un permiso
de **cluster**. Con la lista explícita de v9 esto se vuelve doblemente
cierto: **una base agregada a `Dev SQL`, o pedida por nombre pero
todavía no escrita en `@bases_permitidas`, NO queda cubierta
automáticamente**: `bisalta_lectura` no tendrá `CREATE USER` ni ninguna
de las dos membresías ahí hasta que alguien (a) agregue esa base al
`INSERT INTO @bases_permitidas` de `sqlserver-parte-b.sql` y (b) vuelva a
correr el script completo — y mientras tanto esa base nueva no tiene ni
la lectura ni la segunda red del `DENY`. No hay manera de evitar esto en
SQL Server sin un trigger de servidor sobre `CREATE DATABASE` — fuera del
scope de este runbook — así que la asimetría se documenta acá en vez de
compensarse con código nuevo (contract v5, sección "Garantías por motor
(asimetría declarada, no disimulada)").

El mismo hueco existe, por el mismo motivo, para una base que **ya está
en la lista pero estaba `OFFLINE` o `RESTORING`** al momento de correr
`sqlserver-parte-b.sql`: el script la nombra por `PRINT` en vez de
saltearla en silencio (ver comentario del script, "SIN SALTOS
SILENCIOSOS"), pero no le crea nada en esa corrida, y queda tan
descubierta como una base recién pedida. **Acción operativa**: cada vez
que se pida una base nueva, o que una base ya listada pase a estar
`ONLINE` después de haber estado en otro estado durante la última
corrida, (a) agregarla (si no estaba) al `INSERT` de
`sqlserver-parte-b.sql` y a `sqlserver-inverso.sql` en el mismo cambio,
(b) registrar el pedido con fecha y solicitante en `APROBACIONES.md`, y
(c) re-correr `sqlserver-parte-b.sql` — en ese orden, antes de agregar
esa base al catálogo de `bisalta-db`.

## `SSISDB` queda fuera del loop

`SSISDB` (`database_id = 36`, 5.77 GB, `INVENTARIO.md`) es el catálogo de
SQL Server Integration Services, no una base de negocio: guarda los
proyectos desplegados con sus parámetros y connection managers —un lugar
donde viven cadenas de conexión— más los logs de ejecución.

**Decisión tomada** (contract v6, "Cambios v5 → v6", punto 1 — Patrick
Ocampo, Slack 2026-09-18 15:52 CST): `SSISDB` queda **fuera** del loop de
SQL Server. Su razón, textual: *"guarda los proyectos desplegados con sus
parámetros y connection managers, o sea que es un lugar donde viven
cadenas de conexión, más los logs de ejecución. Cero dato de negocio y sí
credenciales."* Un servidor MCP cuyo propósito es que ninguna credencial
pase por el contexto no puede alcanzar el lugar donde viven las cadenas de
conexión — es una razón más fuerte que la de "no es una base de negocio"
que este runbook tenía antes de v6, y no depende de si `SSISDB` entraría o
no al catálogo de la aplicación: aunque nunca se agregara a
`catalogo.json`, dejarla dentro del loop igual le daría a `bisalta_lectura`
acceso de lectura a credenciales, sin que el catálogo lo medie.

**Desde v9, el criterio de alcance es la lista** (`@bases_permitidas`), no
un filtro de exclusión sobre `sys.databases` — `SSISDB` queda fuera
simplemente porque nunca fue pedida por nombre, igual que cualquier otra
base de `Dev SQL` que tampoco esté en la lista. Lo que v9 agrega es la
**defensa en profundidad**: `SSISDB` sigue estando además en
`@bases_prohibidas`, así que si alguien la escribiera por error en
`@bases_permitidas`, el script la rechaza igual y lo dice por `PRINT` (ver
comentario de `sqlserver-parte-b.sql`) — nunca la procesa en silencio, ni
siquiera si quedara nombrada en la lista por accidente. Tras cualquier
corrida, `bisalta_lectura` no existe como user en `SSISDB` — AC7 la
cuenta junto a las cuatro bases de sistema con `tiene_user = 0` (ver
sección de AC7 más arriba), no entre las bases de la lista. No entra
tampoco al catálogo de la aplicación (`plugins/bisalta-db/catalogo.json`)
— nadie la agregó ahí.

## Inverso

- Postgres: `postgres-inverso.sql`, conectado a cada base donde se corrió
  la parte B, en orden (ver comentario del archivo sobre por qué el `DROP
  ROLE` requiere limpiar todas las bases primero).
- SQL Server: `sqlserver-inverso.sql`, una sola corrida contra la instancia
  (recorre la misma lista explícita que la parte B, quitando
  `bisalta_lectura` de `db_denydatawriter` explícitamente antes de borrar
  el user en cada una — contract v5, AC42 — y al final borra el login).
  Si se agrega una base a `sqlserver-parte-b.sql`, se agrega la misma fila
  a `sqlserver-inverso.sql` en el mismo cambio (ver comentario de
  cabecera de ese archivo).
- AWS: los tres secretos se borran a mano desde la cuenta de dev/qa (no
  hay script: crear/borrar secretos está fuera del scope de este runbook,
  igual que crearlos).

### Procedimiento de baja (sacar una base de la lista de SQL Server)

Agregar una base es simétrico (se agrega la misma fila a las dos listas
en el mismo cambio), pero **quitar una base no lo es**: `sqlserver-parte-b.sql`
sólo procesa lo que está en su lista *hoy* — nunca revisa ni revierte lo
que procesó en una corrida anterior con una lista distinta. Si se edita
la lista antes de revertir, ninguno de los dos scripts vuelve a nombrar
esa base nunca más, y `bisalta_lectura` queda como user ahí (con su
`db_denydatawriter`) para siempre — y el bloque `##ac7_check` de la
sección "AC7" de arriba se pone rojo (`tiene_user = 1` fuera de la lista)
sin que ningún documento explique la causa.

**El `DROP LOGIN` final de `sqlserver-inverso.sql` es incondicional**: no
mira cuántas bases quedan en la lista, corre siempre que el login exista.
Correr el archivo real (con la lista completa) para dar de baja una sola
base revertiría **todas** las bases, no sólo esa — y correr una copia
recortada a sólo la base a dar de baja evita eso en el `DROP
USER`/`ALTER ROLE`, pero el `DROP LOGIN` de más abajo se ejecuta igual y
deja **sin login** a `bisalta_lectura` para las demás bases que seguían
activas. Por eso, si queda al menos otra base activa, la copia de trabajo
tiene que recortar la lista **y** quitar el bloque final de `DROP LOGIN`.

Orden correcto para dar de baja una base que **no** es la última de la
lista (por ejemplo, `Ecommerce_qa`, con `COMPRAS`, `COMPRAS_STG`,
`Ecommerce`, `EXACTUS` y `BI` quedando activas):

1. **Antes de tocar ninguna de las dos listas**, hacer una copia de
   trabajo `sqlserver-inverso-baja-ecommerce_qa.sql` a partir de
   `sqlserver-inverso.sql` con dos cambios: (a) `INSERT INTO
   @bases_permitidas` con **sólo** la fila `(N'Ecommerce_qa')`, y (b) el
   bloque final `IF EXISTS (... sys.server_principals ...) DROP LOGIN
   bisalta_lectura; GO` **quitado por completo** (las demás bases todavía
   necesitan ese login). Correrla:
   ```
   sqlcmd -S 10.24.40.137 -E -b -i sqlserver-inverso-baja-ecommerce_qa.sql
   ```
   Esto le quita a `bisalta_lectura` las dos membresías y el user en
   `Ecommerce_qa` únicamente, sin tocar el login ni las demás bases.
2. Recién ahora, sacar la fila `(N'Ecommerce_qa')` del `INSERT` de
   `sqlserver-parte-b.sql` **y** de `sqlserver-inverso.sql`, en el mismo
   cambio (mismo criterio que agregar: las dos listas se editan juntas).
3. Registrar la baja en `APROBACIONES.md` (fecha y quién la pidió), igual
   que un alta.
4. Confirmar con el bloque `##ac7_check`: `tiene_user = 0` para
   `Ecommerce_qa`, y `tiene_user = 1` sin cambios en las cinco bases que
   siguen en la lista.
5. Descartar la copia de trabajo (`sqlserver-inverso-baja-ecommerce_qa.sql`):
   no se commitea.

**Caso distinto — la base a dar de baja es la última que queda en la
lista** (decomiso completo, ninguna otra base sigue activa): ahí sí
corresponde correr `sqlserver-inverso.sql` real, sin modificar, porque el
`DROP LOGIN` final es exactamente lo que corresponde cuando no queda
ninguna base que siga necesitando el login.

Invertir el orden (editar las listas primero, revertir después) no tiene
remedio con estos dos scripts: ya ninguno de los dos nombra la base
dada de baja, así que no hay forma de que el inverso la vuelva a tocar.

Ningún script de R1 se corrió contra una base real: no hay estado externo
pendiente de revertir además de lo que este runbook ya describe.
