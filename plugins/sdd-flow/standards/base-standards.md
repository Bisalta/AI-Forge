# Base Development Standards — sdd-flow

Single source of truth para todos los agentes del ciclo SDD. (Condensado de `Construplaza/TemplateNewRepository` → `SDD/ai-specs/specs/base-standards`.)

## Core Rules (no negociables)
1. Leer archivos antes de editar. Nunca adivinar estructura existente.
2. Hacer exactamente lo pedido. Nada más.
3. Cero secretos en código.
4. Solo queries parametrizadas. Nada de concatenación de strings en SQL.
5. Validar todo input en los bordes del sistema (Zod / Pydantic / equivalente del stack).
6. Sin escapes del type-checker: `any`, `dynamic`, `interface{}`, `@ts-ignore`, `# type: ignore` (ver perfiles, `quality-gates.md` §9).
7. **Cada acceptance criterion tiene un test.** "Tests verdes" sin tests nuevos no es cobertura — ver `standards/quality-gates.md`.
8. **Nada se declara `done` sin evidencia**: comando + exit code registrados. Escalera de gates en `quality-gates.md` §4-§5.
9. **Reuse antes de crear**: buscar lo existente (grep) antes de escribir una función/servicio nuevo. Duplicar lógica es un rechazo de review.
10. Tareas chicas, una a la vez. Cambios incrementales. Bugfix = test rojo primero.

## Calidad verificable
`standards/quality-gates.md` es la fuente normativa: Definition of Done, acceptance criteria numerados, binding AC↔test, escalera de gates, contrato de evidencia, **mitigaciones prohibidas** (nunca ablandar un test o silenciar el linter para pasar un gate — eso es BLOCKED y pregunta al planner) y el modelo de severidades del review con cota de 3 rondas.

Los **comandos concretos** de cada repo viven en `SDD/docs/doc_quality_gates.md` (lo genera `/sdd-init`). Ningún agente inventa comandos de verificación.

## Áreas (detalle en el repo standard de la empresa)
- `000-core-principles` · `001-code-quality` · `002-security` · `003-git-workflow`
- `004-testing` · `005-typescript` · `006-react-nextjs` · `007-api-design`
- `008-performance` · `009-ai-agent-behavior`
- **Calidad y testing**: `standards/quality-gates.md` (ship con el plugin — no depende del repo de la empresa).
- **SEO (frontend)**: ver `standards/seo-frontend.md`. Advisory; aplica solo si el contract trae `seo.applies == true`.

## Capas de integración (degradación por entorno)

El flujo se adapta al entorno — detectá una vez al arrancar y avisá la capa elegida:
1. **Git con remote** (`git remote` no vacío) → branch + **PR** contra la base (capa completa, abajo).
2. **Git sin remote** → branch + review obligatorio (`reviewer-agent` Opus o self-review) + **merge local** a la base con `--no-ff`. NUNCA commit directo a la base igual. No hay PR (no hay dónde).
3. **No es git** (carpeta suelta) → avisá una vez y corré el ciclo SDD **sin** la capa de branch/PR. Proxima sigue siendo opcional e independiente de esto.

Proxima es ortogonal a la capa de integración: puede haber tracking Proxima en capa 2 o 3, y no haberlo en capa 1.

## Git / branches (de Construplaza)
- **TODO trabajo (feature, fix, mejora, lo que sea) nace en branch nueva. NUNCA commits directos a ramas normales** (`main`, `dev`, `qa`, `pre-prod` — protegidas, no push directo, no se borran).
- **Rama base: elegirla y confirmarla SIEMPRE** antes de crear la branch — proponé `dev` si existe, sino la default del repo, y confirmá con el usuario/planner.
- **Orden estricto**: primero la tarea Proxima, después la branch (el key debe existir para nombrarla).
- Branch de trabajo:
  - **Con Proxima**: `{action}-{KEY}-{desc}`, `action ∈ feat|fix|chore|refactor|docs`. **`KEY` = key de la tarea madre** (ej. `GEN-30`) — las subtasks Proxima NO tienen key (solo UUID), por eso la branch usa siempre el key de la madre. Multi-agente: insertá el slug del agente para desambiguar → `{action}-{KEY}-{agente}-{desc}` (ej. `feat-GEN-30-be-add-endpoint`). Single-repo: `{action}-{KEY}-{desc}` (ej. `feat-GEN-30-add-endpoint`).
  - **Sin Proxima** (MCP ausente o el usuario declinó): `<MODULO>-<TICKET>` (ej. `COMPRAS-FAC-81`); sin ticket: `<MODULO>-<desc-corta>`.
  - Se borra al integrar.
