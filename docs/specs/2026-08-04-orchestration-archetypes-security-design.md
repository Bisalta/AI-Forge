# Design — Orquestación real, seguridad como gate y arquetipos (v0.9.0)

**Fecha**: 2026-08-04
**Plugin**: `sdd-flow`
**Estado**: implementado en `claude/plugin-code-consistency-quality-rfpwct` (mismo PR que v0.8.0)
**Depende de**: `2026-08-04-quality-gates-design.md` (v0.8.0 — ACs numerados, binding AC↔test, evidencia, severidades)

## Problema

v0.8.0 hizo verificable la calidad de lo que se define. Quedaban tres huecos para que el plugin entregue un resultado maduro sin importar el requerimiento:

1. **No hay orquestador, hay una descripción de orquestador.** `/sdd` decía "spawneá subagentes" pero todo el estado del ciclo era prosa markdown: un orquestador no puede decidir parseando párrafos. No había schema de estado, ni retornos estructurados, ni protocolo de crash/resume, ni caps — `.sdd/state.json` existía solo como algo que la statusline intentaba leer.
2. **Seguridad y mantenibilidad declaradas, no verificables.** "Cero secretos" y "confirmá operaciones destructivas" sin threat model, sin tests negativos exigidos, sin gate de supply chain. Las decisiones arquitectónicas morían dentro del `contract.md` de una task que nadie vuelve a abrir; los `MINOR` no corregidos se evaporaban.
3. **El pipeline trataba igual un endpoint y una migración.** La consistencia por tipo de trabajo dependía de que el planner improvisara bien cada vez (pendiente #5 del roadmap).

## Decisiones

### D1 — Contrato de máquina en tres piezas (`standards/orchestration.md`)
**Estado**: `.sdd/state.json`, single-writer (el planner), escrito antes y después de cada transición. Claves planas `phase/phases_total/agents_active/blocked` conservadas porque `statusline.sh` ya las leía; se agrega `agents[]` con round/verdict/gates/ACs y `escalations[]`. El state es un **índice**, no una segunda verdad: si contradice la evidencia (`verification/`), gana la evidencia.

**Retornos**: cada subagente cierra su output con exactamente un bloque JSON (`sdd.result` / `sdd.review`). El orquestador parsea eso, no prosa. `acs[].state` admite `missing` — la admisión honesta es parseable; esconderla no.

**Protocolo**: aceptación de un `done` validando el artefacto (evidencia existe, exit codes, sin ACs `missing`, `contract_version` vigente) — sin re-correr nada (eso ya lo hace el reviewer; duplicarlo es costo sin señal nueva). Caps duros: 3 rondas de review (ya existía), 2 reintentos del mismo gate rojo, 3 agentes paralelos, 1 re-spawn por `failed`. Resume: agente `spawned` sin retorno ⇒ sesión muerta ⇒ verificar la branch real y re-spawnear desde el brief avisando del trabajo parcial.

### D2 — Spawn con Agent tool, degradación inline, serialización por repo
Se descartó el Workflow tool como mecanismo: requiere opt-in explícito del usuario y no está en todos los entornos — un plugin no puede asumirlo. `Agent` tool con el **modelo del brief como override de spawn** (el frontmatter del agente queda como default); sin Agent tool, **degradación inline documentada** (la sesión ejecuta los briefs en serie con el mismo contrato de estado y evidencia). Regla dura nueva: **un agente activo por repo** — dos agentes sobre el mismo working tree se pisan (archivos, index, servers de test); mismo repo ⇒ serie o worktrees declarados en el brief.

### D3 — La Fase 1 del review es un script (`scripts/sdd-check.sh`)
Los greps mecánicos (tests skipeados/eliminados, supresores, `any` nuevo, configs ablandadas, catch silencioso) son determinísticos: en un script no alucinan y no se cansan. Exit 2 con BLOCKERs candidatos; **el script propone, el reviewer confirma contra el contract** (un skip es legítimo si el contract declara el cambio). Fail-open fuera de git. `/sdd-init` lo copia a `SDD/scripts/` para que el reviewer y CI lo corran sin depender del plugin instalado. Detalle de implementación: awk POSIX no soporta `\b` — boundaries explícitos `[^A-Za-z0-9_]` con línea padded (bug real encontrado en test: `a: any` no disparaba).

### D4 — Seguridad como gate (`standards/security.md`)
- **Threat model mínimo de 4 preguntas cerradas** en el HLTC para toda superficie invocable (quién invoca, qué recibe el rol equivocado, input hostil, datos de quién). Sin superficie nueva ⇒ `N/A` explícito. HLTC sin threat model = BLOCKER **de contract** — el reviewer escala al planner, no rebota al implementador.
- **Tests negativos obligatorios como ACs**: 403 de rol equivocado, 401, IDOR, input hostil. Se apoyan en el régimen existente (AC sin test = BLOCKER) en vez de crear uno nuevo.
- **Gate 9 en la escalera**: secret scan del diff + audit de dependencias (critical/high directa con fix = BLOCKER; el resto al ledger de deuda). Sin tooling, el grep mínimo declarado — nunca `N/A` completo en silencio.
- **Supply chain**: dependencia nueva = decisión del contract con justificación y alternativa descartada; agregarla de contrabando = MAJOR (el reviewer diffea manifiestos).

### D5 — Memoria de mantenibilidad: ADR + ledger de deuda + retro
- **ADRs** (`templates/adr.md` → `docs/adr/NNN-*.md`): el planner los emite cuando una decisión sobrevive a la task. Cierra el ciclo de contexto: `/sdd-init` y el refinement los leen después.
- **Ledger de deuda** (`templates/debt-ledger.md` → `SDD/debt.md`): `MINOR` sin corregir, `N/A` aceptados y vulnerabilidades sin fix, con dueño y estado. Append-only; en Feature Ready el planner revisa las filas abiertas del área tocada. DoD ampliada (ítem 9: contabilidad cerrada).
- **Retro** (`SDD/retro.md`): una línea por `ESCALATE`/blocker repetido/prerequisito no documentado; en Feature Ready, patrones repetidos ⇒ propuesta de ajuste al doc que corresponda.
- **Umbrales estructurales** en el reviewer (12c): función desmesurada, anidamiento, duplicación — `MAJOR` sin justificación, cediendo ante el patrón del repo. Señal, no religión.

### D6 — Paridad con CI (ofrecida, no impuesta)
Gates locales y CI tienen que ser los mismos comandos o "verde local" no significa nada. `/sdd-init`: con CI existente, compara y propone alinear **la escalera hacia CI** (CI es lo que ya protege el repo); sin CI y con GitHub, ofrece generar el workflow que corre la escalera + `sdd-check.sh`; otra plataforma, deja el pendiente anotado. Nunca genera de oficio.

### D7 — Arquetipos: exactamente uno, checklist como ACs (`standards/archetypes.md`)
8 arquetipos, cada uno con **NFR obligatorias, tipos de test exigidos y checklist que entra al HLTC como ACs** (o `N/A` razonado ítem por ítem — omisión silenciosa = MAJOR de contract). Regla decision-closed: **un** arquetipo por requerimiento; "endpoint + migración" son dos requerimientos con orden de integración. Los checklists codifican los failure modes conocidos de cada forma: migración ⇒ dry-run/conteo/rollback/idempotencia; job ⇒ re-entrega/veneno/solapamiento/alarma de silencio; ui ⇒ los cuatro estados (vacío·carga·error·éxito); refactor ⇒ suite intacta antes/después y caracterización previa si no hay tests; bugfix ⇒ causa raíz + búsqueda de hermanos.

### D8 — Concerns transversales con el patrón `seo:` (`standards/concerns.md`)
El mecanismo que v0.6.0 probó con SEO, generalizado: activación cerrada en el refinement (4 flags: UI, contrato público, datos personales, ≥2 locales + pregunta de observabilidad + presupuesto de performance), persistencia en el contract, y **blocking/advisory declarado por adelantado** — el agente nunca decide en el momento si algo importaba. `security` y `observability` siempre blocking sin pregunta; `performance` es la bisagra honesta: blocking con número, advisory sin él ("rápido" no es un gate). `enrich-user-story` suma las dimensiones 7-9 (arquetipo, NFR, concerns) y los bloques `archetype:`/`nfr:`/`concerns:` al requerimiento.

## Alcance implementado

**Nuevo**: `standards/orchestration.md` · `standards/security.md` · `standards/archetypes.md` · `standards/concerns.md` · `scripts/sdd-check.sh` · `templates/adr.md` · `templates/debt-ledger.md`.

**Modificado**: `/sdd` (Fase −1 resume, Fase 4 spawn real + serialización + aceptación, retro) · `sdd-plan` (threat model, deps declaradas, ADR, arquetipo+concerns→ACs) · `enrich-user-story` (dimensiones 7-9, bloques nuevos) · `implementing-agent` (security §5, deps BLOCKED, bloque `sdd.result`) · `reviewer-agent` (script en Fase 1, 7b arquetipo/concerns, 12b security, 12c estructura, 12d deuda, bloque `sdd.review`) · `sdd-init` (gate 9, copia del script, paridad CI) · `sdd-status` (state primario) · `statusline.sh` (gates ✓/✗ y ACs sin test) · `quality-gates.md` (gate 9, DoD ítem 9).

## Fuera de alcance

- **Modo `--hasta-pr`** (seguir de Feature Ready a PR): cambia la decisión de diseño #2 (gate humano único) — solo con pedido explícito del usuario.
- **Enforcement de los caps por hook**: los caps viven en el prompt del orquestador; un hook determinístico que corte spawns excedentes requeriría contar spawns fuera de la sesión. Se evalúa cuando el orquestador tenga kilometraje real.
- **Presupuesto de tokens**: un prompt no puede medirlos; los caps contables (rondas/reintentos/paralelo) son el proxy honesto.
