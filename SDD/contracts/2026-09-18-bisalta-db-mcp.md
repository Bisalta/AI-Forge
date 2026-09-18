# HLTC — Plugin `bisalta-db`: consulta de solo lectura sin credencial en contexto

- **Versión**: v1
- **Ticket**: GEN-108 (subtareas GEN-108.1 · GEN-108.2)
- **Repo**: `Bisalta/AI-Forge` · **Rama base**: `prod` · **Rama de trabajo**: `feat-GEN-108-mcp-bisalta-db`
- **Capa de integración**: git + remote → PR
- **Estado**: auto-aprobado y logueado (gate humano en Feature Ready)
- **Requerimientos**: R1 (`infra`) · R2 (`third-party-integration`) · **orden de integración R1 → R2**

---

## Objective

Que Claude Code y NEO consulten las bases de Bisalta mandando SQL y recibiendo filas, sin que ninguna credencial entre en el contexto de una sesión. La credencial no desaparece: pasa de un archivo que hoy hay que leerle al modelo a un secreto de AWS que el proceso resuelve y la sesión nunca ve.

## Out of scope

- **Auditoría por consulta.** CloudTrail registra quién obtuvo el secreto, no qué consultó. Responder "quién leyó qué" exige un servicio HTTP intermedio (Lambda + API Gateway + Cognito); evaluado y descartado por desproporcionado para este alcance.
- **El cluster `cluster-cr4rbgr7qlr6`** (cuenta AWS de producción). Ahí viven los doce catálogos medidos el 18-sep-2026, incluidos los cinco pares `_prod`/`_stg` de la empresa. Los roles de Postgres son objetos de cluster: crear un login en cualquier `_stg` es crearlo al lado de producción.
- **`Prod SQL` (`192.168.252.22`)**, en esa misma cuenta.
- **Escritura de cualquier tipo.** Una escritura necesaria se corre a mano en DBeaver, donde una persona ve lo que va a pasar antes de que pase.
- **IAM auth de Aurora.** Hoy `false` en el cluster (verificado con `describe-db-clusters`). Decisión abierta de Patrick Ocampo; si entra, cambia cómo se obtiene la credencial al conectar, no la forma del catálogo.
- **Ejecutar los scripts de R1.** Este ciclo los redacta y los verifica; los corre quien tiene privilegios de administración en cada motor.
- **Rotación de la bitácora local.** El servidor sólo agrega líneas. Registrado en `SDD/debt.md`.
- **Adopción de `postgres-mcp-hardened` (Rust).** Evaluado; queda como plan B si el equipo decide no mantener código propio.

## Público consumidor y compatibilidad

Superficie pública nueva: dos herramientas MCP. No hay consumidor previo, así que no hay compatibilidad hacia atrás que preservar. `api-compat`: `N/A — superficie nueva sin consumidores existentes`.

---

## Threat model (`security.md` §1)

1. **¿Quién puede invocarlo?** Cualquier proceso local que tenga el plugin habilitado **y** credenciales AWS con permiso de lectura sobre el secreto de esa conexión. La barrera real es IAM, no el plugin: sin permiso sobre el secreto, la conexión falla aunque la entrada del catálogo esté presente.
2. **¿Qué pasa con el rol equivocado?** Sin permiso IAM sobre el secreto, `consultar` devuelve `{ "error": "secreto_inaccesible" }` nombrando la conexión y el identificador del secreto, **sin volcar la respuesta cruda de AWS** (puede traer el ARN de la identidad llamante). Exit code 5.
3. **¿Qué pasa con input hostil?** El único campo de entrada libre es `sql`. Lo valida la lista blanca del dialecto de la conexión, **antes de conectar**: se quitan comentarios y literales, se parte en sentencias, y cada sentencia debe empezar con `SELECT` o `WITH`. Al rechazar, el error devuelve los primeros 90 caracteres de la sentencia ofensora — nunca el archivo completo, nunca un stack trace. Exit code 4.
4. **¿Qué datos toca y de quién?** Datos de proveedores, empleados y operación de Construplaza. Las conexiones de Postgres son de `dev`/`qa`. Las de SQL Server son **copias de producción** (`EXACTUS` 395 GB, `BI` 177 GB, `COMPRAS` 107 GB): los tamaños no son de desarrollo. No hay acceso por ID de recurso, así que **no hay superficie de IDOR**: la unidad de autorización es la conexión entera, no una fila.

