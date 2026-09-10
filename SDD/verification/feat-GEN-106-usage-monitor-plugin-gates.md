# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-106-usage-monitor-plugin` · **Commit**: `ba496d5` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:a8f010a76c4f561a`) · **Fecha**: 2026-09-08T19:50:57Z
- Tree: `5a1211d6d7f47ed5614da2f9909d273c345df836` — ARBOL SUCIO. Archivos sin commitear:
  - `M  .claude-plugin/marketplace.json`
  - `M  CHANGELOG.md`
  - `M  README.md`
  - `M  SDD/debt.md`
  - `M  SDD/docs/doc_quality_gates.md`
  - `A  SDD/tests/fixtures/usage-log-sample.txt`
  - `A  SDD/tests/test_usage_summary.sh`
  - `A  SDD/verification/feat-GEN-106-usage-monitor-plugin-gates.md`
  - `A  SDD/verification/feat-GEN-106-usage-monitor-plugin.md`
  - `A  plugins/usage-monitor/.claude-plugin/plugin.json`
  - `A  plugins/usage-monitor/README.md`
  - `A  plugins/usage-monitor/commands/usage-summary.md`
  - `A  plugins/usage-monitor/scripts/parse-usage-log.js`
  - `A  plugins/usage-monitor/scripts/usage-summary.sh`
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-08T19:50:01Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-08T19:50:01Z | verde |
| 3 | type-check | — | — | 2026-09-08T19:50:02Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-08T19:50:02Z | verde |
| 5 | integration | — | — | 2026-09-08T19:50:56Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-08T19:50:56Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-08T19:50:56Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-08T19:50:56Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-08T19:50:56Z | verde |
| 10 | smoke manual | — | — | 2026-09-08T19:50:57Z | [SKIPPED] sin comando en el doc (N/A) |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_check_self_scoping.sh
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
PASS  test_usage_summary.sh
---
14 passed, 0 failed (14 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 137 archivos versionados (1 excluido: self)
```

