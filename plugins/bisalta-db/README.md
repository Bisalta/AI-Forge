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

## Las cinco capas, y la primera está en el motor — el plugin la comprueba

0. **El endpoint.** Las entradas de Postgres apuntan al endpoint de réplica de
   lectura de Aurora (`cluster-ro-`), que rechaza las escrituras **en el
   motor**. Pero Aurora apunta ese endpoint **al writer** cuando el cluster se
   queda sin réplicas, así que el endpoint solo no alcanza: desde v16 el plugin
   **comprueba en cada consulta** que la sesión llegó a una réplica —una guarda
   con `pg_is_in_recovery()` que corre en la misma conexión y antes del SQL del
   consumidor— y, si no, se niega con `no_es_replica` (código 9) sin ejecutar
   ese SQL.
1. **El rol** de base es de solo lectura (`claude_lectura`, miembro de
   `pg_read_all_data`). Lo crea el runbook de `aprovisionamiento/`. Un solo
   rol: NEO no abre ninguna conexión Postgres (lee Odoo por XML-RPC), así
   que no hay un segundo consumidor que necesite el suyo (contract v13).
2. **La sesión** se abre en `default_transaction_read_only=on`. El límite de
   tiempo de sentencia **ya no lo manda el plugin** (hasta v18 mandaba
   `statement_timeout=120000` por `PGOPTIONS`, y le ganaba al del rol): lo
   fija el rol (`ALTER ROLE claude_lectura SET statement_timeout = '60s'`,
   `aprovisionamiento/postgres-parte-a.sql`); si 60s queda corto para un
   agregado legítimo, se sube ahí, no en el cliente (v19).
3. **La lista blanca** exige que *cada* sentencia empiece con `SELECT` o
   `WITH` **y** que no contenga una escritura embebida (`INSERT`, `UPDATE`,
   `DELETE`, `MERGE` o `INTO` como palabra; en `postgres`, además,
   `set_config`), después de quitar comentarios y literales. **No es la
   barrera que impide una escritura** (v19): es la primera capa, la que
   rechaza temprano y con un mensaje claro; lo que impide el daño son las
   capas de atrás — la réplica, la sesión y el rol. Patrick Ocampo revisó el
   validador buscando cómo esquivarla: encontró doce formas de pasarla y
   ninguna es una brecha, porque cada una choca después con alguna de esas
   capas.
4. **El catálogo**: `ambiente` admite `dev` y `qa` **y nada más**. Producción
   es irrepresentable, no rechazada por nombre — rechazar por nombre es red,
   no barrera.

### Por qué lista blanca y no lista negra

Un bloque `DO $$ ... $$` puede hacer cualquier cosa, y una lista negra de
INSERT/UPDATE/DELETE lo deja pasar entero. Y la palabra tiene que estar **al
principio** de la sentencia: la versión laxa (buscar `SELECT` en cualquier
posición) pasaba once de los doce tests originales, y el caso que la mató fue
`DELETE ... WHERE id IN (SELECT ...)`.

**Y empezar con `SELECT` o `WITH` no alcanza** (contract v16). Un `WITH`
puede llevar una escritura adentro —`WITH x AS (DELETE ... RETURNING *) SELECT
...` en Postgres, `WITH c AS (SELECT ...) DELETE FROM c` en SQL Server—,
`SELECT ... INTO nueva` crea una tabla, y `SELECT set_config(...)` cambia un
parámetro de la sesión desde dentro de una lectura. Medido el 23-sep-2026:
todas esas formas **se aceptaban**. Por eso, además del ancla, cada sentencia
ya normalizada se rechaza si nombra una de esas palabras (motivo
`escritura_embebida`, y `funcion_prohibida` para `set_config`). Rechaza de
más, a sabiendas: `SELECT ... FOR UPDATE` —toma locks de fila, y una
herramienta de solo lectura no los necesita— y un identificador entre
comillas dobles con uno de esos nombres, porque la normalización no quita
comillas dobles. Falla cerrado.

Si de verdad hace falta escribir, **no se amplía la lista blanca**: se corre a
mano en DBeaver, donde una persona ve lo que va a pasar antes de que pase.

### Diferencias por dialecto

