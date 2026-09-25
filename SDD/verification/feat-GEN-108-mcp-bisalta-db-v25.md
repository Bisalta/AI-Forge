# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `10c1421` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-25T13:30:45Z
- Tree: `f95ab655479f0f942428daea8af3678a07391148` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-25T13:29:37Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-25T13:29:37Z | verde |
| 3 | type-check | — | — | 2026-09-25T13:29:38Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-25T13:29:38Z | verde |
| 5 | integration | — | — | 2026-09-25T13:30:12Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-25T13:30:12Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-25T13:30:12Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-25T13:30:12Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-25T13:30:12Z | verde |
| 10 | smoke manual | — | — | 2026-09-25T13:30:13Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-25T13:30:13Z | verde |

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
secret-scan: sin hallazgos sobre 184 archivos versionados (1 excluido: self)
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

# Addendum del planner — v25 (NO lo escribió el runner)

La escalera de arriba se corrió sobre `10c1421`, que ya incluye las correcciones de la ronda 1 de la review de v25. Las mediciones, las mutaciones y la verificación en vivo se corrieron sobre `da93f90`, el commit que agregó la escalera: el código y los tests son los de `10c1421`. Esta versión del report reemplaza a la de `e62cff6`, que queda en el historial.

## 1. Las mediciones que decidieron el diseño — salida literal

Se hicieron el 25-sep antes de cambiar el código, y se repitieron con este script para pegar la salida (review de v25, ronda 1, MAJOR 2). Las pruebas 1 y 2 deshacen en `conexion.js`, sólo mientras corren, la línea que v25 agregó, y la restauran con `git checkout`.

```
árbol da93f90

### 1. Postgres con el sslmode por omisión (prefer)
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }

### 2. SQL Server con -N true y sin -C
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "TLS Handshake failed: tls: failed to verify certificate: x509: “SSL_Self_Signed_Fallback” certificate is not standards compliant\nTLS Handshake failed: tls: failed to verify certificate: x509: “SSL_Self_Signed_Fallback” certificate is not standards compliant" }

### 3. SQL Server con -N true -C (lo que quedó)
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }

### 4. Dónde escribe sqlcmd sus errores (sin base: un puerto local cerrado)
exit=1 stdout_bytes=210 stderr_bytes=0
stdout: unable to open tcp connection with host '127.0.0.1:1': dial tcp 127.0.0.1:1: connect: connection refused unable to open tcp connection with host '127.0.0.1:1': dial tcp 127.0.0.1:1: connect: connectio

### 5. SQL Server: el cifrado no se puede leer desde la propia sesión
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "cifrado": "NULL" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "Msg 300, Level 14, State 1, Server EC2AMAZ-2RGHL0C, Line 1\nVIEW SERVER STATE permission was denied on object 'server', database 'master'." }

Árbol al terminar: limpio
```

| # | Lo que decide |
|---|---|
| 1 | Con `prefer`, Postgres ya cifraba con TLS 1.3. `require` no cambia eso: impide caer a texto plano si el servidor no ofrece TLS. |
| 2 | **Justifica `-C`**: sin él, la conexión falla. La causa es que la instancia presenta `SSL_Self_Signed_Fallback`, el certificado autofirmado que SQL Server genera solo cuando no tiene uno configurado (`D71`). |
| 3 | Con `-N true -C`, conecta. |
| 4 | **Justifica `AC57`**: `sqlcmd` escribe el error en stdout (210 bytes) y deja stderr vacío. Medido sin tocar ninguna base, contra un puerto local cerrado. |
| 5 | El login no puede leer desde su sesión si la conexión va cifrada. Por eso el cifrado de SQL Server se verifica del lado del cliente (pruebas 2 y 3). |

### El script

