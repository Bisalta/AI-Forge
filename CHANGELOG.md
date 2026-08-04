# Changelog

Cambios del marketplace `ai-forge`. Orden descendente (lo más reciente primero).

## project-foundation

### 0.1.0 — 2026-08-03
- Plugin nuevo: empaqueta el skill personal `project-foundation` para distribuirlo como standard de empresa (opcional). Crea o back-fillea los seis documentos fundacionales de un proyecto — PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan — desde cero (entrevista, greenfield) o derivando de un codebase existente (subagentes de exploración en paralelo, luego confirma supuestos).
- Escribe por defecto en `docs/foundation/`, con dependencia declarada PRD → TRD → (UI/UX Brief ∥ App Flow ∥ Backend Schema) → Implementation Plan.
- **Interopera con `sdd-flow`** (si también está instalado, no es requisito): habilita que `enrich-user-story` lea el PRD, `sdd-plan` chequee el Implementation Plan, y `/sdd-init` referencie el TRD/Backend Schema en vez de duplicarlos — ver `sdd-flow` 0.7.0.
- Nuevo comando `/project-foundation:init`.

## sdd-flow

### 0.10.0 — 2026-08-04
Hardening sobre el análisis de modos de falla de v0.9.0: la evidencia deja de escribirla un modelo, el closure del contract se lintea, greenfield arranca con gates vivos, y el único gate humano se protege del rubber-stamp. Patrón rector: **mover confianza de prompts a scripts**. Spec en `docs/specs/2026-08-04-evidence-hardening-design.md`.

- **Nuevo `scripts/sdd-run-gates.sh` — evidencia generada, no declarada** (el cambio de confianza más grande): lee la tabla de `doc_quality_gates.md`, corre la escalera en orden, corta al primer rojo y **emite él mismo** el reporte con exit codes, timestamps y output por gate (+ línea JSON `sdd.gates` parseable). El agente referencia el reporte, no lo transcribe; editarlo a mano invalida la evidencia; el reviewer verifica que el reporte sea generado (tabla manuscrita sin razón = BLOCKER). Soporta `--full` (suite completa), `--keep-going` (CI) y `SDD_GATE_TIMEOUT`.
- **Nuevo `scripts/sdd-lint-contract.sh` — closure verificable**: frases que violan las closure rules (ES/EN, saltando bloques de código y las citas de las propias reglas) = BLOCKER; paths citados que no existen en el repo (sin marca `NEW`) = WARN (contract alucinado, de otro repo, o inventario sucio). `sdd-plan` lo corre antes de auto-aprobar; `/sdd` lo exige verde en Fase 2; el reviewer lo corre en Fase 1 y escala frases abiertas como defecto del plan.
- **Nuevo arquetipo `project-scaffold` — greenfield con gates desde el día cero**: en repo sin escalera funcional, la primera task de cualquier `/sdd` es el scaffold (layout, runner con primer test real verde, lint/format/type-check del perfil, `doc_quality_gates.md` re-verificado contra la realidad, scripts copiados, CI si hay remote, tokens de diseño como ADR si hay UI). Cierra el hueco: el sistema de calidad estaba apagado justo al fundar un proyecto.
- **Contract fixtures (multi-repo)**: cuando dos agentes comparten una interfaz, el planner emite `fixtures/<interfaz>.json` (pares request/response reales, single-writer) y cada brief lleva un contract test contra el fixture — el contract pasa de documento a test compartido; el drift BE↔FE se detecta en test, no al integrar.
- **Feature Ready brief (`templates/feature-ready-brief.md`)**: el ping del único gate humano pasa de muro de evidencia a UNA pantalla — qué es, qué decisiones se tomaron por él, dónde está el riesgo, qué mirar en 5 minutos, estado honesto; la evidencia completa queda como apéndice de links.
- **Anti-fatiga en el refinement** (una decisión cerrada por cansancio es peor que una abierta): inferir primero con evidencia y preguntar solo lo no inferible, máximo ~2 rondas agrupadas con `AskUserQuestion`, detección de señales de fatiga → paquete único de defaults con confirmación de una vez, y distinción inferido/confirmado en el artefacto.
- **Proporcionalidad explícita**: la DoD no se negocia, la ceremonia sí — trabajo trivial va por `/sdd-fixes` con **mini-DoD** (branch + test del cambio + runner verde + cero mitigaciones prohibidas); el refinement propone la vía corta solo; un fix que no puede cumplir la mini-DoD no era trivial → `ambiguo` + `/sdd-enrich`.
- **Evals del propio plugin (`evals/golden-requirements.md`)**: un requerimiento golden por arquetipo + propiedades universales (linter verde, ACs, threat model, ≤2 rondas de refinement) y específicas (IDOR en endpoint, 4 estados en UI, dry-run en migración…), más goldens adversariales (trabajo doble → partir en dos; typo → vía corta). Base de la poda: v1.0 debería ser más chica que v0.10.
- **Hardening mecánico**: `guard-git.sh` con ramas protegidas configurables (`SDD_PROTECTED_BRANCHES`, globs — `release/*`, `hotfix/*` cubiertos por default); `sdd-check.sh` con patrones extensibles por repo (`SDD/scripts/sdd-check.patterns` — los markers del stack dejan de ser prosa) y `--version`; `/sdd-init` copia los tres scripts con control de versión (nunca pisa una copia modificada sin mostrar diff) y el CI generado corre el mismo runner (`--keep-going`) — un solo lugar define los comandos.
- **Lock de planner en el state**: campo `planner{session, claimed_at}`; state ajeno con `updated_at` reciente → no asumir ownership, preguntar. `sdd.result.gates[]` debe ser consistente con el reporte del runner — difieren → gana el reporte y el `done` se rechaza. Reviewer: todo hallazgo cita `archivo:línea` leído de verdad.

