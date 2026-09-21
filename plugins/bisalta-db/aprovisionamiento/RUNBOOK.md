# Runbook — aprovisionamiento de solo lectura para `bisalta-db`

Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v11, requerimiento R1 (`infra`), AC1–AC10, AC41, AC42, AC43.

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
`db_denydatawriter` se sumó a `db_datareader` como segunda red (AC42): el
`DENY` le ganaba a cualquier `GRANT` posterior. **Revertido en v10** (ver
sección "v10" abajo): `db_denydatawriter` sale del loop, y `db_datareader`
pasa a ser la única garantía.

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

**v10 (decisiones de Patrick Ocampo, Slack 21-sep-2026 12:22 y 12:44)**:
dos reversiones sobre lo que R1 había dejado `APPROVED`, ninguna un
rechazo del trabajo — las dos revierten decisiones puntuales.

1. **Sale `db_denydatawriter`.** Cada base concedida lleva `db_datareader`
   y nada más. Revierte el punto 4 de v4. Patrick pidió explícitamente que
   quedara escrito con lo que se pierde, no sólo con lo que queda —
   textual, ya en `APROBACIONES.md` punto 6: *"sin `db_denydatawriter` no
   queda un `DENY` explícito, así que un `GRANT` de escritura concedido por
   error en el futuro no tendría nada que lo anule."* La tabla "Garantías
   por motor" (arriba en el contract, y en `README.md`) vuelve a **una
   sola garantía** en SQL Server, y la afirmación *"el rol es la única
   barrera"* pasa de ser una omisión a ser una decisión cierta. `AC42`
   cambia de propiedad: ya no afirma que el `DENY` le gane a un `GRANT`,
   afirma que el user no tiene NINGUNA otra membresía además de
   `db_datareader` — ver sección "AC42" más abajo, reescrita entera.
2. **El inverso deja de leer la lista: revoca por enumeración.** Patrick
   rechazó el Procedimiento de baja que R1 había documentado —correr el
   inverso con la lista completa y editarla después— porque "depende de
   que alguien recuerde el orden". Su regla, textual: *"Se concede desde
   una lista explícita, se revoca por enumeración."* `sqlserver-inverso.sql`
   ahora recorre `sys.databases` entero buscando dónde existe
   `bisalta_lectura` en `sys.database_principals`, y lo saca de ahí, sin
   leer `@bases_permitidas` en absoluto — ver comentario de cabecera de ese
   archivo. Esto **simplifica del todo** el Procedimiento de baja (sección
   "Inverso" más abajo, reescrita): ya no hace falta ninguna copia de
   trabajo recortada, y el `DROP LOGIN` incondicional del final deja de
   ser un caso especial a vigilar, porque después de una enumeración
   completa es exactamente lo que corresponde.

**v11 (ronda 2 de review sobre v10, dos MAJOR y dos MINOR)**: la decisión
central del punto 2 de v10 tiene AC propio recién ahora — `AC43`, nuevo,
sección propia más abajo — porque su única cobertura hasta acá era
incidental (mismo defecto que el `ESCALATE` de v6 → v7). Además:

1. **MAJOR 1 — la comprobación de "ninguna otra membresía" de `AC42`
   filtraba por una lista cerrada de nombres de rol** (`r.name IN
   ('db_datareader','db_denydatawriter','db_datawriter','db_owner')`), que
   mide "ninguna de estas tres" y no "ninguna otra": una membresía en
   `db_ddladmin`, `db_securityadmin`, `db_accessadmin`,
   `db_backupoperator`, `db_denydatareader` o un rol de base a mano
   pasaba con el mismo verde falso. Corregido quitando el filtro por
   nombre — ver sección "AC42" más abajo.
2. **MAJOR 2 — el inverso saca al user de "TODAS" las bases era más de lo
   que el script sostiene**: una base `NO ONLINE` con el user no se toca
   (el `PRINT` ya lo decía, sección "SIN SALTOS SILENCIOSOS" del
   comentario de cabecera de `sqlserver-inverso.sql`), pero el `DROP
   LOGIN` incondicional del final corre igual — dejando un **huérfano**
   real si eso pasa. Acotado a "toda base **ONLINE**" en el comentario de
   cabecera de `sqlserver-inverso.sql` y en `sqlserver-parte-b.sql`, y
   agregado a la viñeta "Inverso" y al "Procedimiento de baja" (pasos 2 y
   4) el mandato de revisar las líneas `NO ONLINE:`/el listado de
   `sys.databases` antes de dar el inverso por completo.
