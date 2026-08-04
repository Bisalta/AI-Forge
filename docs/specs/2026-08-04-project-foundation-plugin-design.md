# Spec — Empaquetar `project-foundation` como plugin separado

- **Fecha**: 2026-08-04
- **Plugin**: project-foundation (nuevo)
- **Estado**: diseño aprobado, implementado en esta misma rama
- **Branch**: add-project-foundation-plugin

## Problema

Existía un skill personal `project-foundation` (fuera de este repo, en `~/.claude-personal/skills/`) que genera los seis documentos fundacionales de un proyecto (PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan). Al agregar `/sdd-init` a `sdd-flow` (spec `2026-08-03-foundation-docs-bootstrap-design.md`), `sdd-flow` quedó preparado para **leer** los outputs de ese skill (`docs/foundation/01-prd.md`, `06-implementation-plan.md`, etc.) si ya existían — pero el skill en sí seguía sin ser parte del marketplace de empresa, solo disponible para quien lo tuviera instalado localmente.

## Objetivo

Distribuir `project-foundation` como segundo plugin de `AI-Forge`, instalable igual que `sdd-flow`, preservando dos propiedades no negociables:

1. **`sdd-flow` sigue siendo autosuficiente sin `project-foundation`.** Un dev que instale solo `sdd-flow` y le dé un caso de uso nunca debe toparse con un punto donde el flujo exija instalar o correr `project-foundation` — su modo `greenfield` en `/sdd-init` ya cubre eso por sí solo.
2. **`project-foundation` funciona standalone**, sin depender de que `sdd-flow` esté instalado.

## Decisiones cerradas (no re-litigar)

1. **Plugin separado, no un sexto skill dentro de `sdd-flow`.** Ciclo de vida distinto (versiona independiente, se instala independiente) y responsabilidad distinta (day-zero de todo el proyecto vs. ciclo por-feature de SDD). Meterlo dentro de `sdd-flow` hubiera acoplado el versionado de algo que no tiene nada que ver con el pipeline SDD.
2. **Acoplamiento por convención de path, no por dependencia declarada.** `sdd-flow` no declara a `project-foundation` como dependencia en su `plugin.json` — simplemente sabe leer `docs/foundation/*` si existe. `project-foundation` tampoco declara a `sdd-flow`. La interoperabilidad es 100% opcional en ambas direcciones; ninguno de los dos plugins puede convertirse en un requisito duro del otro.
3. **Contenido del skill copiado fiel al original.** Sin reescribir sustancia — solo se agregó una nota de interoperabilidad hacia `sdd-flow` (no obligatoria) y se ajustó el frontmatter (se quitó `argument-hint`, que es un campo de `commands/`, no de `skills/`).
4. **Comando `/project-foundation:init`**, no `/project-foundation:project-foundation`. El nombre del comando lo define el nombre del archivo (`commands/init.md`), no el nombre del plugin — evita la redundancia de tipeo del nombre repetido dos veces en la invocación completa.

## Componentes

### A · `plugins/project-foundation/`
- `.claude-plugin/plugin.json` — manifest v0.1.0, mismo formato que `sdd-flow`.
- `commands/init.md` — wrapper corto que invoca el skill.
- `skills/project-foundation/SKILL.md` — contenido fiel al skill personal original, con la nota de interoperabilidad agregada.
- `README.md` propio, mismo patrón que `plugins/sdd-flow/README.md`.

### B · Registro en el marketplace
- `.claude-plugin/marketplace.json`: nueva entrada en `plugins[]`.
- `README.md`/`CHANGELOG.md`/`CLAUDE.md` raíz actualizados: ya no es "sdd-flow, primer y único plugin" sino dos plugins independientes.

## Fuera de alcance

- No se cablea ningún mecanismo real de subagentes de exploración en paralelo — el skill lo **instruye** en el prompt (igual que hacía el skill personal original), pero no hay `allowed-tools` ni orquestación que lo garantice. Mismo estado pendiente que el orquestador real de `/sdd` (roadmap de `sdd-flow`, pendiente #1). El wording de `README.md` de este plugin se ajustó para no prometer esto como un mecanismo cableado.
- No se declara dependencia formal entre plugins en ningún `plugin.json` — el acoplamiento es puramente por convención de path (`docs/foundation/`), reversible sin romper ninguno de los dos si un equipo solo usa uno.