### Riesgo aceptado, con dueño

Las filas que el servidor devuelve **quedan en el transcript de la sesión**. El objetivo del plugin es exactamente devolverlas, así que no hay diseño que lo evite sin negar la función. Ian Vargas eligió explícitamente, en el refinement del 18-sep-2026, que el **tope duro de filas y bytes sea la única barrera**, y descartó la lista de exclusión de columnas por conexión. Queda como riesgo aceptado, no como control:

- La aprobación de Esteban Fait o Sebastián para consultar datos de producción es **precondición nombrada de habilitar el plugin al equipo**, no un acceptance criterion de este contract. Está planteada por escrito a Patrick Ocampo.
- Ambos puntos se registran en `SDD/debt.md`.

## Concerns (`plugins/sdd-flow/standards/concerns.md`)

```
concerns:
  security:      blocking
  observability: blocking
  data-privacy:  blocking
  performance:   advisory   # los 120 s son tope de seguridad, no presupuesto medido
  a11y:          n/a        # sin UI
  design:        n/a        # sin UI
  api-compat:    n/a        # superficie nueva sin consumidores existentes
  i18n:          n/a        # monolingüe
  seo:           n/a        # sin frontend
```

- **security** (blocking): threat model de arriba; ACs negativos AC15–AC25, AC31, AC33, AC35.
- **observability** (blocking): AC30 (bitácora por invocación) y AC29 (`application_name` que distingue el rol del lado del motor). Cómo se detecta que se rompió: toda invocación con exit code distinto de 0 deja su línea en la bitácora con la causa.
- **data-privacy** (blocking): AC25 cierra el ítem de PII y credenciales fuera de logs y mensajes de error; AC26 y AC27 acotan los campos expuestos a lo que la consulta pida, con tope duro. Retención y borrado: `N/A — el plugin no crea datos personales nuevos, sólo lee`. Datos personales hacia terceros: **riesgo aceptado con dueño** (ver arriba), no AC.
- **performance** (advisory): `PERF1` — una consulta que recorre una tabla sin índice sobre `BI` o `EXACTUS` es responsabilidad de quien la escribe; el servidor la corta a los 120 s. El reviewer lo reporta, no lo bloquea.

## Dependencias nuevas (`security.md` §4)

**Ninguna dependencia de paquete.** Es la decisión central del contract.

| Se descartó | Por qué |
|---|---|
| `@modelcontextprotocol/server-postgres` | Deprecado en 2025 y con inyección SQL que se salta su propio modo de solo lectura: pasa el SQL sin parametrizar y permite salir de la transacción read-only para ejecutar DDL/DML con todos los privilegios de la conexión. |
| `@modelcontextprotocol/sdk` + `pg` + `mssql` | Introduce `package.json`, lockfile y árbol de `node_modules` en un repo que hoy no tiene ningún manifiesto de dependencias, y agrega el gate de audit de dependencias. El arranque con `npx -y` baja y ejecuta código de internet con credenciales de base en la mano. |

Binarios externos, invocados como CLI y **no** versionados por este repo: `psql`, `sqlcmd`, `aws`. Medido en la máquina de referencia el 18-sep-2026: `psql` 14.18 y `aws` 2.27.49 presentes, **`sqlcmd` ausente**. Cada uno ausente degrada con mensaje nombrando el binario, igual que `sdd-run-gates.sh` ya hace con `timeout`.

---

## Architectural Delta