3. **MINOR — `@estado IS NULL`** en `sqlserver-inverso.sql`: una base
   borrada entre el `SELECT` del cursor y la re-consulta de `state` caía
   por `UNKNOWN` al `ELSE` y ejecutaba `USE` sobre una base inexistente.
   Corregido: el cursor trae `name` y `state` en una sola pasada, sin
   re-consulta y sin `NULL` posible.
4. **MINOR — la mutación de `AC42` concede `db_datawriter` sobre todo
   `EXACTUS`** (395 GB, copia de producción) al login compartido; una
   interrupción entre conceder y revocar dejaría esa concesión en pie sin
   que el runbook lo dijera. Declarado en la sección "AC42" más abajo.

Barrido de clase de esta ronda (impact set, no directorio): el mismo
sobreclamado de "TODAS las bases" para el inverso también vivía en el
comentario "CÓMO DAR DE BAJA UNA BASE" de `sqlserver-parte-b.sql` —
corregido ahí también.

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
   —y nada más, desde v10— a cada base nombrada ahí). El script sale `0`
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

## Verificación de AC1–AC8, AC41, AC42 y AC43

Cada verificación es `manual-only`: ningún harness de este repo puede crear
un rol de Postgres, alcanzar la VPC de dev/qa, o alcanzar `10.24.40.137`.
Estado tras esta ronda: **pendiente-de-ejecucion** para las once.

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

**Estado de arranque de la instancia de prueba** (aplica a los dos pasos
de abajo, "Lista vacía" y "Mutación declarada"): el paso de lista vacía
sólo mide lo que declara si la instancia de prueba **nunca fue
aprovisionada antes con el user `bisalta_lectura` en ninguna base** — el
**login** sí tiene que existir, y este mismo bloque manda crearlo abajo
(si el user ya existiera en
alguna base de una corrida previa, `tiene_user` seguiría en `1` ahí y no
en `0` en absolutamente todas las filas, sin que la copia recién corrida
tenga nada que ver). El paso de mutación, al revés, sólo llega a correr
si el **login** `bisalta_lectura` **ya existe** en esa instancia antes de
la corrida — `sqlserver-parte-b-mutada-v8.sql`, igual que el real, sólo
hace `CREATE USER ... FOR LOGIN bisalta_lectura` dentro de cada base y
nunca crea el login del servidor; sin él, `sqlcmd` falla con `Msg 15007`
antes de tocar ninguna base y el rojo esperado no aparece. Aprovisionar
el login con `sqlserver-parte-a.sql` real contra esa instancia de prueba
antes de arrancar la secuencia de este AC.

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
cierre real necesita un paso de reversión explícito — pero desde v10 ya
**no hace falta ninguna copia de trabajo del inverso**: `sqlserver-
inverso.sql` real revoca por enumeración (recorre `sys.databases` entero
buscando `bisalta_lectura` en `sys.database_principals`, sin leer
`@bases_permitidas`), así que encuentra y saca al user de **cualquier**
base donde la corrida mutada lo haya dejado, esté o no esté en la lista
real, sin necesitar saber cuál fue el filtro de la mutación. Correrlo tal
cual, sin modificar, contra la instancia de prueba:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-inverso.sql
```

Esto deja la instancia de prueba **sin ningún** `bisalta_lectura` en
ninguna base, y **sin el login** (el inverso real termina con `DROP
LOGIN` incondicional — ver su comentario de cabecera: tras una
enumeración completa, esa incondicionalidad es correcta, no un caso
especial a vigilar). Por eso el cierre del rojo tiene dos pasos más, no
uno: recrear el login y volver a conceder por lista, **en ese orden**:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-a.sql
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b.sql
```

(la sustitución del placeholder de contraseña de `sqlserver-parte-a.sql`
aplica igual que en cualquier otra corrida — ver su comentario de
cabecera). Recién ahora volver a correr el bloque `##ac7_check` para
confirmar el verde de cierre — `tiene_user = 1` sólo en las bases de
`@bases_permitidas`, `0` en todo lo demás — antes de tocar `Dev SQL` con
los archivos reales. Descartar las dos copias de trabajo que sí siguen
haciendo falta (`sqlserver-parte-b-lista-vacia.sql`,
`sqlserver-parte-b-mutada-v8.sql`): ninguna se commitea.