| | `postgres` | `sqlserver` |
|---|---|---|
| Ancla `SELECT`/`WITH` por sentencia | sí | sí |
| Palabra de escritura (`INSERT`, `UPDATE`, `DELETE`, `MERGE`, `INTO`) en cualquier posición | **rechazada** | **rechazada** |
| `set_config` | **rechazada** | n/a |
| Varias sentencias separadas por `;` | **aceptadas** | **rechazadas**: cualquier `;` que quede tras quitar comentarios y literales |
| Apertura de comilla de dólar (`$$`, `$tag$`) | **rechazada** | n/a |
| `EXEC`, `EXECUTE`, identificador `sp_`/`xp_` | n/a | **rechazados** |
| `TRUNCATE`, `DROP`, `CREATE`, `ALTER` en cualquier posición (v19, `AC52`) | n/a | **rechazadas** |
| Literal, identificador o comentario de bloque sin cerrar (v20, `AC51`) | **rechazado**, con el tipo en el motivo | **rechazado**, con el tipo en el motivo |

En `sqlserver` se manda **una sola sentencia y sin punto y coma**: no existe
equivalente de sesión de solo lectura que contenga un batch de T-SQL. La lista
blanca es ahí la primera capa, la que rechaza temprano y con un mensaje claro;
**la barrera es el rol** (ver la tabla de abajo).

## Garantías por motor (asimetría declarada, no disimulada)

| | Postgres (`dev`/`qa`) | SQL Server (`Dev SQL`) |
|---|---|---|
| Rol de solo lectura | sí — **condicional** (v15): `pg_read_all_data` no escribe, pero un `GRANT` futuro sí puede; en PG 14 `public` traía `CREATE` para `PUBLIC` y el rol creaba tablas propias hasta que se revocó el 22-sep-2026 | sí — **y es la única barrera**, literalmente, desde v10. **Condicional**: se sostiene mientras nadie conceda escritura. El rechazo es **por privilegio** (`Msg 262: CREATE TABLE permission denied`, medido por Patrick Ocampo conectado como el login el 23-sep-2026), y el consumidor no lo puede apagar — a diferencia de Postgres, donde el primer freno es un parámetro de sesión que el rol sí apaga con un `SET` (v17, punto 4). Eso no cambia el `nivel`: sigue `condicional` porque el plugin no comprueba el privilegio en cada consulta — fuerza y nivel son ejes distintos |
| Sesión abierta en solo lectura | sí, `default_transaction_read_only=on` — **condicional**: el plugin no la comprueba. Dentro de una llamada no se puede apagar (medido el 23-sep-2026: `transaction read-write mode must be set before any query`), y el rol la tiene además fijada por `ALTER ROLE`. | **no existe equivalente** |
| `DENY` de escritura sobre el rol | no aplica | **no** — `db_denydatawriter` se quitó en v10 por decisión de Patrick Ocampo. Sin él no queda un `DENY` explícito, así que un `GRANT` de escritura concedido por error no tendría nada que lo anule |
| Motor que rechaza escrituras | sí, endpoint `cluster-ro-` de Aurora — **incondicional desde v16, porque el plugin lo comprueba en cada consulta** (guarda de réplica): Aurora apunta ese endpoint al writer si el cluster se queda sin réplicas, y entonces el plugin se niega con `no_es_replica` | **no hay réplica** |
| Enumeración de los nombres de base (v17, `AC48`) | **visibles**: `pg_database` es legible por todo rol; ocultarla rompe clientes (conocido, no medido) — riesgo aceptado | **cerrada** con `DENY VIEW ANY DATABASE`: el login ve `master`, `tempdb` y la base de su propia conexión, y ninguna otra |
| Alcance del permiso | `pg_read_all_data`, de cluster — alcanza las 29 bases del cluster de dev/qa desde que el rol existe, no sólo las del catálogo | `db_datareader`, **por base**: una base nueva no queda cubierta sola |

Que esa asimetría esté escrita en `garantias`, entrada por entrada, es lo que
evita que alguien asuma que todas las conexiones son igual de seguras.

**Y las garantías tampoco son iguales entre sí** (contract v15; criterio
cerrado en v16). Cada una declara su `nivel`, y `listar_conexiones` lo
devuelve:

| Nivel | Qué significa | Cuáles |
|---|---|---|
| `incondicional` | el plugin la comprueba **en cada consulta, en la misma sesión y antes de ejecutar el SQL del consumidor**, y se niega a ejecutarlo si no se cumple | `endpoint-replica-lectura` — la guarda de réplica comprueba `pg_is_in_recovery()` y, si la sesión cayó en el writer, responde `no_es_replica`. Si esa guarda se quita, la garantía deja de ser incondicional: el nivel sigue a la verificación, no a la intuición sobre el mecanismo |
| `condicional` | cualquier otra: se sostiene mientras se cumpla la `condicion` que la propia entrada declara | `rol-solo-lectura` y `sesion-read-only` en Postgres; `rol-solo-lectura`, la única que hay, en SQL Server |