| Capa | Delta |
|---|---|
| **API** | Dos herramientas MCP: `consultar(conexion, sql)` y `listar_conexiones()`. Transporte stdio, JSON-RPC 2.0 delimitado por saltos de línea, escrito a mano. Se declara `protocolVersion` `2024-11-05`. |
| **Service** | (NEW) `plugins/bisalta-db/scripts/servidor-mcp.js` — bucle JSON-RPC, despacho de herramientas, armado de la respuesta con topes. |
| **Domain** | (NEW) `plugins/bisalta-db/scripts/lista-blanca.js` — normalización (quitar comentarios y literales), partición en sentencias y validación por dialecto. Es el port de `consulta-lectura.sh` (archivo de OTRO repo: `Bisalta/Proveedores-Back@feat-PROV-131-api-comprassync`, carpeta `scripts/`), con su lección: la comprobación exige la palabra **al principio** de la sentencia, no en cualquier posición. |
| **Repository** | (NEW) `plugins/bisalta-db/scripts/catalogo.js` — lectura y validación de `plugins/bisalta-db/catalogo.json`. `plugins/bisalta-db/scripts/conexion.js` — resolución del secreto vía `aws` y ejecución del cliente CLI del dialecto. |
| **Integration** | AWS Secrets Manager (región `us-east-1`, cuenta de dev/qa) por el binario `aws`. Aurora PostgreSQL por `psql`. SQL Server por `sqlcmd`. |
| **Test impact** | Tres archivos nuevos en `SDD/tests/`: `test_lista_blanca.sh`, `test_catalogo.sh`, `test_servidor_mcp.sh`. Los descubre `SDD/tests/run.sh` por su glob `test_*.sh`; no se toca el runner. |
| **Ownership boundaries** | El producto distribuible vive **sólo** en `plugins/bisalta-db/`. Los tests viven **sólo** en `SDD/tests/` e invocan los scripts por su path completo, desde afuera — es la regla de `doc_architecture.md`, sección Layer Responsibilities. Los scripts SQL de R1 viven en `plugins/bisalta-db/aprovisionamiento/` porque agregar una fuente nueva exige re-correrlos: son parte de lo que se instala, no andamiaje de este repo. |
| **Reuse statement** | Los asserts salen **únicamente** de `SDD/tests/lib.sh`; ningún test define un `assert_*` propio. El patrón de fixture temporal es el de `SDD/tests/test_run_gates.sh`: directorio bajo `SDD/tests/.tmp/<nombre>-$$` con `trap ... EXIT`. El precedente de Node plano probado desde bash es `plugins/usage-monitor/scripts/parse-usage-log.js` con `SDD/tests/test_usage_summary.sh`. |

## Impact set

Símbolos y archivos existentes que se modifican, con sus consumidores grepeados:

| Archivo | Cambio | Consumidores existentes | Cobertura |
|---|---|---|---|
| `.claude-plugin/marketplace.json` | se agrega una quinta entrada `bisalta-db` | Claude Code al resolver `/plugin install`; ningún script del repo lo parsea (grep de `marketplace.json` sobre `plugins/` y `SDD/`: cero coincidencias en código) | AC36 |
| `CHANGELOG.md` | entrada nueva al tope | ninguno automatizado | sin test — es prosa |
| `SDD/docs/doc_quality_gates.md` | se agregan `plugins/bisalta-db/scripts/*.sh` al glob del gate 2 y se corrige el prerequisito de `shellcheck` | `sdd-run-gates.sh` parsea su tabla de gates | AC38 |
| `SDD/docs/doc_architecture.md` | se agrega `plugins/bisalta-db/` al layout y a las reglas de ubicación | lectura humana y de agentes | AC39 |

**No se modifica ningún símbolo ejecutable existente.** Todo el código nuevo es aditivo, en archivos nuevos. Por eso no hay análisis de regresión de callers: la suite existente (12 archivos de test) tiene que seguir verde sin cambios, y eso es AC40.

## Source of truth

| Dato | Dueño |
|---|---|
| Qué conexiones existen y qué garantías tiene cada una | `plugins/bisalta-db/catalogo.json` (NEW) |
| El usuario y la contraseña de cada conexión | El secreto de AWS Secrets Manager que la entrada nombra. **Nunca el catálogo, nunca el código, nunca una variable de entorno persistida.** |
| Quién puede usar una conexión | La política IAM sobre el ARN de ese secreto |
| Qué SQL es aceptable | `plugins/bisalta-db/scripts/lista-blanca.js` (NEW), por dialecto |

## Contrato de datos

### `catalogo.json`

Arreglo de objetos. El validador **rechaza cualquier campo no listado acá** y cualquier campo faltante.

| Campo | Presencia | Valores | Comportamiento ante ausencia |
|---|---|---|---|
| `nombre` | requerido | minúsculas, dígitos y guiones; único en el arreglo | el catálogo entero se rechaza |
| `dialecto` | requerido | exactamente `postgres` o `sqlserver` | el catálogo entero se rechaza |
| `ambiente` | requerido | exactamente `dev` o `qa` | el catálogo entero se rechaza |
| `host` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `puerto` | requerido | entero entre 1 y 65535 | el catálogo entero se rechaza |
| `base` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `secret_id` | requerido | identificador o ARN del secreto | el catálogo entero se rechaza |
| `region` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `garantias` | requerido | arreglo de al menos un elemento, cada uno exactamente `rol-solo-lectura`, `sesion-read-only` o `endpoint-replica-lectura` | el catálogo entero se rechaza |

