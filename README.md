# ai-forge

Marketplace interno de **Bisalta Ltda** para tooling de Claude Code — plugins, skills y standards de desarrollo asistido por AI.

## Instalación (en cualquier proyecto)

```
/plugin marketplace add Construplaza/AI-Forge
/plugin install sdd-flow
```

Luego tipeá `/` y vas a ver los comandos del plugin (`/sdd-flow:sdd`, etc).

## Plugins disponibles

| Plugin | Versión | Qué hace |
|---|---|---|
| [**sdd-flow**](./plugins/sdd-flow) | 0.1.0 | Spec-Driven Development multi-agente: planner Opus 4.8 cierra decisiones y corta tareas, subagentes Sonnet/Haiku ejecutan, coordinación file-based `AGENT_{uuid}`. |

## Estructura

```
ai-forge/
├── .claude-plugin/marketplace.json   índice del marketplace
├── plugins/
│   └── sdd-flow/                      primer plugin (ver su README)
├── CHANGELOG.md
└── README.md
```

## Cómo usar sdd-flow

### Flujo típico (del requerimiento al código)

```
/sdd-enrich <idea cruda>          → cierra decisiones, produce requerimiento
/sdd-contract <slug o req>        → genera el contrato técnico (HLTC)
/sdd <descripcion de lo que querés lograr>   → ciclo completo autónomo
```

**El flujo completo con `/sdd`** corre sin gates intermedios hasta **Feature Ready**: enrichment → contract → specs por agente → ejecución multi-agente → review. El humano interviene solo al final (Feature Ready → PR).

### Comandos disponibles

| Comando | Cuándo usarlo |
|---|---|
| `/sdd <idea>` | Ciclo SDD completo: refinement → contract → specs → ejecución multi-agente. Usalo cuando tenés una tarea nueva. |
| `/sdd-enrich <idea>` | Solo la fase de refinement. Útil para cerrar decisiones antes de planear o cuando la tarea es compleja y querés separar el "qué" del "cómo". |
| `/sdd-contract <slug>` | Genera o actualiza el High-Level Technical Contract (HLTC). Útil si ya tenés el requerimiento cerrado y querés planear sin ejecutar. |
| `/sdd-status` | Tablero de estado: tareas activas, bloqueos, mensajes sin procesar entre agentes, versión de contract. Solo lectura. |
| `/sdd-pr` | Genera la descripción del Pull Request a partir de los cambios del repo. Usalo antes de abrir el PR. |

### Cómo funciona internamente

El **planner (Opus 4.8)** toma la idea, cierra decisiones en 6 dimensiones (solution shape, output, behavior, actor, scope, success criteria), produce el HLTC y corta task briefs por `AGENT_{uuid}` (un agente = un repo + branch + working-dir). Cada task brief lleva modelo asignado (`sonnet` default, `opus` para tareas pesadas, `haiku` para triviales). Los **agentes implementadores** ejecutan; un **reviewer agent (Opus)** valida. Si un agente se bloquea por decisión no resuelta → le pregunta al planner, no adivina.

### Closure rules (el contract es innegociable)

El pipeline corre sin aprobación humana, por eso el contract debe ser preciso: **prohibido** "if needed / or / prefer / may be / when available". Si dos ingenieros lo implementarían distinto, la spec es inválida y el agente frena.

---

## Agregar un plugin nuevo

1. Crear `plugins/<nombre>/.claude-plugin/plugin.json` + sus `commands/skills/agents`.
2. Registrarlo en `.claude-plugin/marketplace.json` (`plugins[]` con `source: "./plugins/<nombre>"`).
3. Bumpear versión en el `plugin.json` del plugin y anotar en `CHANGELOG.md`.

## Versionado

SemVer por plugin (`MAJOR.MINOR.PATCH`) en cada `plugin.json`. El marketplace no tiene versión propia; lo que versiona es cada plugin. Los usuarios actualizan con `/plugin marketplace update ai-forge` + reinstalar.