### 0.9.0 — 2026-08-04
Tres frentes sobre la base de v0.8.0: **contrato de máquina** para orquestación real, **seguridad como gate**, y **arquetipos + concerns** (la otra mitad de "no importa el requerimiento"). Spec en `docs/specs/2026-08-04-orchestration-archetypes-security-design.md`.

**Orquestación (contrato de máquina)**
- **Nuevo `standards/orchestration.md`**: schema de `.sdd/state.json` (single-writer el planner, escrito antes/después de cada transición, compatible con las claves que `statusline.sh` ya leía — el state es índice, la evidencia manda), retornos estructurados **`sdd.result`/`sdd.review`** (último bloque JSON del output de cada subagente; `acs[].state: missing` hace parseable la admisión honesta), aceptación de un `done` validando el artefacto, **caps duros** (3 rondas, 2 reintentos del mismo gate rojo, 3 agentes paralelos, 1 re-spawn por `failed`) y **resume** tras crash (agente `spawned` sin retorno → verificar su branch real y re-spawnear desde el brief).
- **Spawn real en `/sdd`**: Agent tool con el **modelo del brief como override**; sin Agent tool, **degradación inline documentada**. Se descartó Workflow tool (requiere opt-in del usuario, no está en todos los entornos). **Serialización por repo**: un agente activo por working tree; mismo repo → serie o worktrees declarados. Nueva **Fase −1** de resume.
- **Nuevo `scripts/sdd-check.sh`**: la Fase 1 mecánica del review como script determinístico (tests skipeados/eliminados, supresores, `any` nuevo, configs ablandadas, catch silencioso; exit 2 con BLOCKERs candidatos, fail-open fuera de git). El script propone, el reviewer confirma contra el contract. `/sdd-init` lo copia a `SDD/scripts/` para que review y CI lo corran sin el plugin.
- `statusline.sh` muestra gates (`✓/✗`) y ACs sin test desde el state; `/sdd-status` usa el state como fuente primaria (la evidencia gana ante discrepancia). Retro: `SDD/retro.md` append-only (una línea por `ESCALATE`/blocker repetido); en Feature Ready, patrones repetidos → propuesta de ajuste a docs.

