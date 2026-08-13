# sdd-flow

Plugin de Claude Code para **Spec-Driven Development** multi-agente. Standard de empresa (opcional) para exprimir Claude de forma eficiente y consistente.

Planner **Opus 4.8** cierra decisiones y corta tareas → subagentes **Sonnet** (default) / **Opus** (pesadas) / **Haiku** (triviales) ejecutan → coordinación file-based multi-repo con topología flexible `AGENT_{uuid}`. Pipeline autónomo hasta **Feature Ready**; el humano revisa de ahí en adelante.

Núcleo SDD adaptado de [`Construplaza/TemplateNewRepository`](https://github.com/Construplaza/TemplateNewRepository) (`SDD/`). Capa multi-agente adaptada del protocolo `cross_agent_implementations`.

## Instalación

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow@ai-forge
```

**Actualizar** (sin desinstalar): `/plugin marketplace update ai-forge` → `/plugin install sdd-flow@ai-forge` → `/reload-plugins`. El marketplace sirve la rama default del repo — lo mergeado, no lo que está en PRs.

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

## Orquestación

`/sdd` corre con contrato de máquina (`standards/orchestration.md`): estado en `.sdd/state.json` (lo escribe solo el planner; lo leen la statusline y `/sdd-status`), subagentes que retornan bloques JSON parseables (`sdd.result`/`sdd.review`), spawn vía Agent tool con el modelo del brief (fallback inline si el entorno no tiene subagentes), **un agente activo por repo**, caps duros (3 rondas de review · 2 reintentos de gate · 3 agentes paralelos) y **resume**: si la sesión muere a mitad de ciclo, `/sdd` detecta el state y ofrece continuar sin reejecutar lo aprobado.

## Qué exige cada tipo de requerimiento

- **`standards/archetypes.md`** — 10 arquetipos (`api-endpoint · ui-feature · data-migration · background-job · third-party-integration · bugfix · refactor · infra · project-scaffold · analysis`), cada uno con NFR obligatorias, tests exigidos y checklist que entra al contract como ACs. Exactamente uno por requerimiento; repo sin gates → `project-scaffold` primero; trabajo trivial → vía corta `/sdd-fixes` con mini-DoD; entregable que es una conclusión o una cifra → `analysis`.
- **`standards/concerns.md`** — cualidades transversales activadas en el refinement y declaradas blocking/advisory por adelantado: `security` y `observability` siempre; `a11y`/`design` con UI; `data-privacy`, `api-compat`, `i18n` por flag; `performance` blocking solo con presupuesto numérico; `seo` advisory.
- **`standards/security.md`** — threat model de 4 preguntas en el contract, tests negativos obligatorios (403/401/IDOR/input hostil), gate de secret scan + audit de dependencias, y toda dependencia nueva como decisión del contract.

## Calidad verificable

La promesa del plugin es que **no importa el requerimiento**, la salida sea consistente y probada. Eso no se sostiene con prosa, así que `standards/quality-gates.md` lo convierte en artefactos:

- **Acceptance criteria numerados** `AC1..ACn` en el contract → cada uno con **su test declarado** (`archivo::"caso"`). AC sin test no se aprueba, aunque la suite esté verde.
- **Escalera de gates** fija (format → lint → type-check → unit → integration → build → e2e → cobertura del diff → security) con los comandos reales del repo en `SDD/docs/doc_quality_gates.md`. Nadie inventa comandos.
- **Evidencia generada, no declarada**: `scripts/sdd-run-gates.sh` corre la escalera desde el doc de gates y **emite él mismo** el reporte con exit codes — el agente lo referencia, no lo escribe. El reviewer re-corre el subset barato y compara; una tabla manuscrita sin razón es BLOCKER.
- **Mitigaciones prohibidas**: ablandar un test, `@ts-ignore`, bajar un threshold o `--no-verify` para pasar un gate es rechazo directo. El camino es BLOCKED → preguntar al planner.
- **Review con severidades** (`BLOCKER`/`MAJOR`/`MINOR`/`ADVISORY`) y **cota de 3 rondas** con `ESCALATE`, para que el loop no se convierta en presión para ablandar tests.
- **Closure linteable**: `scripts/sdd-lint-contract.sh` — frases abiertas ("if needed", "podría ser") = BLOCKER; paths citados que no existen = WARN. Corre antes de auto-aprobar el contract.
- **Guards determinísticos** (`hooks/guard-git.sh` + `scripts/`): commit en rama protegida (configurable, `SDD_PROTECTED_BRANCHES` con globs), `--no-verify`, `push --force` sin lease. Fail-open; escape hatch `SDD_ALLOW_BASE_COMMIT=1`.

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
│   ├── enrich-user-story/       refinement decision-closed + arquetipo + NFR + concerns
│   ├── sdd-plan/                planner Opus: HLTC + task briefs (closure rules, ACs, threat model, ADRs)
│   ├── sdd-verify/              escalera de gates + evidencia con exit codes
│   ├── sdd-seo/                 auditoría SEO advisory on-demand
│   └── write-pr-report/         descripción de PR (de Construplaza)
├── agents/
│   ├── implementing-agent.md    ejecutor (Sonnet default; retorna sdd.result)
│   └── reviewer-agent.md        revisor adversarial (Opus, severidades + ESCALATE; retorna sdd.review)
├── hooks/
│   ├── statusline.sh            badge [SDD · fase x/5 · agentes · ✓gates ✗rojos]
│   ├── hooks.json               registro de hooks del plugin
│   └── guard-git.sh             PreToolUse: rama protegida · --no-verify · push --force
├── scripts/
│   ├── sdd-check.sh             chequeo mecánico del diff (+ patterns por repo)
│   ├── sdd-run-gates.sh         corre la escalera y GENERA el reporte de evidencia
│   └── sdd-lint-contract.sh     closure del contract (frases abiertas, paths alucinados)
├── evals/
│   └── golden-requirements.md   un golden por arquetipo + propiedades (G1-G11)
├── standards/
│   ├── base-standards.md        reglas no negociables
│   ├── quality-gates.md         DoD, ACs↔test, escalera, evidencia, mitigaciones prohibidas
│   ├── orchestration.md         state.json, retornos sdd.result/sdd.review, spawn, caps, resume
│   ├── security.md              threat model, tests negativos, secret scan + audit, supply chain
│   ├── archetypes.md            9 arquetipos: NFR + tests + checklist por tipo de requerimiento
│   ├── concerns.md              transversales blocking/advisory (a11y, design, privacy, i18n, perf…)
│   └── seo-frontend.md          checklist SEO advisory (2 tiers)
└── templates/                   doc_architecture.md, doc_verification_guide.md, doc_quality_gates.md,
                                 verification-report.md, adr.md, debt-ledger.md, feature-ready-brief.md,
                                 coordination-README.md
```

## Estado

**v0.10.0.** La superficie normativa está completa y lo crítico dejó de depender de prompts: la evidencia la genera un script, el closure se lintea, el greenfield arranca con `project-scaffold`, y el gate humano recibe un brief de una pantalla. Enforcement determinístico: `guard-git.sh`, `sdd-check.sh`, `sdd-run-gates.sh`, `sdd-lint-contract.sh`. Lo que falta es kilometraje real — correr los goldens de `evals/` y ciclos completos en repos de verdad, y podar con esa data (v1.0 debería ser más chica, no más grande). Ver `CHANGELOG.md` y `CLAUDE.md`.
