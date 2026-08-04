---
name: sdd-plan
description: Planner Opus para SDD. Convierte un requerimiento decision-closed en un High-Level Technical Contract senior-reviewable y luego en task briefs ejecutables por subagentes. No implementa codigo. Usar tras enrich-user-story, antes de spawnear agentes.
---

# SDD Planner (Opus)

Sos el planner. **No implementás código.** Producís dos artefactos: el HLTC y los task briefs. Corré preferentemente en **Opus 4.8** (`claude-opus-4-8`).

## Antes de planear
1. Leé `SDD/docs/doc_architecture.md`, `SDD/docs/doc_verification_guide.md` y `SDD/docs/doc_quality_gates.md` de cada repo involucrado. Si no existen, corré el comando `/sdd-init` del plugin para bootstrapearlos (deriva o entrevista) en vez de dejar el HLTC bloqueado. Sin `doc_quality_gates.md` no podés escribir validation steps con comandos reales — los inventarías.
2. Tomá como input el requerimiento decision-closed (salida de `enrich-user-story`).
3. Si existe `docs/foundation/06-implementation-plan.md` (roadmap del proyecto, opcional — no bloquea si falta), leelo antes de cerrar el alcance: sirve para el chequeo de roadmap de la Fase A.

## Fase A — High-Level Technical Contract (HLTC)

Senior-reviewable. Debe cubrir:
- Objective + out-of-scope
- Public contract impact · Input/output exacto · Backward compatibility
- **Architectural Delta** (canónico): API (rutas, schemas), Service (clases/funciones), Domain (mappers/normalizers), Repository, Integration, Test impact, Ownership boundaries (dónde vive / dónde NO), Reuse statement
- Artifact inventory (archivos + símbolos)
- **Impact set**: por cada símbolo que se modifica, los callers/imports existentes (grepealos, no los supongas). Es la base del análisis de regresión de los briefs.
- Source of truth · Mapping ownership
- Error/fallback behavior
- **Acceptance criteria numerados `AC1..ACn`** (ver abajo)
- Validation strategy (por escenario, no comandos)
- Risks

### Acceptance criteria (obligatorio — es lo que hace verificable al contract)
Sección `## Acceptance criteria` con IDs estables `AC1..ACn`. Cada AC:
- describe **comportamiento observable**, no implementación ("devuelve 422 con `code: INVALID_QTY`", no "valida con Zod");
- es verificable por un solo test — si necesita dos, son dos ACs;
- respeta las closure rules (nada de "if needed / or / prefer").

Los IDs son estables entre versiones: un AC retirado se marca `AC4 — retirado en v2`, no se recicla el número. Cubrí con ACs los tres escenarios del expected behavior: flujo normal, edge y falla.

Un AC que sólo se puede verificar a mano se declara explícito `manual-only: <razón>` y el brief lleva los pasos exactos de smoke. `manual-only` sin razón = contract inválido. Detalle en `standards/quality-gates.md` §2.

### SEO (si el contract trae `seo.applies == true`)
Cuando el requerimiento incluye el bloque `seo:` con `applies: true`, agregá al HLTC una sección **aparte** `## SEO criteria (advisory)` con criterios **decision-closed** (sin "if needed / may / prefer"), tomados de `standards/seo-frontend.md`.

**No los numeres como `ACn`**: los ACs son gate de aprobación (AC sin test = BLOCKER) y el SEO es advisory por decisión de diseño (v0.6.0). Usá IDs propios `SEO1..SEOn`. Si un ítem SEO **sí** tiene que ser bloqueante para esta feature (ej. el requerimiento es específicamente "que la landing sea indexable"), entonces promovelo a un `ACn` con su test — pero eso es una decisión explícita del planner, no el default.

Criterios a incluir:
- Siempre el Tier Universal.
- El Tier Indexable solo si `seo.indexable == true`.
- El ítem `hreflang` solo si `seo.indexable == true` **y** `seo.locales` tiene ≥2 entradas (es directiva de indexación: sin sitio indexable no aplica aunque sea multi-idioma).
Si `seo.applies == false` o no hay bloque `seo:`, no agregues criterios SEO.

### Chequeo de roadmap (si existe `docs/foundation/06-implementation-plan.md`)
Antes de cerrar el "Objective + out-of-scope" del HLTC, comparalo contra las fases/milestones declaradas en el implementation plan del proyecto (si lo leíste en "Antes de planear"):
- Si el alcance propuesto incluye trabajo que el plan asigna explícitamente a una fase **futura** → señalalo en el HLTC (sección out-of-scope o Risks) en vez de aceptarlo en silencio como si fuera scope normal de esta feature. No lo saques del HLTC vos solo — es una señal para que el humano decida en Feature Ready, no un bloqueo de planning.
- Si no hay ese documento, seguí igual que siempre — este chequeo es un extra, no un requisito.

### Closure rules (obligatorias)
Prohibido: "if needed", "if applicable", "or", "prefer", "may be", "when available", "if present", "derived from".
- Toda decisión que afecta comportamiento → resuelta a un solo approach. Si no → pregunta-bloqueo.
- Cada campo de payload visible: presence (required/nullable), source of truth, missing-data behavior, transformation, sin síntesis.
- Naming consistente: un concepto = un nombre.
- Falla: si dos ingenieros lo implementarían distinto, el contract es inválido.

### Auto-approve (modo multi-agente)
A diferencia del template original, el HLTC se **auto-aprueba y se loguea** (no frena a esperar humano). El gate humano está en Feature Ready. Por eso las closure rules son innegociables: el contract debe quedar cerrado sin revisión humana intermedia.

