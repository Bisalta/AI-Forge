# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `5712a5e` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-24T15:58:31Z
- Tree: `6b4e5680888ac075d277880f4c9b2e52918a55c9` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-24T15:57:25Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-24T15:57:25Z | verde |
| 3 | type-check | — | — | 2026-09-24T15:57:26Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-24T15:57:26Z | verde |
| 5 | integration | — | — | 2026-09-24T15:57:59Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-24T15:57:59Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-24T15:57:59Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-24T15:57:59Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-24T15:57:59Z | verde |
| 10 | smoke manual | — | — | 2026-09-24T15:58:00Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-24T15:58:00Z | verde |

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
secret-scan: sin hallazgos sobre 177 archivos versionados (1 excluido: self)
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

# Addendum del planner — v20 (NO lo escribió el runner)

**Quién hizo qué.** Ningún agente pudo implementar v20: el filtro de seguridad cortó tres veces el trabajo de ajustar la lista blanca contra formas de pasarla. Los casos (`SDD/tests/fixtures/casos-adversariales-v20.js`) y la función `normalizar()` son de Patrick Ocampo, que la revisó antes de entregarla. Ian Vargas pegó los dos; el planner integró la función en `validarSql()` y extendió el test para recorrer los dos archivos de casos (`4f2d6cb`).

## 1. Casos

Los 42 casos de los dos archivos de Patrick coinciden con el veredicto esperado: 21 de 21 en cada uno, medidos por la suite (`test_lista_blanca.sh`) y cargados por índice, sin que ninguna consulta salga de su archivo.

## 2. Mutaciones declaradas en `AC51` v20 — salida literal del script

Cada mutación apaga una regla, verifica que se aplicó, mide, restaura y verifica que se restauró. Se registran el exit code y la cantidad de asserts que caen.

### (b) regla de los literales E'…' apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=0 fail=0
- verde (restaurado): exit=0 fail=0

### (c) regla de los corchetes apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
- verde (restaurado): exit=0 fail=0

### (d) construcción sin cerrar aceptada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio salvo este report, recién escrito por el runner y todavía sin commitear (`git status` lo mostraba como único cambio; `lista-blanca.js` idéntico al commit).

**Lectura:**
- **(c)** y **(d)** matan su barrera: el test cae con la regla apagada y vuelve a verde restaurada.
- **(b) queda abierta**: con la regla de los literales `E'…'` apagada, la suite sigue verde. Hoy ningún caso mata esa regla. El análisis de por qué no lo pudo hacer el planner —lo corta el mismo filtro—, y se le pidió a Patrick el caso que falta (Slack, 24-sep). Declarado igual en el contract (`AC51`, mutación (b)).
- La mutación **(a)** —volver a la normalización anterior a v19— la cubre el triple de `AC51` en el report de v19 parte 2; con la firma nueva de `normalizar()` (devuelve un objeto) la versión vieja ni siquiera es sustituible sin tocar `validarSql()`.

## 3. El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC51 v20. Cada una apaga una regla con `false &&`,
# verifica que se aplicó, mide, restaura con git checkout y verifica que se
# restauró. Registra exit code y cantidad de asserts que caen.
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/lista-blanca.js; T=SDD/tests/test_lista_blanca.sh
correr() { local o ec; o="$(bash "$T" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c 'FAIL' <<<"$o")"; }
mutar() { local nombre="$1" viejo="$2" nuevo="$3"
  echo "### $nombre"
  printf -- '- verde (árbol real): '; correr
  python3 - "$F" "$viejo" "$nuevo" <<'PY'
import sys
p,v,n=sys.argv[1:4]; s=open(p).read(); assert s.count(v)==1,(v,s.count(v)); open(p,'w').write(s.replace(v,n))
PY
  if git diff --quiet -- "$F"; then echo "- ABORTA: la mutación no se aplicó"; return 1; fi
  printf -- '- mutado:             '; correr
  git checkout -q -- "$F"
  if ! git diff --quiet -- "$F"; then echo "- ABORTA: no se restauró"; return 1; fi
  printf -- '- verde (restaurado): '; correr
  echo; }
mutar "(b) regla de los literales E'…' apagada" "if (dialecto === 'postgres' && (c === 'E'" "if (false && dialecto === 'postgres' && (c === 'E'"
mutar "(c) regla de los corchetes apagada" "if (dialecto === 'sqlserver' && c === '[')" "if (false && dialecto === 'sqlserver' && c === '[')"
mutar "(d) construcción sin cerrar aceptada" "if (normalizada.sinCerrar) {" "if (false && normalizada.sinCerrar) {"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```
