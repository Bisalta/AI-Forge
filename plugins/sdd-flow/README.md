# sdd-flow

Plugin de Claude Code para **Spec-Driven Development** multi-agente. Standard de empresa (opcional) para exprimir Claude de forma eficiente y consistente.

Planner **Opus 4.8** cierra decisiones y corta tareas → subagentes **Sonnet** (default) / **Opus** (pesadas) / **Haiku** (triviales) ejecutan → coordinación file-based multi-repo con topología flexible `AGENT_{uuid}`. Pipeline autónomo hasta **Feature Ready**; el humano revisa de ahí en adelante.

Núcleo SDD adaptado de [`Construplaza/TemplateNewRepository`](https://github.com/Construplaza/TemplateNewRepository) (`SDD/`). Capa multi-agente adaptada del protocolo `cross_agent_implementations`.

## Instalación

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow
```

## Uso

| Comando | Qué hace |
|---|---|
| `/sdd-init` | Bootstrapea `SDD/docs/doc_architecture.md`, `doc_verification_guide.md` y `doc_quality_gates.md` (derivar o entrevistar) |
| `/sdd "<idea>"` | Ciclo completo: refinement → contract → spec → ejecución multi-agente → Feature Ready |
| `/sdd-enrich "<idea>"` | Solo refinement (cerrar decisiones) |
| `/sdd-contract` | Generar/ver el High-Level Technical Contract |
| `/sdd-verify` | Corre la escalera de gates y escribe la evidencia (comando + exit code) |
| `/sdd-status` | Tablero de agentes y tareas en vuelo (con estado de gates y ACs sin test) |
| `/sdd-pr` | Descripción de PR desde los cambios |
| `/sdd-agents` | Bootstrap de coordinación file-based multi-agente (`AGENT_<slug>`) |
| `/sdd-fixes` | Batch de fixes con intake + triage automático |
| `/sdd-seo` | Auditoría SEO advisory on-demand del frontend. |

## Calidad verificable

La promesa del plugin es que **no importa el requerimiento**, la salida sea consistente y probada. Eso no se sostiene con prosa, así que `standards/quality-gates.md` lo convierte en artefactos:

- **Acceptance criteria numerados** `AC1..ACn` en el contract → cada uno con **su test declarado** (`archivo::"caso"`). AC sin test no se aprueba, aunque la suite esté verde.
- **Escalera de gates** fija (format → lint → type-check → unit → integration → build → e2e → cobertura del diff) con los comandos reales del repo en `SDD/docs/doc_quality_gates.md`. Nadie inventa comandos.
- **Evidencia con exit codes** por gate en `verification/AGENT_<slug>.md`. Nada se declara `done` sin ella; el reviewer re-corre el subset barato y compara.
- **Mitigaciones prohibidas**: ablandar un test, `@ts-ignore`, bajar un threshold o `--no-verify` para pasar un gate es rechazo directo. El camino es BLOCKED → preguntar al planner.
- **Review con severidades** (`BLOCKER`/`MAJOR`/`MINOR`/`ADVISORY`) y **cota de 3 rondas** con `ESCALATE`, para que el loop no se convierta en presión para ablandar tests.
- **Un guard determinístico** (`hooks/guard-git.sh`): bloquea commit en rama protegida, `--no-verify` y `push --force` sin lease. Fail-open; escape hatch `SDD_ALLOW_BASE_COMMIT=1`.

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
├── commands/                    /sdd-init, /sdd, /sdd-enrich, /sdd-contract, /sdd-verify, /sdd-status, /sdd-pr, /sdd-agents, /sdd-fixes, /sdd-seo
├── skills/
│   ├── sdd-init/                bootstrap de docs fundacionales (derivar o entrevistar)
│   ├── enrich-user-story/       refinement decision-closed (de Construplaza; lee PRD si existe)
│   ├── sdd-plan/                planner Opus: HLTC + task briefs (closure rules, ACs numerados)
│   ├── sdd-verify/              escalera de gates + evidencia con exit codes
│   ├── sdd-seo/                 auditoría SEO advisory on-demand
│   └── write-pr-report/         descripción de PR (de Construplaza)
├── agents/
│   ├── implementing-agent.md    ejecutor (Sonnet default)
│   └── reviewer-agent.md        revisor adversarial (Opus, severidades + ESCALATE)
├── hooks/
│   ├── statusline.sh            badge [SDD · fase x/5 · n agentes]
│   ├── hooks.json               registro de hooks del plugin
│   └── guard-git.sh             PreToolUse: rama protegida · --no-verify · push --force
├── standards/
│   ├── base-standards.md        reglas no negociables
│   ├── quality-gates.md         DoD, ACs↔test, escalera, evidencia, mitigaciones prohibidas
│   └── seo-frontend.md          checklist SEO advisory (2 tiers)
└── templates/                   doc_architecture.md, doc_verification_guide.md, doc_quality_gates.md, verification-report.md, coordination-README.md
```

## Estado

**v0.8.0.** Funcionan de verdad como prompts/skills: `/sdd-init`, refinement (`enrich-user-story`), generación de contract (`sdd-plan`) y `/sdd-verify`. El guard de git es el único componente que enforcea de forma determinística. Pendiente de cablear: orquestación real de spawn de subagentes para `/sdd`, statusline `state.json` (nadie lo escribe todavía), y arquetipos de requerimiento (la otra mitad de la consistencia). Ver `CHANGELOG.md` para el detalle versión por versión y `CLAUDE.md` para el estado completo del roadmap.
