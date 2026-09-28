# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `10c519f` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-28T18:21:43Z
- Tree: `41913a7f1950974d16bba165b7820be880569d88` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-28T18:19:02Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-28T18:19:02Z | verde |
| 3 | type-check | — | — | 2026-09-28T18:19:03Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-28T18:19:03Z | verde |
| 5 | integration | — | — | 2026-09-28T18:20:20Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-28T18:20:20Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-28T18:20:20Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-28T18:20:20Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-28T18:20:20Z | verde |
| 10 | smoke manual | — | — | 2026-09-28T18:20:22Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-28T18:20:22Z | verde |

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
secret-scan: sin hallazgos sobre 187 archivos versionados (1 excluido: self)
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

La escalera de arriba se corrió sobre `10c519f`, con las correcciones de las rondas 1 y 2 de la review de v27. Las mediciones, las mutaciones y la verificación en vivo se corrieron sobre `bf0107f`, el commit que agregó la escalera: el código y los tests son los de `10c519f`. Esta versión del report reemplaza a las de `3092cae` (correo en claro) y `5da2146` (§1 reformateado a mano), que quedan en el historial.

**Una corrida roja antes.** La escalera de `5d45bac` salió con el gate 9 en rojo, porque un comentario decía "secreto:" seguido de texto. No se commiteó: el commit está condicionado a `"red":0` (`RT56`). Se corrigió en `d1fb3d0`.

## 1. Mediciones de privacidad y de D71 — salida cruda del script

Las consultas sólo **cuentan** sesiones: no leen el nombre ni la consulta de nadie. Las reglas del security group se cuentan por tipo de origen, sin imprimir direcciones.

```
árbol bf0107f
### 1. Qué ve claude_lectura de las sesiones de otros roles
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "sesiones_de_otros_roles": "10", "con_application_name_visible": "4", "con_consulta_oculta": "10", "roles_distintos": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### 2. Qué registra el motor
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "log_connections": "off", "log_line_prefix": "%t:%r:%u@%d:[%p]:", "log_statement": "none", "log_min_duration_statement": "-1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### 3. Performance Insights en las instancias del cluster
$ aws rds describe-db-instances --region us-east-1 --query "DBInstances[?DBClusterIdentifier=='sistemas-costruplaza-db'].{instancia:DBInstanceIdentifier,pi:PerformanceInsightsEnabled}" --output json
[
    {
        "instancia": "sistemas-costruplaza-db-instance-1",
        "pi": false
    },
    {
        "instancia": "sistemas-costruplaza-db-instance-1-reader",
        "pi": false
    }
]
### 4. Export de logs a CloudWatch
$ aws rds describe-db-clusters --region us-east-1 --db-cluster-identifier sistemas-costruplaza-db --query "DBClusters[0].EnabledCloudwatchLogsExports" --output json
null
### 5. D71: orígenes que admite el security group de la instancia de SQL Server (contados, sin direcciones)
$ aws ec2 describe-instances --region us-east-1 --filters Name=private-ip-address,Values=10.24.40.137 --query 'Reservations[].Instances[].{ip_publica:PublicIpAddress,cantidad_de_security_groups:length(SecurityGroups)}' --output json
[
    {
        "ip_publica": null,
        "cantidad_de_security_groups": 1
    }
]
$ aws ec2 describe-security-groups --region us-east-1 --group-ids $SG --query 'SecurityGroups[0].IpPermissions' --output json | python3 -c <cuenta por tipo de origen; ver el script>
puertos=tcp 1433-1433  origenes_privados=4 origenes_publicos=0 otros_sg=0
puertos=tcp 0-65535    origenes_privados=1 origenes_publicos=2 otros_sg=0
puertos=todos          origenes_privados=3 origenes_publicos=1 otros_sg=0
puertos=tcp 22-22      origenes_privados=1 origenes_publicos=0 otros_sg=0
puertos=tcp 3389-3389  origenes_privados=1 origenes_publicos=1 otros_sg=0
Árbol al terminar: limpio
```