**No existe un campo de usuario ni de contraseña.** Los dos salen del secreto, que tiene la forma estándar de RDS: un campo llamado `username` y otro llamado `password`, ambos en la carga JSON del secreto.

`ambiente` admite dos valores y nada más: producción es irrepresentable en este catálogo, no rechazada por nombre. Rechazar por nombre es red, no barrera.

### Respuesta de `consultar`

```
{
  "conexion": "<nombre>",
  "dialecto": "<postgres|sqlserver>",
  "filas": [ { ... } ],
  "filas_devueltas": <entero>,
  "truncado": <booleano>,
  "motivo_truncado": "<limite_filas|limite_bytes|null>"
}
```

- Tope de filas: **1000**. Tope de bytes de `filas` serializado: **1048576** (1 MiB).
- Al truncar, `filas` trae las primeras filas que caben, `truncado` es `true` y `motivo_truncado` nombra cuál de los dos topes se alcanzó primero. **Truncar no es un error**: la respuesta es exitosa.
- `motivo_truncado` es `null` exactamente cuando `truncado` es `false`.

### Respuesta de `listar_conexiones`

Arreglo con `nombre`, `dialecto`, `ambiente`, `base` y `garantias` de cada entrada. **No incluye `host`, `puerto`, `secret_id` ni `region`**: son superficie de reconocimiento que el consumidor no necesita.

## Comportamiento de error

| Situación | Exit code | Respuesta |
|---|---|---|
| Uso incorrecto (falta `conexion` o `sql`) | 2 | `{ "error": "uso" }` con la firma esperada |
| Nombre de conexión ausente del catálogo | 3 | `{ "error": "conexion_desconocida" }` con la lista de nombres válidos |
| Sentencia rechazada por la lista blanca | 4 | `{ "error": "no_es_lectura" }` con los primeros 90 caracteres de la sentencia ofensora |
| Secreto que no resuelve | 5 | `{ "error": "secreto_inaccesible" }` con nombre de conexión e identificador del secreto, sin la respuesta cruda de AWS |
| Conexión rechazada o caída | 6 | `{ "error": "conexion_fallida" }` con el mensaje del cliente, sin la credencial |
| `statement_timeout` alcanzado (120 s) | 7 | `{ "error": "tiempo_agotado" }` |
| Binario del cliente ausente | 8 | `{ "error": "cliente_ausente" }` nombrando el binario que falta |

## Garantías por motor (asimetría declarada, no disimulada)

| | Postgres (`dev`/`qa`) | SQL Server (`Dev SQL`) |
|---|---|---|
| Rol de solo lectura | sí | sí — **y es la única barrera** |
| Sesión abierta en solo lectura | sí, `default_transaction_read_only=on` | **no existe equivalente** |
| Motor que rechaza escrituras | sí, endpoint `cluster-ro-` de Aurora | **no hay réplica** |
| Alcance del permiso | `pg_read_all_data`, de cluster | `db_datareader`, **por base**: una base nueva no queda cubierta sola |

Que esa asimetría esté escrita en `garantias`, entrada por entrada, es lo que evita que alguien asuma que todas las conexiones son igual de seguras.

## Entrega de la credencial al cliente

- **Postgres**: archivo temporal en modo 600 creado bajo un directorio de `mkdtemp`, apuntado por `PGPASSFILE`, borrado en un `finally` que corre también cuando la consulta falla. **Prohibido `PGPASSWORD`, `PGUSER`, `PGHOST`, `--username` y `--host`** — es la invariante que los tests de `Proveedores-Back` ya fijaban y que se porta literal.
- **SQL Server**: variable de entorno `SQLCMDPASSWORD` acotada al proceso hijo. `sqlcmd` no tiene equivalente de archivo, y `-P` dejaría la contraseña visible en la tabla de procesos. La asimetría queda escrita acá.
- En los dos casos, la contraseña **nunca** viaja por `argv`.

---

## Acceptance criteria

### R1 — aprovisionamiento (`infra`)

**AC1** — En el cluster de dev/qa existen los roles `claude_lectura` y `neo_lectura`, ambos con `LOGIN` y membresía de `pg_read_all_data`, ninguno con `NOINHERIT`; una consulta de lectura sobre una tabla de `proveedores_dev` devuelve filas con cualquiera de los dos.
`manual-only: requiere privilegios de administración en el cluster y red a la VPC de dev/qa; ningún harness de este repo puede crear un rol de Postgres.`

