# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `0b508ae` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-24T17:37:39Z
- Tree: `576cff569ec323693df0e12dc94b8ad3864178b2` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-24T17:36:37Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-24T17:36:37Z | verde |
| 3 | type-check | — | — | 2026-09-24T17:36:38Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-24T17:36:38Z | verde |
| 5 | integration | — | — | 2026-09-24T17:37:08Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-24T17:37:08Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-24T17:37:08Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-24T17:37:08Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-24T17:37:08Z | verde |
| 10 | smoke manual | — | — | 2026-09-24T17:37:09Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-24T17:37:09Z | verde |

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
secret-scan: sin hallazgos sobre 179 archivos versionados (1 excluido: self)
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

# Addendum del planner — v22 (NO lo escribió el runner)

## 1. Casos — salida literal, agrupada por prefijo de assert

Se agrupa por prefijo porque el nombre de cada assert incluye la descripción que Patrick le puso al caso.

```
$ out="$(bash SDD/tests/test_lista_blanca.sh 2>&1)"; ec=$?
$ for p in <cada prefijo de abajo>; do grep -cE "^  ok +$p" <<<"$out"; grep -cE "^  FAIL +$p" <<<"$out"; done
$ grep -c '^  ok' <<<"$out"; grep -c '^  FAIL' <<<"$out"; echo "$ec"
AC51/AC52 caso [0-9]+ \(                           ok=21 FAIL=0
AC51 v20 caso [0-9]+ \(                            ok=21 FAIL=0
AC51 v20 caso [0-9]+: el motivo lleva el tipo      ok=5 FAIL=0
AC51/AC52 el archivo                               ok=2 FAIL=0
AC51 v20 el archivo                                ok=2 FAIL=0
AC51 v20 hay casos                                 ok=1 FAIL=0
total del archivo: ok=128 FAIL=0 · exit=0
```

## 2. Binding AC ↔ test (`SDD/tests/test_lista_blanca.sh`)

| AC | Asserts |
|---|---|
| `AC51` / `AC52`, primera tanda | `AC51/AC52 caso <índice> (<dialecto>): <motivo>` — 21, uno por caso de `casos-adversariales-lista-blanca.js` |
| `AC51` v20, segunda tanda | `AC51 v20 caso <índice> (<dialecto>): <motivo>` — 21, uno por caso de `casos-adversariales-v20.js` |
| `AC51` v20, tipo en el motivo | `AC51 v20 caso <índice>: el motivo lleva el tipo (<tipo>)` — 5, uno por caso de construcción sin cerrar. **Excepción**: en uno de los cinco la descripción del caso no nombra el tipo, y ahí el assert verifica sólo el prefijo `construccion_sin_cerrar_`; en los otros cuatro, el tipo exacto |
| Controles del recorrido | `… el archivo de casos adversariales carga` y `… trae casos`, por archivo; `AC51 v20 hay casos de construcción sin cerrar …` |

## 3. Mutaciones — pendiente, a cargo de una persona

La evidencia de las mutaciones de `AC51` sobre este árbol queda **pendiente**. Rehacerlas es trabajo sobre la lista blanca que el filtro de seguridad corta cuando lo hace un agente (`RT54`), y se cortó también esta vez. Lo que hay mientras tanto: el report de v20 (`6b848f9`), corrido sobre aquel árbol, y el triple del test nuevo del tipo en el motivo (abajo). Estado declarado en el contract v22: **(b) abierta**, a la espera del caso de Patrick; **(c) abierta en parte**; (a) declarada con adaptador; (d) cae.

**Triple del test del tipo en el motivo** (24-sep, sobre `9948aff`). La mutación saca el sufijo con el tipo del motivo en `validarSql()` —plomería, no la normalización—; verifica que se aplicó y que se restauró:

```
$ bash SDD/tests/test_lista_blanca.sh   # contando '^  FAIL'
verde:      exit=0 asserts_que_caen=0
mutado:     exit=1 asserts_que_caen=5
restaurado: exit=0 asserts_que_caen=0
```