**Seguridad (nuevo `standards/security.md`)**
- **Threat model mínimo de 4 preguntas cerradas** en el HLTC para toda superficie invocable; sin superficie nueva → `N/A` explícito. HLTC sin threat model = BLOCKER de contract (el reviewer escala al planner).
- **Tests negativos obligatorios como ACs**: 403 de rol equivocado, 401, **IDOR** (usuario A no toca recursos de B), input hostil — mismo régimen AC sin test = BLOCKER.
- **Gate 9 nuevo en la escalera**: secret scan del diff + audit de dependencias (critical/high directa con fix = BLOCKER, resto al ledger). Sin tooling → grep mínimo declarado, nunca `N/A` silencioso.
- **Supply chain**: dependencia nueva = decisión del contract (justificación + alternativa descartada); implementing agent que la necesita y no está → BLOCKED; meterla de contrabando = MAJOR (el reviewer diffea manifiestos). Reglas de implementación: PII fuera de logs, errores sin detalle interno, authz en la capa declarada (nunca solo front).

**Mantenibilidad con memoria**
- **ADRs** (`templates/adr.md` → `docs/adr/`): el planner los emite cuando la decisión sobrevive a la task; `/sdd-init` y el refinement los leen después.
- **Ledger de deuda** (`templates/debt-ledger.md` → `SDD/debt.md`): `MINOR` sin corregir, `N/A` aceptados y vulns sin fix, con dueño y estado; el reviewer los registra al aprobar. **DoD ítem 9**: contabilidad cerrada.
- Reviewer: umbrales estructurales como señal `MAJOR` sin justificación (12c), cediendo ante el patrón del repo.
- **Paridad con CI** (`/sdd-init`): con CI existente compara y alinea la escalera hacia CI; sin CI (GitHub) ofrece generar el workflow con los mismos comandos + `sdd-check.sh`. Nunca de oficio.

**Arquetipos + concerns**
- **Nuevo `standards/archetypes.md`**: 8 arquetipos (`api-endpoint · ui-feature · data-migration · background-job · third-party-integration · bugfix · refactor · infra`), cada uno con NFR obligatorias, tests exigidos y checklist que entra al HLTC como ACs (omisión silenciosa = MAJOR de contract). **Exactamente uno por requerimiento**; si parece dos, son dos. Los checklists codifican los failure modes de cada forma: migración → dry-run/conteo/rollback; job → re-entrega/veneno/alarma de silencio; UI → los cuatro estados (vacío·carga·error·éxito); refactor → suite intacta + caracterización previa; bugfix → causa raíz + búsqueda de hermanos.
- **Nuevo `standards/concerns.md`**: el patrón `seo:` generalizado — activación cerrada en refinement (4 flags + observabilidad + presupuesto), blocking/advisory declarado por adelantado. `security` y `observability` siempre blocking; `a11y`/`design` con UI; `data-privacy`, `api-compat`, `i18n` por flag; `performance` blocking solo con número.
- **`enrich-user-story`**: dimensiones 7 (arquetipo), 8 (NFR con valores concretos: authz, volume, idempotency, observability, migration, rollout) y 9 (concerns); el requerimiento lleva bloques `archetype:`, `nfr:` y `concerns:`. **`sdd-plan`** los inyecta como ACs (blocking) o sección advisory.

### 0.8.0 — 2026-08-04
Calidad **verificable** en vez de declarada. El plugin ya cerraba bien *qué* construir; esta versión cierra *cómo se prueba* que se construyó bien, para que la salida sea consistente sin importar el requerimiento. Spec en `docs/specs/2026-08-04-quality-gates-design.md`.

