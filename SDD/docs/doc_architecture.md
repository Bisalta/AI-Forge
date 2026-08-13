# Architecture Guide — AI-Forge

## Purpose

Referencia canónica de arquitectura de este repo para agentes y devs. Este repo **es** un marketplace de plugins de Claude Code (`Bisalta/AI-Forge`) — no tiene backend, frontend ni base de datos: el "producto" es el árbol de archivos (comandos, skills, agentes, hooks, standards) que un plugin instala en la sesión de Claude Code de quien lo use.

Usalo para decidir:
1. Dónde va un archivo nuevo (¿es producto del plugin, o andamiaje de ESTE repo?).
2. Qué separa `plugins/` de `SDD/` — la distinción que más importa acá.
3. Cómo fluye el ciclo SDD entre sus artefactos.
4. Qué no se toca sin decisión explícita del planner.

Para los comandos de verificación, ver [`SDD/docs/doc_quality_gates.md`](./doc_quality_gates.md).

---

## Project Stack

| Layer | Technology |
|-------|-----------|
| Distribución | Claude Code plugin marketplace (`.claude-plugin/marketplace.json`) |
| Runtime de los plugins | Markdown (commands/skills/agents, los interpreta Claude, no un intérprete de código) + JSON de config (`plugin.json`, `hooks.json`) |
| Scripts ejecutables | Bash 3.2 (piso macOS) — `scripts/*.sh`, `hooks/*.sh`, `SDD/tests/*.sh` |
| Tests | Harness bash propio (`SDD/tests/run.sh` + `SDD/tests/test_*.sh`), sin framework externo |
| CI | N/A — sin `.github/workflows` (deuda registrada, ver contract de R0) |
| Auth / DB / infra de app | N/A — no hay backend ni frontend en este repo |

---

## Project Layout

```
AI-Forge/
├── .claude-plugin/
│   └── marketplace.json          ← índice del marketplace (owner: Bisalta Ltda), lista los plugins publicados
├── .github/
│   └── CODEOWNERS                ← reviewers por defecto de los PR (sin workflows todavía)
├── plugins/                      ← PRODUCTO DISTRIBUIBLE — lo que un dev instala en su Claude Code
│   ├── sdd-flow/                 ← plugin principal: pipeline Spec-Driven Development multi-agente
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/             ← /sdd, /sdd-enrich, /sdd-contract, /sdd-status, /sdd-pr, /sdd-fixes,
│   │   │                            /sdd-agents, /sdd-seo, /sdd-init, /sdd-verify (un .md por comando)
│   │   ├── skills/                ← enrich-user-story, sdd-plan, sdd-init, sdd-verify, sdd-seo,
│   │   │                            write-pr-report (cada uno con su SKILL.md)
│   │   ├── agents/                ← implementing-agent.md (sonnet), reviewer-agent.md (opus)
│   │   ├── hooks/                 ← guard-git.sh (PreToolUse/Bash), statusline.sh, hooks.json
│   │   ├── scripts/                ← sdd-run-gates.sh, sdd-lint-contract.sh, sdd-check.sh
│   │   ├── standards/              ← base-standards.md, quality-gates.md, security.md, archetypes.md,
│   │   │                            concerns.md, orchestration.md, seo-frontend.md
│   │   ├── templates/              ← doc_architecture.md, doc_quality_gates.md, doc_verification_guide.md,
│   │   │                            verification-report.md, debt-ledger.md, adr.md, feature-ready-brief.md,
│   │   │                            coordination-README.md — esqueletos que un repo QUE INSTALA el plugin
│   │   │                            copia y llena; nunca se editan pensando en ESTE repo
│   │   └── evals/                  ← golden-requirements.md (casos de referencia del propio plugin)
│   └── project-foundation/         ← segundo plugin: documentos fundacionales de proyecto (PRD/TRD/etc.)
│       ├── .claude-plugin/plugin.json
│       ├── commands/init.md
│       └── skills/project-foundation/SKILL.md
├── docs/                          ← historia de diseño DE ESTE REPO (no de un repo que instale el plugin)
│   ├── plans/                     ← planes de features del propio AI-Forge
│   └── specs/                     ← specs de diseño del propio AI-Forge (una por feature del plugin)
├── SDD/                           ← ANDAMIAJE DE ESTE REPO — instancia del propio pipeline SDD
│   │                                 corriendo sobre sí mismo (AI-Forge se desarrolla con su propio plugin)
│   ├── contracts/                 ← HLTC de cada ciclo /sdd corrido sobre este repo
│   ├── briefs/                    ← task briefs por AGENT_<slug>, uno por requerimiento del contract
│   ├── docs/                      ← doc_architecture.md (este archivo) + doc_quality_gates.md — la
│   │                                 realidad verificada de ESTE repo, generada por R0
│   ├── tests/                     ← harness de tests DE ESTE REPO (run.sh, lib.sh, test_*.sh,
│   │                                 secret-scan.sh); `.tmp/` gitignoreado, fixtures de usar-y-tirar
│   └── verification/              ← verification reports por branch/agente (evidencia de gates)
├── CHANGELOG.md                   ← versiones de cada plugin, orden descendente
├── CLAUDE.md                      ← guía de Claude Code para este repo (contexto de diseño)
├── README.md
└── .gitignore
```

