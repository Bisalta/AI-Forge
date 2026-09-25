# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `9446298` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-25T18:29:37Z
- Tree: `891542fcf583512510dcb95fa8e9dce3951b1ae0` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-25T18:26:56Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-25T18:26:56Z | verde |
| 3 | type-check | — | — | 2026-09-25T18:26:58Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-25T18:26:58Z | verde |
| 5 | integration | — | — | 2026-09-25T18:28:16Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-25T18:28:16Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-25T18:28:16Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-25T18:28:16Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-25T18:28:16Z | verde |
| 10 | smoke manual | — | — | 2026-09-25T18:28:18Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-25T18:28:18Z | verde |

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

# Addendum del planner — v26 (NO lo escribió el runner)

La escalera de arriba se corrió sobre `9446298`. Las mutaciones, la verificación en vivo y la lectura del bundle se corrieron sobre `196dc3e`, el commit que agregó la escalera: el código y los tests son los de `9446298`.

**Una corrida roja antes de ésta.** La primera escalera de v26 (`c85b4ea`) salió con el gate 9 en rojo: el secret-scan encontró en el bundle un patrón con forma de clave de AWS. El commit se encadenó detrás del runner sin mirar su resultado (`RT56`). Se resolvió con `AC59`, y esta escalera la reemplaza. La roja queda en el historial.

## 1. El bundle de RDS — salida literal

```
origen: https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem (descargado el 25-sep-2026 con curl --proto '=https' --tlsv1.2)
bytes: 165408
sha256: e5bb2084ccf45087bda1c9bffdea0eb15ee67f0b91646106e466714f9de3c7e3
certificados: 108
claves privadas: 0
autoridades de Amazon RDS: 108 de 108
vencidas al 25-sep-2026: 0 · vencen entre 2061-05-18 y 2125-05-20
```

```bash
#!/usr/bin/env bash
# Procedencia y contenido del bundle de RDS (AC58). No conecta a ninguna base.
set -u
cd "$(git rev-parse --show-toplevel)"
B=plugins/bisalta-db/certificados/rds-global-bundle.pem
echo "origen: https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem (descargado el 25-sep-2026 con curl --proto '=https' --tlsv1.2)"
printf 'bytes: %s\n' "$(wc -c <"$B" | tr -d ' ')"
printf 'sha256: %s\n' "$(shasum -a 256 "$B" | cut -d' ' -f1)"
printf 'certificados: %s\n' "$(grep -c 'BEGIN CERTIFICATE' "$B")"
printf 'claves privadas: %s\n' "$(grep -c 'PRIVATE KEY' "$B")"
python3 - "$B" <<'PY'
import sys, subprocess, datetime
t = open(sys.argv[1]).read()
certs = ['-----BEGIN CERTIFICATE-----' + c.split('-----END CERTIFICATE-----')[0] + '-----END CERTIFICATE-----\n'
         for c in t.split('-----BEGIN CERTIFICATE-----')[1:]]
rds = vence = 0; fechas = []
for c in certs:
    o = subprocess.run(['openssl', 'x509', '-noout', '-subject', '-enddate'], input=c, capture_output=True, text=True).stdout
    if 'OU=Amazon RDS' in o.split('\n')[0]: rds += 1
    f = datetime.datetime.strptime(o.split('notAfter=')[1].strip(), '%b %d %H:%M:%S %Y %Z'); fechas.append(f)
print('autoridades de Amazon RDS: %d de %d' % (rds, len(certs)))
print('vencidas al 25-sep-2026: %d · vencen entre %s y %s' % (sum(f < datetime.datetime(2026, 9, 25) for f in fechas), min(fechas).date(), max(fechas).date()))
PY
```

## 2. Mutaciones de `AC53` a `AC59` — salida literal

Es el script de v25 con cuatro cambios. `AC55 (a)` quita ahora la línea de `verify-full`. Hay tres mutaciones nuevas de `AC58` y tres de `AC59`, que corren contra `SDD/tests/test_secret_scan.sh`.

