# Verification Report — fix-check-self-scoping

Bugfix directo, sin contract (hallazgo ya diagnosticado externamente — Bisalta/WMS-Back, ciclo WMS-34 — y ya registrado como deuda abierta en este repo). Cierra `SDD/debt.md` D11; detalle completo en `SDD/retro.md` RT22.

- **Branch**: `fix-check-self-scoping`
- **Commit evaluado**: `ce42be1`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (`sha256:3f46f92b1b0dfe44`)

---

## Gates — evidencia GENERADA

- **Reporte generado**: `SDD/verification/fix-check-self-scoping-gates.md` (árbol LIMPIO, tree `6ff79e97dd3c52ec91a0fbd213d01a99b3a4b248`)
- **Resumen**: `{"green": 3, "red": 0, "skipped": 7}` — los 7 `SKIPPED` son N/A declarados en el propio doc de gates de este repo (sin shfmt instalado, bash no tipado, sin build/e2e/coverage-tool, sin ACs manual-only), no fallas.

---

## Test de reproducción (bugfix)

| Corrida | Comando | Exit code | Esperado |
|---|---|---|---|
| antes del fix | `bash SDD/tests/test_check_self_scoping.sh` | 1 | rojo (reproduce el bug) |
| después del fix | `bash SDD/tests/test_check_self_scoping.sh` | 0 | verde |

```
  FAIL  casoA D11 - sdd-check.sh agregado fresco no se autodetecta (exit 0) — esperado [0], obtenido [2]
  FAIL  casoA D11 - no debería mencionar SDD/scripts/sdd-check.sh como BLOCKER
  FAIL  casoB eco-creciente - reporte .md que cita el marcador no se marca solo (exit 0) — esperado [0], obtenido [2]
  FAIL  casoB eco-creciente - no debería marcar report-R1.md como BLOCKER
  ok    casoC no-regresion - violaciones reales en archivos normales siguen en rojo (exit 2)
  ok    casoC no-regresion - supresor built-in sigue detectando en .ts
  ok    casoC no-regresion - patron custom sigue detectando en .ts
FAIL — 4 assert(s) fallaron
```

Corrida después del fix (`SDD/tests/run.sh`, gate 4 de la tabla de arriba): `PASS test_check_self_scoping.sh`, 13/13 archivos verdes.

**Mutación**: no aplica — el bug ya estaba en el árbol (`quality-gates.md` §10.3, último párrafo). Dos corridas alcanzan.

---

## Impact set

| Símbolo cambiado | Caller | Cobertura |
|---|---|---|
| `sdd-check.sh` (reglas built-in + loop de patrones custom) | `plugins/sdd-flow/agents/reviewer-agent.md` Fase 1 (`sdd-check.sh <base>`) | `SDD/tests/test_check_self_scoping.sh` casoA/casoC — no-regresión sobre archivos reales |
| `sdd-check.sh` (auto-exclusión) | Consumidores vía `/sdd-init` (copia a `SDD/scripts/sdd-check.sh` en repos externos) | `SDD/tests/test_check_self_scoping.sh` casoA — simula exactamente esa distribución |
| `sdd-check.sh` (loop de patrones custom + guard `.md`) | `SDD_CHECK_PATTERNS` / `SDD/scripts/sdd-check.patterns` (no existe en este repo; sí en repos consumidores, ej. Bisalta/WMS-Back) | `SDD/tests/test_check_self_scoping.sh` casoB |

---

## Rojos preexistentes

Ninguno — `SDD/tests/run.sh` sobre `origin/prod` (antes de este commit) no incluye `test_check_self_scoping.sh` (no existía); el resto de la suite (12 archivos) ya corría verde en la base.