- Commits: `[TIPO] [TICKET] [Módulo] [Descripción]`. Tipos: ADD/FIX/REF/IMP/REM/REV/MOV/REL.
- **Identidad de agente en el commit**: el implementing-agent commitea con `git -c user.name="$SDD_AGENT_NAME" -c user.email="$SDD_AGENT_EMAIL" commit -m "..."` — default `sdd-agent` / `sdd-agent@users.noreply.github.com`, overrideable por repo con esas dos variables de entorno. El commit nunca toma la identidad git del usuario. Repos que exportan `SDD_AGENT_ENFORCE=1` lo hacen cumplir: `hooks/guard-git.sh` deniega un `git commit` que no declare esa identidad (`quality-gates.md`, regla del AC de autoría tautológico). Sin esa variable en el entorno, el hook no opina — un humano commiteando en el mismo repo no queda bloqueado.
- **Integración** según capa: con remote → **PR** (a CODEOWNERS) hacia la base; sin remote → **merge local `--no-ff`** tras review. Tests verdes obligatorio en ambas. Nunca commit directo a la base.
- **Cierre Proxima**: la tarea/subtask pasa a `done` **cuando se integra** (PR mergeado, o merge local hecho) — no antes. Solo el planner llama al MCP `proxima`; los implementing-agents reportan estado/integración por el canal file-based.

## Modelos (tier, nunca versión)

El plugin declara **tier**, nunca versión. En el frontmatter de agents, skills y commands va
`opus`, `sonnet` o `haiku` — nada más. Los alias resuelven al último modelo de cada tier, así
que se mantienen al día solos.

**Nota de verificación** (agregada tras revisión externa, GEN-101): que el harness honre
`model:` en el frontmatter de un **agent** o un **command** es superficie establecida. Que lo
honre en el frontmatter de un **skill** cuando ese skill se invoca indirectamente (un command
sin `model:` propio que a su vez llama al skill) no está verificado en este repo. Por eso,
donde un skill de tier barato tiene también un command que lo invoca (ej. `write-pr-report` ↔
`/sdd-pr`), **el command declara su propio `model:` en vez de asumir que hereda el del skill**
— defensivo, no una confirmación de que la herencia funciona.

**Un identificador de modelo con número de versión en cualquier archivo del plugin es un
defecto** (`claude-opus-4-8`, `claude-sonnet-4-6`, «Opus 4.8», «Sonnet 4.6»). No porque el
modelo sea peor, sino porque el archivo empieza a mentir el día que sale el siguiente y nadie
lo nota: el alias sigue resolviendo bien mientras la prosa dice otra cosa.

Dos excepciones, ambas por la misma razón — registran un hecho pasado en vez de seleccionar
un modelo futuro:

- El trailer `Co-Authored-By:` de un commit, que atribuye el trabajo al modelo que lo hizo.
- El `CHANGELOG.md` y los design specs, que narran qué pasó y cuándo.

Asignación por tarea (la decide el planner, `sdd-plan` Fase B):

| Tier | Cuándo |
|---|---|
| `opus` | Planner y reviewer, siempre. Tarea pesada o arquitectónica. |
| `sonnet` | Default de todo implementing agent. |
| `haiku` | Trabajo mecánico de contexto acotado, y briefs triviales según el criterio cerrado de `archetypes.md`. |

**El reviewer no baja de `opus`.** Es el detector: en el ciclo GEN-94 encontró ocho defectos y
seis eran del plan, no del código. Abaratarlo ahorra en el único lugar donde el error es caro.

## AI agent behavior
- Scope acotado al task brief. Escalá (BLOCKED) ante decisión faltante — no adivines.
- Confirmá operaciones destructivas.
- Nunca declares una validación que no corriste.

> Nota: este archivo es el puente. Cuando el plugin se instala en un repo Construplaza, los `.mdc` detallados ya viven en `SDD/ai-specs/specs/base-standards/` y mandan esos.
