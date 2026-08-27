# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `refactor-GEN-101-optimizacion-consumo` · **Commit**: `7087d04` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:8b2e27bb797098a5`) · **Fecha**: 2026-08-26T15:31:01Z
- Tree: `37a1d16decb9af594015030882699531b0fa56f6` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-08-26T15:29:18Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-08-26T15:29:18Z | verde |
| 3 | type-check | — | — | 2026-08-26T15:29:19Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-08-26T15:29:19Z | verde |
| 5 | integration | — | — | 2026-08-26T15:30:09Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-08-26T15:30:09Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-08-26T15:30:09Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-08-26T15:30:09Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-08-26T15:30:09Z | verde |
| 10 | smoke manual | — | — | 2026-08-26T15:30:10Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-08-26T15:30:10Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_analysis_archetype.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
12 passed, 0 failed (12 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 111 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_analysis_archetype.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
12 passed, 0 failed (12 total)
```

