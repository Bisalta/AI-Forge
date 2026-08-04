# ADR-NNN: <decisión en una línea, en presente>

- **Fecha**: <YYYY-MM-DD>
- **Estado**: aceptada <!-- aceptada | reemplazada por ADR-MMM | deprecada -->
- **Origen**: <contract de la task `<slug>` vN | ESCALATE de AGENT_<x> | decisión directa del planner>

## Contexto

<Qué problema forzó la decisión, en 2-4 líneas. Los hechos que la condicionaron: constraint del stack, deuda existente, requerimiento del negocio. Sin narrativa.>

## Decisión

<La decisión, cerrada. Sin "prefer / may be / if needed" — las closure rules aplican acá también. Si hay valores concretos (timeouts, versiones, nombres), van acá.>

## Alternativas descartadas

- **<alternativa>** — <por qué no, una línea>
- **<alternativa>** — <por qué no, una línea>

## Consecuencias

- <qué se vuelve más fácil>
- <qué se vuelve más difícil o queda como deuda — si genera deuda, registrarla en `SDD/debt.md`>

<!--
Convención sdd-flow: los ADRs viven en docs/adr/NNN-<slug>.md, numeración
incremental sin reusar. Los emite el planner cuando un contract toma una
decisión arquitectónica (nueva dependencia, cambio de capa/ownership, patrón
nuevo, breaking change de contrato público) — la decisión sobrevive a la task;
el contract.md de la task no lo vuelve a leer nadie. /sdd-init y
enrich-user-story los leen como contexto si existen.
-->
