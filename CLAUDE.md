# CLAUDE.md — AI-Forge

Guía para Claude Code al trabajar en este repo. Captura el contexto de diseño de la sesión donde nació el proyecto.

## Qué es

**AI-Forge** = marketplace interno de **Bisalta Ltda** (hosteado en `github.com/Bisalta/AI-Forge`) para tooling de Claude Code. Dos plugins: **`sdd-flow`** (SDD multi-agente) y **`project-foundation`** (los seis docs fundacionales de un proyecto).

**Objetivo**: standard de empresa (NO obligatorio) para que todos los devs usen Claude de forma eficiente y consistente.

Install para cualquier dev:
```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow
/plugin install project-foundation
```

## El plugin sdd-flow — concepto

Pipeline SDD: **planner Opus 4.8** cierra decisiones y corta tareas → **subagentes** las ejecutan (Sonnet default, Opus si pesada, Haiku si trivial) → coordinación file-based multi-repo con topología flexible `AGENT_{uuid}` (cada agente = repo + branch + working-dir).

### Ciclo (basado en el "Ciclo de desarrollo SDD" de LIDR)
```
USER STORY
  → DECISION-CLOSED REFINEMENT      (skill enrich-user-story · Opus)
  → HIGH-LEVEL TECHNICAL CONTRACT   (skill sdd-plan · auto-approve+log · single-writer)
  → IMPLEMENTATION SPEC             (task briefs por AGENT_{uuid} · modelo por tarea)
  → IMPLEMENTING AGENT + REVIEW ↻   (implementing-agent Sonnet · reviewer-agent Opus)
  → BRANCH·TESTS·DOCS·CODE·TESTING REPORT·PROPOSAL UPDATE
  → FEATURE READY  ←★ ÚNICO gate humano  → FEATURE FOR PR → FEATURE PUBLISHED
```
Diagrama renderizado: `cross_agent_implementations/sdd-cycle-v2.jpg`.

## El plugin project-foundation — concepto

Empaqueta el skill personal `project-foundation` (que ya vivía en `~/.claude-personal/skills/`) para distribuirlo como standard de empresa. Genera los **seis documentos fundacionales** de un proyecto (PRD → TRD → UI/UX Brief · App Flow · Backend Schema → Implementation Plan) en `docs/foundation/`, greenfield (entrevista) o derivando de un codebase existente. Standalone — no depende de `sdd-flow` — pero si ambos están instalados, `sdd-flow` puede leer sus outputs (ver PR de bootstrap de docs fundacionales en `sdd-flow`, si ya se mergeó).

## Decisiones de diseño tomadas (no re-litigar)

1. **Forma = plugin** (no skill suelto): empaqueta commands+skills+agents+hooks, distribuible por marketplace, versionable.
2. **Gate humano único = desde Feature Ready.** El pipeline `User Story → Feature Ready` corre **autónomo, sin aprobación humana intermedia**. (Se descartó el gate de aprobación de contract — opción A elegida por el usuario.)
3. **Spec review = solo agentes, sin humano**: self-review ó `reviewer-agent` en Opus (sin sesgo). Configurable.
4. **Contract single-writer**: solo el planner escribe `contract.md`; los agentes mandan `contract-change-request`; el planner ratifica y bumpea versión (v1→vN). Mejor que ack-gating peer-to-peer; escala a N agentes.
5. **Orden de integración**: cuando hay dependencias entre repos, se declara el orden de merge (ej. BE→FE→mobile).
6. **Escape hatch**: "decision-closed" = lista de open-questions vacía o riesgo aceptado. En ejecución, decisión no resuelta → agente queda **BLOCKED → pregunta al planner, NO adivina**.
7. **Closure rules innegociables** (porque el contract se auto-aprueba): prohibido "if needed / or / prefer / may be / when available / derived from". Si dos ingenieros lo implementarían distinto, el contract es inválido.

## Orígenes (de dónde se copió)

- **Núcleo SDD** ← `github.com/Construplaza/TemplateNewRepository`, carpeta `SDD/`:
  - `skills/enrich-user-story` y `skills/write-pr-report` → copiados tal cual.
  - `docs/doc_ai_planning_mode.md` → base del skill `sdd-plan` (HLTC, Architectural Delta, closure rules, task briefs con IDs `T<fase>.<i>`, Execution Report, Accountability).
  - `specs/base-standards/` (000-009) → condensado en `standards/base-standards.md`.
  - `docs/doc_architecture.md` + `docs/doc_verification_guide.md` → `templates/`.
  - Patrón symlinks `.claude/.codex/.cursor → ai-specs` (un set de specs, 3 herramientas).