- **Cualquier login conectado a la réplica ve el nombre de la sesión**, aunque no la consulta (medición 1). Es simétrico. Por eso viaja un seudónimo y no el correo.
- **No queda registro del nombre** (mediciones 2 a 4): no hay log de conexiones, el prefijo de log no incluye la aplicación (`%a`), no hay export a CloudWatch y Performance Insights está desactivado.
- **D71** (medición 5): la instancia no tiene IP pública, pero su security group admite, además de rangos privados, **orígenes públicos puntuales** por todo TCP, por todos los puertos y por el 3389. Por eso la condición "sólo por la VPN" no está verificada (contract, "Cambios v26 → v27").

### El script

```bash
#!/usr/bin/env bash
# Mediciones de privacidad de v27 (AC60), con el servidor del repo contra la
# réplica de Postgres, y con aws rds sobre el cluster. Las consultas sólo
# CUENTAN sesiones: no leen el nombre ni la consulta de nadie. La salida es
# la del plugin tal cual (JSON de la herramienta), sin reformatear.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### 1. Qué ve claude_lectura de las sesiones de otros roles"
call proveedores-dev "SELECT count(*) FILTER (WHERE usename IS DISTINCT FROM current_user) AS sesiones_de_otros_roles, count(*) FILTER (WHERE usename IS DISTINCT FROM current_user AND coalesce(application_name,'') <> '') AS con_application_name_visible, count(*) FILTER (WHERE usename IS DISTINCT FROM current_user AND query = '<insufficient privilege>') AS con_consulta_oculta, count(DISTINCT usename) FILTER (WHERE usename IS DISTINCT FROM current_user) AS roles_distintos FROM pg_stat_activity"
echo "### 2. Qué registra el motor"
call proveedores-dev "SELECT current_setting('log_connections') AS log_connections, current_setting('log_line_prefix') AS log_line_prefix, current_setting('log_statement') AS log_statement, current_setting('log_min_duration_statement') AS log_min_duration_statement"
echo "### 3. Performance Insights en las instancias del cluster"
echo "\$ aws rds describe-db-instances --region us-east-1 --query \"DBInstances[?DBClusterIdentifier=='sistemas-costruplaza-db'].{instancia:DBInstanceIdentifier,pi:PerformanceInsightsEnabled}\" --output json"
aws rds describe-db-instances --region us-east-1 --query "DBInstances[?DBClusterIdentifier=='sistemas-costruplaza-db'].{instancia:DBInstanceIdentifier,pi:PerformanceInsightsEnabled}" --output json
echo "### 4. Export de logs a CloudWatch"
echo "\$ aws rds describe-db-clusters --region us-east-1 --db-cluster-identifier sistemas-costruplaza-db --query \"DBClusters[0].EnabledCloudwatchLogsExports\" --output json"
aws rds describe-db-clusters --region us-east-1 --db-cluster-identifier sistemas-costruplaza-db --query "DBClusters[0].EnabledCloudwatchLogsExports" --output json
echo "### 5. D71: orígenes que admite el security group de la instancia de SQL Server (contados, sin direcciones)"
echo "\$ aws ec2 describe-instances --region us-east-1 --filters Name=private-ip-address,Values=10.24.40.137 --query 'Reservations[].Instances[].{ip_publica:PublicIpAddress,cantidad_de_security_groups:length(SecurityGroups)}' --output json"
SG="$(aws ec2 describe-instances --region us-east-1 --filters Name=private-ip-address,Values=10.24.40.137 --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' --output text)"
aws ec2 describe-instances --region us-east-1 --filters Name=private-ip-address,Values=10.24.40.137 --query 'Reservations[].Instances[].{ip_publica:PublicIpAddress,cantidad_de_security_groups:length(SecurityGroups)}' --output json
echo "\$ aws ec2 describe-security-groups --region us-east-1 --group-ids \$SG --query 'SecurityGroups[0].IpPermissions' --output json | python3 -c <cuenta por tipo de origen; ver el script>"
aws ec2 describe-security-groups --region us-east-1 --group-ids "$SG" --query 'SecurityGroups[0].IpPermissions' --output json | python3 -c '
import json, sys, ipaddress
reglas = json.load(sys.stdin)
for r in reglas:
    puertos = "todos" if r["IpProtocol"] == "-1" else "%s %s-%s" % (r["IpProtocol"], r.get("FromPort"), r.get("ToPort"))
    publicas = privadas = 0
    for c in r.get("IpRanges", []):
        red = ipaddress.ip_network(c["CidrIp"], strict=False)
        if red.is_private: privadas += 1
        else: publicas += 1
    print("puertos=%-14s origenes_privados=%d origenes_publicos=%d otros_sg=%d" % (puertos, privadas, publicas, len(r.get("UserIdGroupPairs", []))))
'
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 2. Mutaciones de `AC29` y `AC60` — salida literal

```
árbol bf0107f

