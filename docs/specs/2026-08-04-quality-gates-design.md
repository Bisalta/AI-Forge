# Design — Quality Gates verificables en sdd-flow (v0.8.0)

**Fecha**: 2026-08-04
**Plugin**: `sdd-flow`
**Estado**: implementado en la branch `claude/plugin-code-consistency-quality-rfpwct`

## Problema

El objetivo declarado del plugin es que **no importa el requerimiento**, la salida sea consistente, probada y de alto nivel. Hasta v0.7.0 el plugin cerraba muy bien **qué** construir (las closure rules del contract son fuertes) pero la calidad del **cómo** quedaba declarada en prosa, no verificable:

1. **Standards como puntero vacío.** `base-standards.md` nombraba diez áreas (`001-code-quality`, `004-testing`, …) cuyo detalle "vive en el repo standard de la empresa". Instalado fuera de un repo Construplaza, el standard de calidad no existía.
2. **Testing declarativo.** "Tests deben pasar antes de cualquier PR" + "TDD cuando aplique" + validation strategy "por escenario, no comandos" ⇒ un agente podía entregar con la suite verde sin haber escrito un solo test del comportamiento nuevo.
3. **Evidencia inexistente.** `reviewer-agent` tenía la instrucción "verificá evidencia, no confíes en el reporte", pero ningún template producía evidencia. En la práctica el reviewer terminaba confiando en el Execution Report — el reporte de la misma parte interesada.
4. **Comandos inventados.** Sin una fuente de comandos por repo, cada agente adivinaba `npm test` vs `pnpm vitest run`. La consistencia se fugaba exactamente ahí.
5. **Loop de review sin cota.** "Loop hasta cumplir acceptance criteria" (sin techo) + veredicto binario sin severidades. El failure mode conocido: en la ronda 5 el agente ablanda un test para salir del loop.

## Decisiones

### D1 — La unidad de verdad de "está probado" es el acceptance criterion numerado
El HLTC emite `AC1..ACn` (comportamiento observable, uno por test, IDs estables entre versiones del contract). Cada brief recibe los ACs que le tocan **con su ID original**, y el implementing agent llena una tabla `AC ↔ test binding` con el nombre literal del test. **AC sin test = BLOCKER.**

Alternativa descartada: thresholds de coverage global. Son un proxy indirecto (80% de cobertura no dice nada sobre *este* comportamiento), y son la primera cosa que un agente baja para pasar el gate. La cobertura del diff + el binding atacan lo mismo de forma directa y no negociable.

Escape hatch honesto: un AC verificable sólo a mano se declara `manual-only: <razón>` en el HLTC y el brief lleva los pasos de smoke. Sin razón declarada, el contract es inválido.

### D2 — Escalera de gates fija, comandos por repo
El **método** (orden de gates, corta al primer rojo, suite completa antes de integrar, cobertura del diff) vive en `standards/quality-gates.md`, que ship con el plugin. Los **comandos** viven en `SDD/docs/doc_quality_gates.md`, generado por `/sdd-init` derivando de los manifiestos reales.

Se eligió un tercer documento SDD en lugar de extender `doc_verification_guide.md` porque cumplen funciones distintas y mezclarlas degrada las dos: la guía de verificación es *curada y opcional* ("qué conviene correr según qué cambié"), la escalera es *obligatoria y sin elección* ("qué corre siempre antes de declarar `done`"). El doc de gates además carga cosas que la guía no tiene: prerequisitos de entorno, rojos preexistentes de la base, tiempo esperado de la suite, markers prohibidos del stack.

### D3 — La evidencia es un archivo, no una afirmación
`templates/verification-report.md` → `tasks/<slug>/verification/AGENT_<slug>.md` (un archivo por agente, para no romper el ownership 1-way del protocolo de coordinación) o `SDD/verification/<branch>.md` en single-repo. Por gate: comando exacto · exit code · timestamp · output. Más impact set y rojos preexistentes.

Consecuencias: `verificación ausente = BLOCKER`; el reviewer **re-corre el subset barato** (type-check + unit) y si difiere de la evidencia, la evidencia está podrida; `/sdd-status` puede mostrar un `done` sin evidencia como lo que es (trabajo en curso).

Para bugfixes se exige la **doble corrida**: el test de reproducción rojo antes del fix (exit ≠ 0, registrado) y verde después. Un bugfix sin rojo previo no está probado, está supuesto.

### D4 — Mitigaciones prohibidas, explícitas y grepeables
Nueve formas conocidas de hacer pasar un gate sin resolver el problema (§6): tests borrados/skipeados/aflojados, `@ts-ignore`/`eslint-disable`/`# type: ignore` sin referencia al contract, `any` para callar al type-checker, thresholds bajados, `--no-verify`/`--force`, retry de flaky, catch silencioso, hardcodeo del valor esperado.