- **Nuevo `standards/quality-gates.md`** — fuente normativa que ship con el plugin (ya no un puntero al repo de standards de la empresa): Definition of Done idéntica para cualquier requerimiento, acceptance criteria numerados, binding AC↔test, escalera de gates, contrato de evidencia, mitigaciones prohibidas, severidades de review y perfiles por stack.
- **Acceptance criteria numerados `AC1..ACn`** en el HLTC (comportamiento observable, uno por test, IDs estables entre versiones) + **impact set** (callers reales de cada símbolo que se modifica, grepeados). Cada brief recibe sus ACs con el ID original; un AC pertenece a exactamente un agente.
- **Binding AC ↔ test obligatorio**: el implementing agent declara el test literal (`archivo::"caso"`) que cubre cada AC. **AC sin test = BLOCKER**, sin importar que la suite esté verde. Un AC sólo verificable a mano se declara `manual-only: <razón>` con pasos de smoke.
- **Escalera de gates fija** (format → lint → type-check → unit → integration → build → e2e → cobertura del diff), corta al primer rojo, suite completa obligatoria antes de integrar. Cobertura **del diff** en lugar de thresholds globales (que son frágiles y se bajan solos).
- **Nuevo `SDD/docs/doc_quality_gates.md`**, generado por `/sdd-init` (nuevo template): los comandos **reales** de cada repo, sus prerequisitos de entorno, rojos preexistentes de la base, tiempo esperado de la suite y markers prohibidos del stack. Ningún agente inventa comandos de verificación; un gate ausente se declara `N/A` con razón.
- **Evidencia como artefacto** (nuevo `templates/verification-report.md` → `tasks/<slug>/verification/AGENT_<slug>.md`, o `SDD/verification/<branch>.md` en single-repo): comando exacto · exit code · timestamp · output por gate, más impact set y rojos preexistentes. Evidencia ausente = BLOCKER. Bugfix: **doble corrida** obligatoria del test de reproducción (rojo antes del fix, verde después).
- **Mitigaciones prohibidas explícitas** (§6): tests borrados/skipeados/aflojados, `@ts-ignore`/`eslint-disable`/`# type: ignore` sin referencia al contract, `any` para callar al type-checker, thresholds bajados, `--no-verify`/`--force`, retry de flaky, catch silencioso, hardcodeo del valor esperado. Ante un gate que no pasa sin uno de estos atajos → BLOCKED y pregunta al planner.
- **`reviewer-agent` con dientes**: Fase 1 mecánica antes de opinar (grep de tests tocados y markers prohibidos, verificación del binding, auditoría de la evidencia y **re-corrida propia del subset barato** — si difiere de la evidencia, la evidencia está podrida). Severidades `BLOCKER`/`MAJOR`/`MINOR`/`ADVISORY`, `APPROVED` sólo con cero BLOCKER y cero MAJOR, y tercer veredicto **`ESCALATE`**.
- **Loop de review acotado a 3 rondas** (`/sdd` Fase 4 y `sdd-plan`). Sin cota, el agente empieza a ablandar tests para salir del loop; con cota, el disenso escala al planner y, si hace falta, al gate humano.
- **Checklist de Feature Ready** en `/sdd` Fase 5: ACs cubiertos, suite completa corrida, evidencia por agente, cero mitigaciones prohibidas, `APPROVED` por brief, docs delta aplicado.
- **Nuevo command + skill `/sdd-verify`**: corre la escalera on-demand, distingue rojo propio de rojo preexistente de la base, corre los chequeos mecánicos sobre el diff y escribe el verification report. Veredicto `GATES VERDES` / `GATES ROJOS` / `EVIDENCIA INCOMPLETA`.
- **Enforcement determinístico (nuevo `hooks/hooks.json` + `hooks/guard-git.sh`)**: `PreToolUse` sobre `Bash` que bloquea las tres reglas duras que un agente apurado igual rompe — commit con HEAD en rama protegida, `--no-verify`, y `git push --force` sin `--force-with-lease`. **Fail-open** por diseño (sin `jq`, sin git o JSON inesperado → deja pasar) y con escape hatch `SDD_ALLOW_BASE_COMMIT=1`.
- **`base-standards.md` reescrito** en las core rules: cada AC tiene test, nada se declara `done` sin evidencia, reuse antes de crear, bugfix con test rojo primero. Las reglas con forma de lenguaje (`any`, Zod) se despegaron de TypeScript hacia perfiles por stack.
- **Docs delta como parte del `done`**: si el Architectural Delta tocó capas/rutas/contratos, se actualiza `doc_architecture.md`; si aparecieron comandos nuevos, `doc_verification_guide.md` y `doc_quality_gates.md`. Evita que los docs fundacionales se desactualicen y degraden el refinement siguiente.
- `/sdd-status` ahora reporta gates por agente, ACs sin test, y marca los `done` sin evidencia como trabajo en curso. `write-pr-report` funda la sección Validation en la evidencia registrada (permitido decir qué no se corrió; prohibido afirmar un check sin resultado).

