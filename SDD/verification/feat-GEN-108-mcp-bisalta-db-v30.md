# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-aviso-aislamiento` · **Commit**: `fa4af6b` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-10-01T15:49:03Z
- Tree: `914dd5b6781dc93f2c0e916ee879b887f4cd3744` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-10-01T15:46:03Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-10-01T15:46:03Z | verde |
| 3 | type-check | — | — | 2026-10-01T15:46:04Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-10-01T15:46:05Z | verde |
| 5 | integration | — | — | 2026-10-01T15:47:32Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-10-01T15:47:32Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-10-01T15:47:32Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-10-01T15:47:32Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-10-01T15:47:32Z | verde |
| 10 | smoke manual | — | — | 2026-10-01T15:47:35Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-10-01T15:47:35Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 189 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```


---

# Addendum del planner — v30 (NO lo escribió el runner)

Salida literal de los scripts, pegados al final de cada sección. Las mutaciones y la medición en vivo corrieron sobre el árbol del código sellado arriba (`fa4af6b`), con el árbol limpio al empezar y al terminar; cada salida dice sobre qué commit corrió.

## 1. En vivo, servidor del repo

```
árbol fa4af6b
### AC62: SQL Server trae aislamiento y aviso antes de las filas, y el nivel coincide con el de la sesión
{ "conexion": "compras", "dialecto": "sqlserver", "aislamiento": "READ UNCOMMITTED", "aviso": "Corrió en READ UNCOMMITTED: puede incluir filas que otra transacción todavía no confirmó y, si alguien escribía mientras tanto, filas leídas dos veces o salteadas. Un COUNT o un total pueden estar mal.", "filas": [ { "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC62: Postgres no trae ninguno de los dos
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC63: un error de consulta de SQL Server (tabla inexistente) trae aislamiento
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "Msg 208, Level 16, State 1, Server EC2AMAZ-2RGHL0C, Line 1\nInvalid object name 'tabla_que_no_existe_bisalta_db'.", "aislamiento": "READ UNCOMMITTED" }
### AC63: un error de consulta de Postgres no lo trae
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "ERROR: relation \"tabla_que_no_existe_bisalta_db\" does not exist\nLINE 1: SELECT x FROM tabla_que_no_existe_bisalta_db\n ^" }
Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v30 (AC62 y AC63), con el servidor del repo, contra las
# bases reales. Sólo lectura de la propia sesión; ninguna credencial pasa por
# esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio al empezar"; exit 1; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### AC62: SQL Server trae aislamiento y aviso antes de las filas, y el nivel coincide con el de la sesión"
call compras "SELECT transaction_isolation_level AS nivel FROM sys.dm_exec_sessions WHERE session_id = @@SPID"
echo "### AC62: Postgres no trae ninguno de los dos"
call proveedores-dev "SELECT 1 AS uno"
echo "### AC63: un error de consulta de SQL Server (tabla inexistente) trae aislamiento"
call compras "SELECT x FROM tabla_que_no_existe_bisalta_db"
echo "### AC63: un error de consulta de Postgres no lo trae"
call proveedores-dev "SELECT x FROM tabla_que_no_existe_bisalta_db"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC61` (reescritas) y `AC62` — salida literal

```
árbol fa4af6b

### AC61 (a) sin el prefijo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC62 el nivel informado es el mismo que se mandó a sqlcmd
- verde (restaurado): exit=0 fail=0

### AC61 (b) el prefijo después de la consulta
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC62 el nivel informado es el mismo que se mandó a sqlcmd
- verde (restaurado): exit=0 fail=0

### AC61 (c) READ COMMITTED en lugar de READ UNCOMMITTED
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=117
      FAIL  AC34 initialize responde el protocolVersion declarado — no encontré ["protocolVersion":"2024-11-05"] en la salida
      FAIL  AC34 initialize se identifica como bisalta-db — no encontré ["name":"bisalta-db"] en la salida
      FAIL  AC34 serverInfo.version es la de plugin.json
      FAIL  AC34 tools/list devuelve exactamente consultar y listar_conexiones
      FAIL  AC61 la descripción de consultar avisa el nivel de aislamiento de SQL Server — no encontré [En SQL Server la consulta corre en READ UNCOMMITTED] en la salida
      FAIL  AC61 la descripción de consultar avisa que puede leer filas sin confirmar — no encontré [que otra transacción todavía no confirmó] en la salida
      FAIL  AC61 la descripción de consultar avisa que puede leer dos veces o saltear filas confirmadas — no encontré [leer dos veces o saltear filas ya confirmadas] en la salida
      FAIL  AC61 la descripción de consultar avisa el corte con el error 601 — no encontré [o cortar con el error 601] en la salida
      FAIL  AC34 la notificación initialized no genera respuesta
      FAIL  AC35 listar_conexiones devuelve el nombre de la conexión — no encontré ["nombre":"proveedores-dev"] en la salida
      FAIL  AC35 listar_conexiones devuelve las garantías — no encontré ["garantias"] en la salida
      FAIL  AC45a listar_conexiones propaga el nivel de cada garantía — no encontré ["nivel"] en la salida
      FAIL  AC45a listar_conexiones distingue la garantía incondicional — no encontré ["incondicional"] en la salida
      FAIL  AC35 listar_conexiones devuelve el ambiente — no encontré ["ambiente":"dev"] en la salida
      FAIL  AC31 una conexión ausente del catálogo devuelve el código 3 — no encontré ["codigo":3] en la salida
      FAIL  AC31 el error es conexion_desconocida — no encontré ["error":"conexion_desconocida"] en la salida
      FAIL  AC31 el error trae la lista de nombres válidos — no encontré [proveedores-dev] en la salida
      FAIL  AC31 (control) con una conexión válida el stub de aws sí registra la invocación
      FAIL  AC31 el proceso sale 3 con una conexión desconocida
      FAIL  AC23 (control) la contraseña sí llega al cliente por el archivo de credenciales — no encontré [PASSFILE_CONTIENE_CREDENCIAL si] en la salida
      FAIL  AC23 el archivo de credenciales queda en modo 600 — no encontré [PASSFILE_MODO -rw-------] en la salida
      FAIL  AC28 el comando abre la sesión en solo lectura — no encontré [default_transaction_read_only=on] en la salida
      FAIL  AC29 el comando lleva el usuario del secreto en PGAPPNAME — no encontré [PGAPPNAME claude_lectura] en la salida
      FAIL  AC30 la bitácora registra la conexión — no encontré ["conexion":"proveedores-dev"] en la salida
      FAIL  AC30 la bitácora registra el dialecto — no encontré ["dialecto":"postgres"] en la salida
      FAIL  AC30 la bitácora registra el hash de la consulta — no encontré ["hash_consulta":"sha256:] en la salida
      FAIL  AC30 la bitácora registra las filas devueltas — no encontré ["filas_devueltas":2] en la salida
      FAIL  AC30 la bitácora registra si truncó — no encontré ["truncado":false] en la salida
      FAIL  AC30 la bitácora registra la duración — no encontré ["duracion_ms":] en la salida
      FAIL  AC30 la bitácora registra el código de salida — no encontré ["codigo":0] en la salida
      FAIL  AC30 la bitácora escribe una línea por invocación
      FAIL  AC46 el comando lleva --quiet (sin él psql imprime DO como primera línea del CSV)
      FAIL  AC46 el comando lleva exactamente dos --command
      FAIL  AC46 el primer --command es exactamente la guarda de réplica
      FAIL  AC46 el segundo --command es el SQL del consumidor
      FAIL  AC46 si la guarda falla, la respuesta tiene código 9 — no encontré ["codigo":9] en la salida
      FAIL  AC46 si la guarda falla, el error es no_es_replica — no encontré ["error":"no_es_replica"] en la salida
      FAIL  AC46 el error no_es_replica nombra la conexión — no encontré [proveedores-dev] en la salida
      FAIL  AC46 la bitácora registra el código 9 — no encontré ["codigo":9] en la salida
      FAIL  AC46 el proceso sale 9 cuando la conexión no llegó a una réplica
      FAIL  AC25 una conexión que falla devuelve el código 6 — no encontré ["codigo":6] en la salida
      FAIL  AC25 el error de conexión trae el mensaje del cliente — no encontré [no route to host] en la salida
      FAIL  AC24 (control) el archivo de credenciales existía mientras corría la consulta que falló — no encontré [PASSFILE_EXISTE si] en la salida
      FAIL  AC33 un secreto que no resuelve devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC33 el error es secreto_inaccesible — no encontré ["error":"secreto_inaccesible"] en la salida
      FAIL  AC33 el error nombra la conexión — no encontré [proveedores-dev] en la salida
      FAIL  AC33 el error nombra el identificador del secreto — no encontré [dev/bd/claude-lectura-postgres] en la salida
      FAIL  AC33 (control) el stub de aws corrió y falló en esa misma invocación
      FAIL  AC33 el proceso sale 5 cuando el secreto no resuelve
      FAIL  AC32 con el cliente ausente del PATH la consulta devuelve el código 8 — no encontré ["codigo":8] en la salida
      FAIL  AC32 el error es cliente_ausente — no encontré ["error":"cliente_ausente"] en la salida
      FAIL  AC32 el error nombra el binario que falta — no encontré [psql] en la salida
      FAIL  AC32 el proceso sale 8 cuando falta el binario del cliente
      FAIL  sin el argumento sql, la herramienta devuelve el código 2 — no encontré ["codigo":2] en la salida
      FAIL  sin el argumento sql, el error es uso — no encontré ["error":"uso"] en la salida
      FAIL  con un catálogo ilegible, consultar devuelve el código 2 — no encontré ["codigo":2] en la salida
      FAIL  con un catálogo ilegible, el error es catalogo_invalido — no encontré ["error":"catalogo_invalido"] en la salida
      FAIL  con un catálogo ilegible, el proceso sale 2
      FAIL  con un catálogo que no existe, el proceso sale 2
      FAIL  con un catálogo ilegible, listar_conexiones devuelve el código 2 — no encontré ["codigo":2] en la salida
      FAIL  con un catálogo ilegible, listar_conexiones da catalogo_invalido — no encontré ["error":"catalogo_invalido"] en la salida
      FAIL  un statement_timeout alcanzado devuelve el código 7 — no encontré ["codigo":7] en la salida
      FAIL  un statement_timeout alcanzado devuelve tiempo_agotado — no encontré ["error":"tiempo_agotado"] en la salida
      FAIL  una escritura devuelve el código 4 — no encontré ["codigo":4] en la salida
      FAIL  una escritura devuelve no_es_lectura — no encontré ["error":"no_es_lectura"] en la salida
      FAIL  el rechazo trae la sentencia ofensora — no encontré [DELETE FROM x] en la salida
      FAIL  AC26 un resultado de más de 1000 filas devuelve exactamente 1000 — no encontré ["filas_devueltas":1000] en la salida
      FAIL  AC26 el tope de filas marca truncado en true — no encontré ["truncado":true] en la salida
      FAIL  AC26 el motivo del truncado es limite_filas — no encontré ["motivo_truncado":"limite_filas"] en la salida
      FAIL  AC27 un resultado de más de 1 MiB marca truncado en true — no encontré ["truncado":true] en la salida
      FAIL  AC27 el motivo del truncado es limite_bytes — no encontré ["motivo_truncado":"limite_bytes"] en la salida
      FAIL  AC27 el tope de bytes devuelve las filas que caben, ni cero ni todas
      FAIL  un resultado chico no se marca truncado — no encontré ["truncado":false] en la salida
      FAIL  motivo_truncado es null exactamente cuando truncado es false — no encontré ["motivo_truncado":null] en la salida
      FAIL  las filas se parsean respetando las comas dentro de un campo — no encontré ["luis, el otro"] en la salida
      FAIL  AC37 la conexión responde mientras está en el catálogo — no encontré ["conexion":"proveedores-qa"] en la salida
      FAIL  AC37 quitar la entrada del catálogo devuelve el código 3 sin reiniciar el servidor — no encontré ["codigo":3] en la salida
      FAIL  AC37 el kill switch responde conexion_desconocida — no encontré ["error":"conexion_desconocida"] en la salida
      FAIL  una conexión sqlserver responde con su dialecto — no encontré ["dialecto":"sqlserver"] en la salida
      FAIL  el comando de sqlserver apunta al host y puerto de la entrada — no encontré [10.24.40.137,1433] en la salida
      FAIL  AC54 sqlcmd lleva -t 60 (el mismo límite que el rol de Postgres) — no encontré [ARG -t|ARG 60|] en la salida
      FAIL  AC55 sqlcmd exige el cifrado con -N true — no encontré [ARG -N|ARG true|] en la salida
      FAIL  AC55 sqlcmd lleva -C (el certificado de la instancia no es de una autoridad conocida, D71) — no encontré [ARG -C|] en la salida
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC62 la respuesta de sqlserver informa el nivel de aislamiento
      FAIL  AC62 la respuesta de sqlserver trae el aviso — no encontré ["aviso":"Corrió en READ UNCOMMITTED] en la salida
      FAIL  AC62 el aviso nombra las filas sin confirmar — no encontré [otra transacción todavía no confirmó] en la salida
      FAIL  AC62 el aviso nombra las filas leídas dos veces o salteadas — no encontré [filas leídas dos veces o salteadas] en la salida
      FAIL  AC62 el aviso va antes de las filas
      FAIL  AC62 (control) la consulta postgres responde — no encontré ["dialecto":"postgres"] en la salida
      FAIL  AC62 un nivel sin aviso escrito se rechaza
      FAIL  AC57 un error de sqlcmd se informa como conexion_fallida — no encontré ["error":"conexion_fallida"] en la salida
      FAIL  AC57 el mensaje de un error de sqlcmd no llega vacío — no encontré [VIEW SERVER STATE permission was denied] en la salida
      FAIL  AC57 (control) el mensaje tomado de stdout pasa por la redacción — no encontré [[redactado]] en la salida
      FAIL  AC63 un error de consulta de sqlserver informa el aislamiento — no encontré ["aislamiento":"READ UNCOMMITTED"] en la salida
      FAIL  AC57 un error después de filas no se lee como corte por el dato que dice Timeout expired — no encontré ["error":"conexion_fallida"] en la salida
      FAIL  AC57 el mensaje empieza en el Msg, no en los datos — no encontré ["mensaje":"Msg 245] en la salida
      FAIL  AC57 sin Msg, el mensaje es el final de stdout — no encontré [FIN-DEL-ERROR] en la salida
      FAIL  AC57 el corte por -t de sqlcmd se informa como tiempo_agotado — no encontré ["error":"tiempo_agotado"] en la salida
      FAIL  AC63 un corte de sqlserver informa el aislamiento — no encontré ["aislamiento":"READ UNCOMMITTED"] en la salida
      FAIL  AC55/AC58 psql exige TLS y autentica al servidor (PGSSLMODE=verify-full) — no encontré [PGSSLMODE verify-full] en la salida
      FAIL  AC58 psql apunta PGSSLROOTCERT al bundle de RDS del plugin — no encontré [certificados/rds-global-bundle.pem] en la salida
      FAIL  AC58 el archivo al que apunta PGSSLROOTCERT existe — no encontré [PGSSLROOTCERT_EXISTE si] en la salida
      FAIL  AC56 al arrancar, el servidor borra el temporal huérfano del plugin
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y el seudónimo de quien consulta
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y el seudónimo — no encontré [ARG -H|ARG claude_lectura/u-349175ad|] en la salida
      FAIL  AC60 la identidad se pide una sola vez por proceso
      FAIL  AC60 (control) las dos consultas llevan el seudónimo
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 de un rol asumido el seudónimo sale del nombre de sesión
      FAIL  AC60 sts se llama con la región de la entrada y sólo pide el ARN
      FAIL  AC60 si sts falla, la consulta siguiente vuelve a pedir la identidad
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
      FAIL  AC60 un ARN sin nombre (root) se guarda como ? y no se vuelve a pedir
      FAIL  AC60 --seudonimo-de imprime el seudónimo de un nombre
      FAIL  AC60 --seudonimo imprime el seudónimo propio, con la identidad de AWS
      FAIL  AC60 --seudonimo como valor de --sql no activa el modo seudónimo — no encontré ["error": "conexion_desconocida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC61 (d) sin el aviso en la descripción
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=4
      FAIL  AC61 la descripción de consultar avisa el nivel de aislamiento de SQL Server — no encontré [En SQL Server la consulta corre en READ UNCOMMITTED] en la salida
      FAIL  AC61 la descripción de consultar avisa que puede leer filas sin confirmar — no encontré [que otra transacción todavía no confirmó] en la salida
      FAIL  AC61 la descripción de consultar avisa que puede leer dos veces o saltear filas confirmadas — no encontré [leer dos veces o saltear filas ya confirmadas] en la salida
      FAIL  AC61 la descripción de consultar avisa el corte con el error 601 — no encontré [o cortar con el error 601] en la salida
- verde (restaurado): exit=0 fail=0

### AC61 (e) sin la frase de las filas repetidas o salteadas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC61 la descripción de consultar avisa que puede leer dos veces o saltear filas confirmadas — no encontré [leer dos veces o saltear filas ya confirmadas] en la salida
      FAIL  AC61 la descripción de consultar avisa el corte con el error 601 — no encontré [o cortar con el error 601] en la salida
- verde (restaurado): exit=0 fail=0

### AC61 (f) sin el corte con el error 601
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC61 la descripción de consultar avisa el corte con el error 601 — no encontré [o cortar con el error 601] en la salida
- verde (restaurado): exit=0 fail=0

### AC62 (a) sin los dos campos
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
      FAIL  AC62 la respuesta de sqlserver informa el nivel de aislamiento
      FAIL  AC62 el nivel informado es el mismo que se mandó a sqlcmd
      FAIL  AC62 la respuesta de sqlserver trae el aviso — no encontré ["aviso":"Corrió en READ UNCOMMITTED] en la salida
      FAIL  AC62 el aviso nombra las filas sin confirmar — no encontré [otra transacción todavía no confirmó] en la salida
      FAIL  AC62 el aviso nombra las filas leídas dos veces o salteadas — no encontré [filas leídas dos veces o salteadas] en la salida
      FAIL  AC62 el aviso va antes de las filas
- verde (restaurado): exit=0 fail=0

### AC62 (b) nivel informado a mano, distinto
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC62 la respuesta de sqlserver informa el nivel de aislamiento
      FAIL  AC62 el nivel informado es el mismo que se mandó a sqlcmd
- verde (restaurado): exit=0 fail=0

### AC62 (c) los dos campos también en Postgres
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC62 la respuesta de postgres no lleva aislamiento — encontré ["aislamiento"] y no debería estar
      FAIL  AC62 la respuesta de postgres no lleva aviso — encontré ["aviso"] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC62 (d) el aviso después de las filas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC62 el aviso va antes de las filas
- verde (restaurado): exit=0 fail=0

### AC62 (e) el prefijo escrito a mano, con otro nivel
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC62 el nivel informado es el mismo que se mandó a sqlcmd
- verde (restaurado): exit=0 fail=0

### AC62 (f) el aviso sin la cláusula de las filas sin confirmar
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC62 el aviso nombra las filas sin confirmar — no encontré [otra transacción todavía no confirmó] en la salida
- verde (restaurado): exit=0 fail=0

### AC62 (g) un nivel sin aviso devuelve un texto genérico
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC62 un nivel sin aviso escrito se rechaza
- verde (restaurado): exit=0 fail=0

### AC63 (a) sin aislamiento en los errores
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC63 un error de consulta de sqlserver informa el aislamiento — no encontré ["aislamiento":"READ UNCOMMITTED"] en la salida
      FAIL  AC63 un corte de sqlserver informa el aislamiento — no encontré ["aislamiento":"READ UNCOMMITTED"] en la salida
- verde (restaurado): exit=0 fail=0

### AC63 (b) aislamiento también en los errores de Postgres
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC63 un error de postgres no lleva aislamiento — encontré ["aislamiento"] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC34 serverInfo.version desalineada de plugin.json
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC34 serverInfo.version es la de plugin.json
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC34, AC61, AC62 y AC63 (contract v30). Cada una cambia una
# línea con reemplazo exacto (tiene que aparecer una sola vez), verifica que
# se aplicó, corre el test del AC, restaura con git checkout y verifica que
# se restauró. Imprime exit code, cantidad de asserts que caen y sus nombres.
set -u
cd "$(git rev-parse --show-toplevel)"
LB=plugins/bisalta-db/scripts/lista-blanca.js
CX=plugins/bisalta-db/scripts/conexion.js
SV=plugins/bisalta-db/scripts/servidor-mcp.js
TL=SDD/tests/test_lista_blanca.sh
TS=SDD/tests/test_servidor_mcp.sh
SS=SDD/tests/secret-scan.sh
TSS=SDD/tests/test_secret_scan.sh
correr() { local o ec; o="$(bash "$1" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c '^  FAIL' <<<"$o")"; grep '^  FAIL' <<<"$o" | sed 's/ — esperado.*//; s/ (exit [0-9]*)//; s/^/    /'; }
mutar() { local nombre="$1" archivo="$2" test="$3" viejo="$4" nuevo="$5"
  echo "### $nombre"
  printf -- '- verde (árbol real): '; correr "$test"
  python3 - "$archivo" "$viejo" "$nuevo" <<'PY'
import sys
p,v,n=sys.argv[1:4]; s=open(p).read(); assert s.count(v)==1,(v,s.count(v)); open(p,'w').write(s.replace(v,n))
PY
  if git diff --quiet -- "$archivo"; then echo "- ABORTA: la mutación no se aplicó"; return 1; fi
  printf -- '- mutado:             '; correr "$test"
  git checkout -q -- "$archivo"
  if ! git diff --quiet -- "$archivo"; then echo "- ABORTA: no se restauró"; return 1; fi
  printf -- '- verde (restaurado): '; correr "$test"
  echo; }
# RT56: sobre un árbol commiteado. Cada restauración es un `git checkout`,
# que devolvería la versión commiteada y se llevaría lo que no lo está.
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio al empezar"; exit 1; }
echo "árbol $(git rev-parse --short HEAD)"; echo
mutar "AC61 (a) sin el prefijo" "$CX" "$TS" \
  "'-Q', AISLAMIENTO_SQLSERVER + sql]" "'-Q', sql]"
mutar "AC61 (b) el prefijo después de la consulta" "$CX" "$TS" \
  "'-Q', AISLAMIENTO_SQLSERVER + sql]" "'-Q', sql + '; ' + AISLAMIENTO_SQLSERVER]"
mutar "AC61 (c) READ COMMITTED en lugar de READ UNCOMMITTED" "$CX" "$TS" \
  "const NIVEL_AISLAMIENTO_SQLSERVER = 'READ UNCOMMITTED';" "const NIVEL_AISLAMIENTO_SQLSERVER = 'READ COMMITTED';"
mutar "AC61 (d) sin el aviso en la descripción" "$SV" "$TS" \
  "con un límite de 60 s por consulta. En SQL Server la consulta corre en ' +
      'READ UNCOMMITTED para no bloquear a quien escribe: puede devolver filas que otra transacción ' +
      'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. Las respuestas exitosas de ' +" "con un límite de 60 s por consulta. Las respuestas exitosas de ' +"
mutar "AC61 (e) sin la frase de las filas repetidas o salteadas" "$SV" "$TS" \
  "'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. Las respuestas exitosas de ' +" "'todavía no confirmó. Las respuestas exitosas de ' +"
mutar "AC61 (f) sin el corte con el error 601" "$SV" "$TS" \
  "pueden dar mal) o cortar con el error 601. Las respuestas" "pueden dar mal). Las respuestas"
mutar "AC62 (a) sin los dos campos" "$SV" "$TS" \
  "    cuerpo.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
    cuerpo.aviso = conexion.AVISO_AISLAMIENTO_SQLSERVER;
" ""
mutar "AC62 (b) nivel informado a mano, distinto" "$SV" "$TS" \
  "cuerpo.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;" "cuerpo.aislamiento = 'READ COMMITTED';"
mutar "AC62 (c) los dos campos también en Postgres" "$SV" "$TS" \
  "  if (entrada.dialecto === 'sqlserver') {
    cuerpo.aislamiento" "  if (true) {
    cuerpo.aislamiento"
mutar "AC62 (d) el aviso después de las filas" "$SV" "$TS" \
  "  if (entrada.dialecto === 'sqlserver') {
    cuerpo.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
    cuerpo.aviso = conexion.AVISO_AISLAMIENTO_SQLSERVER;
  }
  Object.assign(cuerpo, {
    filas: topes.filas,
    filas_devueltas: topes.filas.length,
    truncado: topes.truncado,
    motivo_truncado: topes.motivo_truncado
  });" "  Object.assign(cuerpo, {
    filas: topes.filas,
    filas_devueltas: topes.filas.length,
    truncado: topes.truncado,
    motivo_truncado: topes.motivo_truncado
  });
  if (entrada.dialecto === 'sqlserver') {
    cuerpo.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
    cuerpo.aviso = conexion.AVISO_AISLAMIENTO_SQLSERVER;
  }"
mutar "AC62 (e) el prefijo escrito a mano, con otro nivel" "$CX" "$TS" \
  "const AISLAMIENTO_SQLSERVER = 'SET TRANSACTION ISOLATION LEVEL ' + NIVEL_AISLAMIENTO_SQLSERVER + '; ';" "const AISLAMIENTO_SQLSERVER = 'SET TRANSACTION ISOLATION LEVEL READ COMMITTED; ';"
mutar "AC62 (f) el aviso sin la cláusula de las filas sin confirmar" "$CX" "$TS" \
  "puede incluir filas que otra transacción todavía no ' +
    'confirmó y, si alguien escribía mientras tanto, filas" "si alguien escribía mientras tanto, puede incluir ' +
    'filas"
mutar "AC62 (g) un nivel sin aviso devuelve un texto genérico" "$CX" "$TS" \
  "    throw new Error('nivel de aislamiento sin aviso escrito: ' + String(nivel));" "    return 'Corrió en ' + String(nivel) + '.';"
mutar "AC63 (a) sin aislamiento en los errores" "$SV" "$TS" \
  "      extra.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
" ""
mutar "AC63 (b) aislamiento también en los errores de Postgres" "$SV" "$TS" \
  "if (entrada.dialecto === 'sqlserver' && (codigo === 6 || codigo === 7)) {" "if (codigo === 6 || codigo === 7) {"
mutar "AC34 serverInfo.version desalineada de plugin.json" "$SV" "$TS" \
  "const VERSION_SERVIDOR = '0.2.0';" "const VERSION_SERVIDOR = '0.1.0';"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Linter de closure

```
$ bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md
exit 0
```
