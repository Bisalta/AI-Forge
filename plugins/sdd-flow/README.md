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
| `/sdd "<idea>"` | Ciclo completo: refinement → contract → spec → ejecución multi-agente → Feature Ready |
| `/sdd-enrich "<idea>"` | Solo refinement (cerrar decisiones) |
| `/sdd-contract` | Generar/ver el High-Level Technical Contract |
| `/sdd-status` | Tablero de agentes y tareas en vuelo |
| `/sdd-pr` | Descripción de PR desde los cambios |
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
├── commands/                    /sdd, /sdd-enrich, /sdd-contract, /sdd-status, /sdd-pr
├── skills/
│   ├── enrich-user-story/       refinement decision-closed (de Construplaza)
│   ├── sdd-plan/                planner Opus: HLTC + task briefs (closure rules)
│   └── write-pr-report/         descripción de PR (de Construplaza)
├── agents/
│   ├── implementing-agent.md    ejecutor (Sonnet default)
│   └── reviewer-agent.md        revisor adversarial (Opus)
├── hooks/statusline.sh          badge [SDD · fase x/5 · n agentes]
├── standards/base-standards.md  reglas no negociables
└── templates/                   doc_architecture.md, doc_verification_guide.md
```

## Estado

**v0.1.0 — esqueleto / prototipo.** Falta cablear: orquestación real de spawn de subagentes, protocolo `AGENT_{uuid}` completo, statusline state.json, marketplace.json. Ver design doc (pendiente).