---

## Layer Responsibilities

### `plugins/` — producto distribuible

Todo lo que un dev instala vía `/plugin install <nombre>` vive acá. Es la única carpeta que termina en la máquina de otro repo cuando alguien instala el plugin. **R0 no toca nada acá** (out of scope explícito de su contract) — es la regla general para cualquier tarea de tipo `project-scaffold`/`infra` sobre el propio AI-Forge: el andamiaje de calidad de este repo no es parte del producto.

- `commands/`: un `.md` por slash-command, frontmatter + prompt.
- `skills/<nombre>/SKILL.md`: lógica invocable por Claude (planner, refinement, etc.).
- `agents/`: definición de subagentes (`implementing-agent`, `reviewer-agent`) con su modelo.
- `hooks/`: scripts bash que Claude Code ejecuta en eventos del ciclo de vida (`PreToolUse`, etc.), declarados en `hooks.json`.
- `scripts/`: bash invocado por comandos/skills/hooks (`sdd-run-gates.sh` es el runner de evidencia).
- `standards/`: markdown normativo (quality gates, security, arquetipos, base standards) — la fuente de verdad que commands/skills/agents referencian por sección, nunca recopian.
- `templates/`: esqueletos que un repo consumidor llena con `/sdd-init`; nunca se editan pensando en el propio AI-Forge.

### `SDD/` — andamiaje de ESTE repo

El resultado de correr el propio pipeline `/sdd` sobre AI-Forge. Nunca se mezcla con `plugins/`: un test de `SDD/tests/` prueba scripts de `plugins/sdd-flow/scripts/` desde afuera (invocándolos con su path completo), nunca vive adentro de `plugins/`.

- `contracts/`, `briefs/`: artefactos de planificación de cada ciclo SDD corrido sobre este repo.
- `docs/`: los tres docs que todo repo con `/sdd-init` tiene — acá, `doc_architecture.md` (este archivo) y `doc_quality_gates.md`. (`doc_verification_guide.md` no aplica: v0.10.0 lo reemplazó por el runner + `doc_quality_gates.md`, ver contract R0 "Out of scope".)
- `tests/`: harness propio. `lib.sh` es el único lugar con `assert_*`; `run.sh` descubre y agrega; cada `test_*.sh` es una unidad de comportamiento verificable.
- `verification/`: reportes de evidencia por branch/agente (`templates/verification-report.md`).

### `docs/` (raíz) — historia de diseño del propio AI-Forge

Specs y planes de las features del plugin en sí (ej. `docs/specs/2026-08-04-quality-gates-design.md`). No confundir con `SDD/docs/`: esto es "por qué el plugin es como es", aquello es "cómo se verifica este repo".

---

## Main Flows

- **Ciclo SDD sobre un repo consumidor**: `enrich-user-story` (refinement decision-closed) → `sdd-plan` (HLTC + Architectural Delta + ACs) → task briefs por `AGENT_{uuid}` → `implementing-agent` (Sonnet) ejecuta → `reviewer-agent` (Opus) audita → Feature Ready (único gate humano). Ver `plugins/sdd-flow/commands/sdd.md`.
- **Ciclo SDD sobre AI-Forge mismo** (este repo): idéntico, pero los artefactos caen en `SDD/` de la raíz en vez de en un repo externo — es lo que generó este propio documento (contract `SDD/contracts/2026-08-13-sicop-hardening.md`, tarea R0).
- **Evidencia de gates**: `plugins/sdd-flow/scripts/sdd-run-gates.sh` lee `SDD/docs/doc_quality_gates.md`, corre la escalera de la sección de arriba en orden, y escribe él mismo el reporte con exit codes — nunca lo transcribe un modelo.
- **Instalación por un tercero**: `/plugin marketplace add Construplaza/AI-Forge` → `/plugin install sdd-flow` (u otro plugin de `plugins/`) — lee `.claude-plugin/marketplace.json`.

---

## Naming Conventions