### AC60 (a) PGAPPNAME sin el seudónimo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y el seudónimo de quien consulta
      FAIL  AC60 (control) las dos consultas llevan el seudónimo
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 de un rol asumido el seudónimo sale del nombre de sesión
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
- verde (restaurado): exit=0 fail=0

### AC60 (b) sqlcmd sin -H
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y el seudónimo — no encontré [ARG -H|ARG claude_lectura/u-349175ad|] en la salida
- verde (restaurado): exit=0 fail=0

### AC60 (c) sin guardar el seudónimo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC60 la identidad se pide una sola vez por proceso
      FAIL  AC60 un ARN sin nombre (root) se guarda como ? y no se vuelve a pedir
- verde (restaurado): exit=0 fail=0

### AC60 (d) el seudónimo se pide al cargar el módulo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=4
      FAIL  AC31 con una conexión desconocida no se invoca el binario aws
      FAIL  una escritura se rechaza ANTES de resolver el secreto y de conectar
      FAIL  AC60 un SQL rechazado no invoca aws
      FAIL  AC60 un sts que no responde se corta rápido (menos de 20 s)
- verde (restaurado): exit=0 fail=0

### AC60 (e) un fallo de sts frena la consulta
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=3
      FAIL  AC60 si sts falla, la consulta no se frena — encontré ["error"] y no debería estar
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 (control) la consulta con sts lento igual responde — encontré ["error"] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC60 (f) el nombre en claro en lugar del seudónimo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=9
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y el seudónimo de quien consulta
      FAIL  AC60 el correo de quien consulta no viaja en claro en Postgres — encontré [persona.prueba@ejemplo.com] y no debería estar
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y el seudónimo — no encontré [ARG -H|ARG claude_lectura/u-349175ad|] en la salida
      FAIL  AC60 el correo de quien consulta no viaja en claro en SQL Server — encontré [persona.prueba@ejemplo.com] y no debería estar
      FAIL  AC60 (control) las dos consultas llevan el seudónimo
      FAIL  AC60 de un rol asumido el seudónimo sale del nombre de sesión
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
      FAIL  AC60 --seudonimo imprime el seudónimo propio, con la identidad de AWS
      FAIL  AC60 --seudonimo no imprime el nombre — encontré [persona.prueba@ejemplo.com] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC60 (g) usa el ARN entero
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y el seudónimo de quien consulta
      FAIL  AC60 sqlcmd lleva -H con el usuario del secreto y el seudónimo — no encontré [ARG -H|ARG claude_lectura/u-349175ad|] en la salida
      FAIL  AC60 (control) las dos consultas llevan el seudónimo
      FAIL  AC60 de un rol asumido el seudónimo sale del nombre de sesión
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
      FAIL  AC60 --seudonimo imprime el seudónimo propio, con la identidad de AWS
- verde (restaurado): exit=0 fail=0

### AC60 (h) guarda el ? de un sts fallido
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC60 si sts falla, la consulta siguiente vuelve a pedir la identidad
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
- verde (restaurado): exit=0 fail=0

### AC60 (i) no guarda el ? de un ARN sin nombre
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 un ARN sin nombre (root) se guarda como ? y no se vuelve a pedir
- verde (restaurado): exit=0 fail=0