### 0.7.0 — 2026-08-03
- **Nuevo comando + skill `/sdd-init`**: bootstrapea `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` — derivando de un codebase existente o entrevistando en greenfield — en vez de dejarlos como esqueleto `[PLACEHOLDER]`. Cierra el punto de entrada bloqueado: hasta ahora, si esos dos archivos no existían llenos, `enrich-user-story` frenaba antes de la primera pregunta sin ninguna ruta de recuperación dentro del propio plugin.
- **Interoperabilidad con `docs/foundation/`**: si el repo ya tiene los seis documentos fundacionales de un day-zero externo (PRD/TRD/UI-UX/App Flow/Backend Schema/Implementation Plan — convención del skill `project-foundation`), `/sdd-init` referencia `02-trd.md`/`05-backend-schema.md` en vez de duplicar su contenido en `doc_architecture.md`. `doc_verification_guide.md` siempre se genera fresco (ningún equivalente en esos seis documentos).
- **`enrich-user-story` lee el PRD si existe** (`docs/foundation/01-prd.md`, opcional, no bloqueante): las dimensiones *actor y contexto de uso* y *success criteria* ahora pueden anclarse en personas/jobs-to-be-done/métricas de producto reales, en vez de fundamentarse solo en arquitectura de código.
- **`sdd-plan` chequea el roadmap si existe** (`docs/foundation/06-implementation-plan.md`, opcional): antes de cerrar el alcance del HLTC, señala si el scope propuesto choca con una fase declarada como futura, en vez de aceptarlo en silencio.
- Spec en `docs/specs/2026-08-03-foundation-docs-bootstrap-design.md`.

### 0.6.0 — 2026-06-22
- **SEO frontend advisory**: concern SEO agregado al flujo SDD para proyectos con front. Es **advisory** — nunca bloquea Feature Ready. Activación explícita en `enrich-user-story` (pregunta al usuario si aplica SEO); resultado persiste como bloque `seo: { applies, indexable, locales }` en el contract.
- **Checklist 2 tiers en `standards/seo-frontend.md`**: tier Universal (aplica a todo proyecto con front: meta tags, og/twitter cards, canonical, robots, sitemap básico) y tier Indexable (solo cuando `seo.indexable: true`: structured data, hreflang, Core Web Vitals, lazy-load, preload LCP).
- **`sdd-plan` inyecta criterios SEO**: cuando `seo.applies` está seteado en el contract, el planner incluye criterios SEO decision-closed en el HLTC y en los task briefs de los agentes de front.
- **`reviewer-agent` reporta sección "SEO (advisory)"**: sección separada en el reporte de review, sin capacidad de bloquear la aprobación del agente.
- **Nuevo command + skill `/sdd-seo`**: auditoría SEO on-demand del frontend. Corre Lighthouse si está disponible; fallback a auditoría estática contra el checklist de `standards/seo-frontend.md`. Reporta findings sin bloquear el flujo.
- Spec en `docs/specs/2026-06-22-seo-frontend-advisory-design.md`.