`SSISDB` sigue sin ser una decisión pendiente (contract v6, "Cambios v5 →
v6", punto 1, decisión de Patrick Ocampo): en v9 queda fuera porque nunca
está en `@bases_permitidas`, y si alguien la agregara por error,
`@bases_prohibidas` la rechaza igual (ver comentario de
`sqlserver-parte-b.sql` y sección "`SSISDB` queda fuera del loop" más
abajo).

### AC42 — el user tiene `db_datareader` y ninguna otra membresía en cada base de la lista

`AC42` cambió de propiedad en v10 (decisión de Patrick Ocampo): ya no
afirma que un `DENY` le gane a un `GRANT` — afirma que el user **no tiene
ninguna otra membresía** además de `db_datareader`: ni `db_denydatawriter`
(que ya no existe en el loop), ni `db_datawriter`, ni `db_owner`. Un
`INSERT` falla por **ausencia de permiso**, nunca por `DENY`.

Comprobación real, sobre `EXACTUS` en `Dev SQL` — una de las bases
nombradas en `@bases_permitidas`, ya aprovisionada por
`sqlserver-parte-b.sql` real:

**Sin filtro de nombres de rol** (ronda 2 de review, MAJOR 1): `AC42`
afirma `db_datareader` **y ninguna otra** — no "ninguna de una lista
cerrada de tres". Filtrar `r.name IN (...)` mide sólo esas tres y deja
pasar cualquier otra membresía de base (`db_ddladmin`, `db_securityadmin`,
`db_accessadmin`, `db_backupoperator`, `db_denydatareader`, o un rol de
base definido a mano) con el mismo verde falso: la fila que la consulta
devolvería seguiría siendo una sola (`db_datareader`), sin que la
propiedad que `AC42` afirma fuera cierta. La consulta sin filtro es el
enunciado literal del AC: `public` es implícito y **no** aparece en
`sys.database_role_members`, así que no hace falta excluirlo a mano.

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "
SELECT r.name AS rol
FROM sys.database_role_members drm
JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
WHERE m.name = 'bisalta_lectura'
ORDER BY r.name;
"
```

Esperado: **una sola fila**, `db_datareader` — ninguna otra, sin importar
su nombre. Repetir la misma consulta cambiando `-d EXACTUS` por cada una
de las demás bases que declare `@bases_permitidas` en
`sqlserver-parte-b.sql` vigente (abrir el script para ver cuáles son, no
retranscribirlas acá): una sola fila en cada una.

**Con la lista explícita (v9), y desde v10 sin necesidad de ninguna copia
de trabajo del script**: a diferencia de la ronda anterior, la mutación
de AC42 ya no necesita una base de scratch nueva agregada a una copia de
`sqlserver-parte-b.sql` — usa directamente una de las bases **ya
concedidas de verdad** (`EXACTUS`), con una tabla de scratch adentro, y
**sin ningún `GRANT` de objeto**: el acceso de escritura tiene que venir
únicamente de la membresía de rol (`db_datawriter`), igual que AC6 — un
`GRANT INSERT` puntual sobre la tabla dejaría pasar el `INSERT` con o sin
esa membresía, y no probaría nada sobre lo que AC42 afirma.

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "CREATE TABLE zz_scratch_ac42 (id int);"
```

**Comprobación real (verde), sobre la tabla recién creada**, con el user
tal como lo deja `sqlserver-parte-b.sql` real (sólo `db_datareader`):

```
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d EXACTUS -Q "INSERT INTO zz_scratch_ac42 VALUES (1);"
```

Esperado: falla con `The INSERT permission was denied` — ausencia de
permiso, sin que nada lo deniegue explícitamente.

**Mutación declarada** (contract v10, AC42): otorgar `db_datawriter` al
user sobre esta misma base de scratch. **Ojo (ronda 2 de review,
MINOR)**: `ALTER ROLE db_datawriter ADD MEMBER` no acota el permiso a
`zz_scratch_ac42` — concede escritura sobre **todo `EXACTUS`**, la copia
de producción completa (395 GB), al login vivo compartido
(`bisalta_lectura`), no sólo sobre la tabla de scratch. El camino feliz de
este procedimiento revoca esa membresía dos pasos más abajo y nadie
escribe nada en el medio, pero si algo interrumpe la corrida entre estos
dos comandos (la sesión se corta, alguien más usa la misma instancia), la
concesión sobre toda la base queda en pie sin que este runbook lo declare
en ningún lado hasta ese momento — quien retome tiene que revisar
`sys.database_role_members` en `EXACTUS` antes de asumir el estado
esperado:

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "ALTER ROLE db_datawriter ADD MEMBER bisalta_lectura;"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d EXACTUS -Q "INSERT INTO zz_scratch_ac42 VALUES (1);"
```

Esperado en este paso: el `INSERT` **pasa** — es la comprobación de que
"falla" se pone roja con `db_datawriter` de más en el rol, sobre una base
que la parte B real nunca le da.

Restaurar quitando **sólo** `db_datawriter` — `db_datareader` sigue
asignada, la tabla de scratch sigue viva, la comprobación real tiene que
correr sobre la misma tabla:

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "ALTER ROLE db_datawriter DROP MEMBER bisalta_lectura;"
SQLCMDPASSWORD='<contraseña real>' sqlcmd -S 10.24.40.137 -U bisalta_lectura -d EXACTUS -Q "INSERT INTO zz_scratch_ac42 VALUES (1);"
```

Esperado: el `INSERT` **vuelve a fallar**, con `The INSERT permission was
denied` — otra vez por **ausencia de permiso** (sin `db_datawriter` y sin
ningún `DENY` que lo bloquee expresamente): es exactamente lo que v10
dejó — que la única capacidad del login es leer. Recién ahora, con el
triple completo (verde real → rojo de mutación → verde de cierre)
corrido, limpiar:

```
sqlcmd -S 10.24.40.137 -E -d EXACTUS -Q "DROP TABLE zz_scratch_ac42;"
```

### AC43 — el inverso revoca por enumeración, no lee `@bases_permitidas`

`AC43` (contract v11) es el AC propio que le faltaba a la decisión central
de v10: hasta ahora, que `sqlserver-inverso.sql` revoca por enumeración en
vez de leer la lista sólo tenía cobertura **incidental** (el verde de
cierre de la mutación de `AC7`, sección de arriba, sería imposible si el
inverso leyera únicamente `@bases_permitidas` — pero ningún AC lo afirmaba
por sí mismo, y eso es exactamente el defecto que causó el `ESCALATE` de
v6 → v7 de este mismo contract). Afirma dos cosas: (a) el inverso saca al
user de toda base **ONLINE** donde exista, estén o no en la lista,
incluidas las cuatro de sistema; (b) el script **no lee
`@bases_permitidas` en su cuerpo ejecutable** — el string sólo aparece en
el comentario de cabecera que documenta justamente que no se lee (líneas
6 y 23 de `sqlserver-inverso.sql`), y ese comentario no cuenta como
lectura. Confirmable acotando el grep a lo que no es comentario:
`grep -n "bases_permitidas" sqlserver-inverso.sql | grep -v '^[0-9]*:--'`,
que **no tiene que devolver nada** (el `grep -v` filtra cualquier línea
cuyo contenido, después de los dos puntos del número de línea, empiece
con `--`).

**Comprobación real (verde), sobre una instancia de prueba** (no `Dev
SQL` directamente): crear a mano el user `bisalta_lectura` en una base
que **no** esté en `@bases_permitidas` de `sqlserver-parte-b.sql`
vigente — `CONSTRUPLAZA_EFLOW` (`INVENTARIO.md`, 266.92 GB) sirve de
ejemplo porque es una base real de `Dev SQL` que la lista nunca nombra —
y también en `msdb`, una de las cuatro bases de sistema que (a) nombra
explícitamente: sin este segundo user, esa mitad de (a) sólo se sostiene
por inspección del cursor sin filtro (`SELECT name, state FROM
sys.databases`, sin condición sobre `database_id` ni sobre el nombre),
nunca por una corrida real (ronda 3 de review, MINOR — `D40` se cerró
apoyándose en esa afirmación sin ejercitarla). Requiere que el login
`bisalta_lectura` ya exista en esa instancia (aprovisionarlo con
`sqlserver-parte-a.sql` real si hace falta, igual que en AC7):

```
sqlcmd -S <instancia-de-prueba> -E -d CONSTRUPLAZA_EFLOW -Q "CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura;"
sqlcmd -S <instancia-de-prueba> -E -d msdb -Q "CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura;"
```

Correr el inverso real, sin modificar:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-inverso.sql
```

Esperado: el `DROP USER bisalta_lectura` corre también dentro de
`CONSTRUPLAZA_EFLOW` y dentro de `msdb` — confirmar con

```
sqlcmd -S <instancia-de-prueba> -E -d CONSTRUPLAZA_EFLOW -Q "SELECT 1 FROM sys.database_principals WHERE name = 'bisalta_lectura';"
sqlcmd -S <instancia-de-prueba> -E -d msdb -Q "SELECT 1 FROM sys.database_principals WHERE name = 'bisalta_lectura';"
```

que tienen que devolver **cero filas** las dos. La primera es la
comprobación de que el inverso saca al user de una base que nunca estuvo
en la lista y que nadie tuvo que nombrar; la segunda es la comprobación
de que también lo saca de una base **de sistema**, ejercitando de verdad
la mitad de (a) que hasta esta ronda sólo se afirmaba por lectura del
script.

**Mutación declarada** (contract v11, AC43): en una copia de trabajo
`sqlserver-inverso-mutado.sql`, reemplazar el cursor `SELECT name, state
FROM sys.databases` por uno que recorra `@bases_permitidas` — la forma
que el script tenía hasta v9 (mismo patrón de cursor sobre la variable de
tabla que usa hoy `sqlserver-parte-b.sql`, declarando la misma lista de
bases con `INSERT INTO @bases_permitidas`, y sin filtro `state` porque
esa forma vieja no lo necesitaba para revocar por lista). Repetir el paso
de crear a mano al user en `CONSTRUPLAZA_EFLOW` (si ya se limpió en el
paso anterior) y correr la copia mutada:

```
sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-inverso-mutado.sql
```

Esperado en este paso: la comprobación se pone **roja** —
`bisalta_lectura` **sobrevive** en `CONSTRUPLAZA_EFLOW` (la consulta de
`sys.database_principals` de arriba devuelve una fila), porque el cursor
mutado sólo recorre las bases de `@bases_permitidas` y esa base nunca
estuvo ahí. Restaurar la enumeración real (descartar la copia mutada, no
commitearla nunca) y volver a correr `sqlserver-inverso.sql` real contra
la instancia de prueba para confirmar el verde de cierre —
`bisalta_lectura` fuera de `CONSTRUPLAZA_EFLOW` otra vez.

`manual-only: requiere la instancia de Dev SQL; misma razón que AC5.`

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

`db_datareader` es permiso **por base** en SQL Server, a diferencia de
`pg_read_all_data` en Postgres, que es un permiso de **cluster**. Con la
lista explícita de v9 esto se vuelve doblemente cierto: **una base
agregada a `Dev SQL`, o pedida por nombre pero todavía no escrita en
`@bases_permitidas`, NO queda cubierta automáticamente**: `bisalta_lectura`
no tendrá `CREATE USER` ni `db_datareader` ahí hasta que alguien (a)
agregue esa base al `INSERT INTO @bases_permitidas` de
`sqlserver-parte-b.sql` y (b) vuelva a correr el script completo — y
mientras tanto esa base nueva no tiene ninguna lectura. No hay manera de
evitar esto en SQL Server sin un trigger de servidor sobre `CREATE
DATABASE` — fuera del scope de este runbook — así que la asimetría se
documenta acá en vez de compensarse con código nuevo (contract v10,
sección "Garantías por motor (asimetría declarada, no disimulada)").

El mismo hueco existe, por el mismo motivo, para una base que **ya está
en la lista pero estaba `OFFLINE` o `RESTORING`** al momento de correr
`sqlserver-parte-b.sql`: el script la nombra por `PRINT` en vez de
saltearla en silencio (ver comentario del script, "SIN SALTOS
SILENCIOSOS"), pero no le crea nada en esa corrida, y queda tan
descubierta como una base recién pedida. **Acción operativa**: cada vez
que se pida una base nueva, o que una base ya listada pase a estar
`ONLINE` después de haber estado en otro estado durante la última
corrida, (a) agregarla (si no estaba) al `INSERT` de
`sqlserver-parte-b.sql` (desde v10, `sqlserver-inverso.sql` **no tiene
ninguna lista que actualizar en paralelo** — enumera `sys.databases`
solo, ver su comentario de cabecera), (b) registrar el pedido con fecha
y solicitante en `APROBACIONES.md`, y (c) re-correr `sqlserver-parte-b.sql`
— en ese orden, antes de agregar esa base al catálogo de `bisalta-db`.

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
- SQL Server: `sqlserver-inverso.sql`, una sola corrida contra la
  instancia. **Desde v10 no lee ninguna lista** (decisión de Patrick
  Ocampo: "se concede desde una lista explícita, se revoca por
  enumeración") — recorre `sys.databases` entero, busca en cada base
  **ONLINE** si `sys.database_principals` tiene a `bisalta_lectura`, y lo
  saca de ahí; al final borra el login, siempre, incondicionalmente. No
  hace falta agregar ni quitar nada de `sqlserver-inverso.sql` cuando se
  edita la lista de `sqlserver-parte-b.sql`: no tiene lista propia que
  mantener en sincronía (ver comentario de cabecera de ese archivo).
  **Antes de correrlo** (ronda 2 de review, MAJOR 2), revisar si alguna
  base relevante está `NO ONLINE` — `SELECT name, state FROM
  sys.databases WHERE state <> 0` (misma consulta que la sección "AC7"
  prescribe para lo que su cursor no puede ver): una base así **no** se
  toca en esta corrida — el script la reporta por `PRINT` y sigue, pero
  el `DROP LOGIN` incondicional del final corre igual. El resultado es un
  **user huérfano**: `bisalta_lectura` sigue existiendo en esa base sin
  ningún login de servidor detrás, hasta que alguien la vuelva a poner
  `ONLINE`. La limpieza de ese huérfano **no es volver a correr
  `sqlserver-inverso.sql` completo** contra la instancia: para entonces el
  script ya borró el login y ya revocó al user de todas las demás bases
  que estaban `ONLINE` en esa corrida, así que una segunda corrida
  completa no tiene nada más que hacer sobre esas otras bases — y si
  alguna de ellas fue re-concedida después (por ejemplo, con
  `sqlserver-parte-a.sql` + `sqlserver-parte-b.sql`, como en un alta o en
  el "Procedimiento de baja" más abajo), esa segunda corrida se la
  revoca otra vez y vuelve a borrar el login, deshaciendo trabajo ya
  hecho. La limpieza correcta es dirigida, contra la base huérfana sola:

  ```
  sqlcmd -S <instancia> -E -d <base> -Q "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'bisalta_lectura') DROP USER bisalta_lectura;"
  ```

  Si en cambio alguien repara ese huérfano con la rutina estándar
  (`ALTER USER ... WITH LOGIN` contra el login vivo), esa base recupera
  `db_datareader` sin haber estado nunca en `@bases_permitidas` ni haber
  sido pedida de nuevo — dejarla anotada como pendiente de limpieza
  dirigida (no de "reintentar el inverso") evita ese resultado.
- AWS: los tres secretos se borran a mano desde la cuenta de dev/qa (no
  hay script: crear/borrar secretos está fuera del scope de este runbook,
  igual que crearlos).

### Procedimiento de baja (sacar una base de la lista de SQL Server)

Desde v10 esto se simplifica del todo: ya no hace falta ninguna copia de
trabajo recortada, ni cuidar en qué orden se editan dos listas, porque
`sqlserver-inverso.sql` ya no tiene una lista propia — encuentra
`bisalta_lectura` donde sea que esté por enumeración. El costo de esa
simplicidad es que el inverso, corrido tal cual, es una revocación
**total**: saca al user de **todas** las bases donde exista, no sólo de
la que se quiere dar de baja, y borra el login. El procedimiento por eso
tiene tres pasos donde antes había una copia de trabajo cuidadosamente
recortada:

Orden para dar de baja una base (por ejemplo, `Ecommerce_qa`, con
`COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `EXACTUS` y `BI` quedando activas):