- **Capa multi-agente** ← protocolo de `cross_agent_implementations/` (inbox/outbox numerado, ownership 1-way, status board). Generalizado de BE/FE/mobile hardcodeado a `AGENT_{uuid}`.

## Estructura

```
AI-Forge/
├── .claude-plugin/marketplace.json   índice (owner: Bisalta Ltda)
├── plugins/sdd-flow/
│   ├── .claude-plugin/plugin.json    v0.11.0
│   ├── commands/   sdd-init · sdd · sdd-enrich · sdd-contract · sdd-verify · sdd-status · sdd-pr · sdd-fixes · sdd-agents · sdd-seo
│   ├── skills/     sdd-init · enrich-user-story · sdd-plan · sdd-verify · sdd-seo · write-pr-report
│   ├── agents/     implementing-agent (sonnet) · reviewer-agent (opus)
│   ├── hooks/      statusline.sh · hooks.json · guard-git.sh (PreToolUse Bash; SDD_PROTECTED_BRANCHES)
│   ├── scripts/    sdd-check.sh (diff) · sdd-run-gates.sh (corre escalera y GENERA evidencia) · sdd-lint-contract.sh (closure)
│   ├── evals/      golden-requirements.md (un golden por arquetipo + propiedades; insumo de la poda)
│   ├── standards/  base-standards.md · quality-gates.md (§10 mutación) · orchestration.md · security.md · archetypes.md (10) · concerns.md · seo-frontend.md
│   └── templates/  doc_architecture.md · doc_verification_guide.md · doc_quality_gates.md · verification-report.md · adr.md · debt-ledger.md · feature-ready-brief.md · coordination-README.md
├── plugins/project-foundation/
│   ├── .claude-plugin/plugin.json    v0.1.0
│   ├── commands/   init (→ /project-foundation:init)
│   └── skills/     project-foundation (los seis docs fundacionales)
├── CHANGELOG.md · README.md · .gitignore
```

## Estado actual: v0.11.0 — la evidencia no puede mentir por descuido

