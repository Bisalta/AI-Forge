# ai-forge

Marketplace interno de **Bisalta Ltda** para tooling de Claude Code — plugins, skills y standards de desarrollo asistido por AI.

## Instalación (en cualquier proyecto)

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow
/plugin install project-foundation
```

Luego tipeá `/` y vas a ver los comandos de cada plugin (`/sdd-flow:sdd`, `/project-foundation:project-foundation`, etc).

## Plugins disponibles

| Plugin | Versión | Qué hace |
|---|---|---|
| [**sdd-flow**](./plugins/sdd-flow) | 0.7.0 | Spec-Driven Development multi-agente: planner Opus 4.8 cierra decisiones y corta tareas, subagentes Sonnet/Haiku ejecutan, coordinación file-based `AGENT_{uuid}`. |
| [**project-foundation**](./plugins/project-foundation) | 0.1.0 | Crea o back-fillea los seis documentos fundacionales de un proyecto (PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan) desde cero o derivando de un codebase existente. Interopera con `sdd-flow` si ambos están instalados. |

## Estructura

```
ai-forge/
├── .claude-plugin/marketplace.json   índice del marketplace
├── plugins/
│   ├── sdd-flow/                      SDD multi-agente (ver su README)
│   └── project-foundation/            seis docs fundacionales (ver su README)
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
| `/sdd-init` | Bootstrapea (o llena) `SDD/docs/doc_architecture.md` y `doc_verification_guide.md` — derivando de un codebase existente o entrevistando en greenfield. Corrélo si `/sdd-enrich` frena por falta de estos docs, o al arrancar sdd-flow en un repo nuevo. |
| `/sdd <idea>` | Ciclo SDD completo: refinement → contract → specs → ejecución multi-agente. Usalo cuando tenés una tarea nueva. |
| `/sdd-enrich <idea>` | Solo la fase de refinement. Útil para cerrar decisiones antes de planear o cuando la tarea es compleja y querés separar el "qué" del "cómo". |
| `/sdd-contract <slug>` | Genera o actualiza el High-Level Technical Contract (HLTC). Útil si ya tenés el requerimiento cerrado y querés planear sin ejecutar. |
| `/sdd-status` | Tablero de estado: tareas activas, bloqueos, mensajes sin procesar entre agentes, versión de contract. Solo lectura. |
| `/sdd-pr` | Genera la descripción del Pull Request a partir de los cambios del repo. Usalo antes de abrir el PR. |
| `/sdd-agents` | Bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) para una task que cruza varios repos. |
| `/sdd-fixes` | Estructura una tanda de fixes/ajustes sueltos en `fixes.md`, con triage automático (trivial/mediano/ambiguo). |
| `/sdd-seo` | Auditoría SEO advisory on-demand del frontend actual contra `standards/seo-frontend.md`. |

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
