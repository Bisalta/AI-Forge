# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `b684ac9` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-24T22:21:34Z
- Tree: `ed18ae0d47b1a46f9d0a676db8e443f14f6f9d6c` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-24T22:20:27Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-24T22:20:27Z | verde |
| 3 | type-check | — | — | 2026-09-24T22:20:28Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-24T22:20:28Z | verde |
| 5 | integration | — | — | 2026-09-24T22:21:01Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-24T22:21:01Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-24T22:21:01Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-24T22:21:01Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-24T22:21:01Z | verde |
| 10 | smoke manual | — | — | 2026-09-24T22:21:02Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-24T22:21:02Z | verde |

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
secret-scan: sin hallazgos sobre 182 archivos versionados (1 excluido: self)
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

# Addendum del planner (NO lo escribió el runner)

## Mutación (a) de `AC51` sobre este árbol (`D65`)

La escalera de arriba se corrió sobre `b684ac9`. El commit siguiente (`6592dde`) sólo agregó este report, así que el código y los tests son los mismos que corrió la mutación.

La mutación vuelve a la normalización anterior a v19, sacada de `dffb83a`. Como la función de hoy devuelve un objeto, la vieja entra con el adaptador que declara `AC51`: `{ texto: normalizarVieja(sql), sinCerrar: null }`. Salida literal del script:

```
### (a) normalización anterior a v19, con adaptador — árbol 6592dde
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=15
      FAIL  AC51/AC52 caso 0 (postgres)
      FAIL  AC51/AC52 caso 1 (sqlserver)
      FAIL  AC51/AC52 caso 2 (postgres)
      FAIL  AC51/AC52 caso 3 (postgres)
      FAIL  AC51 v20 caso 9 (sqlserver)
      FAIL  AC51 v20 caso 12 (postgres)
      FAIL  AC51 v20 caso 13 (postgres)
      FAIL  AC51 v20 caso 14 (postgres)
      FAIL  AC51 v20 caso 15 (postgres)
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 12
      FAIL  AC51 v20 caso 13
      FAIL  AC51 v20 caso 14
      FAIL  AC51 v20 caso 15
      FAIL  AC51 v20 caso 16
- verde (restaurado): exit=0 fail=0
Árbol al terminar: limpio
```

- **(a) cae.** Hacen falta dos lecturas:
  - Los casos 0 a 3 de la primera tanda y el 9 de la segunda caen por la normalización misma. Es lo que la mutación mide: la función vieja no ve lo mismo que el motor.
  - Los casos 12 a 16, que son de construcción sin cerrar, en sus dos asserts, caen **sólo** por el adaptador: la función vieja no detecta construcciones sin cerrar, así que el adaptador siempre devuelve `sinCerrar: null`.
- **Esa separación está medida, no inferida** (review de la mutación (a), ronda 1, MINOR 3). Los controles de abajo aplican cada mitad por separado. Con sólo el adaptador caen 10 asserts, los de los casos 12 a 16. Con sólo la normalización vieja caen 5: los casos 0 a 3 de la primera tanda y el 9 de la segunda. Los dos conjuntos no se superponen, y la (a) completa tira exactamente su unión, 15.
- Con esto, las cuatro mutaciones declaradas en `AC51` están corridas: la (a) sobre el árbol actual; (b), (c) y (d) sobre `76f258e` (report de v23, §2), y después de ese commit el único cambio en `SDD/tests/` es la descripción del caso 13. Caen (a), (b) y (d). La (c) cae sólo en parte (`D64`).

### El script

```bash
#!/usr/bin/env bash
# Mutación (a) de AC51: volver a la normalización anterior a v19 (la de
# dffb83a). Como la función de hoy devuelve un objeto, la vieja entra con un
# adaptador: { texto: normalizarVieja(sql), sinCerrar: null } (contract, AC51).
# Verifica que se aplicó, mide, restaura y verifica que se restauró.
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/lista-blanca.js; T=SDD/tests/test_lista_blanca.sh
correr() { local o ec; o="$(bash "$T" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c '^  FAIL' <<<"$o")"; grep '^  FAIL' <<<"$o" | sed 's/:.*//; s/^/    /'; }
VIEJA="$(git show dffb83a:"$F" | sed -n '/^function normalizar(sql) {$/,/^}$/p' | sed 's/^function normalizar(sql)/function normalizarVieja(sql)/')"
[ "$(grep -c '^function normalizarVieja' <<<"$VIEJA")" = 1 ] || { echo "- ABORTA: no se extrajo la función vieja"; exit 1; }
echo "### (a) normalización anterior a v19, con adaptador — árbol $(git rev-parse --short HEAD)"
printf -- '- verde (árbol real): '; correr
VIEJA="$VIEJA" python3 - "$F" <<'PY'
import os, sys
p=sys.argv[1]; s=open(p).read()
llamada="const normalizada = normalizar(sql, dialecto);"
adaptador="const normalizada = { texto: normalizarVieja(sql), sinCerrar: null };"
ancla="function validarSql(sql, dialecto) {"
assert s.count(llamada)==1 and s.count(ancla)==1
s=s.replace(llamada, adaptador).replace(ancla, os.environ['VIEJA']+"\n\n"+ancla)
open(p,'w').write(s)
PY
if git diff --quiet -- "$F"; then echo "- ABORTA: la mutación no se aplicó"; exit 1; fi
node -e "require('./$F')" || { echo "- ABORTA: el archivo mutado no carga"; git checkout -q -- "$F"; exit 1; }
printf -- '- mutado:             '; correr
git checkout -q -- "$F"
if ! git diff --quiet -- "$F"; then echo "- ABORTA: no se restauró"; exit 1; fi
printf -- '- verde (restaurado): '; correr
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

### Controles de aislamiento — salida literal

```
árbol 7b1f9ac
### adaptador
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=10
      FAIL  AC51 v20 caso 12 (postgres)
      FAIL  AC51 v20 caso 13 (postgres)
      FAIL  AC51 v20 caso 14 (postgres)
      FAIL  AC51 v20 caso 15 (postgres)
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 12
      FAIL  AC51 v20 caso 13
      FAIL  AC51 v20 caso 14
      FAIL  AC51 v20 caso 15
      FAIL  AC51 v20 caso 16
