# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-tenant-por-sesion` · **Commit**: `a2fa075` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-10-02T17:39:13Z
- Tree: `7679ea61f408f61983d72f135aca11881a4e13d5` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-10-02T17:36:04Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-10-02T17:36:04Z | verde |
| 3 | type-check | — | — | 2026-10-02T17:36:05Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-10-02T17:36:05Z | verde |
| 5 | integration | — | — | 2026-10-02T17:37:36Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-10-02T17:37:36Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-10-02T17:37:36Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-10-02T17:37:36Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-10-02T17:37:36Z | verde |
| 10 | smoke manual | — | — | 2026-10-02T17:37:39Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-10-02T17:37:39Z | verde |

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
secret-scan: sin hallazgos sobre 192 archivos versionados (1 excluido: self)
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

# Addendum del planner — v34 (NO lo escribió el runner)

Salida literal de los scripts, pegados al final de cada sección. Las mutaciones y la medición en vivo corrieron sobre el árbol del código sellado arriba (`a2fa075`), con el árbol limpio al empezar y al terminar; cada salida dice sobre qué commit corrió.

## 1. En vivo, servidor del repo

```
árbol a2fa075
### AC64: smartcheck-qa con el tenant por sesión (esperado: 2998 filas, 1 tenant)
{ "conexion": "smartcheck-qa", "dialecto": "postgres", "filas": [ { "filas": "3020", "tenants": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC64: proveedores-dev, sin sesion, responde igual que antes
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC65: una tabla con columna token sale redactada (sólo dos filas)
{ "conexion": "smartcheck-qa", "dialecto": "postgres", "columnas_redactadas": [ "token" ], "filas": [ { "token": "[redactado]" }, { "token": "[redactado]" } ], "filas_devueltas": 2, "truncado": false, "motivo_truncado": null }
### AC66: el aviso del motor va en avisos_motor, no en filas
{ "conexion": "compras", "dialecto": "sqlserver", "aislamiento": "READ UNCOMMITTED", "aviso": "Corrió en READ UNCOMMITTED: puede incluir filas que otra transacción todavía no confirmó y, si alguien escribía mientras tanto, filas leídas dos veces o salteadas. Un COUNT o un total pueden estar mal.", "filas": [ { "tipo": "SQL_SCALAR_FUNCTION", "objetos": 123, "visibles": 123 }, { "tipo": "SQL_STORED_PROCEDURE", "objetos": 630, "visibles": 630 } ], "filas_devueltas": 2, "truncado": false, "motivo_truncado": null }
### AC67: un valor de 20000 caracteres con un salto de línea, y un número (largos y tipos)
{"error":null,"formato_tabla":"no","filas_devueltas":1,"filas":[{"v":{"largo":3,"saltos":1},"t":{"largo":20000,"saltos":0},"n":1}]}
### AC67: una columna sin nombre pasa a tabla
{"error":null,"formato_tabla":"sí","filas_devueltas":1,"filas":[{"columna_1":{"largo":3,"saltos":0}}]}
### AC67: la definición más larga de COMPRAS, largo en el motor contra largo recibido (sin el texto)
{"error":null,"formato_tabla":"no","filas_devueltas":1,"filas":[{"largo_motor":107648,"definicion":{"largo":107648,"saltos":3092}}]}
Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v34 (AC64 a AC67), con el servidor del repo, contra
# las bases reales. Sólo conteos y metadatos; ninguna credencial ni ningún
# UUID pasa por esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio al empezar"; exit 1; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### AC64: smartcheck-qa con el tenant por sesión (esperado: 2998 filas, 1 tenant)"
call smartcheck-qa "SELECT count(*) AS filas, count(DISTINCT tenant_id) AS tenants FROM smartcheck.requests"
echo "### AC64: proveedores-dev, sin sesion, responde igual que antes"
call proveedores-dev "SELECT 1 AS uno"
echo "### AC65: una tabla con columna token sale redactada (sólo dos filas)"
call smartcheck-qa "SELECT token FROM smartcheck.push_tokens LIMIT 2"
echo "### AC66: el aviso del motor va en avisos_motor, no en filas"
call compras "SELECT o.type_desc AS tipo, count(*) AS objetos, count(m.definition) AS visibles FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id = o.object_id WHERE o.type IN ('P','FN') GROUP BY o.type_desc"
# AC67: sólo largos y tipos, nunca el texto: la definición de un SP es código
# de la empresa y puede traer lo que D93 aceptó.
largos() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{const j=JSON.parse(JSON.parse(d).result.content[0].text);const filas=(j.filas||[]).map(f=>Object.fromEntries(Object.entries(f).map(([k,v])=>[k,v===null?null:(typeof v==="string"?{largo:v.length,saltos:(v.match(/\n/g)||[]).length}:v)])));console.log(JSON.stringify({error:j.error||null,formato_tabla:j.formato_tabla?"sí":"no",filas_devueltas:j.filas_devueltas,filas:filas}))})'; }
echo "### AC67: un valor de 20000 caracteres con un salto de línea, y un número (largos y tipos)"
largos compras "SELECT CAST(N'a' + CHAR(10) + N'b' AS nvarchar(max)) AS v, REPLICATE(CAST(N'x' AS nvarchar(max)), 20000) AS t, 1 AS n"
echo "### AC67: una columna sin nombre pasa a tabla"
largos compras "SELECT count(*) FROM sys.objects"
echo "### AC67: la definición más larga de COMPRAS, largo en el motor contra largo recibido (sin el texto)"
largos compras "SELECT TOP 1 LEN(definition) AS largo_motor, definition AS definicion FROM sys.sql_modules ORDER BY LEN(definition) DESC"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC47` (regla de Patrick), `AC64`, `AC65`, `AC66` y `AC67` — salida literal

