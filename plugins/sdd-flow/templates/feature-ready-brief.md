# Feature Ready — <título de la feature>

<!--
El único gate humano del ciclo. Si revisar cuesta 40 minutos de lectura, el humano
aprueba por confianza y el gate se vuelve decorativo. Este brief es UNA pantalla:
lo que el humano necesita para decidir en ~5 minutos. La evidencia completa queda
como apéndice de links — disponible, no obligatoria.
Regla de honestidad: nada de lo de abajo se resume "en verde" si no lo está.
-->

## Qué es (2-3 líneas)

<Qué hace la feature en términos de producto/usuario, no de archivos. Arquetipo: `<archetype>`. Contract `vN`.>

## Decisiones que tomé por vos

<Las 2-4 decisiones del ciclo que el humano NO aprobó explícitamente y le podrían importar — defaults aceptados por paquete en el refinement, ratificaciones de contract durante ejecución, ADRs emitidos. Una línea cada una, con link al ADR si existe.>

- <decisión> — <por qué> (`docs/adr/NNN`)

## Dónde está el riesgo

<Lo que un senior miraría primero. 2-4 líneas máximo. Ej.: "la migración toca 2M de filas — el dry-run dio 1.998.407, el conteo real 1.998.407"; "el retry del webhook es la parte con menos kilometraje".>

## Qué mirar en 5 minutos

1. `<archivo:línea>` — <por qué ahí está el corazón del cambio>
2. `<test clave>` — <el AC más importante que protege>
3. <si aplica: el fixture/pantalla/comando para verlo funcionando>

## Estado honesto

| | |
|---|---|
| ACs | <N>/<N> con test verde (<M> `manual-only` ejecutados) |
| Gates | <verde / qué quedó `[SKIPPED]` y por qué> |
| Review | `APPROVED` ronda <n> · <hallazgos MINOR abiertos → `SDD/debt.md` DN-DM> |
| Rojos preexistentes | <ninguno / cuáles, con evidencia de que ya fallaban en la base> |
| Advisory | <SEO/perf: n hallazgos, severidad máxima> |
| Deuda dejada | <n ítems en el ledger / ninguno> |

## Siguiente paso

<Qué pasa si aprobás (orden de PRs/merge) y qué NO está incluido (out-of-scope que quedó afuera a propósito).>

---
**Apéndice (evidencia completa)**: contract `<path>` · verification reports `<paths>` · gates run `<path>` · retro `<path si hubo entradas>`