**v0.11.0** (PR #8, ciclo `/sdd` `GEN-94`): seis requerimientos pedidos por **SICOP** y **Taller de Servicio** tras medir el proceso en producción, más el `project-scaffold` que este repo necesitaba para poder probarse a sí mismo. Todos atacan la misma familia: **un artefacto que afirma una propiedad que no puede sostener**.

- **El runner sella el árbol verificado, no `HEAD`** — `sdd-run-gates.sh` (v0.12.0) estampa el hash del árbol que corrió y **sale 4 negándose a escribir** cuando el destino es evidencia commiteable y el árbol está sucio. La estrictez se deriva del path de `-o`, no de una bandera: el modo de falla es el olvido, y una bandera que hay que recordar lo reproduce. `git write-tree` está descartado (sólo captura el índice); va `git stash create`.
- **Identidad de agente** — `sdd-agent`, enforceada por `guard-git.sh` con `SDD_AGENT_ENFORCE=1`, **por encima** del hatch de rama y del caso detached. Nace apagado. Habilita cualquier gate con humano en el circuito, que hasta ahora era inexpresable.
- **`quality-gates.md` §10 — prueba por mutación** de todo AC de detección, en cualquier arquetipo (antes sólo `bugfix`). Evidencia = triple **verde → rojo → verde**. §10.1 trae el criterio de clasificación cerrado y enumerativo, que es lo único que evita triplicar el costo de todos los ACs. La mutación la declara el planner en el contract. Las **correcciones post-`APPROVED` vuelven al loop**.
- **Décimo arquetipo `analysis`** — el análisis que produce números para decidir entra al mismo flujo que el código. Antes no podía: ninguno de los nueve lo cubría y el refinement exige exactamente uno.
- **Identidad de contenido de los docs** — el runner estampa `sha256:` del doc de gates (una ruta no identifica un contenido), `sdd-init` no sobrescribe un doc trabajado a mano sin mostrar el diff, y el reviewer distingue "evidencia podrida" de "los gates cambiaron durante el ciclo".
- **`sdd-check.sh`** deja de marcar la prosa que describe lo que prohíbe.

**Lo que dejó el kilometraje** (pendiente #1, ahora cerrado): `SDD/retro.md` con 11 entradas y `SDD/debt.md` con 11 ítems, escritos durante el ciclo. El hallazgo de fondo: de los ocho defectos que el review encontró, **seis eran del plan, no del código** — en los seis el implementador cumplió literalmente lo pedido y lo pedido estaba mal. Y una clase que no estaba en ninguna propuesta: **la medición que no mide lo que dice medir**, cinco veces (un hook que señala por JSON y no por exit code, un `PATH` con builtins shadowed, `git ls-files` y `git stash create` que no ven untracked, y un arnés que devolvía `127` sin correr nada). La regla que sale: **un triple cuyas tres corridas no se distinguen no es un triple, es una medición muerta**.

Los scripts versionan **independiente** del plugin a propósito: `sdd-init` usa `--version` para decidir si actualiza una copia local, así que bumpear scripts que no cambiaron ofrecería actualizar archivos idénticos.

## Historial: v0.10.0 — evidencia generada + hardening

**v0.10.0** (mismo PR): hardening sobre el análisis de modos de falla. **La evidencia deja de escribirla un modelo**: `scripts/sdd-run-gates.sh` corre la escalera desde `doc_quality_gates.md` y emite él mismo el reporte con exit codes (+ JSON `sdd.gates`); reporte manuscrito sin razón = BLOCKER. **Closure linteable**: `scripts/sdd-lint-contract.sh` (frases abiertas = BLOCKER, paths alucinados = WARN) corre en el self-review del planner, en `/sdd` Fase 2 y en el reviewer — un linter rojo prueba que NO hay closure. **Greenfield con gates vivos**: noveno arquetipo `project-scaffold` obligatorio como primera task en repo sin escalera. **Contract fixtures** para interfaces compartidas (pares request/response que ambos agentes testean — el drift BE↔FE se detecta en test). **Feature Ready brief** de una pantalla (`templates/feature-ready-brief.md`) para que el único gate humano no sea rubber-stamp. **Anti-fatiga** en el refinement (inferir primero con evidencia, ≤2 rondas, paquete de defaults ante fatiga). **Proporcionalidad**: vía corta `/sdd-fixes` con mini-DoD (test + runner verde + cero mitigaciones). **Evals del propio plugin** (`evals/golden-requirements.md`, G1-G11 incl. adversariales) — insumo de la poda futura. Hardening mecánico: ramas protegidas configurables (`SDD_PROTECTED_BRANCHES`, globs), patrones de `sdd-check` extensibles por repo, scripts versionados (`--version`), lock de planner en el state. Spec en `docs/specs/2026-08-04-evidence-hardening-design.md`.

**v0.9.0**: tres frentes. (1) **Contrato de máquina** (`standards/orchestration.md`): `.sdd/state.json` single-writer compatible con la statusline, retornos `sdd.result`/`sdd.review` (último bloque JSON de cada subagente), spawn real vía Agent tool con modelo por brief y **fallback inline** (Workflow tool descartado: requiere opt-in), serialización un-agente-por-repo, caps duros (3 rondas · 2 reintentos de gate · 3 paralelos · 1 re-spawn), resume tras crash (Fase −1 de `/sdd`) y retro (`SDD/retro.md`). La Fase 1 mecánica del review ahora es un script determinístico (`scripts/sdd-check.sh`, fail-open, exit 2 con BLOCKERs candidatos; `/sdd-init` lo copia a `SDD/scripts/` para CI). (2) **Seguridad como gate** (`standards/security.md`): threat model de 4 preguntas cerradas en el HLTC, ACs negativos obligatorios (403/401/**IDOR**/input hostil), gate 9 (secret scan + audit de deps, critical/high = BLOCKER), supply chain (dependencia nueva = decisión del contract; de contrabando = MAJOR). Más memoria de mantenibilidad: ADRs (`docs/adr/`), ledger de deuda (`SDD/debt.md`), DoD ítem 9, umbrales estructurales, paridad con CI ofrecida por `/sdd-init`. (3) **Arquetipos + concerns** (cierra pendiente #5): 8 arquetipos con NFR/tests/checklist→ACs (`standards/archetypes.md`, exactamente uno por requerimiento), concerns transversales con el patrón `seo:` generalizado (`standards/concerns.md`; security/observability siempre blocking, performance blocking solo con número), `enrich-user-story` con dimensiones 7-9 y bloques `archetype:`/`nfr:`/`concerns:`. Spec en `docs/specs/2026-08-04-orchestration-archetypes-security-design.md`.

**v0.8.0**: la calidad pasa de declarada a verificable. El plugin ya cerraba bien *qué* construir; esto cierra *cómo se prueba*. Nuevo `standards/quality-gates.md` (ship con el plugin, ya no un puntero al repo de standards de la empresa): **Definition of Done** idéntica para cualquier requerimiento, **acceptance criteria numerados `AC1..ACn`** en el HLTC con **binding AC↔test obligatorio** (AC sin test = BLOCKER, aunque la suite esté verde), **escalera de gates** fija con los comandos reales del repo en el nuevo `SDD/docs/doc_quality_gates.md` (lo genera `/sdd-init` — nadie inventa comandos), **evidencia con exit codes** en `verification/AGENT_<slug>.md` (nada se declara `done` sin ella; bugfix exige doble corrida del test de reproducción), **mitigaciones prohibidas** explícitas (ablandar tests, `@ts-ignore`, bajar thresholds, `--no-verify` → BLOCKED y pregunta al planner), **reviewer con Fase 1 mecánica** (grep + re-corrida propia del subset barato) y **severidades + cota de 3 rondas + `ESCALATE`**. Nuevo `/sdd-verify` (escalera on-demand + evidencia) y **primer enforcement determinístico** del plugin: `hooks/guard-git.sh` (`PreToolUse` sobre Bash) bloquea commit en rama protegida, `--no-verify` y `push --force` sin lease — fail-open, escape hatch `SDD_ALLOW_BASE_COMMIT=1`. Spec en `docs/specs/2026-08-04-quality-gates-design.md`.

**v0.7.0**: nuevo comando+skill `/sdd-init` — bootstrapea `SDD/docs/doc_architecture.md` y `doc_verification_guide.md` (derivar de codebase existente o entrevistar en greenfield) en vez de dejarlos como esqueleto `[PLACEHOLDER]`. Antes de esto, si esos docs no existían llenos, `enrich-user-story` frenaba sin ninguna ruta de recuperación dentro del plugin. Si el repo ya tiene `docs/foundation/` (seis documentos de un day-zero externo — convención del skill `project-foundation`), `doc_architecture.md` referencia `02-trd.md`/`05-backend-schema.md` en vez de duplicarlos; `doc_verification_guide.md` siempre se genera fresco. Además, `enrich-user-story` ahora lee `docs/foundation/01-prd.md` si existe (opcional, no bloqueante) para anclar actor/success-criteria en producto real, y `sdd-plan` chequea `docs/foundation/06-implementation-plan.md` si existe para detectar scope creep contra el roadmap. Spec en `docs/specs/2026-08-03-foundation-docs-bootstrap-design.md`.

**v0.6.0**: SEO frontend como concern **advisory** (nunca bloquea Feature Ready) para proyectos con front. Activación por pregunta en `enrich-user-story` (no automática): persiste como bloque `seo: { applies, indexable, locales }` en el contract. Checklist 2 tiers (Universal / Indexable) en `standards/seo-frontend.md`. `sdd-plan` inyecta criterios SEO decision-closed al HLTC y briefs cuando `seo.applies`. `reviewer-agent` reporta sección "SEO (advisory)" sin bloquear. Nuevo command + skill `/sdd-seo` (auditoría on-demand, Lighthouse o fallback estático). Spec en `docs/specs/2026-06-22-seo-frontend-advisory-design.md`.

**v0.5.0**: integración Proxima (Fase 0 en `/sdd`: detectar MCP → match proyecto → preguntar → tarea madre + subtask por agente, planner single-writer del MCP) y branch `{action}-{KEY_MADRE}-{agente}-{desc}` atada al key de la tarea madre (las subtasks Proxima no tienen key, solo UUID; reemplaza `<MODULO>-<TICKET>` con Proxima, fallback sin él); cierre de tarea al integrar. **Flexible por entorno (capas de integración)**: git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → ciclo sin branch/PR. Corre con o sin el MCP `proxima`. Spec en `docs/specs/2026-06-16-proxima-branch-pr-rules-design.md`.

**v0.4.0**: regla dura de branching (branch por trabajo, base confirmada, integración solo PR) aplicada en standards, `/sdd-fixes`, protocolo de coordinación y kickoffs.

**v0.2.0**: comando `/sdd-fixes` (batch de fixes con intake+triage+visualizador `fixes.md`) y badge statusline `⚡ fixes N/M` — spec en `docs/specs/2026-06-09-sdd-fixes-command-design.md`.

**v0.3.0**: comando `/sdd-agents` (bootstrap coordinación multi-agente `AGENT_<slug>` + kickoff prompts) y template `coordination-README.md` con el protocolo — spec en `docs/specs/2026-06-10-sdd-agents-bootstrap-design.md`. Cierra pendiente #2.

**Funciona de verdad**: bootstrap de docs (`sdd-init`), refinement (`enrich-user-story`), generación de contract (`sdd-plan`) y gates+evidencia (`sdd-verify`). Son prompts/skills reales. Componentes que **enforcean** sin depender de que el modelo obedezca: `hooks/guard-git.sh` y `scripts/sdd-check.sh`.

**Pendiente**:
1. ~~**Orquestador real `/sdd`**~~ — ✅ CERRADO en v0.11.0. El contrato se cerró en v0.9.0; el **kilometraje real** llegó con el ciclo `GEN-94`: seis requerimientos de punta a punta sobre este mismo repo, 42 ACs, 8 versiones de contract, tres `ESCALATE`/`REJECTED` resueltos. El parseo de `sdd.result` aguantó las 14 invocaciones sin un solo fallo. Lo que crujió está en `SDD/retro.md` (11 entradas) y `SDD/debt.md` (11 ítems), y varias entradas proponen ajustes concretos al plugin que **todavía no se implementaron** — en particular que `sdd-lint-contract.sh` detecte secciones obligatorias ausentes (hoy sólo mira frases y paths, y por eso un contract sin threat model se auto-aprobó) y que el self-review de `sdd-plan` verifique cada AC contra el out-of-scope de su propio requerimiento.
2. ~~**Bootstrap `AGENT_{uuid}`**~~ — ✅ CERRADO en v0.3.0 con `/sdd-agents`.
3. ~~**statusline `state.json`**~~ — ✅ CERRADO en v0.9.0 (el orquestador lo escribe; la statusline muestra gates y ACs sin test).
4. **Design doc formal** del plugin (el flujo de brainstorming quedó en diagrama, falta el doc en `docs/`).
5. ~~**Arquetipos + bloque `nfr:`**~~ — ✅ CERRADO en v0.9.0 (`standards/archetypes.md` + `standards/concerns.md` + dimensiones 7-9 de `enrich-user-story`).
6. **Enforcement de caps por hook** (hoy los caps son prompt del orquestador) — evaluar cuando el orquestador tenga kilometraje.
7. **Modo opt-in `--hasta-pr`** (de Feature Ready a PR abierto) — cambia la decisión #2; solo si el usuario lo pide explícito.

## Convenciones

- **Versionado**: SemVer por plugin en su `plugin.json`. Bumpear + anotar en `CHANGELOG.md` (orden descendente) + commit/push. Marketplace no tiene versión propia.
- **Plugin nuevo**: `plugins/<nombre>/.claude-plugin/plugin.json` + registrar en `marketplace.json` (`source: "./plugins/<nombre>"`).
- **Modelos**: Opus 4.8 = `claude-opus-4-8`, Sonnet 4.6 = `claude-sonnet-4-6`, Haiku 4.5 = `claude-haiku-4-5-20251001`. En agents frontmatter alcanza con `opus`/`sonnet`/`haiku`.
- **Commits**: convención Construplaza `[TIPO] [TICKET] [Módulo] [Descripción]` (ADD/FIX/REF/IMP/REM/REV/MOV/REL). Cerrar con `Co-Authored-By: Claude Opus 4.8`.
- **Branching (regla dura, aplica también a ESTE repo)**: todo trabajo (feature/fix/lo que sea) nace en branch nueva — NUNCA commits directos a `main` ni ramas normales. Elegir y confirmar la rama base antes de crear la branch (`<MODULO>-<TICKET>`, sin ticket `<MODULO>-<desc>`). Integración SOLO vía PR.
- Idioma: bilingüe ES/EN, match al thread.

## Próximo paso sugerido

**Kilometraje real** (#1): correr `/sdd` de punta a punta en un repo de verdad — un requerimiento chico por arquetipo distinto — y anotar en `SDD/retro.md` todo lo que cruja (parseo de `sdd.result`, resume, serialización por repo, ruido de los checklists). El plugin ya tiene la superficie normativa completa; lo que falta no es más spec, es fricción real que diga qué sobra y qué falta ajustar.