```bash
#!/usr/bin/env bash
# Mediciones que decidieron el diseño de v25 (AC55 y AC57), repetidas con
# script para que la salida quede pegada tal cual (review de v25, ronda 1,
# MAJOR 2). Las pruebas 1 y 2 cambian una línea de conexion.js sólo mientras
# corren y la restauran con git checkout. Sólo consultas de lectura; ninguna
# credencial pasa por esta salida. La 4 no conecta a ninguna base.
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/conexion.js
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio"; exit 1; }
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
cambiar() { python3 - "$F" "$1" "$2" <<'PY'
import sys
p,v,n=sys.argv[1:4]; s=open(p).read(); assert s.count(v)==1,(v,s.count(v)); open(p,'w').write(s.replace(v,n))
PY
  git diff --quiet -- "$F" && { echo "ABORTA: el cambio no se aplicó"; exit 1; }; }
restaurar() { git checkout -q -- "$F"; git diff --quiet -- "$F" || { echo "ABORTA: no se restauró"; exit 1; }; }
echo "árbol $(git rev-parse --short HEAD)"
echo
echo "### 1. Postgres con el sslmode por omisión (prefer)"
cambiar "      PGSSLMODE: 'require',
" ""
call proveedores-dev "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
restaurar
echo
echo "### 2. SQL Server con -N true y sin -C"
cambiar "'-N', 'true', '-C', '-t'," "'-N', 'true', '-t',"
call compras "SELECT 1 AS uno"
restaurar
echo
echo "### 3. SQL Server con -N true -C (lo que quedó)"
call compras "SELECT 1 AS uno"
echo
echo "### 4. Dónde escribe sqlcmd sus errores (sin base: un puerto local cerrado)"
out="$(mktemp)"; err="$(mktemp)"
# La variable de la contraseña, armada en dos piezas como en conexion.js, y
# con un valor falso: sin ella, sqlcmd la pide por terminal y no llega a conectar.
VARIABLE="SQLCMD""PASSWORD"
env "$VARIABLE=falsa" sqlcmd -S 127.0.0.1,1 -U nadie -N true -C -t 5 -l 3 -b -Q "SELECT 1" >"$out" 2>"$err" </dev/null; ec=$?
printf 'exit=%s stdout_bytes=%s stderr_bytes=%s\n' "$ec" "$(wc -c <"$out" | tr -d ' ')" "$(wc -c <"$err" | tr -d ' ')"
printf 'stdout: %s\n' "$(head -c 200 "$out" | tr '\n' ' ')"
rm -f "$out" "$err"
echo
echo "### 5. SQL Server: el cifrado no se puede leer desde la propia sesión"
call compras "SELECT CONNECTIONPROPERTY('encrypt_option') AS cifrado"
call compras "SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID"
echo
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC53` a `AC57` — salida literal

