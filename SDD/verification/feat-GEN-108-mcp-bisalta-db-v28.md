# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `a2a2484` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-28T23:36:24Z
- Tree: `7af8909fdd124939b774459f72a2337fce1f1b7a` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-28T23:33:31Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-28T23:33:31Z | verde |
| 3 | type-check | — | — | 2026-09-28T23:33:33Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-28T23:33:33Z | verde |
| 5 | integration | — | — | 2026-09-28T23:34:58Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-28T23:34:58Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-28T23:34:58Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-28T23:34:58Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-28T23:34:58Z | verde |
| 10 | smoke manual | — | — | 2026-09-28T23:35:01Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-28T23:35:01Z | verde |

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
secret-scan: sin hallazgos sobre 188 archivos versionados (1 excluido: self)
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

# Addendum del planner — v28 (NO lo escribió el runner)

Todo lo de abajo es salida literal de los scripts, que se pegan al final de cada sección. Los corrió el planner sobre `eb50eda`, con el árbol limpio al empezar y al terminar. La escalera de arriba es la del runner.

## 1. Antes del cambio — el plugin instalado (v27)

Medido a las 16:3x del 28-sep, con la herramienta `consultar` del plugin instalado en la sesión, que todavía corría el código de v27. Es la respuesta tal cual:

```
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "nivel": "2" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
```

La consulta fue `SELECT transaction_isolation_level AS nivel FROM sys.dm_exec_sessions WHERE session_id = @@SPID`. `2` es `READ COMMITTED`.

## 2. Después del cambio — servidor del repo, salida cruda

`1` es `READ UNCOMMITTED`. Las seis bases del catálogo tienen `rcsi = 0`, y el login no ve las demás bases de la instancia (`AC48`).

```
árbol eb50eda
### AC61: nivel de aislamiento de la propia sesión en las seis bases del catálogo (1 = READ UNCOMMITTED)
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "base": "COMPRAS", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "compras-stg", "dialecto": "sqlserver", "filas": [ { "base": "COMPRAS_STG", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "ecommerce", "dialecto": "sqlserver", "filas": [ { "base": "Ecommerce", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "ecommerce-qa", "dialecto": "sqlserver", "filas": [ { "base": "Ecommerce_qa", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "exactus", "dialecto": "sqlserver", "filas": [ { "base": "EXACTUS", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "bi", "dialecto": "sqlserver", "filas": [ { "base": "BI", "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC61: consultas con WITH y con comentarios al final y al inicio responden
{ "conexion": "bi", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "ecommerce", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### D75: READ_COMMITTED_SNAPSHOT y edición de la instancia
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "name": "COMPRAS", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "compras-stg", "dialecto": "sqlserver", "filas": [ { "name": "COMPRAS_STG", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "ecommerce", "dialecto": "sqlserver", "filas": [ { "name": "Ecommerce", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "ecommerce-qa", "dialecto": "sqlserver", "filas": [ { "name": "Ecommerce_qa", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "exactus", "dialecto": "sqlserver", "filas": [ { "name": "EXACTUS", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "bi", "dialecto": "sqlserver", "filas": [ { "name": "BI", "rcsi": "0", "snapshot": "OFF", "edicion": "Standard Edition (64-bit)", "version": "15.0.4440.1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### D73: tope de conexiones del rol
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "base": "proveedores_dev", "rol": "claude_lectura", "tope": "12" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "smartcheck-dev", "dialecto": "postgres", "filas": [ { "base": "smartcheck_dev", "rol": "claude_lectura", "tope": "12" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "conexion": "smartfleet-qa", "dialecto": "postgres", "filas": [ { "base": "smartfleet_qa", "rol": "claude_lectura", "tope": "12" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v28 (AC61, D73, D75), con el servidor del repo, contra
# las bases reales. Sólo lectura de catálogos y de la propia sesión; ninguna
# credencial pasa por esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio al empezar"; exit 1; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### AC61: nivel de aislamiento de la propia sesión en las seis bases del catálogo (1 = READ UNCOMMITTED)"
for c in compras compras-stg ecommerce ecommerce-qa exactus bi; do
  call "$c" "SELECT DB_NAME() AS base, transaction_isolation_level AS nivel FROM sys.dm_exec_sessions WHERE session_id = @@SPID"
done
echo "### AC61: consultas con WITH y con comentarios al final y al inicio responden"
call bi "WITH c AS (SELECT 1 AS uno) SELECT uno FROM c"
call compras "SELECT 1 AS uno -- comentario al final"
call compras "/* comentario de bloque al inicio */ SELECT 1 AS uno"
call ecommerce "-- comentario de línea al inicio\nSELECT 1 AS uno"
echo "### D75: READ_COMMITTED_SNAPSHOT y edición de la instancia"
for c in compras compras-stg ecommerce ecommerce-qa exactus bi; do
  call "$c" "SELECT name, is_read_committed_snapshot_on AS rcsi, snapshot_isolation_state_desc AS snapshot, CAST(SERVERPROPERTY('Edition') AS nvarchar(128)) AS edicion, CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(64)) AS version FROM sys.databases WHERE name = DB_NAME()"
done
echo "### D73: tope de conexiones del rol"
for c in proveedores-dev smartcheck-dev smartfleet-qa; do
  call "$c" "SELECT current_database() AS base, current_user AS rol, rolconnlimit AS tope FROM pg_roles WHERE rolname = current_user"
done
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Mutaciones de `AC61` — salida literal

```
árbol eb50eda

### AC61 (a) sin el prefijo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
- verde (restaurado): exit=0 fail=0

### AC61 (b) el prefijo después de la consulta
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
- verde (restaurado): exit=0 fail=0

### AC61 (c) READ COMMITTED en lugar de READ UNCOMMITTED
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
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

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC61 (contract v28). Cada una cambia una
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
  "'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; '" "'SET TRANSACTION ISOLATION LEVEL READ COMMITTED; '"
mutar "AC61 (d) sin el aviso en la descripción" "$SV" "$TS" \
  "con un límite de 60 s por consulta. En SQL Server la consulta corre en ' +
      'READ UNCOMMITTED para no bloquear a quien escribe: puede devolver filas que otra transacción ' +
      'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. ' +" "con un límite de 60 s por consulta. ' +"
mutar "AC61 (e) sin la frase de las filas repetidas o salteadas" "$SV" "$TS" \
  "'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. ' +" "'todavía no confirmó. ' +"
mutar "AC61 (f) sin el corte con el error 601" "$SV" "$TS" \
  "'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. ' +" "'confirmadas (un COUNT o un total pueden dar mal). ' +"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 4. Linter de closure sobre el contract

```
$ bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md
exit 0
```