```
árbol 196dc3e

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
      FAIL  AC55/AC58 psql exige TLS y autentica al servidor (PGSSLMODE=verify-full) — no encontré [PGSSLMODE verify-full] en la salida
- verde (restaurado): exit=0 fail=0

### AC58 (a) vuelve a require
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC55/AC58 psql exige TLS y autentica al servidor (PGSSLMODE=verify-full) — no encontré [PGSSLMODE verify-full] en la salida
- verde (restaurado): exit=0 fail=0

### AC58 (b) sin PGSSLROOTCERT
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC58 psql apunta PGSSLROOTCERT al bundle de RDS del plugin — no encontré [certificados/rds-global-bundle.pem] en la salida
      FAIL  AC58 el archivo al que apunta PGSSLROOTCERT existe — no encontré [PGSSLROOTCERT_EXISTE si] en la salida
- verde (restaurado): exit=0 fail=0

### AC58 (c) PGSSLROOTCERT a un archivo que no existe
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC58 psql apunta PGSSLROOTCERT al bundle de RDS del plugin — no encontré [certificados/rds-global-bundle.pem] en la salida
      FAIL  AC58 el archivo al que apunta PGSSLROOTCERT existe — no encontré [PGSSLROOTCERT_EXISTE si] en la salida
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

### AC56 (e) stat en lugar de lstat
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC56 no sigue un symlink con el nombre del plugin (lstat)
- verde (restaurado): exit=0 fail=0

### AC57 (a) el error se lee sólo de stderr
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC57 el mensaje de un error de sqlcmd no llega vacío — no encontré [VIEW SERVER STATE permission was denied] en la salida
      FAIL  AC57 (control) el mensaje tomado de stdout pasa por la redacción — no encontré [[redactado]] en la salida
      FAIL  AC57 el mensaje empieza en el Msg, no en los datos — no encontré ["mensaje":"Msg 245] en la salida
      FAIL  AC57 sin Msg, el mensaje es el final de stdout — no encontré [FIN-DEL-ERROR] en la salida
      FAIL  AC57 el corte por -t de sqlcmd se informa como tiempo_agotado — no encontré ["error":"tiempo_agotado"] en la salida
- verde (restaurado): exit=0 fail=0

### AC57 (b) stdout se lee también cuando el proceso no falló
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC57 una corrida exitosa cuyo dato dice Timeout expired no es un error — encontré ["error"] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC57 (c) toma stdout entero, sin buscar el Msg
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=4
      FAIL  AC57 un error después de filas no se lee como corte por el dato que dice Timeout expired — no encontré ["error":"conexion_fallida"] en la salida
      FAIL  AC57 el mensaje empieza en el Msg, no en los datos — no encontré ["mensaje":"Msg 245] en la salida
      FAIL  AC57 sin Msg, el mensaje es el final de stdout — no encontré [FIN-DEL-ERROR] en la salida
      FAIL  AC57 sin Msg, el principio de un stdout largo queda afuera — encontré [INICIO-LARGO] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC57 (d) corta antes de redactar
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC57 una credencial partida por el corte no deja ver su final (se redacta antes de cortar) — encontré [A1B2C3D4E5] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC57 (e) sin Msg, toma stdout entero y no su final
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC57 sin Msg, el mensaje es el final de stdout — no encontré [FIN-DEL-ERROR] en la salida
      FAIL  AC57 sin Msg, el principio de un stdout largo queda afuera — encontré [INICIO-LARGO] y no debería estar
- verde (restaurado): exit=0 fail=0

### AC59 (a) sin la regla de los certificados
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  forma7 base64 de un certificado con forma de clave AWS - verde (es un certificado público)
- verde (restaurado): exit=0 fail=0

### AC59 (b) vacía toda línea dentro del bloque, sea o no base64
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  forma9 una línea que no es base64 dentro de un certificado - rojo
      FAIL  forma9 el número de línea es el del archivo — no encontré [form9.pem:2:] en la salida
- verde (restaurado): exit=0 fail=0

### AC59 (c) vacía las líneas base64 aunque estén fuera de un certificado
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  forma8 la misma línea fuera de un certificado - rojo
      FAIL  forma8 la misma línea fuera de un certificado - rojo — no encontré [form8.txt] en la salida
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- Las 40 caen, y las 80 corridas verdes, la del árbol real y la restaurada de cada una, salen `exit=0 fail=0`.

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC53 a AC59 (contract v26). Cada una cambia una
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
mutar "AC55 (a) Postgres sin PGSSLMODE" "$CX" "$TS" "      PGSSLMODE: 'verify-full',
" ""
mutar "AC58 (a) vuelve a require" "$CX" "$TS" "PGSSLMODE: 'verify-full'," "PGSSLMODE: 'require',"
mutar "AC58 (b) sin PGSSLROOTCERT" "$CX" "$TS" "      PGSSLROOTCERT: BUNDLE_RDS,
" ""
mutar "AC58 (c) PGSSLROOTCERT a un archivo que no existe" "$CX" "$TS" "'certificados', 'rds-global-bundle.pem'" "'certificados', 'no-existe.pem'"
mutar "AC55 (b) sqlcmd sin -N true" "$CX" "$TS" "'-N', 'true', '-C', '-t'," "'-C', '-t',"
mutar "AC55 (c) sqlcmd sin -C" "$CX" "$TS" "'-N', 'true', '-C', '-t'," "'-N', 'true', '-t',"
mutar "AC56 (a) el servidor no limpia al arrancar" "$SV" "$TS" "  conexion.limpiarTemporalesHuerfanos();
" ""
mutar "AC56 (b) borra sin mirar la edad" "$CX" "$TS" "if (!st.isDirectory() || ahora - st.mtimeMs < edad) continue;" "if (!st.isDirectory()) continue;"
mutar "AC56 (c) borra sin mirar el nombre" "$CX" "$TS" "    if (!NOMBRE_TEMP.test(nombres[i])) continue;
" ""
mutar "AC56 (d) acepta cualquier nombre con el prefijo" "$CX" "$TS" \
  "if (!NOMBRE_TEMP.test(nombres[i])) continue;" "if (nombres[i].indexOf(PREFIJO_TEMP) !== 0) continue;"
mutar "AC56 (e) stat en lugar de lstat" "$CX" "$TS" \
  "const st = fs.lstatSync(ruta);" "const st = fs.statSync(ruta);"
mutar "AC57 (a) el error se lee sólo de stderr" "$CX" "$TS" \
  "? errorDeSqlcmd(redactar(r.stdout, sensibles)) : r.stderr;" "? r.stderr : r.stderr;"
mutar "AC57 (b) stdout se lee también cuando el proceso no falló" "$CX" "$TS" \
  "entrada.dialecto === 'sqlserver' && r.status !== 0 && String(r.stderr || '').trim() === ''" \
  "entrada.dialecto === 'sqlserver' && String(r.stderr || '').trim() === ''"
mutar "AC57 (c) toma stdout entero, sin buscar el Msg" "$CX" "$TS" \
  "? errorDeSqlcmd(redactar(r.stdout, sensibles)) : r.stderr;" "? redactar(r.stdout, sensibles) : r.stderr;"
mutar "AC57 (d) corta antes de redactar" "$CX" "$TS" \
  "errorDeSqlcmd(redactar(r.stdout, sensibles))" "errorDeSqlcmd(r.stdout)"
mutar "AC57 (e) sin Msg, toma stdout entero y no su final" "$CX" "$TS" \
  "return m ? s.slice(m.index) : s.slice(-500);" "return m ? s.slice(m.index) : s;"
mutar "AC59 (a) sin la regla de los certificados" "$SS" "$TSS" \
  "    en_cert && /^[A-Za-z0-9+\\/=]+$/ { print \"\"; next }
" ""
mutar "AC59 (b) vacía toda línea dentro del bloque, sea o no base64" "$SS" "$TSS" \
  "en_cert && /^[A-Za-z0-9+\\/=]+$/ { print \"\"; next }" "en_cert { print \"\"; next }"
mutar "AC59 (c) vacía las líneas base64 aunque estén fuera de un certificado" "$SS" "$TSS" \
  "en_cert && /^[A-Za-z0-9+\\/=]+$/ { print \"\"; next }" "/^[A-Za-z0-9+\\/=]+$/ { print \"\"; next }"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Verificación en vivo, con el servidor del repo — salida literal

```
árbol 196dc3e · bundle sha256 e5bb2084ccf45087