**AC2** — Un `INSERT` ejecutado por `claude_lectura` sobre `proveedores_dev` falla con error de permiso.
`manual-only: misma razón que AC1.`
**Mutación declarada**: otorgar `INSERT` a `claude_lectura` sobre una tabla de scratch creada para la prueba; la comprobación tiene que ponerse roja; revocar el permiso y borrar la tabla de scratch.

**AC3** — El script de la parte A corrido dos veces seguidas sale 0 las dos veces y deja el mismo conjunto de roles.
`manual-only: misma razón que AC1.`

**AC4** — Tras correr el script inverso, `claude_lectura` no puede conectar al cluster.
`manual-only: misma razón que AC1.`

**AC5** — El login de solo lectura de `Dev SQL` lee de `EXACTUS`.
`manual-only: requiere el login creado por el administrador y red a 10.24.40.137.`

**AC6** — Un `INSERT` con ese login falla con error de permiso.
`manual-only: misma razón que AC5.`
**Mutación declarada**: agregar el user a `db_datawriter` en una base de scratch; la comprobación tiene que ponerse roja; quitarlo del rol y borrar la base de scratch.

**AC7** — Tras correr la parte B, el user existe en todas las bases de usuario en línea y en **ninguna** de las cuatro bases de sistema (`master`, `model`, `msdb`, `tempdb`).
`manual-only: misma razón que AC5.`
**Mutación declarada**: quitar del cursor el filtro que excluye las bases de sistema y volver a correr la parte B contra una instancia de prueba; la comprobación tiene que ponerse roja; restaurar el filtro.

**AC8** — Cada conexión del catálogo tiene un secreto en Secrets Manager con los dos campos de la forma estándar de RDS, legible con la política IAM declarada en el runbook.
`manual-only: requiere permisos de escritura en Secrets Manager de la cuenta de dev/qa.`

**AC9** — `bash SDD/tests/secret-scan.sh` sale 0 sobre el árbol con los scripts de R1 agregados.
**Mutación declarada**: insertar en el archivo nuevo `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` un literal con forma de credencial (clave, separador y valor contiguos); el scan tiene que salir distinto de 0 nombrando el archivo y la línea sin imprimir el valor; revertir la línea.

**AC10** — El runbook declara explícitamente que una base nueva de SQL Server no queda cubierta hasta re-correr la parte B.

### R2 — catálogo

**AC11** — Una entrada de catálogo cuyo `ambiente` no es `dev` ni `qa` hace que el validador salga distinto de 0 nombrando la entrada.
**Mutación declarada**: cambiar el `ambiente` de la primera entrada de `catalogo.json` a `stg`; `test_catalogo.sh` tiene que ponerse rojo; restaurar el valor original.

**AC12** — Ninguna entrada del catálogo tiene como `host` algo que contenga `cluster-cr4rbgr7qlr6` ni `192.168.252.22`, y el validador rechaza el catálogo si aparece.
**Mutación declarada**: agregar una entrada con `host` `192.168.252.22`; el validador tiene que salir distinto de 0; borrar la entrada.

**AC13** — El validador rechaza una entrada que traiga un campo no declarado en el contrato de datos.
**Mutación declarada**: agregar un campo `usuario` a una entrada; el validador tiene que salir distinto de 0; borrarlo.

**AC14** — El validador rechaza una entrada con `garantias` vacío.
**Mutación declarada**: vaciar el arreglo `garantias` de una entrada; el validador tiene que salir distinto de 0; restaurarlo.

### R2 — lista blanca

**AC15** — Las diez escrituras simples se rechazan con exit 4: `UPDATE`, `DELETE`, `INSERT`, `TRUNCATE`, `DROP`, `ALTER`, `GRANT`, un bloque `DO`, `CALL` y `COPY`.
**Mutación declarada**: hacer que `validarSql` devuelva siempre aceptado; `test_lista_blanca.sh` tiene que ponerse rojo; revertir.

