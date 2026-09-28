# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `d1fb0e8` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-28T13:56:23Z
- Tree: `e887372edc3814226412c809381f6c88d45f7359` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-28T13:53:52Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-28T13:53:52Z | verde |
| 3 | type-check | — | — | 2026-09-28T13:53:54Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-28T13:53:54Z | verde |
| 5 | integration | — | — | 2026-09-28T13:55:06Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-28T13:55:06Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-28T13:55:06Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-28T13:55:06Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-28T13:55:06Z | verde |
| 10 | smoke manual | — | — | 2026-09-28T13:55:08Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-28T13:55:08Z | verde |

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
secret-scan: sin hallazgos sobre 186 archivos versionados (1 excluido: self)
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

# Addendum del planner — v27 (NO lo escribió el runner)

La escalera de arriba se corrió sobre `d1fb0e8`. Las mutaciones y la verificación en vivo se corrieron sobre `b537cc0`, el commit que agregó la escalera: el código y los tests son los de `d1fb0e8`.

## 1. Mutaciones de `AC29` y `AC60` — salida literal

```
árbol b537cc0

### AC60 (a) PGAPPNAME sin la identidad
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=4
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y quién consulta
      FAIL  AC60 (control) las dos consultas llevan la identidad
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 de un rol asumido se usa la sesión, sin caracteres raros
- verde (restaurado): exit=0 fail=0

### AC60 (b) sqlcmd sin -H
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y quién consulta — no encontré [ARG -H|ARG claude_lectura/persona.prueba@ejemplo.com|] en la salida
- verde (restaurado): exit=0 fail=0

### AC60 (c) sin guardar la identidad
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 la identidad se pide una sola vez por proceso
- verde (restaurado): exit=0 fail=0

### AC60 (d) la identidad se pide al cargar el módulo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC31 con una conexión desconocida no se invoca el binario aws
      FAIL  una escritura se rechaza ANTES de resolver el secreto y de conectar
      FAIL  AC60 un SQL rechazado no invoca aws
- verde (restaurado): exit=0 fail=0

### AC60 (e) un fallo de sts frena la consulta
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC60 si sts falla, la consulta no se frena — encontré ["error"] y no debería estar
      FAIL  AC60 si sts falla, la identidad es ?
- verde (restaurado): exit=0 fail=0

### AC60 (f) sin sanear el nombre
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 de un rol asumido se usa la sesión, sin caracteres raros
- verde (restaurado): exit=0 fail=0

### AC60 (g) usa el ARN entero
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y quién consulta
      FAIL  AC60 el nombre de la sesión no lleva el número de cuenta — encontré [123456789012] y no debería estar
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y quién consulta — no encontré [ARG -H|ARG claude_lectura/persona.prueba@ejemplo.com|] en la salida
      FAIL  AC60 (control) las dos consultas llevan la identidad
      FAIL  AC60 de un rol asumido se usa la sesión, sin caracteres raros
- verde (restaurado): exit=0 fail=0

### AC29 (a) sin PGAPPNAME
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC29 el comando lleva el usuario del secreto en PGAPPNAME — no encontré [PGAPPNAME claude_lectura] en la salida
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y quién consulta
      FAIL  AC60 (control) las dos consultas llevan la identidad
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 de un rol asumido se usa la sesión, sin caracteres raros
- verde (restaurado): exit=0 fail=0

### AC29 (b) application_name de vuelta en PGOPTIONS
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC29 PGOPTIONS no lleva application_name (psql le gana al -c) — encontré [application_name] y no debería estar
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- Caen las 9, y las 18 corridas verdes salen `exit=0 fail=0`.
- **`AC60 (d)`**, pedir la identidad al cargar el módulo, tira también el assert de `AC31`: con una conexión desconocida no se invoca `aws`. Es la condición "después del secreto".

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC29 y AC60 (contract v27). Cada una cambia una
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
mutar "AC60 (a) PGAPPNAME sin la identidad" "$CX" "$TS" \
  'PGAPPNAME: nombreDeSesion(usuario, identidad),' 'PGAPPNAME: usuario,'
mutar "AC60 (b) sqlcmd sin -H" "$CX" "$TS" \
  "      '-H', nombreDeSesion(usuario, identidad),
" ''
mutar "AC60 (c) sin guardar la identidad" "$CX" "$TS" \
  '  if (nombre !== IDENTIDAD_DESCONOCIDA) identidadResuelta = nombre;
' ''
mutar "AC60 (d) la identidad se pide al cargar el módulo" "$CX" "$TS" \
  'module.exports = {' "resolverIdentidad('us-east-1');
module.exports = {"
mutar "AC60 (e) un fallo de sts frena la consulta" "$CX" "$TS" \
  '  if (r.error || r.status !== 0) return IDENTIDAD_DESCONOCIDA;
  const nombre = nombreDeArn(r.stdout);' "  if (r.error || r.status !== 0) throw fallo(5, 'secreto_inaccesible', 'sts');
  const nombre = nombreDeArn(r.stdout);"
mutar "AC60 (f) sin sanear el nombre" "$CX" "$TS" \
  "tramos[tramos.length - 1].replace(/[^A-Za-z0-9@._+-]/g, '_');" 'tramos[tramos.length - 1];'
mutar "AC60 (g) usa el ARN entero" "$CX" "$TS" \
  'const nombre = nombreDeArn(r.stdout);' 'const nombre = String(r.stdout).trim();'
mutar "AC29 (a) sin PGAPPNAME" "$CX" "$TS" \
  '      PGAPPNAME: nombreDeSesion(usuario, identidad),
' ''
mutar "AC29 (b) application_name de vuelta en PGOPTIONS" "$CX" "$TS" \
  "PGOPTIONS: '-c default_transaction_read_only=on'," "PGOPTIONS: '-c default_transaction_read_only=on -c application_name=otra',"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Verificación en vivo, con el servidor del repo — salida literal, con la identidad tapada

La salida trae el usuario IAM de Ian. Se reemplazó por `<identidad de quien consulta>` antes de pegarla, con `sed 's/<el correo>/<identidad de quien consulta>/g'`, por la regla de no dejar datos identificables de empleados. Lo demás es literal.

```
árbol b537cc0
### Postgres: application_name de la propia sesión
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "application_name": "claude_lectura/<identidad de quien consulta>", "usename": "claude_lectura" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### SQL Server: HOST_NAME() de la propia sesión
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "estacion": "bisalta_lectura/<identidad de quien consulta>", "login": "bisalta_lectura" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
Árbol al terminar: limpio
```

- **Postgres**: `application_name` es `claude_lectura/<identidad>`. Antes de v27 era `claude_lectura` a secas (medido el 28-sep).
- **SQL Server**: `HOST_NAME()` es `bisalta_lectura/<identidad>`. Antes era el nombre de la máquina, que venía por omisión de `sqlcmd`.

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v27 (AC60), con el servidor del repo, contra las
# bases reales. Sólo lectura de la propia sesión; ninguna credencial pasa por
# esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### Postgres: application_name de la propia sesión"
call proveedores-dev "SELECT application_name, usename FROM pg_stat_activity WHERE pid = pg_backend_pid()"
echo "### SQL Server: HOST_NAME() de la propia sesión"
call compras "SELECT HOST_NAME() AS estacion, SUSER_NAME() AS login"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Binding AC ↔ test (`SDD/tests/test_servidor_mcp.sh`)

| AC | Asserts |
|---|---|
| `AC60` | `AC60 …`: 9 asserts. Son el nombre en Postgres y en SQL Server, sin número de cuenta, una sola llamada por proceso y su control, un SQL rechazado no invoca `aws`, `sts` que falla no frena y deja `?`, y el rol asumido saneado. Más la parte `manual-only` del §2 |
| `AC29` | Los asserts de v15 siguen: `PGAPPNAME` empieza con el usuario del secreto, y `PGOPTIONS` no lleva `application_name` |