### 1. AC58: las seis conexiones de Postgres con verify-full
proveedores-dev: { "conexion": "proveedores-dev", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
proveedores-qa: { "conexion": "proveedores-qa", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
smartcheck-dev: { "conexion": "smartcheck-dev", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
smartcheck-qa: { "conexion": "smartcheck-qa", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
smartfleet-dev: { "conexion": "smartfleet-dev", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
smartfleet-qa: { "conexion": "smartfleet-qa", "dialecto": "postgres", "filas": [ { "ssl": "t", "version": "TLSv1.3" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }

### 2. AC58, control negativo: con una autoridad ajena, no conecta
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "psql: error: connection to server at \"sistemas-costruplaza-db.cluster-ro-cfrl3owqzwof.us-east-1.rds.amazonaws.com\" (10.24.40.24), port 5432 failed: SSL error: certificate verify failed" }

### 3. SQL Server sigue igual (AC55, AC57)
{ "conexion": "compras", "dialecto": "sqlserver", "filas": [ { "uno": "1" } ], "filas_devueltas": 1, "truncado": false, "motivo_truncado": null }
{ "error": "conexion_fallida", "codigo": 6, "mensaje": "Msg 300, Level 14, State 1, Server EC2AMAZ-2RGHL0C, Line 1\nVIEW SERVER STATE permission was denied on object 'server', database 'master'." }

Árbol al terminar: limpio
```

- **`AC58`**: las seis conexiones de Postgres conectan con `verify-full`. Con el bundle reemplazado por una autoridad recién generada, la conexión falla con `certificate verify failed`: la verificación funciona de verdad, y falla cerrado.
- **SQL Server no cambia**: conecta con `-N true -C`, y los errores llegan con su mensaje (`AC57`). Sigue sin autenticar al servidor (`D71`).
- **El plugin instalado no cambió**: para usar v26 desde Claude Code hay que reinstalar y reiniciar (`D56`).

### El script

```bash
#!/usr/bin/env bash
# Verificación en vivo de v26 (AC58), con el servidor del repo, contra las
# bases reales. Sólo consultas de lectura; ninguna credencial pasa por esta
# salida. El control negativo reemplaza el bundle, sólo mientras corre, por
# una autoridad recién generada que no tiene nada que ver con RDS, y lo
# restaura con git checkout.
set -u
cd "$(git rev-parse --show-toplevel)"
B=plugins/bisalta-db/certificados/rds-global-bundle.pem
[ -z "$(git status --porcelain)" ] || { echo "ABORTA: árbol sucio"; exit 1; }
call() { printf '%s\n%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"medicion","version":"0"}}}' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"consultar\",\"arguments\":{\"conexion\":\"$1\",\"sql\":\"$2\"}}}" | node plugins/bisalta-db/scripts/servidor-mcp.js 2>/dev/null | tail -1 | node -e 'let d="";process.stdin.on("data",x=>d+=x).on("end",()=>{console.log(JSON.parse(d).result.content[0].text.replace(/\s+/g," "))})'; }
echo "árbol $(git rev-parse --short HEAD) · bundle sha256 $(shasum -a 256 "$B" | cut -c1-16)"
echo
echo "### 1. AC58: las seis conexiones de Postgres con verify-full"
for c in proveedores-dev proveedores-qa smartcheck-dev smartcheck-qa smartfleet-dev smartfleet-qa; do
  printf '%s: ' "$c"; call "$c" "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"
done
echo
echo "### 2. AC58, control negativo: con una autoridad ajena, no conecta"
tmp="$(mktemp -d)"
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$tmp/k" -out "$tmp/ajena.pem" -days 1 -subj "/CN=autoridad-ajena-de-prueba" 2>/dev/null
cp "$tmp/ajena.pem" "$B"
git diff --quiet -- "$B" && { echo "ABORTA: el bundle no se reemplazó"; exit 1; }
call proveedores-dev "SELECT 1"
git checkout -q -- "$B"; rm -rf "$tmp"
git diff --quiet -- "$B" || { echo "ABORTA: el bundle no se restauró"; exit 1; }
echo
echo "### 3. SQL Server sigue igual (AC55, AC57)"
call compras "SELECT 1 AS uno"
call compras "SELECT encrypt_option FROM sys.dm_exec_connections WHERE session_id = @@SPID"
echo
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 4. Binding AC ↔ test

| AC | Asserts |
|---|---|
| `AC55`/`AC58` | `SDD/tests/test_servidor_mcp.sh`: `AC55/AC58 psql exige TLS y autentica al servidor …` |
| `AC58` | `SDD/tests/test_servidor_mcp.sh`: `AC58 psql apunta PGSSLROOTCERT …`, `AC58 el archivo al que apunta PGSSLROOTCERT existe`, `AC58 el bundle trae certificados` y `AC58 el bundle no trae ninguna clave privada`; más la parte `manual-only` del §3 |
| `AC59` | `SDD/tests/test_secret_scan.sh`: `forma7 …`, `forma8 …` (dos), `forma9 …` (dos) y el control final de árbol limpio |

El resto del binding de `AC53` a `AC57` no cambió: está en el report de v25, §4.