### 0.5.0 — 2026-06-16
- **Integración Proxima**: nueva Fase 0 en `/sdd` — detecta el MCP `proxima`, matchea proyecto (auto si único, pregunta si ambiguo), pregunta al usuario si crear tareas y crea la **tarea madre** `in_progress`. En Fase 3, **subtask por agente** (`parentKey`); cada branch usa el key de su subtask. **Single-writer Proxima**: solo el planner llama al MCP; los implementing-agents reportan estado por el canal file-based.
- **Branch atada al task key**: nuevo formato `{action}-{KEY_MADRE}-{agente}-{desc}` (single-repo sin slug) que reemplaza `<MODULO>-<TICKET>` cuando hay Proxima; fallback al viejo formato sin Proxima. Orden estricto: tarea Proxima primero → branch después. Nota: las subtasks Proxima no tienen key (solo UUID) — la branch usa siempre el key de la tarea madre; las subtasks se cierran por su UUID.
- **Cierre por integración**: subtask → `done` cuando se integra (no en Feature Ready); tarea madre → `done` cuando todas las subtasks están `done`.
- **Capas de integración (flexibilidad por entorno)**: el flujo se adapta — git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → corre el ciclo sin capa de branch/PR. Proxima es ortogonal a la capa (sirve en local, sin remote, o sin git). Funciona también sin el MCP `proxima` configurado (Fase 0 cae a fallback).
- Aplicado en `commands/sdd.md`, `standards/base-standards.md`, `skills/sdd-plan`, `agents/implementing-agent`, `commands/sdd-agents` (columnas Proxima key / Branch en el contract + kickoff), `templates/coordination-README.md` (sección Proxima single-writer) y `commands/sdd-fixes`. Spec en `docs/specs/2026-06-16-proxima-branch-pr-rules-design.md`.

### 0.4.0 — 2026-06-10
- Regla dura de branching en todo el flujo: cada feature/fix nace en branch propia (`<MODULO>-<TICKET>`), rama base elegida y confirmada siempre, NUNCA commits directos a ramas normales, integración SOLO vía PR. Aplicada en `base-standards.md`, `/sdd-fixes` (branch+PR por item), protocolo de coordinación (`coordination-README.md`) y kickoffs de `/sdd-agents` (rama base declarada en contract).

### 0.3.0 — 2026-06-10
- Nuevo comando `/sdd-agents`: bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) — estructura de task (contract single-writer, status, logs, mensajes numerados por par direccional) + kickoff prompts por agente. Cierra pendiente #2 del roadmap.
- Template `coordination-README.md`: protocolo completo generalizado a N agentes (mensajes con frontmatter, archive, ownership 1-way, BLOCKED ante ambigüedad, orden de integración).

### 0.2.0 — 2026-06-09
- Nuevo comando `/sdd-fixes`: estructura tandas de fixes/ajustes en `fixes.md` con intake, triage automático (trivial/mediano/ambiguo) y apertura del archivo como visualizador lateral editable. No implementa hasta orden explícita.
- Statusline: badge `⚡ fixes N/M` con progreso del batch, combinable con el badge SDD existente.

### 0.1.1 — 2026-06-09
- Fix: manifest `plugin.json` inválido bloqueaba `/plugin install` (`agents: Invalid input`). Se eliminan las claves `commands`/`skills`/`agents` — apuntaban a los directorios default que Claude Code auto-descubre, y el schema de `agents` espera array de archivos, no string de directorio.

### 0.1.0 — 2026-06-09
- Esqueleto inicial del plugin SDD multi-agente.
- Comandos: `/sdd`, `/sdd-enrich`, `/sdd-contract`, `/sdd-status`, `/sdd-pr`.
- Skills: `enrich-user-story`, `sdd-plan`, `write-pr-report`.
- Agentes: `implementing-agent` (Sonnet), `reviewer-agent` (Opus).
- Hook statusline + standards + templates de contexto.
- Pendiente: cableo del orquestador real (spawn de subagentes, protocolo `AGENT_{uuid}`).
