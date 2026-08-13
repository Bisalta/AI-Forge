# Task brief — R4 · infra: arquetipo `analysis`

- **Agente**: `AGENT_r4` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v6**, sección `R4` (AC25-AC28)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening`
- **Proxima subtask id**: `2c091d58-67d3-49d6-88a6-26372bfc14ac` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R4.md`
- **Depende de**: R0, R1, R2, R5 y R3, los cinco `APPROVED`. Es el último requerimiento del ciclo.

## El problema, y por qué la causa es mecánica

Dos trabajos de SICOP no eran ciclos de código —un backtest sobre 19 ofertas y un barrido de consistencia documental— y los dos estuvieron a punto de mergearse sin review porque "no eran un ciclo". Los dos tenían conclusiones falsas.

El backtest concluía que *"el precio no es la palanca, la selección sí"*, apoyado en una brecha de 0,215 entre concursos ganados y perdidos. El review midió que la brecha **se invierte a −0,048** al excluir seis líneas con defecto de datos, **cuatro de ellas de un mismo concurso**. Y el test que la hubiera confirmado —permutación a nivel de concurso, que nunca se corrió— da **p = 0,533**. Nunca se distinguió del ruido, e iba a cambiar el diseño del producto.

**La causa no es cultural, es mecánica.** `plugins/sdd-flow/standards/archetypes.md` tiene nueve arquetipos y ninguno cubre trabajo cuyo producto es un número usado para decidir. `plugins/sdd-flow/skills/enrich-user-story/SKILL.md:92` fuerza exactamente uno y devuelve al refinement cualquier requerimiento sin arquetipo. Hoy un backtest **no puede entrar al pipeline aunque alguien quiera meterlo**.

El caso del barrido documental **no** necesita arquetipo: lo cubre AC24 de R3, que ya está escrito — corregir un artefacto aprobado es una corrección, no un tipo de trabajo nuevo.

## Decisión de diseño (cerrada en el contract — no la re-abras)

Décimo arquetipo `analysis`, con la misma estructura que los otros nueve: NFR obligatorias, tests exigidos, checklist→ACs. Cubre trabajo cuyo entregable es una conclusión o una cifra que alimenta una decisión, con producto en documentos o notebooks en vez de código de aplicación.

## Out of scope