No es una distinción teórica: el 22-sep-2026 Patrick Ocampo midió el peor caso
y `sesion-read-only` **se apaga con un `SET`** —es un valor por omisión de la
sesión, no un candado— y en PG 14 el esquema `public` traía `CREATE` concedido
a `PUBLIC`, o sea a todo rol que exista, así que por el endpoint de escritura el
rol creaba tablas propias. Ninguna tabla existente quedó expuesta, y el hueco se
cerró el mismo día; lo que no se puede seguir sosteniendo es que las tres
garantías aguanten lo mismo. En SQL Server la única que hay es `condicional`,
que es exactamente la asimetría que la tabla de arriba describe.
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
| `garantias` | al menos un **objeto** `{nombre, nivel}`, más `condicion` cuando el nivel es `condicional`. `nombre` ∈ `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura`, `deny-escritura`; `nivel` ∈ `incondicional`, `condicional` |

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

### Las 12 entradas de hoy

| `nombre` | Fuente | Nota |
|---|---|---|
| `proveedores-dev` · `proveedores-qa` · `smartcheck-dev` · `smartcheck-qa` · `smartfleet-dev` · `smartfleet-qa` | bases del cluster Aurora de dev/qa (`sistemas-costruplaza-db`), por el endpoint de réplica | |
| `compras` · `compras-stg` · `ecommerce` · `ecommerce-qa` · `exactus` · `bi` | bases de la instancia `Dev SQL` (`10.24.40.137`), concedidas **a pedido nombrado** — el alcance arranca en cero y cada base entra con fecha y solicitante | copias de producción |

Dos precisiones sobre estos valores:

- Los nombres llevan **guion y no guion bajo** (`proveedores-dev`, no
  `proveedores_dev`) porque el contrato de datos fija ese formato para
  `nombre`. La base a la que apuntan sí conserva su nombre real en el campo
  `base`.
- El `host` de las 6 entradas de Postgres es el **endpoint de réplica de
  lectura** (`cluster-ro-`), que es lo que sostiene la garantía
  `endpoint-replica-lectura`. El runbook de `aprovisionamiento/` documenta el
  endpoint de escritura del mismo cluster, que es otro. Medido: el
  `ReaderEndpoint` existe (22-sep-2026), y el 23-sep el cluster tenía **una
  sola réplica** — con los nombres de instancia cruzados, la que se llama
  `…-reader` es hoy el writer, huella de que ya hubo un failover. **Aurora
  apunta el endpoint de lectura al writer cuando el cluster se queda sin
  réplicas**, así que el endpoint solo no sostiene la garantía. Desde v16 la
  sostiene la guarda de réplica: si el cluster se queda sin réplicas, la
  consulta responde `no_es_replica` (código 9) en vez de correr contra el
  writer.

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
| Tiempo agotado: el motor corta por su propio límite de sentencia (Postgres: `statement_timeout` del rol, 60s — v19), o el plugin corta el proceso (125 s, los dos motores) | 7 | `tiempo_agotado` |
| Binario del cliente ausente | 8 | `cliente_ausente`, nombrando el binario |
| La conexión Postgres no llegó a una réplica de lectura (v16) | 9 | `no_es_replica`, con el nombre de la conexión. **El SQL del consumidor no se ejecutó** |

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
que alguien la sume ahí y re-corra la parte B — `db_datareader` es por
base. Se concede desde esa lista; se revoca por **enumeración**: el
inverso (`sqlserver-inverso.sql`) recorre las bases de la instancia
buscando dónde existe el user y lo saca de ahí, sin leer ninguna lista —
dos direcciones, dos fuentes de verdad.

## Tests

`SDD/tests/test_lista_blanca.sh`, `SDD/tests/test_catalogo.sh` y
`SDD/tests/test_servidor_mcp.sh`, de la suite de este repo
(`bash SDD/tests/run.sh`). Ninguno necesita una base: la lista blanca se
afirma por código de salida **antes de conectar**, y el protocolo se ejercita
alimentando stdin con tramas JSON-RPC.


---

## Instalación desde un marketplace local — el detalle que muerde

`/plugin marketplace add <ruta>` seguido de `/plugin install bisalta-db@ai-forge` **copia** el
plugin a `~/.claude/plugins/cache/ai-forge/bisalta-db/<version>/`. **No sigue el árbol de trabajo.**

