# sdd-flow

Plugin de Claude Code para **Spec-Driven Development** multi-agente. Standard de empresa (opcional) para exprimir Claude de forma eficiente y consistente.

Planner **Opus 4.8** cierra decisiones y corta tareas → subagentes **Sonnet** (default) / **Opus** (pesadas) / **Haiku** (triviales) ejecutan → coordinación file-based multi-repo con topología flexible `AGENT_{uuid}`. Pipeline autónomo hasta **Feature Ready**; el humano revisa de ahí en adelante.

Núcleo SDD adaptado de [`Construplaza/TemplateNewRepository`](https://github.com/Construplaza/TemplateNewRepository) (`SDD/`). Capa multi-agente adaptada del protocolo `cross_agent_implementations`.

## Instalación

```
/plugin marketplace add Construplaza/sdd-flow
/plugin install sdd-flow
```

## Uso

| Comando | Qué hace |
|---|---|
| `/sdd-init` | Bootstrapea `SDD/docs/doc_architecture.md` y `doc_verification_guide.md` (derivar o entrevistar) |
| `/sdd "<idea>"` | Ciclo completo: refinement → contract → spec → ejecución multi-agente → Feature Ready |
| `/sdd-enrich "<idea>"` | Solo refinement (cerrar decisiones) |
| `/sdd-contract` | Generar/ver el High-Level Technical Contract |
| `/sdd-status` | Tablero de agentes y tareas en vuelo |
| `/sdd-pr` | Descripción de PR desde los cambios |
| `/sdd-agents` | Bootstrap de coordinación file-based multi-agente (`AGENT_<slug>`) |
| `/sdd-fixes` | Batch de fixes con intake + triage automático |
| `/sdd-seo` | Auditoría SEO advisory on-demand del frontend. |

## Ciclo

```
USER STORY
  → DECISION-CLOSED REFINEMENT      (enrich-user-story · Opus)
  → HIGH-LEVEL TECHNICAL CONTRACT   (sdd-plan · auto-approve + log · single-writer)
  → IMPLEMENTATION SPEC             (task briefs por AGENT_{uuid} · modelo por tarea)
  → IMPLEMENTING AGENT + REVIEW ↻   (implementing-agent Sonnet · reviewer-agent Opus)
  → BRANCH · TESTS · DOCS · CODE · TESTING REPORT
  → FEATURE READY  ← gate humano    → FEATURE FOR PR → FEATURE PUBLISHED
```

Diagrama: ver `sdd-cycle-v2.jpg` en `cross_agent_implementations/`.

## Estructura

```
sdd-flow/
├── .claude-plugin/plugin.json   manifest
├── commands/                    /sdd-init, /sdd, /sdd-enrich, /sdd-contract, /sdd-status, /sdd-pr, /sdd-agents, /sdd-fixes, /sdd-seo
├── skills/
│   ├── sdd-init/                bootstrap de docs fundacionales (derivar o entrevistar)
│   ├── enrich-user-story/       refinement decision-closed (de Construplaza; lee PRD si existe)
│   ├── sdd-plan/                planner Opus: HLTC + task briefs (closure rules)
│   ├── sdd-seo/                 auditoría SEO advisory on-demand
│   └── write-pr-report/         descripción de PR (de Construplaza)
├── agents/
│   ├── implementing-agent.md    ejecutor (Sonnet default)
│   └── reviewer-agent.md        revisor adversarial (Opus)
├── hooks/statusline.sh          badge [SDD · fase x/5 · n agentes]
├── standards/base-standards.md  reglas no negociables
└── templates/                   doc_architecture.md, doc_verification_guide.md, coordination-README.md
```

## Estado

**v0.7.0.** Funcionan de verdad como prompts/skills: `/sdd-init`, refinement (`enrich-user-story`) y generación de contract (`sdd-plan`). Pendiente de cablear: orquestación real de spawn de subagentes para `/sdd`, statusline `state.json` (nadie lo escribe todavía). Ver `CHANGELOG.md` para el detalle versión por versión y `CLAUDE.md` para el estado completo del roadmap.