### AC60 (j) sts sin --region
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 sts se llama con la región de la entrada y sólo pide el ARN
- verde (restaurado): exit=0 fail=0

### AC60 (k) el límite de sts es el corte de proceso
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 un sts que no responde se corta rápido (menos de 20 s)
- verde (restaurado): exit=0 fail=0

### AC60 (l) --seudonimo imprime el ARN
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC60 --seudonimo imprime el seudónimo propio, con la identidad de AWS
      FAIL  AC60 --seudonimo no imprime el nombre — encontré [persona.prueba@ejemplo.com] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC60 (m) --seudonimo sale 0 sin seudónimo
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 --seudonimo sale 1 cuando no hay seudónimo
- verde (restaurado): exit=0 fail=0

### AC60 (n) el modo se elige con indexOf
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC60 --seudonimo como valor de --sql no activa el modo seudónimo — no encontré ["error": "conexion_desconocida"] en la salida
- verde (restaurado): exit=0 fail=0

### AC29 (a) sin PGAPPNAME
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
      FAIL  AC29 el comando lleva el usuario del secreto en PGAPPNAME — no encontré [PGAPPNAME claude_lectura] en la salida
      FAIL  AC60 PGAPPNAME lleva el usuario del secreto y el seudónimo de quien consulta
      FAIL  AC60 (control) las dos consultas llevan el seudónimo
      FAIL  AC60 si sts falla, la identidad es ?
      FAIL  AC60 de un rol asumido el seudónimo sale del nombre de sesión
      FAIL  AC60 la segunda consulta ya lleva el seudónimo
- verde (restaurado): exit=0 fail=0

### AC29 (b) application_name de vuelta en PGOPTIONS
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC29 PGOPTIONS no lleva application_name (psql le gana al -c) — encontré [application_name] y no debería estar
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- Caen las 16, y las 32 corridas verdes salen `exit=0 fail=0`.

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
mutar "AC60 (a) PGAPPNAME sin el seudónimo" "$CX" "$TS" \
  'PGAPPNAME: nombreDeSesion(usuario, identidad),' 'PGAPPNAME: usuario,'
mutar "AC60 (b) sqlcmd sin -H" "$CX" "$TS" \
  "      '-H', nombreDeSesion(usuario, identidad),
" ''
mutar "AC60 (c) sin guardar el seudónimo" "$CX" "$TS" \
  '  identidadResuelta = seudonimo(nombreDeArn(r.stdout));
  return identidadResuelta;' '  return seudonimo(nombreDeArn(r.stdout));'
mutar "AC60 (d) el seudónimo se pide al cargar el módulo" "$CX" "$TS" \
  'module.exports = {' "resolverIdentidad('us-east-1');
