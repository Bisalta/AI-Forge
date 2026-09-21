# `bisalta-db` — consulta de solo lectura sin credencial en el contexto

Plugin de Claude Code que expone dos herramientas MCP para leer las bases de
**dev/qa** de Bisalta:

| Herramienta | Qué hace |
|---|---|
| `listar_conexiones()` | Lista las conexiones del catálogo con su dialecto, ambiente, base y las garantías de solo lectura de cada una. |
| `consultar(conexion, sql)` | Corre una consulta de solo lectura y devuelve las filas. |

## Para qué existe

Para consultar una base hoy hay que leerle a Claude el archivo con la cadena
de conexión, y todo lo que lee queda en el transcript: la contraseña de un
usuario con permisos de escritura termina archivada. Con este plugin la
credencial no desaparece — **cambia de lugar**: pasa de un archivo que hay
que mostrarle al modelo a un secreto de AWS que el proceso resuelve, usa y
tira. La sesión nunca la ve.

El paquete que resolvería esto no sirve: `@modelcontextprotocol/server-postgres`
está **deprecado desde 2025 y tiene inyección SQL que se salta su propio modo
de solo lectura** — pasa el SQL sin parametrizar y permite salir de la
transacción read-only para ejecutar DDL/DML con todos los privilegios de la
conexión.

