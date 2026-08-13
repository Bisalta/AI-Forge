# Verification Report — <AGENT_slug> · <task-slug>

Evidencia de la escalera de gates (`standards/quality-gates.md` §4-§5). Lo escribe el implementing agent; lo audita el reviewer-agent. Un gate sin fila acá **no corrió**, independientemente de lo que diga el Execution Report.

- **Branch**: `<branch>`
- **Contract**: `contract.md` v<N>
- **Commit evaluado**: `<sha>`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — el reporte generado lo registra **con hash, no sólo con ruta** (`sha256:<16 hex>`, contract R5): una ruta no identifica un contenido, y este doc puede cambiar varias veces durante el propio ciclo. Copiá el hash del encabezado del reporte generado, no lo recalcules a mano acá.

---

## Gates — evidencia GENERADA (no la escribas a mano)

La tabla de gates la produce el runner. Corré:

```bash
bash SDD/scripts/sdd-run-gates.sh --full -o <este-dir>/AGENT_<slug>-gates.md
```

- **Reporte generado**: `<ruta>/AGENT_<slug>-gates.md` (mismo directorio que este archivo — el path COMMITEADO, no `.sdd/` que está gitignoreado y no viaja en el PR)
- **Resumen** (línea `sdd.gates` del runner): `{"green": N, "red": 0, "skipped": M}`
- Corridas rojas intermedias: los reportes previos no se borran ni se editan — se genera uno nuevo; la historia de rojos es señal.

**Solo si el runner no pudo correr** (razón obligatoria: `<cuál>`), la tabla va a mano con el formato del reporte generado — comando exacto · exit code · timestamp UTC · resultado — sabiendo que el reviewer la tratará con el escepticismo que merece una evidencia manuscrita.

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