| Artifact | Convention |
|----------|-----------|
| Archivos bash | `kebab-case.sh` (`sdd-run-gates.sh`, `guard-git.sh`, `test_run_gates.sh` es la excepción: prefijo `test_` fijo, lo exige el glob del harness) |
| Funciones bash | `snake_case` (`assert_eq`, `run_gate`, `git_subcommand`) |
| Variables bash | `snake_case` local, `SCREAMING_SNAKE_CASE` para las que actúan como constante de módulo o se exportan (`TEST_FAILURES`, `SCRIPT_DIR`) |
| Docs de standards/specs | `kebab-case.md`, fecha ISO al frente para specs de diseño (`2026-08-04-quality-gates-design.md`) |
| Contracts/briefs SDD | `SDD/contracts/<fecha>-<slug>.md`, `SDD/briefs/<ID-tarea>-<arquetipo>.md` |

---

## File Placement Rules

Al agregar un archivo, decidí por intención:

1. ¿Es parte de lo que un dev instala al hacer `/plugin install`? → `plugins/<plugin>/...` (nunca `SDD/`).
2. ¿Es un test/doc/contract/brief que existe SOLO porque este repo se desarrolla con su propio pipeline SDD? → `SDD/...` (nunca `plugins/`).
3. ¿Es la historia de diseño de una feature del plugin (spec, plan)? → `docs/specs/` o `docs/plans/` (raíz, no `SDD/docs/`).
4. ¿Nuevo slash-command? → `plugins/<plugin>/commands/<nombre>.md`.
5. ¿Nueva regla normativa que aplica a cualquier repo que instale el plugin? → `plugins/sdd-flow/standards/<archivo>.md`, referenciada por sección desde donde haga falta — nunca recopiada.
6. ¿Nuevo test del harness de este repo? → `SDD/tests/test_<algo>.sh`, usando `SDD/tests/lib.sh` para los asserts (nunca un `assert_*` propio).

---

## API Contracts

N/A — no hay API. La única "interfaz pública" de este repo es el árbol de archivos que `marketplace.json` expone y el shape de `SDD/docs/doc_quality_gates.md` que `sdd-run-gates.sh` parsea (tabla `| # | Gate | \`cmd\` | Obligatorio | Notas |`).

---

## Error Handling

- Scripts bash: `set -uo pipefail` (no `-e`, salvo que el script lo justifique) + chequeos explícitos de precondición (`command -v`, `[ -f ... ]`) que degradan con mensaje a stderr y exit code distinto de 0, nunca un fallo silencioso.
- Hooks (`guard-git.sh`): política **fail-open** explícita y documentada — cualquier entorno inesperado (sin `jq`, sin git, JSON raro) deja pasar la operación. Un guard que rompe sesiones es peor que no tener guard.
- `secret-scan.sh` es la excepción deliberada: **fail-closed** (exit 2) si no puede listar los archivos versionados — sin esa lista no hay forma de garantizar nada, así que no se declara verde por default.

---

## Configuration and Environment

- Sin `.env`: no hay secretos de aplicación (este repo no corre un servicio).
- Variables de entorno que sí importan, todas opcionales con default seguro:
  - `SDD_GATE_TIMEOUT` (`sdd-run-gates.sh`): segundos por gate, default 1800, requiere `timeout`/`gtimeout` (no instalado en la máquina de referencia — ver `doc_quality_gates.md`, sección Prerequisitos).
  - `SDD_ALLOW_BASE_COMMIT`, `SDD_PROTECTED_BRANCHES` (`guard-git.sh`): escape hatches del guard de rama protegida.
  - `SDD_CHECK_PATTERNS` (`sdd-check.sh`): archivo de patrones prohibidos extra por repo.

---

## Anti-patterns (Do Not Introduce)

- Lógica de producto (algo que un plugin instalado ejecutaría) puesta en `SDD/` — `SDD/` es sólo andamiaje de este repo.
- Tests de `SDD/tests/` que vivan dentro de `plugins/` (rompe la separación producto/andamiaje) o que dupliquen `assert_*` fuera de `lib.sh`.
- Fixtures de test versionadas fuera de `SDD/tests/.tmp/` (que está gitignoreado) — cualquier repo git/archivo temporal de un test se genera on-the-fly y se limpia con `trap ... EXIT`.
- Inventar un comando de verificación que no se corrió en esta máquina — `doc_quality_gates.md` es el único lugar de verdad para eso.
- Bashismos por encima del piso 3.2 (`declare -A`, `mapfile`, `readarray`, `${var^^}`, `&>>`) — el repo se clona en macOS con bash 3.2 del sistema.