**AC16** — Las cinco escrituras que llevan una subconsulta adentro se rechazan con exit 4: `DELETE … WHERE id IN (SELECT …)`, `INSERT … SELECT`, `UPDATE … = (SELECT …)`, `CREATE TABLE … AS SELECT` y `CREATE VIEW … WITH (…) AS SELECT`.
**Mutación declarada**: reemplazar el anclaje al principio de la sentencia por una búsqueda de `SELECT` o `WITH` en cualquier posición — la lista blanca laxa que pasaba once de los doce tests originales. `test_lista_blanca.sh` tiene que ponerse rojo en estos cinco casos; revertir el anclaje.

**AC17** — Una escritura detrás de una lectura (`SELECT 1; DELETE FROM …`) se rechaza con exit 4.
**Mutación declarada**: validar únicamente la primera sentencia en vez de todas; `test_lista_blanca.sh` tiene que ponerse rojo; revertir.

**AC18** — Un `UPDATE` que aparece dentro de un comentario, y un `DELETE FROM x` que aparece dentro de un literal de texto, **se aceptan**: el validador sale 0.

**AC19** — Un CTE (`WITH a AS (SELECT 1) SELECT * FROM a`) y tres sentencias de lectura seguidas **se aceptan**: el validador sale 0.

**AC20** — En dialecto `postgres`, una sentencia que contiene una apertura de comilla de dólar se rechaza con exit 4.
**Mutación declarada**: quitar la regla de comilla de dólar del dialecto `postgres`; el caso de `test_lista_blanca.sh` que la cubre tiene que ponerse rojo; revertir.

**AC21** — En dialecto `sqlserver`, se rechazan con exit 4: `EXEC`, `EXECUTE`, un identificador que empieza con `sp_`, uno que empieza con `xp_`, y cualquier `;` que quede tras quitar comentarios y literales.
**Mutación declarada**: quitar las reglas del dialecto `sqlserver` y hacerlo caer en las reglas comunes; los cinco casos tienen que ponerse rojos; revertir.

**AC22** — Dos lecturas encadenadas con `;` **se aceptan** en dialecto `postgres` y **se rechazan** en dialecto `sqlserver`, con la misma entrada.
**Mutación declarada**: hacer que `validarSql` ignore el parámetro de dialecto y aplique siempre las reglas comunes; el caso de sensibilidad tiene que ponerse rojo; revertir.

### R2 — credencial

**AC23** — El código fuente de `plugins/bisalta-db/scripts/` no contiene `PGPASSWORD`, `PGUSER`, `PGHOST`, `--username`, `--host` ni `-P `.
**Mutación declarada**: agregar una línea que exporte `PGPASSWORD` en `conexion.js`; `test_servidor_mcp.sh` tiene que ponerse rojo; borrar la línea.

**AC24** — Tras una consulta que falla al conectar, no queda ningún directorio temporal del servidor bajo el directorio temporal del sistema.
**Mutación declarada**: quitar el `finally` que borra el directorio temporal; `test_servidor_mcp.sh` tiene que ponerse rojo; restaurarlo.

**AC25** — Ni la bitácora, ni la respuesta, ni ningún mensaje de error contienen el valor de la contraseña ni la carga cruda del secreto.
**Mutación declarada**: hacer que la bitácora escriba la carga del secreto; `test_servidor_mcp.sh` tiene que ponerse rojo; revertir.

### R2 — topes, sesión y bitácora

**AC26** — Una consulta cuyo resultado supera las 1000 filas devuelve exactamente 1000, con `truncado` en `true` y `motivo_truncado` en `limite_filas`.

**AC27** — Una consulta cuyo resultado serializado supera 1048576 bytes devuelve las filas que caben, con `truncado` en `true` y `motivo_truncado` en `limite_bytes`.

**AC28** — El comando que el servidor construye para una conexión `postgres` incluye `default_transaction_read_only=on` y `statement_timeout=120000`.

**AC29** — El comando que el servidor construye lleva un `application_name` igual al `username` del secreto, para que `pg_stat_activity` distinga `claude_lectura` de `neo_lectura`.

**AC30** — La bitácora escribe una línea JSON por invocación con conexión, dialecto, hash de la consulta, filas devueltas, si truncó, duración y exit code.

### R2 — modos de falla

**AC31** — Un nombre de conexión ausente del catálogo devuelve exit 3 con la lista de nombres válidos, **sin invocar el binario `aws`**.
**Mutación declarada**: mover la comprobación de existencia de la conexión a después de resolver el secreto; el caso que afirma que `aws` no se invocó tiene que ponerse rojo; revertir el orden.