## Instalación

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install bisalta-db
```

Requisitos en la máquina (ninguno se instala con el plugin):

- `node` (probado con v22.17). **No hay `package.json`, ni lockfile, ni
  `node_modules`**: el servidor es Node plano, cero dependencias.
- `psql` para las conexiones `postgres`; `sqlcmd` para las `sqlserver`. Si el
  binario falta, la consulta devuelve `cliente_ausente` (código 8) nombrando
  cuál falta.
- `aws` con credenciales que tengan permiso de lectura sobre el secreto de esa
  conexión. **La barrera real es IAM, no el plugin**: sin permiso sobre el
  secreto, la conexión falla aunque la entrada del catálogo esté ahí.

## Cómo se declara el servidor MCP (verificado, no supuesto)

Un plugin de Claude Code declara un servidor MCP de dos formas, ambas
documentadas en el plugin oficial `plugin-dev` del marketplace
`anthropics/claude-plugins-official` (skill `mcp-integration`, y
`skills/plugin-structure/references/manifest-reference.md`, sección
`mcpServers`):

1. **`.mcp.json` en la raíz del plugin** (el default: el manifiesto lo busca
   ahí sin que haga falta declararlo). Es el que usa este plugin.
2. **Campo `mcpServers` embebido en `.claude-plugin/plugin.json`**, para
   plugins de un solo servidor.

Acá se usan las dos a la vez, que es compatible: `plugin.json` apunta
explícitamente a `"mcpServers": "./.mcp.json"` y el archivo lleva la
definición.

El archivo admite **dos formas** y Claude Code acepta las dos: el objeto de
servidores suelto, o envuelto en una clave `mcpServers`. Medido sobre el
marketplace oficial instalado en esta máquina: de sus catorce plugins con
`.mcp.json`, cinco usan la envoltura (`context7`, `discord`, `telegram`,
`imessage`, `fakechat`) y nueve no (`serena`, `playwright`, `terraform`,
`github`, ...) — y el catálogo que el propio Claude Code deriva
(`~/.claude/plugins/plugin-catalog-cache.json`, campo
`components.mcpServers`) resuelve **el mismo nombre de servidor** para las dos
formas (`context7 -> ["context7"]`, `serena -> ["serena"]`). Este plugin usa
la envoltura, que es la forma que coincide con el `.mcp.json` de proyecto.

Un servidor `stdio` se declara con `command` y `args`; `${CLAUDE_PLUGIN_ROOT}`
es la única forma portable de referirse a un archivo del propio plugin:

```json
{
  "mcpServers": {
    "bisalta-db": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/scripts/servidor-mcp.js"]
    }
  }
}
```

Las herramientas quedan disponibles como
`mcp__plugin_bisalta-db_bisalta-db__consultar` y
`mcp__plugin_bisalta-db_bisalta-db__listar_conexiones`. `/mcp` las lista.

## Las cinco capas, y la primera no es este código

0. **El endpoint.** Las entradas de Postgres apuntan al endpoint de réplica de
   lectura de Aurora (`cluster-ro-`), que rechaza las escrituras **en el
   motor**. Es la única capa que no depende de que nada de este repo esté bien
   escrito.
1. **El rol** de base es de solo lectura (`claude_lectura` / `neo_lectura`,
   miembros de `pg_read_all_data`). Lo crea el runbook de
   `aprovisionamiento/`.
2. **La sesión** se abre en `default_transaction_read_only=on`, con
   `statement_timeout=120000`.
3. **La lista blanca** exige que *cada* sentencia empiece con `SELECT` o
   `WITH`, después de quitar comentarios y literales.
4. **El catálogo**: `ambiente` admite `dev` y `qa` **y nada más**. Producción
   es irrepresentable, no rechazada por nombre — rechazar por nombre es red,
   no barrera.

### Por qué lista blanca y no lista negra

Un bloque `DO $$ ... $$` puede hacer cualquier cosa, y una lista negra de
INSERT/UPDATE/DELETE lo deja pasar entero. Y la palabra tiene que estar **al
principio** de la sentencia: la versión laxa (buscar `SELECT` en cualquier
posición) pasaba once de los doce tests originales, y el caso que la mató fue
`DELETE ... WHERE id IN (SELECT ...)`.

Si de verdad hace falta escribir, **no se amplía la lista blanca**: se corre a
mano en DBeaver, donde una persona ve lo que va a pasar antes de que pase.

### Diferencias por dialecto

| | `postgres` | `sqlserver` |
|---|---|---|
| Ancla `SELECT`/`WITH` por sentencia | sí | sí |
| Varias sentencias separadas por `;` | **aceptadas** | **rechazadas**: cualquier `;` que quede tras quitar comentarios y literales |
| Apertura de comilla de dólar (`$$`, `$tag$`) | **rechazada** | n/a |
| `EXEC`, `EXECUTE`, identificador `sp_`/`xp_` | n/a | **rechazados** |

En `sqlserver` se manda **una sola sentencia y sin punto y coma**: no existe
equivalente de sesión de solo lectura que contenga un batch de T-SQL, así que
la barrera es el texto.

## Garantías por motor (asimetría declarada, no disimulada)

| | Postgres (`dev`/`qa`) | SQL Server (`Dev SQL`) |
|---|---|---|
| Rol de solo lectura | sí | sí |
| Sesión abierta en solo lectura | sí, `default_transaction_read_only=on` | **no existe equivalente** |
| `DENY` de escritura sobre el rol | no aplica | sí, `db_denydatawriter` — el `DENY` le gana a cualquier `GRANT` |
| Motor que rechaza escrituras | sí (endpoint `cluster-ro-`) | **no hay réplica** |
| Alcance del permiso | `pg_read_all_data`, de cluster — alcanza las 29 bases del cluster de dev/qa desde que el rol existe, no sólo las del catálogo | `db_datareader` + `db_denydatawriter`, **por base**: una base nueva no queda cubierta sola |

Que esa asimetría esté escrita en `garantias`, entrada por entrada, es lo que
evita que alguien asuma que todas las conexiones son igual de seguras.
Las conexiones de `Dev SQL` son además **copias de producción** (`EXACTUS` 395 GB, `BI`
177 GB, `COMPRAS` 107 GB): los tamaños no son de desarrollo.

## El catálogo — `catalogo.json`

Arreglo de objetos. El validador **rechaza cualquier campo no listado acá y
cualquier campo faltante**, y rechaza el catálogo entero (no sólo la entrada)
si algo no cierra.

| Campo | Valores |
|---|---|
| `nombre` | minúsculas, dígitos y guiones; único en el arreglo |
| `dialecto` | `postgres` o `sqlserver` |
| `ambiente` | `dev` o `qa` — **no hay valor que nombre producción** |
| `host` | cadena no vacía; se rechaza si contiene el cluster o el host de la cuenta de producción |
| `puerto` | entero entre 1 y 65535 |
| `base` | cadena no vacía |
| `secret_id` | identificador o ARN del secreto |
| `region` | cadena no vacía |
| `garantias` | al menos un elemento de `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura`, `deny-escritura` |

**No existe campo de usuario ni de contraseña.** Los dos salen del secreto, en
la forma estándar de RDS: un campo `username` y otro con la contraseña, en la
carga JSON del secreto.

El catálogo se lee **en cada invocación**, no al arrancar: borrar una entrada
la deja inaccesible en la consulta siguiente, sin reiniciar nada y sin tocar
código. Es el kill switch local.

Validarlo a mano:

```
node plugins/bisalta-db/scripts/catalogo.js
```

### Las tres entradas de hoy

| `nombre` | Fuente | Nota |
|---|---|---|
| `proveedores-dev` | base `proveedores_dev` del cluster Aurora de dev/qa | |
| `proveedores-qa` | base `proveedores_qa` del mismo cluster | |
| `compras` · `compras-stg` · `ecommerce` · `ecommerce-qa` · `exactus` · `bi` | bases de la instancia `Dev SQL` (`10.24.40.137`), concedidas **a pedido nombrado** — el alcance arranca en cero y cada base entra con fecha y solicitante | copias de producción |

Dos precisiones sobre estos valores:

- Los nombres llevan **guion y no guion bajo** (`proveedores-dev`, no
  `proveedores_dev`) porque el contrato de datos fija ese formato para
  `nombre`. La base a la que apuntan sí conserva su nombre real en el campo
  `base`.
- El `host` de las dos entradas de Postgres es el **endpoint de réplica de
  lectura** (`cluster-ro-`), que es lo que sostiene la garantía
  `endpoint-replica-lectura`. El runbook de `aprovisionamiento/` documenta el
  endpoint de escritura del mismo cluster, que es otro. Antes del primer uso
  real conviene confirmarlo contra `aws rds describe-db-clusters`
  (`ReaderEndpoint`): si el cluster no tuviera réplica, esa garantía hay que
  sacarla de la entrada, no dejarla escrita.

## La credencial

- **Postgres**: archivo temporal en modo 600 bajo un `mkdtemp`, apuntado por
  la variable de libpq que nombra un *archivo* de contraseñas, y borrado en un
  `finally` que corre también cuando la consulta falla. El usuario, el host,
  el puerto y la base viajan en un conninfo (URI); la contraseña, sólo en ese
  archivo.
- **SQL Server**: variable de entorno acotada al proceso hijo. `sqlcmd` no
  tiene equivalente de archivo, y su bandera de contraseña la dejaría visible
  en la tabla de procesos de toda la máquina.
- En los dos casos, **la contraseña nunca viaja por `argv`**.

## Respuesta y topes

```json
{
  "conexion": "proveedores-dev",
  "dialecto": "postgres",
  "filas": [ { "...": "..." } ],
  "filas_devueltas": 12,
  "truncado": false,
  "motivo_truncado": null
}
```

Tope de **1000 filas** y **1048576 bytes** (1 MiB) de `filas` serializado. Al
truncar, `filas` trae las que caben, `truncado` es `true` y `motivo_truncado`
nombra cuál de los dos topes se alcanzó primero. **Truncar no es un error**:
la respuesta es exitosa.

🔴 **Las filas que devuelve quedan en el transcript de la sesión.** Es lo que
el plugin hace, así que no hay diseño que lo evite sin negar la función: el
tope duro es la única barrera, y está aceptado como riesgo con dueño. La
aprobación para consultar datos de producción es precondición de habilitar el
plugin al equipo, no algo que este código controle.

## Errores

| Situación | Código | Respuesta |
|---|---|---|
| Falta `conexion` o `sql` | 2 | `uso`, con la firma esperada |
| Nombre ausente del catálogo | 3 | `conexion_desconocida`, con la lista de nombres válidos |
| Sentencia rechazada por la lista blanca | 4 | `no_es_lectura`, con los primeros 90 caracteres de la sentencia ofensora |
| El secreto no resuelve | 5 | `secreto_inaccesible`, con la conexión y el `secret_id`, **sin la salida cruda de `aws`** |
| Conexión rechazada o caída | 6 | `conexion_fallida`, con el mensaje del cliente, sin la credencial |
| `statement_timeout` (120 s) | 7 | `tiempo_agotado` |
| Binario del cliente ausente | 8 | `cliente_ausente`, nombrando el binario |

El catálogo ilegible o inválido también sale con código 2 (`catalogo_invalido`):
es un error de configuración, del mismo lado que el uso incorrecto.

En el servidor MCP el código viaja en el campo `codigo` del cuerpo de la
respuesta — el proceso vive toda la sesión y no puede salir por consulta. Es
**el mismo código** con el que sale el modo de una sola consulta:

```
node plugins/bisalta-db/scripts/servidor-mcp.js --consultar proveedores-dev --sql "SELECT 1"
echo $?
node plugins/bisalta-db/scripts/servidor-mcp.js --listar-conexiones
```

## Bitácora

Una línea JSON por invocación de `consultar`, sólo se agrega:

```json
{"ts":"...","conexion":"proveedores-dev","dialecto":"postgres","hash_consulta":"sha256:...","filas_devueltas":12,"truncado":false,"duracion_ms":184,"codigo":0}
```

🔴 **La consulta va por hash, nunca en claro**: el SQL puede llevar valores de
negocio y la bitácora sobrevive a la sesión. La contraseña y la carga del
secreto no entran nunca.

Default: `~/.claude/bisalta-db/bitacora.jsonl`. **No rota** — sólo crece;
registrado como deuda.

| Variable de entorno | Default |
|---|---|
| `BISALTA_DB_CATALOGO` | `<raíz del plugin>/catalogo.json` |
| `BISALTA_DB_BITACORA` | `~/.claude/bisalta-db/bitacora.jsonl` |

## Lo que este plugin NO hace

- **Escribir**, de ninguna forma. Una escritura necesaria se corre a mano en
  DBeaver.
- **Tocar producción**: ni el cluster `cluster-cr4rbgr7qlr6` ni `Prod SQL`
  (`192.168.252.22`). El validador rechaza el catálogo si una entrada los
  nombra.
- **Auditar quién consultó qué**: CloudTrail registra quién obtuvo el secreto,
  no qué consultó. Responder eso exige un servicio HTTP intermedio (Lambda +
  API Gateway + Cognito), evaluado y descartado por desproporcionado.

## Aprovisionamiento

`aprovisionamiento/RUNBOOK.md` — roles, logins, secretos y política IAM. Lo
ejecuta una persona con privilegios de administración en cada motor; los
scripts de esa carpeta no se corren desde acá.

🔴 En Postgres, `pg_read_all_data` es una membresía **de cluster**, y
Postgres concede `CONNECT` a PUBLIC por omisión en toda base: un rol
creado por `postgres-parte-a.sql` alcanza las 29 bases del cluster de
dev/qa desde que existe, no sólo las dos que declara `catalogo.json`. Por
eso `aprovisionamiento/postgres-parte-0.sql` corre **antes** de crear
ningún rol y aborta si el cluster contiene alguna base `_prod` — es la
barrera real, no `postgres-parte-b.sql`.

🔴 En SQL Server, el alcance **arranca en cero y se agrega a pedido
nombrado**: el login no toca ninguna base de negocio hasta que alguien la
pide por su nombre, y entonces se concede el mismo día — queda registrado
con fecha y solicitante en `aprovisionamiento/APROBACIONES.md`. La parte B
del runbook recorre una **lista explícita** declarada en el propio
script, no todas las bases de la instancia: **una base nueva, o una
pedida pero todavía no agregada a esa lista, no queda cubierta** hasta
que alguien la sume ahí y re-corra la parte B — `db_datareader` y
`db_denydatawriter` son por base.

## Tests

`SDD/tests/test_lista_blanca.sh`, `SDD/tests/test_catalogo.sh` y
`SDD/tests/test_servidor_mcp.sh`, de la suite de este repo
(`bash SDD/tests/run.sh`). Ninguno necesita una base: la lista blanca se
afirma por código de salida **antes de conectar**, y el protocolo se ejercita
alimentando stdin con tramas JSON-RPC.