Consecuencia medida el 22-sep-2026: se cambió el `secret_id` de las 12 entradas del catálogo en el
repo, y el plugin instalado siguió pidiendo el identificador viejo — con un error
`secreto_inaccesible` que se lee como un problema de permisos y no lo es.

**Cada vez que cambie cualquier archivo del plugin, hay que reinstalar** para que la copia se
refresque. Y ojo con el diagnóstico: `secreto_inaccesible` tiene ahora **tres causas** distintas que
se ven igual — falta el permiso IAM, la forma del secreto no es la esperada, o **el catálogo
instalado está viejo**. Antes de culpar a la política, comparar:

```
python3 -c "import json;print(sorted({e['secret_id'] for e in json.load(open('CATALOGO'))}))"
```

sobre el catálogo del repo y sobre el de `~/.claude/plugins/cache/ai-forge/bisalta-db/<version>/`.

### Reinstalar no alcanza: hay que reiniciar, y la forma de un cambio decide qué se rompe

Medido el 23-sep-2026, al reinstalar para tomar el contract v15. Tres cosas que no son obvias:

**0. `remove` saca el marketplace entero, no un plugin.** `/plugin marketplace remove ai-forge`
desinstala **todos** los plugins de `ai-forge`, no sólo `bisalta-db`. El 23-sep eso se llevó
`sdd-flow` —y con él el hook `guard-git.sh`, que bloquea commits en rama protegida, `--no-verify` y
`push --force`— sin ningún aviso, y el repo trabajó **casi dos horas** sin esa protección (09:39 a 11:30, medido por
los timestamps del registro de plugins y del cache). Y al reinstalarlo apareció que la copia
anterior era `sdd-flow` **0.10.0**, del 21-sep, mientras el repo ya iba por la 0.12: el plugin que
hace cumplir el proceso llevaba dos versiones de atraso respecto del repo donde se aplicaba. Después
del `add`, reinstalar **cada** plugin de `ai-forge` que estuviera instalado, no sólo el que motivó
la reinstalación.

**1. `remove` no borra la copia.** `/plugin marketplace remove ai-forge` saca el marketplace y el
plugin del registro, pero deja la carpeta `cache/ai-forge/bisalta-db/<version>/` en el disco. Un
`grep` sobre esa carpeta después del `remove` sigue encontrando el código viejo — y eso no dice
que la reinstalación falló, dice que todavía no hubo reinstalación.

**2. El código se carga una vez; el catálogo, en cada llamada.** El servidor MCP carga sus scripts
al arrancar y relee `catalogo.json` en cada invocación. Después de reinstalar, un servidor que ya
estaba corriendo queda con **código viejo leyendo datos nuevos**. Qué pasa depende de qué cambió:

| Qué cambió | Efecto sobre una sesión abierta que no se reinició |
|---|---|
| **Valores** del catálogo (un `secret_id`, un `host`, una base nueva) | se toma en la próxima llamada, sin reiniciar |
| **Forma** del catálogo (un campo nuevo, un tipo distinto — como `garantias` pasando de nombres a objetos en v15) | **se rompe**: el validador viejo rechaza el catálogo nuevo con `catalogo_invalido`, código 2 |
| **Código** (`conexion.js`, `lista-blanca.js`, `servidor-mcp.js`) | **no se toma** hasta reiniciar, y no avisa: la sesión sigue funcionando con el comportamiento viejo |

La tercera fila es la peligrosa, porque no falla. La segunda al menos falla **cerrada**: rechaza el
catálogo entero, no se conecta a nada y no valida a medias — el rechazo del 23-sep mostró cada
garantía como `[object Object]`, que es el síntoma de esta mezcla y no un catálogo roto.

**3. Cada sesión tiene su propio servidor.** Claude Code levanta un proceso del servidor MCP por
sesión. Reiniciar una no arregla las otras: toda sesión abierta sigue con su código viejo hasta que
se reinicie. Para ver cuáles quedaron atrás, comparar la hora de arranque de cada proceso contra la
hora de la reinstalación:

```
ps -eo pid,lstart,command | grep '[b]isalta-db.*servidor-mcp'
```

Todo proceso que arrancó antes de reinstalar corre código viejo.

**Orden completo**: `remove` → `add` → `install` **de cada plugin de `ai-forge` que tuvieras** → **reiniciar cada sesión que use el plugin** →
confirmar con algo que el cambio nuevo haga observable. Una verificación que el código viejo
también pasaría no confirma nada.