- No toques los nueve arquetipos existentes. R4 es **aditivo**.
- No toques `scripts/`, `hooks/` ni `standards/quality-gates.md`.
- No reabras ningún AC de R0, R1, R2, R3 ni R5.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/standards/archetypes.md` | (mod) sección `analysis` entre `infra` y "Cómo lo usa el pipeline" |
| `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` | (mod) `analysis` entra a la lista de la dimensión 7 |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | (mod) el binding AC↔test admite la forma de evidencia de `analysis` |
| `SDD/tests/test_analysis_archetype.sh` | (NEW) |

## Contenido normativo del arquetipo

- **NFR obligatorias**: `observability` (la corrida que produce la cifra es reproducible por otro) y `data-privacy` cuando el dataset tiene PII.
- **Tests exigidos**: el test estadístico que **falsaría** la conclusión, corrido y reportado con su valor; más la re-derivación de cada cifra citada desde su fuente.
- **Checklist → ACs** (los siete, textuales del contract):
  1. Hipótesis nula declarada antes de mirar el resultado.
  2. El test que falsaría la conclusión, nombrado y corrido; su resultado se reporta gane o pierda.
  3. Toda cifra re-derivada desde la fuente, con la salida de la consulta adjunta.
  4. Sensibilidad declarada: qué pasa con la conclusión al excluir las filas defectuosas, y si las exclusiones se concentran en pocas unidades.
  5. Unidad de análisis declarada, y el test a esa unidad cuando las observaciones se agrupan.
  6. Tamaño de muestra y potencia declarados, con el número.
  7. La conclusión se escribe con su incertidumbre, no como afirmación categórica.

Cada ítem tiene que poder rastrearse al incidente que lo motiva. Los siete salen del backtest: el 2 es el test de permutación que nunca se corrió, el 4 son las seis líneas excluidas, el 5 son las cuatro de un mismo concurso, el 3 es la cifra citada sin re-derivar.

## Pasos

- [ ] T1.1 Leer `archetypes.md` entero antes de tocarlo, y **respetar su forma**: los nueve existentes tienen exactamente NFR obligatorias · Tests exigidos · Checklist→ACs. El tuyo tiene que leerse como uno más, no como un anexo.
- [ ] T1.2 Escribir `SDD/tests/test_analysis_archetype.sh` (AC25-AC28) con `SDD/tests/lib.sh`. **Corré el test antes del cambio**: tiene que salir ≠0.
- [ ] T2.1 La sección `analysis` en `archetypes.md`, entre `infra` y "Cómo lo usa el pipeline".
- [ ] T2.2 `enrich-user-story/SKILL.md`: `analysis` en la lista de arquetipos de la dimensión 7, y la rama de preguntas NFR que el arquetipo dispara.
- [ ] T2.3 `sdd-plan/SKILL.md`: el binding AC↔test admite la forma de evidencia de `analysis` — un AC cuya evidencia es la salida de una consulta o un test estadístico, no un test unitario.
- [ ] T3.1 Test verde. `bash SDD/tests/run.sh` completo (8 archivos). `shellcheck --severity=warning` en 0.
- [ ] T3.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R4-gates.md` — **commiteá primero, regenerá después**.
- [ ] T3.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent`.

## Acceptance criteria (IDs del contract v6 — no los renumeres)

- **AC25** — `archetypes.md` contiene la sección `analysis` con las tres partes que tienen los otros nueve: NFR obligatorias, tests exigidos y checklist→ACs.
- **AC26** — La sección incluye los siete ítems de checklist del contenido normativo de arriba.
- **AC27** — `enrich-user-story/SKILL.md` incluye `analysis` en la lista de arquetipos de su dimensión 7.
- **AC28** — El total de arquetipos declarado en `archetypes.md` y en `enrich-user-story` coincide: **diez en ambos**. Verificable con grep.

**AC28 es el AC de detección de este requerimiento** — es de la forma "sensibilidad" de `quality-gates.md` §10.1: afirma que dos conteos coinciden. Un test que cuenta mal las **dos** listas de la misma forma equivocada da verde igual, y sigue dando verde el día que alguien agregue un arquetipo a un solo lado. Probalo por mutación: agregá un arquetipo falso a **uno** de los dos archivos, verificá el rojo, revertí. Registrá el triple con el formato nuevo de `templates/verification-report.md`.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC25 | | | | [ ] |
| AC26 | | | | [ ] |
| AC27 | | | | [ ] |
| AC28 | | | | [ ] |

## Reglas innegociables

Las de siempre, y ahora **son norma escrita** gracias a R3: leé `plugins/sdd-flow/standards/quality-gates.md` §10 antes de arrancar, porque es la regla que acabás de heredar y te aplica.

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe** (`RT7`).
- **Verificá cómo se mide antes de creerle a la medición** (`RT8`; cuatro incidentes en este ciclo, uno del planner).
- **No verifiques lint con `git ls-files`** (`D8`). Usá el glob del gate.
- Literales con forma clave-valor, **partidos**, o el gate 9 se pone rojo.
- Ninguna exclusión por path para hacer pasar un gate.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner. Cuatro de los cinco requerimientos anteriores encontraron un defecto de plan; si ves uno, decilo.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Riesgo declarado

Este arquetipo es el único del plugin cuyo checklist es **estadístico**, y el planner que lo escribió no es estadístico. Si un ítem está mal formulado —por ejemplo si el 5 confunde unidad de análisis con unidad de muestreo— el arquetipo va a producir ACs que suenan rigurosos y no lo son, que es el modo de falla exacto que el ciclo entero ataca. Leé los siete con esa desconfianza y **marcá BLOCKED** si alguno no se sostiene.

## Rollback

`git revert`. Aditivo: los nueve arquetipos existentes no cambian.

## Execution Report

- **Summary**:
- **Task status**:
- **Validation executed** (comando · exit code):
- **Blockers**:
- **Files changed**:
- **Final statement**:

---

## Tarea extra — AC42 (agregada en contract v7, del review de R3)

`plugins/sdd-flow/scripts/sdd-check.sh` levanta un `BLOCKER` falso sobre archivos `.md`: la regla de supresores no tiene el guard `file !~ /\.md$/` que **sí** tiene la regla del flag de bypass de hooks, en el mismo script. Resultado medido por el reviewer: `sdd-check.sh e5ef90c` sale 2 porque el `@ts-ignore` que enumera las mitigaciones **prohibidas** en `commands/sdd-fixes.md` dispara la regla — sobre un texto que existía desde antes del diff.

Un checker que se pone rojo sobre la prosa que describe lo que prohíbe entrena al equipo a ignorarlo, y va a reaparecer en cada diff futuro que toque esa línea.

- [ ] T4.1 Agregar el mismo guard de `.md` a la regla de supresores. **Es la única línea que tocás de `scripts/`** — el resto del out-of-scope sigue en pie.
- [ ] T4.2 **AC42 es de detección** (forma "rechazo" de §10.1): probalo por mutación. Quitá el guard recién agregado, verificá que el `BLOCKER` falso reaparece, revertí. Registrá el triple con el formato de `templates/verification-report.md`.
- [ ] T4.3 Verificá que el guard **no** apague la detección real: un supresor en un archivo de código sigue siendo `BLOCKER`. Sin eso, el fix es un ablandamiento disfrazado de guard.

**Aviso operativo**: `guard-git.sh` rechaza cualquier comando cuyo texto contenga el literal del flag de bypass de hooks, aunque esté en prosa. Al escribir el mensaje de commit de esta tarea, evitá el literal o construilo en runtime. Es la misma clase que AC42, en la otra herramienta mecánica del plugin, y ya mordió al planner y al reviewer.
