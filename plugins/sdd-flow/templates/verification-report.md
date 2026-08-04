# Verification Report — <AGENT_slug> · <task-slug>

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5). Lo escribe el implementing agent; lo audita el reviewer-agent. Un gate sin fila acá **no corrió**, independientemente de lo que diga el Execution Report.

- **Branch**: `<branch>`
- **Contract**: `contract.md` v<N>
- **Commit evaluado**: `<sha>`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md`

---

## Gates

| # | Gate | Comando exacto | Exit code | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format | `<cmd>` | 0 | 2026-08-04T14:02:11Z | verde |
| 2 | lint | `<cmd>` | 0 | … | verde |
| 3 | type-check | `<cmd>` | 0 | … | verde |
| 4 | unit | `<cmd>` | 1 → 0 | … | rojo, arreglado (ver abajo) |
| 5 | integration | `<cmd>` | 0 | … | verde |
| 6 | build | `<cmd>` | 0 | … | verde |
| 7 | e2e | — | — | — | N/A — ningún AC lo exige |
| 8 | cobertura del diff | `<cmd>` | 0 | … | 3 archivos tocados, 3 cubiertos |
| 9 | security (secret scan + audit) | `<cmd>` | 0 | … | sin secretos en el diff; 0 critical/high directas |
| — | suite completa | `<cmd>` | 0 | … | verde antes de integrar |

Estados válidos: `verde` · `rojo, arreglado` · `[SKIPPED] <prereq faltante>` · `N/A — <razón>`.
**Prohibido** escribir `verde` sin haber corrido el comando.

---

## Output (últimas líneas por gate no trivial)

### Gate 4 — unit (primera corrida, exit 1)

```
<pegar ~15 últimas líneas: qué test falló y por qué>
```

### Gate 4 — unit (después del fix, exit 0)

```
<pegar el resumen del runner: N passed, 0 failed>
```

---

## Test de reproducción (sólo bugfix — obligatorio)

| Corrida | Comando | Exit code | Esperado |
|---|---|---|---|
| antes del fix | `<cmd -t "nombre del test">` | 1 | rojo (reproduce el bug) |
| después del fix | `<cmd -t "nombre del test">` | 0 | verde |

```
<pegar la línea de falla de la corrida roja — es la prueba de que el test realmente reproducía el bug>
```

---

## Smoke manual (sólo ACs `manual-only`)

### AC<N> — <comportamiento>

1. <paso ejecutado>
2. <paso ejecutado>

**Observado**: <resultado real, no el esperado>

---

## Impact set

Callers/imports de cada símbolo cambiado, y cómo quedaron cubiertos:

| Símbolo cambiado | Caller | Cobertura |
|---|---|---|
| `createOrder()` | `api/routes/orders.ts` | AC1 (integration) |
| `createOrder()` | `jobs/retryOrders.ts` | test de regresión `tests/retry.spec.ts::"retries once"` |
| `createOrder()` | `scripts/seed.ts` | sin test — script de dev, no productivo |

Un caller sin fila = impact set incompleto = `MAJOR` en review.

---

## Rojos preexistentes

Fallas que ya existían en la rama base antes de este trabajo (verificado corriendo el gate en la base):

- <ninguno> | `<test>` — falla también en `<base>` en el commit `<sha>`
