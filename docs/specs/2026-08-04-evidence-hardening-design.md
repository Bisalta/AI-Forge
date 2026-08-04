# Design — Evidencia generada, closure linteable y hardening (v0.10.0)

**Fecha**: 2026-08-04
**Plugin**: `sdd-flow`
**Estado**: implementado en `claude/plugin-code-consistency-quality-rfpwct` (mismo PR que v0.8.0 y v0.9.0)
**Origen**: análisis de modos de falla post-v0.9.0 — qué puede fallar y qué falta para que el plugin sea excepcional creando cambios/sistemas desde requerimientos SDD.

## Los modos de falla que ataca

1. **Teatro de cumplimiento**: la evidencia (`verification.md`) la escribía el mismo modelo que hizo el trabajo — cuanto más se exige el artefacto, más incentivo a producir el artefacto sin el trabajo. La cadena de confianza terminaba en "un modelo dice que corrió algo".
2. **Closure declarado, no verificado**: las closure rules prohibían "if needed" por prosa, y detectarlo era un grep que nadie corría. Un contract podía citar símbolos inexistentes (alucinado, no derivado) y auto-aprobarse.
3. **Greenfield con gates apagados**: en repo vacío la escalera nace toda `N/A` — sin runner, sin lint, sin CI — justo cuando se funda el proyecto.
4. **Drift multi-repo**: el contract en prosa lo interpreta cada lado; el desacuerdo BE↔FE aparece al integrar, tarde.
5. **Rubber-stamp humano**: Feature Ready entregaba un muro de ACs y exit codes en el único gate humano; revisar costaba 40 minutos → se aprobaba por confianza.
6. **Fatiga de refinement**: 9+ dimensiones de preguntas → el usuario contesta "sí dale" → falso closure que el pipeline trata como verdad.
7. **Desproporción**: DoD idéntica para un typo y para una migración → el proceso pesado para lo chico se abandona también para lo grande.
8. **Grietas mecánicas conocidas**: ramas protegidas hardcodeadas (`release/1.2` se escapaba), markers del stack en prosa que el script no leía, copias de scripts sin versionado, doble-planner sin lock.

Principio rector confirmado por tres versiones: **cada mejora se pregunta primero "¿esto puede ser un script?"** — lo determinístico a scripts, el criterio a los modelos.

## Decisiones

### D1 — `sdd-run-gates.sh`: el reporte de gates lo escribe un script
Parsea la tabla de `doc_quality_gates.md` (los comandos ya viven ahí — un solo lugar define la verdad), corre en orden, corta al primer rojo (`--keep-going` para CI), y **emite el reporte**: tabla con exit codes y timestamps + últimas 15 líneas por gate + línea JSON `{"type":"sdd.gates",...}` para el orquestador. El agente pasa de autor a usuario de la evidencia; el reviewer trata una tabla manuscrita sin razón declarada como BLOCKER; editar el reporte generado invalida la evidencia. Fallback manual permitido solo declarando por qué (repos donde el runner no puede correr). `quality-gates.md` §5 reescrito alrededor de esta regla de oro.

Qué NO hace, a propósito: no decide qué gates aplican (lo declara el doc), no arregla, no reintenta. Exit 3 si el doc no existe/parsea — el error correcto es "corré /sdd-init", nunca inventar comandos.

### D2 — `sdd-lint-contract.sh`: un linter rojo prueba que NO hay closure
Frases prohibidas ES/EN (BLOCKER) + inventario de paths citados vs realidad del repo (WARN — puede ser de otro repo en multi-agente). Saltea bloques de código y líneas que citan las propias reglas ("prohibido..."). Asimetría honesta documentada: linter verde no prueba closure (la ambigüedad tiene formas nuevas), linter rojo sí prueba su ausencia. Corre en tres puntos: self-review del planner (antes de auto-aprobar), Fase 2 de `/sdd`, Fase 1 del reviewer (frase abierta en contract auto-aprobado = defecto del plan → `ESCALATE`).

### D3 — `project-scaffold`: noveno arquetipo, obligatorio en greenfield
Regla: repo sin escalera funcional → primera task de cualquier `/sdd` es el scaffold, con checklist propio (runner con **primer test real** verde — no `expect(true)`, perfil de lint/format/type-check, `doc_quality_gates.md` re-verificado ejecutando, scripts copiados, CI si hay remote, tokens de diseño como ADR si hay UI). El requerimiento funcional se planifica como segunda task. Cierra la trampa de "crear sistemas" con el sistema de calidad apagado.