```
árbol a2fa075

### AC64 (a) sin el --command del SET
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC64 el SET del tenant va entre la guarda de réplica y el SQL, con el valor del secreto — no encontré [ARG --command|ARG DO $guarda$ BEGIN IF NOT pg_is_in_recovery() THEN RAISE EXCEPTION 'bisalta-db: la conexion no llego a una replica de lectura'; END IF; END $guarda$|ARG --command|ARG SET app.tenant_ids = '11111111-2222-4333-8444-555555555555'|ARG --command|ARG SELECT 1|] en la salida
      FAIL  AC64 un UUID en mayúsculas en el secreto viaja en minúsculas — no encontré [ARG SET app.tenant_ids = 'abcdef12-3456-4789-8abc-def012345678'] en la salida
      FAIL  AC64 uuid_lista une los tenants con coma y sin espacios, en el orden del catálogo — no encontré [ARG SET app.tenant_ids = '11111111-2222-4333-8444-555555555555,aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'] en la salida
- verde (restaurado): exit=0 fail=0

### AC64 (b) el SET después del SQL
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 el SET del tenant va entre la guarda de réplica y el SQL, con el valor del secreto — no encontré [ARG --command|ARG DO $guarda$ BEGIN IF NOT pg_is_in_recovery() THEN RAISE EXCEPTION 'bisalta-db: la conexion no llego a una replica de lectura'; END IF; END $guarda$|ARG --command|ARG SET app.tenant_ids = '11111111-2222-4333-8444-555555555555'|ARG --command|ARG SELECT 1|] en la salida
- verde (restaurado): exit=0 fail=0

### AC64 (c) un SET también sin sesion
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC46 el comando lleva exactamente dos --command
      FAIL  AC46 el segundo --command es el SQL del consumidor
      FAIL  AC64 una entrada sin sesion no manda ningún SET — encontré [ARG SET ] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC64 (d) sin validar el UUID
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
      FAIL  AC64 un tenant no-uuid en el secreto devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC64 el error de un tenant no-uuid nombra la clave — no encontré [tenant_construplaza] en la salida
      FAIL  AC64 con un tenant no-uuid, psql no se invoca
      FAIL  AC64 un tenant inyeccion en el secreto devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC64 el error de un tenant inyeccion nombra la clave — no encontré [tenant_construplaza] en la salida
      FAIL  AC64 con un tenant inyeccion, psql no se invoca
- verde (restaurado): exit=0 fail=0

### AC64 (e) unir con coma y espacio
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 uuid_lista une los tenants con coma y sin espacios, en el orden del catálogo — no encontré [ARG SET app.tenant_ids = '11111111-2222-4333-8444-555555555555,aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'] en la salida
- verde (restaurado): exit=0 fail=0

### AC64 (f) un tenant que falta no frena
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=9
      FAIL  AC64 un tenant falta en el secreto devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC64 el error de un tenant falta nombra la clave — no encontré [tenant_construplaza] en la salida
      FAIL  AC64 con un tenant falta, psql no se invoca
      FAIL  AC64 un tenant no-uuid en el secreto devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC64 el error de un tenant no-uuid nombra la clave — no encontré [tenant_construplaza] en la salida
      FAIL  AC64 con un tenant no-uuid, psql no se invoca
      FAIL  AC64 un tenant inyeccion en el secreto devuelve el código 5 — no encontré ["codigo":5] en la salida
      FAIL  AC64 el error de un tenant inyeccion nombra la clave — no encontré [tenant_construplaza] en la salida
      FAIL  AC64 con un tenant inyeccion, psql no se invoca
- verde (restaurado): exit=0 fail=0

### AC64 (g) el validador sin la regla de un solo tenant con uuid
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 el validador rechaza el formato uuid con dos tenants
- verde (restaurado): exit=0 fail=0

### AC64 (h) el validador sin el patrón del parámetro
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC64 el validador rechaza un parametro fuera de <prefijo>.<nombre>
      FAIL  AC64 el validador rechaza un parametro sin prefijo
- verde (restaurado): exit=0 fail=0

### AC64 (i) el validador acepta sesion en sqlserver
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 el validador rechaza sesion en una entrada sqlserver
- verde (restaurado): exit=0 fail=0

### AC64 (j) el validador sin exigir alcance
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 el validador rechaza un alcance en blanco
- verde (restaurado): exit=0 fail=0

### AC64 (k) el mensaje de error incluye el valor
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 el error no repite el valor del secreto — encontré [SELECT 1; --] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC65 (a) sin redactar
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=11
      FAIL  AC65 el valor de token no sale en la respuesta — encontré [valor-sensible-abc] y no debería estar
      FAIL  AC65 el valor de api_key no sale en la respuesta — encontré [valor-sensible-def] y no debería estar
      FAIL  AC65 token queda como [redactado] — no encontré ["token":"[redactado]"] en la salida
      FAIL  AC65 la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token","api_key"]] en la salida
      FAIL  AC65 un valor vacío (un NULL de psql) también se redacta, y una columna no sensible vacía queda vacía
      FAIL  AC65 columnas_redactadas va antes de las filas
      FAIL  AC65 los patrones cubren secret, password, passwd, apikey, key_hash y token, sin mirar mayúsculas; un nulo también se redacta
      FAIL  AC65 en sqlserver el valor de token no sale — encontré [valor-sensible-mssql] y no debería estar
      FAIL  AC65 en sqlserver la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token"]] en la salida
      FAIL  AC65 una fila con un token de más de 1 MiB, redactada, entra en el tope de bytes — no encontré ["filas_devueltas":1] en la salida
      FAIL  AC65 esa respuesta no se trunca, porque se mide después de redactar — no encontré ["truncado":false] en la salida
- verde (restaurado): exit=0 fail=0

### AC65 (b) sin columnas_redactadas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC65 la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token","api_key"]] en la salida
      FAIL  AC65 columnas_redactadas va antes de las filas
      FAIL  AC65 en sqlserver la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token"]] en la salida
- verde (restaurado): exit=0 fail=0

### AC65 (c) el patrón sensible a mayúsculas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC65 los patrones cubren secret, password, passwd, apikey, key_hash y token, sin mirar mayúsculas; un nulo también se redacta
- verde (restaurado): exit=0 fail=0

### AC65 (d) dejar sin redactar el vacío
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC65 un valor vacío (un NULL de psql) también se redacta, y una columna no sensible vacía queda vacía
- verde (restaurado): exit=0 fail=0

### AC65 (e) sin passwd
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC65 los patrones cubren secret, password, passwd, apikey, key_hash y token, sin mirar mayúsculas; un nulo también se redacta
- verde (restaurado): exit=0 fail=0

### AC64 (l) sin bajar a minúsculas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 un UUID en mayúsculas en el secreto viaja en minúsculas — no encontré [ARG SET app.tenant_ids = 'abcdef12-3456-4789-8abc-def012345678'] en la salida
- verde (restaurado): exit=0 fail=0

### AC64 (m) proyectar sesion entera
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 listar_conexiones proyecta sesion con parametro, tenants y alcance, y null sin bloque
- verde (restaurado): exit=0 fail=0

### AC64 (n) sin null en una entrada sin bloque
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC64 listar_conexiones proyecta sesion con parametro, tenants y alcance, y null sin bloque
- verde (restaurado): exit=0 fail=0

### AC65 (f) redactar sólo en postgres
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC65 en sqlserver el valor de token no sale — encontré [valor-sensible-mssql] y no debería estar
      FAIL  AC65 en sqlserver la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token"]] en la salida
- verde (restaurado): exit=0 fail=0

### AC65 (g) redactar después de los topes
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC65 una fila con un token de más de 1 MiB, redactada, entra en el tope de bytes — no encontré ["filas_devueltas":1] en la salida
      FAIL  AC65 esa respuesta no se trunca, porque se mide después de redactar — no encontré ["truncado":false] en la salida
- verde (restaurado): exit=0 fail=0

### AC47 v31-a apagar la regla identificador_unicode
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=10
      FAIL  AC47 v31 caso 0 (postgres): el hueco: set_config escrito con escape Unicode
      FAIL  AC47 v31 caso 1 (postgres): minuscula: U& no distingue mayusculas
      FAIL  AC47 v31 caso 2 (postgres): con caracter de escape propio via UESCAPE
      FAIL  AC47 v31 caso 3 (postgres): escondido dentro de un CTE
      FAIL  AC47 v31 caso 4 (postgres): inocente, pero se rechaza igual: no decodificamos, rechazamos la forma
      FAIL  AC47 v31 caso 0: el motivo es identificador_unicode
      FAIL  AC47 v31 caso 1: el motivo es identificador_unicode
      FAIL  AC47 v31 caso 2: el motivo es identificador_unicode
      FAIL  AC47 v31 caso 3: el motivo es identificador_unicode
      FAIL  AC47 v31 caso 4: el motivo es identificador_unicode
- verde (restaurado): exit=0 fail=0

### AC47 v31-b sin el borde de palabra
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC47 v31 caso 6 (postgres): borde: col_u es un identificador y & es el operador; no es U&
- verde (restaurado): exit=0 fail=0

### AC47 v31-c distinguir mayúsculas
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC47 v31 caso 1 (postgres): minuscula: U& no distingue mayusculas
      FAIL  AC47 v31 caso 1: el motivo es identificador_unicode
- verde (restaurado): exit=0 fail=0

### AC66 (a) sin apartar el aviso
- verde (árbol real): exit=0 fail=0
- mutado:             exit=0 fail=0
- verde (restaurado): exit=0 fail=0

### AC66 (b) apartar toda línea que empiece con Warning:
- verde (árbol real): exit=0 fail=0
- mutado:             exit=0 fail=0
- verde (restaurado): exit=0 fail=0

### AC66 (c) apartarlo sin informarlo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC66 el aviso llega en avisos_motor — no encontré ["avisos_motor":["Warning: Null value is eliminated by an aggregate or other SET operation."]] en la salida
- verde (restaurado): exit=0 fail=0

### AC67 (a) sin FOR JSON
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=19
      FAIL  una conexión sqlserver responde con su dialecto — no encontré ["dialecto":"sqlserver"] en la salida
      FAIL  AC62 la respuesta de sqlserver trae el aviso — no encontré ["aviso":"Corrió en READ UNCOMMITTED] en la salida
      FAIL  AC62 el aviso nombra el mismo nivel que el campo aislamiento — no encontré ["aviso":"Corrió en READ UNCOMMITTED:] en la salida
      FAIL  AC62 el aviso nombra las filas sin confirmar — no encontré [otra transacción todavía no confirmó] en la salida
      FAIL  AC62 el aviso nombra las filas leídas dos veces o salteadas — no encontré [filas leídas dos veces o salteadas] en la salida
      FAIL  AC62 el aviso va antes de las filas
      FAIL  AC57 una corrida exitosa cuyo dato dice Timeout expired no es un error — encontré ["error"] y no debería estar
      FAIL  AC65 (control) la consulta sqlserver responde — no encontré ["dialecto":"sqlserver"] en la salida
      FAIL  AC65 en sqlserver la respuesta dice qué columnas se redactaron — no encontré ["columnas_redactadas":["token"]] en la salida
      FAIL  AC66 el aviso no cuenta como fila — no encontré ["filas_devueltas":2] en la salida
      FAIL  AC66 el aviso llega en avisos_motor — no encontré ["avisos_motor":["Warning: Null value is eliminated by an aggregate or other SET operation."]] en la salida
      FAIL  AC66 (control) un valor que empieza con Warning: pero trae separador sigue siendo una fila — no encontré ["tipo":"Warning: dato"] en la salida
      FAIL  AC67 la consulta va seguida de un salto de línea y FOR JSON PATH, INCLUDE_NULL_VALUES — no encontré [ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|FOR JSON PATH, INCLUDE_NULL_VALUES|] en la salida
      FAIL  AC67 un salto de línea llega dentro del valor, un texto de 5000 caracteres llega entero y un número llega como número
      FAIL  AC67 el valor partido en trozos es una sola fila — no encontré ["filas_devueltas":1] en la salida
      FAIL  AC67 un resultado vacío da cero filas — no encontré ["filas":[],"filas_devueltas":0] en la salida
      FAIL  AC67 con una columna sin nombre, sqlcmd corre dos veces: en JSON y en tabla
      FAIL  AC67 la respuesta de respaldo dice que se leyó como tabla — no encontré ["formato_tabla":"Se leyó como tabla] en la salida
      FAIL  AC67 una columna sin nombre se nombra por posición, no con la línea de guiones — no encontré ["columna_1":"953"] en la salida
- verde (restaurado): exit=0 fail=0

### AC67 (b) sin -y 8000
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC67 sqlcmd lleva -y 8000 — no encontré [ARG -y|ARG 8000|] en la salida
      FAIL  AC67 la tabla de respaldo también lleva -y 8000 — no encontré [-y 8000] en la salida
- verde (restaurado): exit=0 fail=0

### AC67 (c) sin el salto de línea antes de FOR JSON
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC67 la consulta va seguida de un salto de línea y FOR JSON PATH, INCLUDE_NULL_VALUES — no encontré [ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|FOR JSON PATH, INCLUDE_NULL_VALUES|] en la salida
- verde (restaurado): exit=0 fail=0

### AC67 (d) sin respaldo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC67 con una columna sin nombre, sqlcmd corre dos veces: en JSON y en tabla
      FAIL  AC67 la respuesta de respaldo dice que se leyó como tabla — no encontré ["formato_tabla":"Se leyó como tabla] en la salida
      FAIL  AC67 una columna sin nombre se nombra por posición, no con la línea de guiones — no encontré ["columna_1":"953"] en la salida
- verde (restaurado): exit=0 fail=0

### AC67 (e) reintentar con cualquier error
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC67 un error que no es de FOR JSON no se reintenta en tabla
- verde (restaurado): exit=0 fail=0

### AC67 (f) sin nombrar por posición la columna sin nombre
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC67 una columna sin nombre se nombra por posición, no con la línea de guiones — no encontré ["columna_1":"953"] en la salida
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC47 v31, AC64, AC65, AC66 y AC67 (contract v34). Cada una cambia una
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
CAT=plugins/bisalta-db/scripts/catalogo.js
TCAT=SDD/tests/test_catalogo.sh
mutar "AC64 (a) sin el --command del SET" "$CX" "$TS" \
  "      valorSesion ? ['--command', 'SET ' + valorSesion.parametro + \" = '\" + valorSesion.valor + \"'\"] : []," "      [],"
mutar "AC64 (b) el SET después del SQL" "$CX" "$TS" \
  "      valorSesion ? ['--command', 'SET ' + valorSesion.parametro + \" = '\" + valorSesion.valor + \"'\"] : [],
      ['--command', sql, conninfo])," "      ['--command', sql],
      valorSesion ? ['--command', 'SET ' + valorSesion.parametro + \" = '\" + valorSesion.valor + \"'\"] : [],
      [conninfo]),"
mutar "AC64 (c) un SET también sin sesion" "$CX" "$TS" \
  "  if (!entrada.sesion) return null;" "  if (!entrada.sesion) return { parametro: 'app.tenant_ids', valor: '00000000-0000-4000-8000-000000000000' };"
mutar "AC64 (d) sin validar el UUID" "$CX" "$TS" \
  "    if (typeof valor !== 'string' || !UUID_VALIDO.test(valor)) {" "    if (typeof valor !== 'string') {"
mutar "AC64 (e) unir con coma y espacio" "$CX" "$TS" \
  "valores.join(',')" "valores.join(', ')"
mutar "AC64 (f) un tenant que falta no frena" "$CX" "$TS" \
  "      throw fallo(5, 'secreto_inaccesible',
        'al secreto de la conexión \`' + entrada.nombre + '\` (secret_id \`' + entrada.secret_id + '\`) le falta \`' +
        clave + '\` o no es un UUID');" "      return null;"
mutar "AC64 (g) el validador sin la regla de un solo tenant con uuid" "$CAT" "$TCAT" \
  "    if (sesion.formato === 'uuid' && sesion.tenants.length !== 1) {" "    if (false) {"
mutar "AC64 (h) el validador sin el patrón del parámetro" "$CAT" "$TCAT" \
  "  if (typeof sesion.parametro !== 'string' || !PARAMETRO_SESION_VALIDO.test(sesion.parametro)) {" "  if (typeof sesion.parametro !== 'string') {"
mutar "AC64 (i) el validador acepta sesion en sqlserver" "$CAT" "$TCAT" \
  "  if (entrada.dialecto !== 'postgres') {
    problemas.push(donde + ': sólo" "  if (false) {
    problemas.push(donde + ': sólo"
mutar "AC64 (j) el validador sin exigir alcance" "$CAT" "$TCAT" \
  "  if (!esCadenaNoVacia(sesion.alcance)) {" "  if (false) {"
mutar "AC64 (k) el mensaje de error incluye el valor" "$CX" "$TS" \
  "        clave + '\` o no es un UUID');" "        clave + '\` o no es un UUID: ' + String(valor));"
mutar "AC65 (a) sin redactar" "$SV" "$TS" \
  "      if (COLUMNA_SENSIBLE.test(columna)) {" "      if (false) {"
mutar "AC65 (b) sin columnas_redactadas" "$SV" "$TS" \
  "    cuerpo.columnas_redactadas = redaccion.redactadas;
" ""
mutar "AC65 (c) el patrón sensible a mayúsculas" "$SV" "$TS" \
  "/token|secret|pass(?:word|wd)|key_hash|api_?key/i;" "/token|secret|pass(?:word|wd)|key_hash|api_?key/;"
mutar "AC65 (d) dejar sin redactar el vacío" "$SV" "$TS" \
  "        copia[columna] = VALOR_REDACTADO;" "        copia[columna] = fila[columna] === '' ? '' : VALOR_REDACTADO;"
mutar "AC65 (e) sin passwd" "$SV" "$TS" \
  "/token|secret|pass(?:word|wd)|key_hash|api_?key/i;" "/token|secret|password|key_hash|api_?key/i;"
mutar "AC64 (l) sin bajar a minúsculas" "$CX" "$TS" \
  "valores.push(valor.toLowerCase());" "valores.push(valor);"
mutar "AC64 (m) proyectar sesion entera" "$CAT" "$TS" \
  "    sesion: entrada.sesion === undefined ? null : {
      parametro: entrada.sesion.parametro,
      tenants: entrada.sesion.tenants,
      alcance: entrada.sesion.alcance
    }" "    sesion: entrada.sesion === undefined ? null : entrada.sesion"
mutar "AC64 (n) sin null en una entrada sin bloque" "$CAT" "$TS" \
  "    sesion: entrada.sesion === undefined ? null : {" "    sesion: entrada.sesion === undefined ? undefined : {"
mutar "AC65 (f) redactar sólo en postgres" "$SV" "$TS" \
  "  const redaccion = redactarColumnasSensibles(resultado.filas);" "  const redaccion = entrada.dialecto === 'postgres' ? redactarColumnasSensibles(resultado.filas) : { filas: resultado.filas, redactadas: [] };"
mutar "AC65 (g) redactar después de los topes" "$SV" "$TS" \
  "  const redaccion = redactarColumnasSensibles(resultado.filas);
  const topes = aplicarTopes(redaccion.filas);" "  const topesCrudos = aplicarTopes(resultado.filas);
  const redaccion = redactarColumnasSensibles(topesCrudos.filas);
  const topes = Object.assign({}, topesCrudos, { filas: redaccion.filas });"
mutar "AC47 v31-a apagar la regla identificador_unicode" "$LB" "$TL" \
  "    if (dialecto === 'postgres' && IDENTIFICADOR_UNICODE_POSTGRES.test(sentencia)) {" "    if (false) {"
mutar "AC47 v31-b sin el borde de palabra" "$LB" "$TL" \
  '/(^|[^A-Za-z0-9_$])[Uu]&"/' '/[Uu]&"/'
mutar "AC47 v31-c distinguir mayúsculas" "$LB" "$TL" \
  '[Uu]&"/;' 'U&"/;'
mutar "AC66 (a) sin apartar el aviso" "$CX" "$TS" \
  "    if (celdas.length === 1 && /^Warning: /.test(linea)) { avisos.push(linea.replace(/\\s+\$/, '')); continue; }" ""
mutar "AC66 (b) apartar toda línea que empiece con Warning:" "$CX" "$TS" \
  "    if (celdas.length === 1 && /^Warning: /.test(linea)) {" "    if (/^Warning: /.test(linea)) {"
mutar "AC66 (c) apartarlo sin informarlo" "$SV" "$TS" \
  "    cuerpo.avisos_motor = resultado.avisos;" ""
mutar "AC67 (a) sin FOR JSON" "$CX" "$TS" \
  "  const sufijo = formato === 'tabla' ? '' : SUFIJO_JSON_SQLSERVER;" "  const sufijo = '';"
mutar "AC67 (b) sin -y 8000" "$CX" "$TS" \
  "      '-b', '-y', ANCHO_SQLSERVER, '-s'," "      '-b', '-s',"
mutar "AC67 (c) sin el salto de línea antes de FOR JSON" "$CX" "$TS" \
  "const SUFIJO_JSON_SQLSERVER = '\\nFOR JSON" "const SUFIJO_JSON_SQLSERVER = ' FOR JSON"
mutar "AC67 (d) sin respaldo" "$CX" "$TS" \
  "    if (entrada.dialecto === 'sqlserver' && r.status !== 0 && SIN_JSON_SQLSERVER.test(String(r.stdout))) {" "    if (false) {"
mutar "AC67 (e) reintentar con cualquier error" "$CX" "$TS" \
  "    if (entrada.dialecto === 'sqlserver' && r.status !== 0 && SIN_JSON_SQLSERVER.test(String(r.stdout))) {" "    if (entrada.dialecto === 'sqlserver' && r.status !== 0) {"
mutar "AC67 (f) sin nombrar por posición la columna sin nombre" "$CX" "$TS" \
  "    if (columnas === null && /^-+\$/.test(" "    if (false && columnas === null && /^-+\$/.test("
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Linter de closure

```
$ bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md
exit 0
```
