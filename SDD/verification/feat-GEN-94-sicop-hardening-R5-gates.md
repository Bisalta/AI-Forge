# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-94-sicop-hardening` · **Commit**: `cd22425` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:e96c7d0f61963400`) · **Fecha**: 2026-08-13T19:39:52Z
- Tree: `d2cc034bf179c8fe4b10e47745e77b37d4675c50` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-08-13T19:39:34Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | 0 | 2026-08-13T19:39:34Z | verde |
| 3 | type-check | — | — | 2026-08-13T19:39:35Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-08-13T19:39:35Z | verde |
| 5 | integration | — | — | 2026-08-13T19:39:43Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-08-13T19:39:43Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-08-13T19:39:43Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-08-13T19:39:43Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-08-13T19:39:43Z | verde |
| 10 | smoke manual | — | — | 2026-08-13T19:39:44Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-08-13T19:39:44Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
6 passed, 0 failed (6 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 89 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
6 passed, 0 failed (6 total)
```