**AC32** — Con el binario del cliente ausente del `PATH`, `consultar` devuelve exit 8 nombrando el binario que falta.

**AC33** — Un secreto que no resuelve devuelve exit 5 nombrando la conexión y el identificador del secreto, y la respuesta **no contiene** la salida cruda del binario `aws`.
**Mutación declarada**: hacer que el mensaje de error concatene la salida cruda de `aws`; el caso tiene que ponerse rojo; revertir.

### R2 — protocolo MCP y empaquetado

**AC34** — El servidor responde `initialize` y luego `tools/list` con exactamente las herramientas `consultar` y `listar_conexiones`, corriendo con `node` sin ningún paquete instalado.

**AC35** — `listar_conexiones` no devuelve `host`, `puerto`, `secret_id` ni `region` en ninguna entrada.
**Mutación declarada**: agregar `host` a la proyección; `test_servidor_mcp.sh` tiene que ponerse rojo; quitarlo.

**AC36** — `.claude-plugin/marketplace.json` lista `bisalta-db` con `source` `./plugins/bisalta-db`, y ese directorio tiene un `.claude-plugin/plugin.json` nuevo con una versión SemVer.

**AC37** — Quitar la entrada de una conexión del catálogo hace que `consultar` sobre ese nombre devuelva exit 3, sin reiniciar el servidor ni tocar código. Es el kill switch local que exige el arquetipo.

**AC38** — `SDD/docs/doc_quality_gates.md` declara el estado real de `shellcheck` en la máquina de referencia y el glob del gate 2 incluye los scripts del plugin nuevo.

**AC39** — `SDD/docs/doc_architecture.md` incluye `plugins/bisalta-db/` en el layout y en las reglas de ubicación de archivos.

**AC40** — `bash SDD/tests/run.sh` sale 0 con los tres archivos de test nuevos, y los doce archivos de test preexistentes siguen verdes sin modificación.

## Checklist del arquetipo

- `third-party-integration` → **sandbox/mock para desarrollo**: `N/A — las conexiones de Postgres del catálogo son de dev/qa, que ya son el ambiente no productivo. Para SQL Server no hay sandbox posible: Dev SQL es una copia de producción, y decirlo es más honesto que llamarlo sandbox.`
- `third-party-integration` → **rate limit del tercero**: `N/A — un motor de base de datos no aplica rate limit; el control de carga es el statement_timeout y el tope de filas.`
- `infra` → **efecto sobre los devs**: cubierto por AC38.

---

## Estrategia de validación (por escenario)

1. **Lista blanca sin base**: los rechazos y las aceptaciones se afirman por exit code **antes de conectar**, igual que los doce tests de `Proveedores-Back`. Una validación que corriera después ya habría mandado la sentencia.
2. **Catálogo sin base**: el validador corre sobre archivos de fixture en `SDD/tests/.tmp/`.
3. **Protocolo MCP sin base**: se alimenta stdin con las tramas JSON-RPC y se afirma sobre stdout.
4. **Conexión real**: sólo los ACs marcados `manual-only`, cuando R1 esté ejecutado.
5. **Mutación**: los veinte ACs de detección llevan su triple verde → rojo → verde, con comando literal y exit code de cada corrida.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| El `protocolVersion` declarado no es el que Claude Code negocia hoy. | AC34 lo verifica con un handshake real. Si falla, es un `contract-change-request`, no una decisión del implementador. |
| El mecanismo exacto por el que un plugin declara un servidor MCP stdio no está verificado en este repo — ningún plugin existente lo hace. | Primera tarea del brief de R2: verificarlo contra la documentación y dejarlo escrito. Si no se puede, queda `BLOCKED` y pregunta. |
| `sqlcmd` ausente en la máquina de referencia: las reglas del dialecto `sqlserver` se prueban, pero la ejecución real no. | AC5 y AC6 son `manual-only` y dependen de R1. La lista blanca de ese dialecto sí queda mutation-tested. |
| `shellcheck` ausente: el gate 2 saldría `[SKIPPED]`, nunca verde. | Prerequisito declarado en los dos briefs: instalarlo antes de la primera corrida de gates. |
| La suite tarda ~62 s hoy y los triples de mutación la alargan. | El umbral de `doc_quality_gates.md` se revisa con el número medido al cerrar, igual que en GEN-101. |
| Las filas de copias de producción quedan en el transcript. | Riesgo aceptado con dueño (ver arriba). No hay mitigación técnica en este alcance. |
