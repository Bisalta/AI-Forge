# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-tenant-por-sesion` · **Commit**: `2c8c656` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-10-01T21:56:53Z
- Tree: `2bea07d9cb78ec1bfa190613ba184a38e813c9f5` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-10-01T21:53:58Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-10-01T21:53:58Z | verde |
| 3 | type-check | — | — | 2026-10-01T21:53:59Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-10-01T21:53:59Z | verde |
| 5 | integration | — | — | 2026-10-01T21:55:24Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-10-01T21:55:24Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-10-01T21:55:24Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-10-01T21:55:24Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-10-01T21:55:24Z | verde |
| 10 | smoke manual | — | — | 2026-10-01T21:55:27Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-10-01T21:55:27Z | verde |

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
secret-scan: sin hallazgos sobre 191 archivos versionados (1 excluido: self)
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

# Addendum del planner — v31 (NO lo escribió el runner)

Salida literal de los scripts, pegados al final de cada sección. Las mutaciones y la medición en vivo corrieron sobre el árbol del código sellado arriba (`2c8c656`), con el árbol limpio al empezar y al terminar; cada salida dice sobre qué commit corrió.

## 1. En vivo, servidor del repo

```
árbol 2c8c656
### AC64: smartcheck-qa con el tenant por sesión (esperado: 2998 filas, 1 tenant)
{ "conexion": "smartcheck-qa", "dialecto": "postgres", "filas": [ { "filas": "3020", "tenants": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC64: proveedores-dev, sin sesion, responde igual que antes
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### AC65: una tabla con columna token sale redactada (sólo dos filas)
{ "conexion": "smartcheck-qa", "dialecto": "postgres", "columnas_redactadas": [ "token" ], "filas": [ { "token": "[redactado]" }, { "token": "[redactado]" } ], "filas_devueltas": 2, "truncado": false, "motivo_truncado": null }
Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v31 (AC64 y AC65), con el servidor del repo, contra
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
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC64` y `AC65` — salida literal

```
árbol 2c8c656

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

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC64 y AC65 (contract v31). Cada una cambia una
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
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Linter de closure

```
$ bash plugins/sdd-flow/scripts/sdd-lint-contract.sh SDD/contracts/2026-09-18-bisalta-db-mcp.md
exit 0
```
