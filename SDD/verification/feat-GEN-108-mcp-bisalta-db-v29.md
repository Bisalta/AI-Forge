# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-aviso-aislamiento` · **Commit**: `4c51a3b` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-30T22:51:59Z
- Tree: `86f0a1ca378d7fa48b922788d6637f9315aff70d` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-30T22:49:04Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-30T22:49:04Z | verde |
| 3 | type-check | — | — | 2026-09-30T22:49:05Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-30T22:49:05Z | verde |
| 5 | integration | — | — | 2026-09-30T22:50:29Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-30T22:50:29Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-30T22:50:29Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-30T22:50:29Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-30T22:50:29Z | verde |
| 10 | smoke manual | — | — | 2026-09-30T22:50:32Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-30T22:50:32Z | verde |

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

# Addendum del planner — v29 (NO lo escribió el runner)

Salida literal de los scripts, pegados al final de cada sección. Las mutaciones y la medición en vivo corrieron sobre el árbol del código sellado arriba (`4c51a3b`), con el árbol limpio al empezar y al terminar; cada salida dice sobre qué commit corrió.

## 1. En vivo, servidor del repo

```
árbol 4c51a3b
### AC62: SQL Server trae aislamiento y aviso antes de las filas, y el nivel coincide con el de la sesión
{ "conexion": "compras", "dialecto": "sqlserver", "aislamiento": "READ UNCOMMITTED", "aviso": "Corrió en READ UNCOMMITTED: puede incluir filas que otra transacción todavía no confirmó y, si alguien escribía mientras tanto, filas leídas dos veces o salteadas. Un COUNT o un total pueden estar mal.", "filas": [ { "nivel": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC62: Postgres no trae ninguno de los dos
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v29 (AC62), con el servidor del repo, contra las
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
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC61` (reescritas) y `AC62` — salida literal

```
árbol 4c51a3b

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
- mutado:             exit=1 fail=3
      FAIL  AC61 sqlcmd recibe el nivel de aislamiento antes de la consulta, y la consulta intacta — no encontré [ARG -Q|ARG SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT 1|] en la salida
      FAIL  AC62 la respuesta de sqlserver informa el nivel de aislamiento
      FAIL  AC62 la respuesta de sqlserver trae el aviso — no encontré ["aviso":"Corrió en READ UNCOMMITTED] en la salida
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

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC61 y AC62 (contract v29). Cada una cambia una
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
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. Cada respuesta de SQL Server ' +" "con un límite de 60 s por consulta. Cada respuesta de SQL Server ' +"
mutar "AC61 (e) sin la frase de las filas repetidas o salteadas" "$SV" "$TS" \
  "'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. Cada respuesta de SQL Server ' +" "'todavía no confirmó. Cada respuesta de SQL Server ' +"
mutar "AC61 (f) sin el corte con el error 601" "$SV" "$TS" \
  "pueden dar mal) o cortar con el error 601. Cada respuesta" "pueden dar mal). Cada respuesta"
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
  ": puede incluir filas que ' +
  'otra transacción todavía no confirmó y, si alguien escribía mientras tanto, filas leídas dos veces o ' +" ": si alguien escribía mientras tanto, puede incluir filas leídas dos veces o ' +"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Linter de closure

```
$ bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md
exit 0
```
