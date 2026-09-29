# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `a6c23cb` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-24T22:58:20Z
- Tree: `9837cd30f239d6f154d7fbb6ddc77f2dbf6692ea` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-24T22:57:12Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-24T22:57:12Z | verde |
| 3 | type-check | — | — | 2026-09-24T22:57:13Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-24T22:57:13Z | verde |
| 5 | integration | — | — | 2026-09-24T22:57:45Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-24T22:57:45Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-24T22:57:45Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-24T22:57:45Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-24T22:57:45Z | verde |
| 10 | smoke manual | — | — | 2026-09-24T22:57:46Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-24T22:57:46Z | verde |

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

# Addendum del planner — v24 (NO lo escribió el runner)

La escalera de arriba se corrió sobre `a6c23cb` (contract v24 y los casos nuevos de `a282e3a`). Las mutaciones se corrieron sobre `eb3e8bc`, el commit que agregó la escalera: el código y los tests son los de `a6c23cb`.

## 1. Casos — salida literal

```
$ out="$(bash SDD/tests/test_lista_blanca.sh 2>&1)"; ec=$?; for p in 'AC51/AC52 caso [0-9]+ \(' 'AC51 v20 caso [0-9]+ \(' 'AC51 v20 caso [0-9]+: el motivo lleva el tipo' 'AC51 \(c\) acepta'; do printf '%-50s ok=%s FAIL=%s\n' "$p" "$(grep -cE "^  ok +$p" <<<"$out")" "$(grep -cE "^  FAIL +$p" <<<"$out")"; done; echo "total del archivo: ok=$(grep -c '^  ok' <<<"$out") FAIL=$(grep -c '^  FAIL' <<<"$out") · exit=$ec"
AC51/AC52 caso [0-9]+ \(                           ok=21 FAIL=0
AC51 v20 caso [0-9]+ \(                            ok=27 FAIL=0
AC51 v20 caso [0-9]+: el motivo lleva el tipo      ok=5 FAIL=0
AC51 \(c\) acepta                                  ok=5 FAIL=0
total del archivo: ok=139 FAIL=0 · exit=0
```

Con v23 el archivo tenía 134 asserts; los cinco casos nuevos suman cinco.

## 2. Las cuatro mutaciones de `AC51` sobre este árbol — salida literal

(b), (c) y (d), con el script del report de v23, §2:

```
### (b) regla de los literales E'…' apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC51 v20 caso 21 (postgres)
      FAIL  AC51 v20 caso 22 (postgres)
      FAIL  AC51 v20 caso 23 (postgres)
      FAIL  AC51 v20 caso 24 (postgres)
      FAIL  AC51 v20 caso 25 (postgres)
- verde (restaurado): exit=0 fail=0

### (c) regla de los corchetes apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=6
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 16
      FAIL  AC51 (c) acepta en sqlserver un nombre entre corchetes con una comilla simple (exit 0) — esperado [0], obtenido [4]
      FAIL  AC51 (c) acepta en sqlserver un nombre entre corchetes con una comilla doble (exit 0) — esperado [0], obtenido [4]
      FAIL  AC51 (c) acepta en sqlserver un nombre entre corchetes con un /* (exit 0) — esperado [0], obtenido [4]
      FAIL  AC51 (c) acepta en sqlserver un nombre entre corchetes con ]] escapado y una comilla (exit 0) — esperado [0], obtenido [4]
- verde (restaurado): exit=0 fail=0

### (d) construcción sin cerrar aceptada
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

Árbol al terminar: limpio
```

(a), con el adaptador y el script del addendum de `…-v23-D67.md`:

```
### (a) normalización anterior a v19, con adaptador — árbol eb3e8bc
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

- **(c) cae.** Con la regla apagada caen los cuatro casos nuevos y los dos asserts del caso 16. El control, un corchete simple, no cae.
- **Los casos nuevos no dependen de la (d).** En la corrida de la (d) no cae ninguno de los asserts `AC51 (c)`: una construcción sin cerrar que se acepta no cambia el veredicto de una consulta que ya se aceptaba. Así, la (c) queda cubierta por casos propios, que era lo que faltaba (`D64`).
- **(a), (b) y (d)** dan lo mismo que en los reports de v23: 15, 5 y 10 asserts.

## 3. Binding AC ↔ test (`SDD/tests/test_lista_blanca.sh`)

Igual que el de v23, con una fila nueva:

| AC | Asserts |
|---|---|
| `AC51`, mutación (c) | `AC51 (c) acepta en sqlserver <descripción>`: 5 asserts, cuatro que matan la mutación y un control. Los escribió el planner (v24). |
