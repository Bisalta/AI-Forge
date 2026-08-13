# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-94-sicop-hardening` · **Commit**: `d8c3b06` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:e96c7d0f61963400`) · **Fecha**: 2026-08-13T20:30:24Z
- Tree: `9b75911879b2ae92bfc742e61195b1fece1c1304` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-08-13T20:30:04Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | 0 | 2026-08-13T20:30:04Z | verde |
| 3 | type-check | — | — | 2026-08-13T20:30:04Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-08-13T20:30:04Z | verde |
| 5 | integration | — | — | 2026-08-13T20:30:14Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-08-13T20:30:14Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-08-13T20:30:14Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-08-13T20:30:14Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-08-13T20:30:14Z | verde |
| 10 | smoke manual | — | — | 2026-08-13T20:30:14Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-08-13T20:30:14Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
7 passed, 0 failed (7 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 94 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
7 passed, 0 failed (7 total)
```