0. **Antes de revocar nada**, sacar la entrada correspondiente de
   `plugins/bisalta-db/catalogo.json` (para `Ecommerce_qa`, la entrada
   `"nombre": "ecommerce-qa"`) — documentar el paso acá, **no editar el
   archivo** como parte de este runbook. Seguido en cualquier otro orden,
   la entrada queda apuntando a una base donde `bisalta_lectura` ya no
   tiene user, y el MCP falla en runtime con error de login la próxima
   vez que alguien la consulte.
1. Sacar la fila `(N'Ecommerce_qa')` del `INSERT INTO @bases_permitidas`
   de `sqlserver-parte-b.sql` (única lista que existe: `sqlserver-
   inverso.sql` no tiene una propia) y registrar la baja en
   `APROBACIONES.md` (fecha y quién la pidió), igual que un alta.
2. **Antes de correr**, revisar si alguna base está `NO ONLINE` (`SELECT
   name, state FROM sys.databases WHERE state <> 0` — la misma consulta
   de la sección "AC7"): si `COMPRAS`, `COMPRAS_STG`, `Ecommerce`,
   `EXACTUS` o `BI` aparecen ahí, este paso **no** las va a limpiar de
   verdad — el script las reporta por `PRINT` y las salta, pero el `DROP
   LOGIN` del final corre igual — y quedarían con un `bisalta_lectura`
   huérfano hasta que vuelvan a estar `ONLINE`. **No** queda pendiente de
   "reintentar el inverso": para cuando se note esto ya pasó el paso 3,
   que re-concede desde cero a `COMPRAS`, `COMPRAS_STG`, `Ecommerce`,
   `EXACTUS` y `BI` — correr `sqlserver-inverso.sql` completo otra vez
   revocaría a esas cinco de nuevo y borraría el login que el paso 3
   acaba de recrear. Anotar cualquier base así como pendiente de limpieza
   **dirigida**, con:
   ```
   sqlcmd -S 10.24.40.137 -E -d <base> -Q "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'bisalta_lectura') DROP USER bisalta_lectura;"
   ```
   cuando esa base vuelva a estar `ONLINE`, antes de seguir.

   Correr `sqlserver-inverso.sql` **real, sin modificar**, contra la
   instancia:
   ```
   sqlcmd -S 10.24.40.137 -E -b -i sqlserver-inverso.sql
   ```
   Esto revoca a `bisalta_lectura` de **todas las bases ONLINE** donde
   exista hoy —incluidas `COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `EXACTUS`
   y `BI`, que se querían mantener— y borra el login. Es a propósito: la
   enumeración no distingue "esta base sale" de "estas otras se quedan".
3. Correr `sqlserver-parte-a.sql` real (recrea el login — con una
   contraseña nueva, que hay que cargar de nuevo en el secreto
   `bisalta-db/sqlserver/bisalta_lectura`) y `sqlserver-parte-b.sql` real
   (recorre la lista, ya sin `Ecommerce_qa` desde el paso 1, y re-concede
   exactamente esas cinco). El mecanismo para conservar las bases que se
   quedan no es "no tocarlas": es volver a concederlas desde la
   declaración — que es lo único que `sqlserver-parte-b.sql` sabe hacer
   bien, y ya está pensado para correrse las veces que haga falta
   (idempotente, ver su comentario "Idempotente").
4. Confirmar con el bloque `##ac7_check` (sección "AC7" de arriba):
   `tiene_user = 0` para `Ecommerce_qa`, y `tiene_user = 1` en las cinco
   bases que siguen en la lista. Correr también `SELECT name, state FROM
   sys.databases WHERE state <> 0` (misma consulta que la sección "AC7"
   prescribe para lo que el cursor de `##ac7_check` no puede ver, y la
   misma del paso 2): cualquier base que aparezca ahí no quedó cubierta
   por esta confirmación. Para este punto el paso 3 ya recreó el login y
   ya re-concedió las cinco bases activas, así que la pendiente **no** se
   resuelve reintentando `sqlserver-inverso.sql` completo — eso repetiría
   la revocación total sobre las cinco que este mismo paso acaba de
   confirmar en `ONLINE` y volvería a borrar el login recién recreado.
   Queda pendiente de limpieza **dirigida** (mismo comando `DROP USER`
   del paso 2, contra esa base sola) para cuando vuelva a estar `ONLINE`.

**Decomiso completo** (ninguna base sigue activa): son los mismos cuatro
pasos, salvo que el paso 1 deja la lista de `sqlserver-parte-b.sql`
**vacía**, y el paso 3 se reduce a correr sólo `sqlserver-parte-a.sql`
(para dejar el login existente, si se quiere conservar para un alta
futura) o directamente omitirse (si no queda ninguna base ni se planea
ninguna a corto plazo) — ya no es un caso especial del inverso, como lo
era hasta v9: es la misma revocación total del paso 2, sin nada que
re-conceder después.

Ningún script de R1 se corrió contra una base real: no hay estado externo
pendiente de revertir además de lo que este runbook ya describe.