- verde (restaurado): exit=0 fail=0

### normalizacion
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC51/AC52 caso 0 (postgres)
      FAIL  AC51/AC52 caso 1 (sqlserver)
      FAIL  AC51/AC52 caso 2 (postgres)
      FAIL  AC51/AC52 caso 3 (postgres)
      FAIL  AC51 v20 caso 9 (sqlserver)
- verde (restaurado): exit=0 fail=0

### completa
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=15
      FAIL  AC51/AC52 caso 0 (postgres)
      FAIL  AC51/AC52 caso 1 (sqlserver)
      FAIL  AC51/AC52 caso 2 (postgres)
      FAIL  AC51/AC52 caso 3 (postgres)
      FAIL  AC51 v20 caso 9 (sqlserver)
      FAIL  AC51 v20 caso 12 (postgres)
      FAIL  AC51 v20 caso 13 (postgres)
      FAIL  AC51 v20 caso 14 (postgres)
      FAIL  AC51 v20 caso 15 (postgres)
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 12
      FAIL  AC51 v20 caso 13
      FAIL  AC51 v20 caso 14
      FAIL  AC51 v20 caso 15
      FAIL  AC51 v20 caso 16
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

```bash
#!/usr/bin/env bash
# Controles de aislamiento de la mutación (a): separan qué asserts caen por
# la normalización vieja y cuáles por el adaptador (sinCerrar: null).
#   adaptador     — texto de la normalización de hoy, sinCerrar: null
#   normalizacion — texto de la normalización vieja, sinCerrar de la de hoy
#   completa      — la mutación (a) tal como la declara AC51
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/lista-blanca.js; T=SDD/tests/test_lista_blanca.sh
correr() { local o ec; o="$(bash "$T" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c '^  FAIL' <<<"$o")"; grep '^  FAIL' <<<"$o" | sed 's/:.*//; s/^/    /'; }
VIEJA="$(git show dffb83a:"$F" | sed -n '/^function normalizar(sql) {$/,/^}$/p' | sed 's/^function normalizar(sql)/function normalizarVieja(sql)/')"
[ "$(grep -c '^function normalizarVieja' <<<"$VIEJA")" = 1 ] || { echo "ABORTA: no se extrajo la función vieja"; exit 1; }
echo "árbol $(git rev-parse --short HEAD)"
for modo in adaptador normalizacion completa; do
  echo "### $modo"
  printf -- '- verde (árbol real): '; correr
  case $modo in
    adaptador)     NUEVA="const normalizada = { texto: normalizar(sql, dialecto).texto, sinCerrar: null };" ;;
    normalizacion) NUEVA="const normalizada = { texto: normalizarVieja(sql), sinCerrar: normalizar(sql, dialecto).sinCerrar };" ;;
    completa)      NUEVA="const normalizada = { texto: normalizarVieja(sql), sinCerrar: null };" ;;
  esac
  VIEJA="$VIEJA" NUEVA="$NUEVA" python3 - "$F" <<'PY'
import os, sys
p=sys.argv[1]; s=open(p).read()
llamada="const normalizada = normalizar(sql, dialecto);"; ancla="function validarSql(sql, dialecto) {"
assert s.count(llamada)==1 and s.count(ancla)==1
s=s.replace(llamada, os.environ['NUEVA']).replace(ancla, os.environ['VIEJA']+"\n\n"+ancla)
open(p,'w').write(s)
PY
  if git diff --quiet -- "$F"; then echo "- ABORTA: la mutación no se aplicó"; exit 1; fi
  node -e "require('./$F')" || { echo "- ABORTA: el archivo mutado no carga"; git checkout -q -- "$F"; exit 1; }
  printf -- '- mutado:             '; correr
  git checkout -q -- "$F"
  if ! git diff --quiet -- "$F"; then echo "- ABORTA: no se restauró"; exit 1; fi
  printf -- '- verde (restaurado): '; correr
  echo
done
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```