### D4 — Contract fixtures: el contract ejecutable
Para interfaces compartidas entre agentes: `fixtures/<interfaz>.json` con pares ejemplo reales (normal + edge + error), single-writer como el contract. Cada brief que toca la interfaz lleva un contract test contra el fixture. Cambio de interfaz → cambio de fixture (bump de contract) → ambos lados lo detectan en test, no al integrar. Se eligió fixtures JSON sobre schemas formales (OpenAPI/JSON Schema) por costo: los pares ejemplo son stack-agnósticos, triviales de testear en cualquier runner, y legibles en el review; un schema formal queda como evolución si el kilometraje lo pide.

### D5 — Feature Ready brief: proteger el único gate humano
`templates/feature-ready-brief.md`, UNA pantalla: qué es · decisiones tomadas por el humano (defaults aceptados en paquete, ratificaciones, ADRs) · dónde está el riesgo · qué mirar en 5 minutos · estado honesto en tabla · evidencia como apéndice de links. La sección "decisiones que tomé por vos" es la clave: es exactamente lo que el humano no vio pasar y le puede importar.

### D6 — Anti-fatiga: inferir primero, preguntar después
Una decisión cerrada por cansancio es peor que una abierta (el pipeline la trata como verdad). Reglas en `enrich-user-story`: todo lo inferible del codebase/ADRs/PRD se presenta como default ya elegido **con su evidencia**; máximo ~2 rondas agrupadas (`AskUserQuestion`); ante señales de fatiga → paquete único de defaults con confirmación de una vez; distinción inferido/confirmado en el artefacto (un default de paquete que resulta mal es `contract-change-request`, no promesa rota).

### D7 — Proporcionalidad: la DoD no se negocia, la ceremonia sí
Trabajo trivial → `/sdd-fixes` con **mini-DoD**: branch + test del cambio (bugfix: corrida roja registrada) + `sdd-run-gates.sh` verde + cero mitigaciones prohibidas. Sin contract ni reviewer, con evidencia. Regla de escape honesta: fix que no puede cumplir la mini-DoD no era trivial → `ambiguo` + `/sdd-enrich`. El refinement propone la vía corta solo (golden G11).

### D8 — Evals: el plugin se testea a sí mismo
`evals/golden-requirements.md`: un golden por arquetipo con propiedades universales (U1-U8: linter verde, ACs, threat model, ≤2 rondas...) y específicas (IDOR, 4 estados, dry-run, veneno...), más dos adversariales: G10 (trabajo doble → debe partirse en dos requerimientos) y G11 (typo → debe proponer vía corta). Manual por ahora; su tabla de resultados es el insumo de la **poda** — la respuesta al riesgo de saturación normativa es data, no intuición: v1.0 debería ser más chica que v0.10.

### D9 — Hardening mecánico
- `guard-git.sh`: `SDD_PROTECTED_BRANCHES` (globs, reemplaza el default); default ampliado con `release/*` y `hotfix/*`.
- `sdd-check.sh`: `SDD/scripts/sdd-check.patterns` (`SEV\trule\tERE` por línea) — los "markers prohibidos del stack" de `doc_quality_gates.md` dejan de ser prosa; `--version`.
- `/sdd-init`: copia los tres scripts con comparación de versión (nunca pisa una copia modificada sin mostrar diff); emite el patterns del stack; el CI generado corre `sdd-run-gates.sh --keep-going` — mismo parser, mismos comandos, paridad real.
- Lock de planner en el state (`planner{session, claimed_at}`; state ajeno reciente → preguntar antes de asumir ownership). `sdd.result.gates[]` debe coincidir con el reporte del runner; difieren → gana el reporte.
- Reviewer: todo hallazgo cita `archivo:línea` leído de verdad (Read/Grep, no memoria del diff).

## Validación de esta versión

- `sdd-run-gates.sh`: corrida verde con `--full` (5 verdes, 2 SKIPPED por `N/A`/`PLACEHOLDER`), rojo que corta la escalera (gates posteriores no corren), JSON de resumen, doc ausente exit 3.
- `sdd-lint-contract.sh`: 2 BLOCKERs de frases ("if needed", "podría ser... a confirmar") + WARN de path fantasma; la cita de las reglas y el bloque de código exentos; `NEW` exento; contract limpio exit 0.
- `guard-git.sh`: deny en `release/1.2` (glob), allow en `trunk` sin env, deny en `trunk` con `SDD_PROTECTED_BRANCHES=trunk,main`.
- `sdd-check.sh`: patrón custom `console-log` del repo detectado como BLOCKER junto a los built-in; `--version` responde.

## Fuera de alcance

- Poda de la superficie normativa: se hace con la data de los evals, no antes (adivinar qué sobra repite el error que la causó).
- Schemas formales para fixtures (OpenAPI): evolución posible si el kilometraje muestra que los pares ejemplo quedan cortos.
- Enforcement de caps por hook y modo `--hasta-pr`: sin cambios respecto de v0.9.0 (pendientes #6 y #7 del roadmap).
