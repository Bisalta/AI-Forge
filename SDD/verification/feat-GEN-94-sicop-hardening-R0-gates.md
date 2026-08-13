# Gates run — generado por sdd-run-gates.sh v0.10.0

- **Branch**: `feat-GEN-94-sicop-hardening` · **Commit**: `e5ef90c` · **Doc**: `SDD/docs/doc_quality_gates.md` · **Fecha**: 2026-08-13T15:09:00Z
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | 0 | 2026-08-13T15:08:59Z | verde |
| 3 | type-check | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-08-13T15:08:59Z | verde |
| 5 | integration | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-08-13T15:08:59Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-08-13T15:08:59Z | verde |
| 10 | smoke manual | — | — | 2026-08-13T15:09:00Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-08-13T15:09:00Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_harness.sh
PASS  test_run_gates.sh
---
2 passed, 0 failed (2 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 74 archivos versionados
```

### Gate — — suite completa (exit 0)

```
PASS  test_harness.sh
PASS  test_run_gates.sh
---
2 passed, 0 failed (2 total)
```