module.exports = {"
mutar "AC60 (e) un fallo de sts frena la consulta" "$CX" "$TS" \
  '  if (r.error || r.status !== 0) return IDENTIDAD_DESCONOCIDA;
  identidadResuelta' "  if (r.error || r.status !== 0) throw fallo(5, 'secreto_inaccesible', 'sts');
  identidadResuelta"
mutar "AC60 (f) el nombre en claro en lugar del seudónimo" "$CX" "$TS" \
  'identidadResuelta = seudonimo(nombreDeArn(r.stdout));' 'identidadResuelta = nombreDeArn(r.stdout);'
mutar "AC60 (g) usa el ARN entero" "$CX" "$TS" \
  'seudonimo(nombreDeArn(r.stdout))' 'seudonimo(String(r.stdout).trim())'
mutar "AC60 (h) guarda el ? de un sts fallido" "$CX" "$TS" \
  '  if (r.error || r.status !== 0) return IDENTIDAD_DESCONOCIDA;
  identidadResuelta' '  if (r.error || r.status !== 0) { identidadResuelta = IDENTIDAD_DESCONOCIDA; return IDENTIDAD_DESCONOCIDA; }
  identidadResuelta'
mutar "AC60 (i) no guarda el ? de un ARN sin nombre" "$CX" "$TS" \
  '  identidadResuelta = seudonimo(nombreDeArn(r.stdout));
  return identidadResuelta;' '  const s0 = seudonimo(nombreDeArn(r.stdout));
  if (s0 !== IDENTIDAD_DESCONOCIDA) identidadResuelta = s0;
  return s0;'
mutar "AC60 (j) sts sin --region" "$CX" "$TS" \
  "    '--region', region,
    '--query', 'Arn'," "    '--query', 'Arn',"
mutar "AC60 (k) el límite de sts es el corte de proceso" "$CX" "$TS" \
  'timeout: TIMEOUT_STS_MS });' 'timeout: TIMEOUT_PROCESO_MS });'
mutar "AC60 (l) --seudonimo imprime el ARN" "$SV" "$TS" \
  'const propio = conexion.resolverIdentidad(region);' "const propio = require('child_process').execFileSync('aws', ['sts', 'get-caller-identity'], { encoding: 'utf8' }).trim();"
mutar "AC60 (m) --seudonimo sale 0 sin seudónimo" "$SV" "$TS" \
  "  if (propio === '?') {" "  if (false) {"
mutar "AC60 (n) el modo se elige con indexOf" "$SV" "$TS" \
  "if (argv[0] === '--seudonimo' || argv[0] === '--seudonimo-de') {" "if (argv.indexOf('--seudonimo') !== -1 || argv.indexOf('--seudonimo-de') !== -1) {"
mutar "AC29 (a) sin PGAPPNAME" "$CX" "$TS" \
  '      PGAPPNAME: nombreDeSesion(usuario, identidad),
' ''
mutar "AC29 (b) application_name de vuelta en PGOPTIONS" "$CX" "$TS" \
  "PGOPTIONS: '-c default_transaction_read_only=on'," "PGOPTIONS: '-c default_transaction_read_only=on -c application_name=otra',"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Verificación en vivo, con el servidor del repo — salida literal

```
árbol bf0107f
### Postgres: application_name de la propia sesión (tiene que ser <usuario>/u-<8 hex>, sin correo)
{ "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "application_name": "claude_lectura/u-34a4b783", "usename": "claude_lectura" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### SQL Server: HOST_NAME() de la propia sesión (ídem)
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "estacion": "bisalta_lectura/u-34a4b783", "login": "bisalta_lectura" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
### El seudónimo propio, con --seudonimo (no imprime el nombre)
u-34a4b783
Árbol al terminar: limpio
```

- En los dos motores, la sesión muestra `<usuario del secreto>/u-<8 hex>`, sin correo. `--seudonimo` imprime el seudónimo y no el nombre.
- El seudónimo que aparece es el de Ian. Es público por diseño: se calcula a partir de su nombre.

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v27 (AC60, seudónimo), con el servidor del repo, contra las
# bases reales. Sólo lectura de la propia sesión; ninguna credencial pasa por
# esta salida.
set -u
cd "$(git rev-parse --show-toplevel)"
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
echo "árbol $(git rev-parse --short HEAD)"
echo "### Postgres: application_name de la propia sesión (tiene que ser <usuario>/u-<8 hex>, sin correo)"
call proveedores-dev "SELECT application_name, usename FROM pg_stat_activity WHERE pid = pg_backend_pid()"
echo "### SQL Server: HOST_NAME() de la propia sesión (ídem)"
call compras "SELECT HOST_NAME() AS estacion, SUSER_NAME() AS login"
echo "### El seudónimo propio, con --seudonimo (no imprime el nombre)"
node plugins/bisalta-db/scripts/servidor-mcp.js --seudonimo
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 4. Binding AC ↔ test (`SDD/tests/test_servidor_mcp.sh`)

| AC | Asserts |
|---|---|
| `AC60` | `AC60 …`, 22 asserts. Son los 20 de la ronda 1 más dos de `--seudonimo`: sale 1 sin seudónimo, y como valor de `--sql` no activa el modo. Más la parte `manual-only` del §3 |
| `AC29` | Los asserts de v15 siguen: `PGAPPNAME` empieza con el usuario del secreto, y `PGOPTIONS` no lleva `application_name` |