Son la parte del review que **no requiere criterio**: se detectan con grep sobre el diff, así que el reviewer las corre primero (Fase 1, mecánica) antes de opinar de arquitectura. El camino legítimo cuando un gate no pasa es BLOCKED → preguntar al planner, nunca ablandar el gate.

### D5 — Severidades y cota de 3 rondas
`BLOCKER` / `MAJOR` (rechazan) · `MINOR` / `ADVISORY` (no rechazan). `APPROVED` exige cero BLOCKER y cero MAJOR. Tercer veredicto nuevo: **`ESCALATE`**, para cuando falta una decisión del contract o se agotan las tres rondas. Sin cota, el loop de review se convierte en presión para ablandar tests.

### D6 — Una capa determinística, chica y fail-open
Todo lo anterior es prompt. Tres prohibiciones se bloquean de verdad con `hooks/guard-git.sh` (`PreToolUse` sobre `Bash`): commit con HEAD en rama protegida, `--no-verify`, `git push --force` sin `--force-with-lease`.

Elegido chico a propósito. No se agregó un `PostToolUse` de formatter/lint por archivo editado: necesita comandos por repo, agrega latencia a cada Edit y puede pelearse con el formatter del proyecto. El hook es **fail-open** (sin `jq`, sin git, JSON inesperado → deja pasar) porque un guard que rompe sesiones es peor que no tener guard, y trae escape hatch `SDD_ALLOW_BASE_COMMIT=1`. Verificado contra 20 casos, incluidos falsos positivos (`git log --grep commit`, `echo 'git commit'`, `--force-with-lease`) y flags globales (`git -C . commit`, `git -c user.email=x commit`).

## Alcance implementado

**Nuevo**
- `standards/quality-gates.md` — normativa: DoD, ACs numerados, binding AC↔test, escalera, evidencia, mitigaciones prohibidas, severidades, capas de enforcement, perfiles por stack.
- `templates/doc_quality_gates.md` — esqueleto por repo (lo llena `/sdd-init`).
- `templates/verification-report.md` — artefacto de evidencia.
- `commands/sdd-verify.md` + `skills/sdd-verify/SKILL.md` — correr la escalera on-demand y producir evidencia; veredicto `GATES VERDES` / `GATES ROJOS` / `EVIDENCIA INCOMPLETA`.
- `hooks/hooks.json` + `hooks/guard-git.sh` — guard determinístico.

**Modificado**
- `base-standards.md` — core rules reescritas (AC con test, nada de `done` sin evidencia, reuse antes de crear, bugfix con test rojo primero); reglas de type-checker despegadas de TypeScript hacia perfiles por stack.
- `sdd-plan` — sección `Acceptance criteria` numerada + impact set en el HLTC; bloque de calidad obligatorio en cada brief (tabla de binding, tarea de gates, cobertura del impact set, docs delta); bugfix arranca por el test rojo; self-review chequea ACs huérfanos y comandos inventados.
- `implementing-agent` — tests como sección propia, gates + evidencia, mitigaciones prohibidas, docs delta, reuse.
- `reviewer-agent` — Fase 1 mecánica (grep + re-corrida del subset barato) antes de la Fase 2 con criterio; severidades; `ESCALATE`; conteo de ronda.
- `/sdd` — Fase 4 con cota de 3 rondas y "ningún brief cierra sin evidencia"; Fase 5 con checklist de Feature Ready.
- `/sdd-init` + skill — genera el tercer documento con comandos verificados (`N/A` explícito cuando el gate no existe).
- `/sdd-status` — columna de gates y ACs sin test; marca los `done` sin evidencia.
- `coordination-README.md` — `verification/AGENT_<slug>.md` en la estructura y en el ownership 1-way; `done` con requisitos; anti-patrones nuevos.
- `write-pr-report` — la sección Validation se funda en la evidencia registrada; permitido decir qué no se corrió, prohibido afirmar un check sin resultado.

## Fuera de alcance (próximo paso)

**Arquetipos de requerimiento** — la otra mitad de "no importa el requerimiento": una taxonomía (`api-endpoint`, `ui-feature`, `data-migration`, `background-job`, `third-party-integration`, `bugfix`, `refactor`, `infra`) donde cada arquetipo trae checklist obligatorio, tipos de test exigidos y NFRs por defecto (una migración necesita dry-run + idempotencia + conteo antes/después; un endpoint necesita authz + paginación + taxonomía de errores). Hoy el pipeline trata igual un endpoint y una migración, y la consistencia depende de que el planner improvise bien.

Junto con eso, un bloque `nfr:` en `enrich-user-story` con el mismo patrón que ya usa `seo:` — las seis dimensiones actuales son todas funcionales, y quedan sin cerrar authz, volumen/paginación, idempotencia/concurrencia, observabilidad, migración/backfill y rollout.

También queda pendiente de v0.7.0: orquestación real de spawn de subagentes en `/sdd` y el `state.json` de la statusline (que ahora podría incluir el estado de gates).