Single-writer: solo el planner escribe `contract.md`. Versionalo (v1, v2...). Agentes que necesiten cambios mandan `contract-change-request`; vos ratificás y bumpeás versión.

## Fase B — Task briefs por agente

Por cada `AGENT_{uuid}` (repo + branch + working-dir):
- **Tracking Proxima** (si está activo): el planner crea una **subtask** por agente (`parentKey` = tarea madre) para granularidad de cierre. Las subtasks NO tienen key (solo UUID) → el brief lleva `proxima_subtask_id` (para cierre) y la `branch` exacta, que usa el **key de la madre**: `{action}-{KEY_MADRE}-{agente}-{desc}` multi-repo, `{action}-{KEY_MADRE}-{desc}` single-repo (`action ∈ feat|fix|chore|refactor|docs`). Sin Proxima → `<MODULO>-<TICKET>` / `<MODULO>-<desc>`. El implementing-agent NO crea tareas Proxima ni cambia su estado.
- **Rama base** confirmada en el contract; nunca commit directo a la base; integración según la capa del repo (con remote → PR; sin remote → merge local `--no-ff` tras review; no-git → sin branch).
- Objective + out-of-scope · prerequisites · files to create/update
- **Los ACs que le tocan, con su ID original del HLTC** (`AC2`, `AC5`… no renumerados). Un AC pertenece a exactamente un agente: si dos lo tocan, se parte en dos ACs.
- Pasos en fases con task IDs estables: `- [ ] T<fase>.<i> Descripción` (una acción verificable por checkbox; no fusionar acciones).
- **Modelo asignado**: `sonnet` default · `opus` si pesada/arquitectónica · `haiku` si trivial.
- Validation steps: los comandos reales de `SDD/docs/doc_quality_gates.md` (nunca inventados) + expected outcome + required/optional.
- Self-check loop antes de entregar · Risks · Rollback · Done criteria.
- `Execution Report` vacío al final (Summary / Task Status / Validation Executed / Blockers / Files Changed / Final Statement).

### Bloque de calidad en cada brief (obligatorio, sin excepción por tamaño)
Todo brief cierra con estas cuatro cosas — son la Definition of Done de `standards/quality-gates.md` §1 instanciada:

1. **Tabla `AC ↔ test binding` vacía** (formato en `quality-gates.md` §3), una fila por AC del agente, para que la llene con el nombre literal del test. AC sin fila llena = no está terminado.
2. **Tarea explícita de gates**: `- [ ] T<fase>.<i> Correr la escalera de gates y escribir el verification report` — con los comandos del `doc_quality_gates.md` del repo y la ruta exacta del reporte (`tasks/<slug>/verification/AGENT_<slug>.md` multi-agente, `SDD/verification/<branch>.md` single-repo).
3. **Cobertura del impact set**: por cada caller listado en el impact set del HLTC que este agente toca, o hay test de regresión o hay justificación escrita. Sin filas silenciosas.
4. **Tarea de docs delta**: si el Delta del agente toca capas/rutas/contratos → actualizar `doc_architecture.md`; si aparecen comandos nuevos → `doc_verification_guide.md` / `doc_quality_gates.md`.

Si el requerimiento es un **bugfix**, la primera tarea del brief es siempre `T1.1 Escribir el test que reproduce el bug y registrar la corrida roja` — antes de cualquier tarea de implementación.

Escribí las validaciones como comandos que existen. Si el repo no tiene un tipo de gate, decilo `N/A — <razón>` en el brief en vez de pedir un comando que va a fallar.

### Accountability del implementing agent (incluir en cada brief)
Marcar `[x]` al completar, `[BLOCKED]` con explicación si no puede, llenar Execution Report, nunca declarar una validación que no corrió. Recordarle las **mitigaciones prohibidas** (`quality-gates.md` §6): ante un gate que no pasa sin ablandar un test o silenciar el type-checker → BLOCKED y pregunta al planner, nunca el atajo.

### Loop de review acotado
El ciclo implementar → review es de **máximo 3 rondas** por brief. Si la ronda 3 no cierra en `APPROVED`, el reviewer emite `ESCALATE` y vos decidís: ratificar contract (bump de versión), cortar scope, o elevarlo al gate humano de Feature Ready. No dejes el loop abierto: es el escenario donde el agente empieza a ablandar tests para salir.

### Orden de integración
Si hay dependencias entre repos, declarar el orden de merge (ej. BE -> FE -> mobile) en el contract.

### SEO en el brief del FE agent
Si el HLTC tiene `## SEO criteria (advisory)`, copiálos al brief del agente de frontend en una sección propia (IDs `SEO1..SEOn`, con su tier Universal / Indexable), **separada de la tabla `AC ↔ test binding`** — no exigen test ni entran en la Definition of Done. El reviewer-agent los chequea en modo advisory; no son gate de Feature Ready.

## Self-review final
Releé como agente sin contexto previo:
- ¿ejecutable end-to-end? ¿alguna frase permite dos implementaciones válidas?
- ¿el task brief introduce decisiones nuevas no aprobadas en el HLTC?
- ¿**cada AC del HLTC está asignado a exactamente un brief**, y ninguno quedó huérfano?
- ¿cada AC es verificable por un test, o está declarado `manual-only` con razón?
- ¿los comandos de validación **existen** en `doc_quality_gates.md`, o inventé alguno?
- ¿algún brief puede declararse `done` sin evidencia con exit codes?

Si hay bloqueo → preguntá antes de finalizar.