```
árbol da93f90

### AC53 (a) la regla entera apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=18
      FAIL  AC51/AC52 caso 8 (sqlserver): el literal se borra al normalizar; el motor si lo ejecuta (v25: ya no es limite conocido, se rechaza por OPENQUERY, AC53)
      FAIL  AC53 rechaza en sqlserver WAITFOR encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver WHILE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver GRANT encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver REVOKE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver DENY encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver USE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver DBCC encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver SET encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver DECLARE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver BEGIN encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver BACKUP encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver RESTORE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver KILL encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver SHUTDOWN encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver OPENROWSET encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver OPENQUERY encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
      FAIL  AC53 rechaza en sqlserver OPENDATASOURCE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (b) sin borde de palabra a la izquierda
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 acepta en sqlserver las palabras como parte de un nombre
- verde (restaurado): exit=0 fail=0

### AC53 (c) la regla mira el SQL sin normalizar
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 acepta en sqlserver las palabras dentro de un literal
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra WAITFOR
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver WAITFOR encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra WHILE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver WHILE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra GRANT
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver GRANT encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra REVOKE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver REVOKE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra DENY
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver DENY encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra USE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver USE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra DBCC
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver DBCC encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra SET
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver SET encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra DECLARE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver DECLARE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra BEGIN
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver BEGIN encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra BACKUP
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver BACKUP encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra RESTORE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver RESTORE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra KILL
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver KILL encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra SHUTDOWN
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver SHUTDOWN encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra OPENROWSET
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver OPENROWSET encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra OPENQUERY
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC51/AC52 caso 8 (sqlserver): el literal se borra al normalizar; el motor si lo ejecuta (v25: ya no es limite conocido, se rechaza por OPENQUERY, AC53)
      FAIL  AC53 rechaza en sqlserver OPENQUERY encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC53 (d) sin la palabra OPENDATASOURCE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC53 rechaza en sqlserver OPENDATASOURCE encadenado detrás de un SELECT — no encontré ["motivo":"sentencia_no_permitida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC54 sin -t
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC54 sqlcmd lleva -t 60 (el mismo límite que el rol de Postgres) — no encontré [ARG -t|ARG 60|] en la salida
- verde (restaurado): exit=0 fail=0

### AC55 (a) Postgres sin PGSSLMODE
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC55 psql exige TLS (PGSSLMODE=require: cifra o no conecta) — no encontré [PGSSLMODE require] en la salida
- verde (restaurado): exit=0 fail=0

### AC55 (b) sqlcmd sin -N true
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC55 sqlcmd exige el cifrado con -N true — no encontré [ARG -N|ARG true|] en la salida
- verde (restaurado): exit=0 fail=0

### AC55 (c) sqlcmd sin -C
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC55 sqlcmd lleva -C (el certificado de la instancia no es de una autoridad conocida, D71) — no encontré [ARG -C|] en la salida
- verde (restaurado): exit=0 fail=0

### AC56 (a) el servidor no limpia al arrancar
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC56 al arrancar, el servidor borra el temporal huérfano del plugin
- verde (restaurado): exit=0 fail=0

### AC56 (b) borra sin mirar la edad
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC56 no borra el temporal reciente (puede ser de otra sesión)
- verde (restaurado): exit=0 fail=0

### AC56 (c) borra sin mirar el nombre
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC56 no borra directorios que no son del plugin
      FAIL  AC56 no borra un directorio viejo con el prefijo que no tiene el nombre de mkdtemp
- verde (restaurado): exit=0 fail=0

### AC56 (d) acepta cualquier nombre con el prefijo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC56 no borra un directorio viejo con el prefijo que no tiene el nombre de mkdtemp
- verde (restaurado): exit=0 fail=0

### AC57 (a) el error se lee sólo de stderr
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=4
      FAIL  AC57 el mensaje de un error de sqlcmd no llega vacío — no encontré [VIEW SERVER STATE permission was denied] en la salida
      FAIL  AC57 (control) el mensaje tomado de stdout pasa por la redacción — no encontré [[redactado]] en la salida
      FAIL  AC57 el mensaje empieza en el Msg, no en los datos — no encontré ["mensaje":"Msg 245] en la salida
      FAIL  AC57 el corte por -t de sqlcmd se informa como tiempo_agotado — no encontré ["error":"tiempo_agotado"] en la salida
- verde (restaurado): exit=0 fail=0

### AC57 (b) stdout se lee también cuando el proceso no falló
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC57 una corrida exitosa cuyo dato dice Timeout expired no es un error — encontré ["error"] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC57 (c) toma stdout entero, sin buscar el Msg
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC57 un error después de filas no se lee como corte por el dato que dice Timeout expired — no encontré ["error":"conexion_fallida"] en la salida
      FAIL  AC57 el mensaje empieza en el Msg, no en los datos — no encontré ["mensaje":"Msg 245] en la salida
- verde (restaurado): exit=0 fail=0

### AC57 (d) sin redacción en el camino de sqlcmd
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC57 la credencial no sale en el mensaje tomado de stdout — encontré [zzz-valor-de-prueba-A1B2C3D4E5] y no debería estar
      FAIL  AC57 (control) el mensaje tomado de stdout pasa por la redacción — no encontré [[redactado]] en la salida
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- Las 32 caen, y las 64 corridas verdes, la del árbol real y la restaurada de cada una, salen `exit=0 fail=0`. Son las 29 de la primera versión más tres nuevas, de las correcciones de la ronda 1: `AC56 (d)`, `AC57 (c)` y `AC57 (d)`. `AC56 (c)` ahora apaga el chequeo del nombre, que reemplazó al del prefijo.
- **`AC53` (d)** corre una vez por palabra, y cada una tira su caso. `OPENQUERY` tira además el caso 8 de Patrick, que desde v25 se rechaza por esa palabra.

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC53 a AC57 (contract v25). Cada una cambia una
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
echo "árbol $(git rev-parse --short HEAD)"; echo
mutar "AC53 (a) la regla entera apagada" "$LB" "$TL" \
  "if (dialecto === 'sqlserver' && SENTENCIA_NO_LECTURA_SQLSERVER.test(sentencia)) {" \
  "if (false && dialecto === 'sqlserver' && SENTENCIA_NO_LECTURA_SQLSERVER.test(sentencia)) {"
mutar "AC53 (b) sin borde de palabra a la izquierda" "$LB" "$TL" \
  "const SENTENCIA_NO_LECTURA_SQLSERVER = /(^|[^A-Za-z0-9_])(" \
  "const SENTENCIA_NO_LECTURA_SQLSERVER = /(^|)("
mutar "AC53 (c) la regla mira el SQL sin normalizar" "$LB" "$TL" \
  "SENTENCIA_NO_LECTURA_SQLSERVER.test(sentencia)" \
  "SENTENCIA_NO_LECTURA_SQLSERVER.test(String(sql))"
for w in WAITFOR WHILE GRANT REVOKE DENY USE DBCC SET DECLARE BEGIN BACKUP RESTORE KILL SHUTDOWN OPENROWSET OPENQUERY OPENDATASOURCE; do
  lista="WAITFOR|WHILE|GRANT|REVOKE|DENY|USE|DBCC|SET|DECLARE|BEGIN|BACKUP|RESTORE|KILL|SHUTDOWN|OPENROWSET|OPENQUERY|OPENDATASOURCE"
  sin="$(printf '%s' "$lista" | tr '|' '\n' | grep -vx "$w" | paste -sd'|' -)"
  mutar "AC53 (d) sin la palabra $w" "$LB" "$TL" "[^A-Za-z0-9_])($lista)(" "[^A-Za-z0-9_])($sin)("
done
mutar "AC54 sin -t" "$CX" "$TS" \
  "'-N', 'true', '-C', '-t', String(TIMEOUT_CONSULTA_SQLSERVER_S)," "'-N', 'true', '-C',"
mutar "AC55 (a) Postgres sin PGSSLMODE" "$CX" "$TS" "      PGSSLMODE: 'require',
" ""
mutar "AC55 (b) sqlcmd sin -N true" "$CX" "$TS" "'-N', 'true', '-C', '-t'," "'-C', '-t',"
mutar "AC55 (c) sqlcmd sin -C" "$CX" "$TS" "'-N', 'true', '-C', '-t'," "'-N', 'true', '-t',"
mutar "AC56 (a) el servidor no limpia al arrancar" "$SV" "$TS" "  conexion.limpiarTemporalesHuerfanos();
" ""
mutar "AC56 (b) borra sin mirar la edad" "$CX" "$TS" "if (!st.isDirectory() || ahora - st.mtimeMs < edad) continue;" "if (!st.isDirectory()) continue;"
mutar "AC56 (c) borra sin mirar el nombre" "$CX" "$TS" "    if (!NOMBRE_TEMP.test(nombres[i])) continue;
" ""
mutar "AC56 (d) acepta cualquier nombre con el prefijo" "$CX" "$TS" \
  "if (!NOMBRE_TEMP.test(nombres[i])) continue;" "if (nombres[i].indexOf(PREFIJO_TEMP) !== 0) continue;"
mutar "AC57 (a) el error se lee sólo de stderr" "$CX" "$TS" \
  "? errorDeSqlcmd(r.stdout) : r.stderr;" "? r.stderr : r.stderr;"
mutar "AC57 (b) stdout se lee también cuando el proceso no falló" "$CX" "$TS" \
  "entrada.dialecto === 'sqlserver' && r.status !== 0 && String(r.stderr || '').trim() === ''" \
  "entrada.dialecto === 'sqlserver' && String(r.stderr || '').trim() === ''"
mutar "AC57 (c) toma stdout entero, sin buscar el Msg" "$CX" "$TS" \
  "? errorDeSqlcmd(r.stdout) : r.stderr;" "? r.stdout : r.stderr;"
mutar "AC57 (d) sin redacción en el camino de sqlcmd" "$CX" "$TS" \
  "const salidaError = redactar(textoError, sensibles);" \
  "const salidaError = entrada.dialecto === 'sqlserver' ? String(textoError) : redactar(textoError, sensibles);"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Verificación en vivo, con el servidor del repo — salida literal

```
árbol da93f90
1) AC55 Postgres: la sesión va cifrada
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
2) AC55 SQL Server: conecta con -N true -C -t 60
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
3) AC57 un error de SQL Server llega con su mensaje
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "Msg 300, Level 14, State 1, Server EC2AMAZ-2RGHL0C, Line 1\nVIEW SERVER STATE permission was denied on object 'server', database 'master'." }
4) AC53 WAITFOR se rechaza antes de conectar
{ "error": "no_es_lectura", "codigo": 4, "motivo": "sentencia_no_permitida", "sentencia": "SELECT 1 WAITFOR DELAY ''" }
Árbol al terminar: limpio
```

- **`AC55`**: Postgres va con TLS 1.3, y SQL Server responde con `-N true -C -t 60`. **Ninguno de los dos verifica el certificado del servidor** (`D70`, `D71`).
- **`AC57`**: el error de SQL Server llega con su mensaje. Antes de v25 llegaba vacío.
- **`AC53`**: `WAITFOR` se rechaza con código 4 y no llega a conectar.
- **`AC54`**: el corte a los 60 s contra el motor no se midió (`D76`).
- **El plugin instalado no cambió**: esto es el servidor del árbol de trabajo. Para usar v25 desde Claude Code hay que reinstalar el plugin y reiniciar la sesión (`D56`).

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v25, con el servidor del repo (no el instalado),
# contra las bases reales. Sólo consultas de lectura; ninguna credencial pasa
# por esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
echo "árbol $(git rev-parse --short HEAD)"
echo "1) AC55 Postgres: la sesión va cifrada"; call proveedores-dev "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
echo "2) AC55 SQL Server: conecta con -N true -C -t 60"; call compras "SELECT 1 AS uno"
echo "3) AC57 un error de SQL Server llega con su mensaje"; call compras "SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID"
echo "4) AC53 WAITFOR se rechaza antes de conectar"; call compras "SELECT 1 WAITFOR DELAY '00:00:01'"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 4. Binding AC ↔ test

| AC | Asserts |
|---|---|
| `AC53` | `SDD/tests/test_lista_blanca.sh`: `AC53 rechaza en sqlserver <palabra> …` (17, con el motivo exacto) y `AC53 acepta en <dialecto> …` (3) |
| `AC54` | `SDD/tests/test_servidor_mcp.sh`: `AC54 sqlcmd lleva -t 60 …` |
| `AC55` | `SDD/tests/test_servidor_mcp.sh`: `AC55 sqlcmd exige el cifrado con -N true`, `AC55 sqlcmd lleva -C …` y `AC55 psql exige TLS …`; más la parte `manual-only` del §3 |
| `AC56` | `SDD/tests/test_servidor_mcp.sh`: `AC56 …` (4: huérfano, reciente, ajeno, y con el prefijo pero sin el nombre de `mkdtemp`) |
| `AC57` | `SDD/tests/test_servidor_mcp.sh`: `AC57 …` (8: mensaje, credencial redactada y su control, error después de filas —dos—, corte por `-t` y corrida exitosa con el dato); más la parte `manual-only` del §3 |
| `AC51`, caso 8 | Cambió su veredicto esperado en `casos-adversariales-lista-blanca.js`; su consulta no se tocó. Verificado cargando los dos archivos y comparando los 21 casos campo por campo: sólo difiere el veredicto del 8 |
