# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `6740fb0` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-25T13:00:34Z
- Tree: `49571b2568439d5d255f110b2058e60e9f21d7cb` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-25T12:59:26Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-25T12:59:26Z | verde |
| 3 | type-check | — | — | 2026-09-25T12:59:28Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-25T12:59:28Z | verde |
| 5 | integration | — | — | 2026-09-25T13:00:00Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-25T13:00:00Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-25T13:00:00Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-25T13:00:00Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-25T13:00:00Z | verde |
| 10 | smoke manual | — | — | 2026-09-25T13:00:01Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-25T13:00:01Z | verde |

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
secret-scan: sin hallazgos sobre 183 archivos versionados (1 excluido: self)
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

La escalera de arriba se corrió sobre `6740fb0`. Las mutaciones y la verificación en vivo se corrieron sobre `46c6185`, el commit que agregó la escalera: el código y los tests son los de `6740fb0`.

## 1. Las mediciones que decidieron el diseño (25-sep, antes de cambiar el código)

Se corrieron con el servidor del repo contra las bases reales, sobre el árbol de `cd4b6b3` (v24). Las banderas de las pruebas 2 y 3 se agregaron a `conexion.js` sólo mientras duró cada corrida, y se restauraron con `git checkout`.

| # | Qué se midió | Resultado |
|---|---|---|
| 1 | Postgres con el `sslmode` por omisión (`prefer`): `pg_stat_ssl` de la propia sesión | `ssl = t`, `TLSv1.3`. Ya cifraba, pero `prefer` no impide caer a texto plano |
| 2 | SQL Server con `-N true`, sin `-C` | `conexion_fallida`: el certificado de la instancia no es de una autoridad en la que confíe el cliente |
| 3 | SQL Server con `-N true -C` | conecta y responde |
| 4 | SQL Server: dónde escribe `sqlcmd` sus errores, con una consulta que falla por permiso | stderr con 0 bytes y stdout con 138: el mensaje entero va por stdout |
| 5 | SQL Server: si el cifrado se puede leer desde la propia sesión | No se puede. `CONNECTIONPROPERTY('encrypt_option')` devuelve `NULL`, y `sys.dm_exec_connections` exige `VIEW SERVER STATE`, que el login no tiene. Por eso el cifrado de SQL Server se verifica del lado del cliente (pruebas 2 y 3), no desde el motor |

## 2. Mutaciones de `AC53` a `AC57` — salida literal

```
árbol 46c6185

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

### AC56 (c) borra sin mirar el prefijo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC56 no borra directorios que no son del plugin
- verde (restaurado): exit=0 fail=0

### AC57 (a) el error se lee sólo de stderr
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC57 el mensaje de un error de sqlcmd no llega vacío — no encontré [VIEW SERVER STATE permission was denied] en la salida
      FAIL  AC57 el corte por -t de sqlcmd se informa como tiempo_agotado — no encontré ["error":"tiempo_agotado"] en la salida
- verde (restaurado): exit=0 fail=0

### AC57 (b) stdout se lee también cuando el proceso no falló
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC57 una corrida exitosa cuyo dato dice Timeout expired no es un error — encontré ["error"] y no debería estar
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- Las 29 caen, y las 58 corridas verdes, la del árbol real y la restaurada de cada una, salen `exit=0 fail=0`.
- **`AC53` (d)** corre una vez por palabra. Cada una tira exactamente su caso. `OPENQUERY` tira además el caso 8 de Patrick, que desde v25 se rechaza por esa palabra.
- **`AC57` (a)** tira dos asserts, el del mensaje y el del corte por `-t`: son las dos consecuencias del mismo defecto.

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
mutar "AC56 (c) borra sin mirar el prefijo" "$CX" "$TS" "    if (nombres[i].indexOf(PREFIJO_TEMP) !== 0) continue;
" ""
mutar "AC57 (a) el error se lee sólo de stderr" "$CX" "$TS" \
  "? r.stdout : r.stderr;" "? r.stderr : r.stderr;"
mutar "AC57 (b) stdout se lee también cuando el proceso no falló" "$CX" "$TS" \
  "entrada.dialecto === 'sqlserver' && r.status !== 0 && String(r.stderr || '').trim() === ''" \
  "entrada.dialecto === 'sqlserver' && String(r.stderr || '').trim() === ''"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Verificación en vivo, con el servidor del repo — salida literal

```
árbol 46c6185
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

- **`AC55`**: Postgres, con `PGSSLMODE=require`, va con TLS 1.3. SQL Server responde con `-N true -C -t 60`. **Ninguno de los dos verifica el certificado del servidor** (`D70`, `D71`).
- **`AC57`**: el error de SQL Server llega con su mensaje. Antes de v25 llegaba vacío (medición 4).
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
| `AC55` | `SDD/tests/test_servidor_mcp.sh`: `AC55 sqlcmd exige el cifrado con -N true`, `AC55 sqlcmd lleva -C …`, `AC55 psql exige TLS …`; más la parte `manual-only` del §3 |
| `AC56` | `SDD/tests/test_servidor_mcp.sh`: `AC56 …` (3: huérfano, reciente y ajeno) |
| `AC57` | `SDD/tests/test_servidor_mcp.sh`: `AC57 …` (4); más la parte `manual-only` del §3 |
| `AC51`, caso 8 | cambió su veredicto esperado en `casos-adversariales-lista-blanca.js`; su consulta no se tocó (verificado cargando los dos archivos y comparando los 21 casos campo por campo: sólo difiere el veredicto del 8) |
