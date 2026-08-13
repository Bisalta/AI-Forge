# Task brief — R3 · infra: prueba por mutación de todo AC que afirme detectar algo

- **Agente**: `AGENT_r3` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v5**, sección `R3` (AC19-AC24)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening`
- **Proxima subtask id**: `68813f9e-1c53-4d0e-959e-5fd1492dfcd6` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R3.md`
- **Depende de**: R0, R1, R2 y R5, los cuatro `APPROVED`

## Qué es esto

Es el requerimiento de mayor rendimiento de todo el ciclo, y es casi todo markdown. Convierte en norma escrita lo que este ciclo viene haciendo de facto en cada AC de detección.

## El problema

Cuatro controles medidos en SICOP tenían forma de control y ningún poder: un test de partición que nada ejecutaba y que salía 0 con y sin violación; una comparación donde 4 de 25 casos comparaban un build contra una copia de sí mismo; un criterio que exigía `LEFT JOIN` y pasaba igual con `INNER` porque el lookup contiene las claves sin familia; y una guarda de autoría verdadera siempre. Ninguno era un error de lógica: los cuatro se veían bien y no podían fallar, y los cuatro se encontraron rompiéndolos a propósito.

**La regla ya existe en el plugin con alcance angosto**: `plugins/sdd-flow/standards/quality-gates.md:19` (DoD ítem 5) exige el rojo antes y el verde después **sólo para el arquetipo `bugfix`**. R3 la generaliza a todo AC de detección, en cualquier arquetipo.

Este mismo ciclo tiene la evidencia de que sirve: el gate de secretos de R0 no detectaba 4 de 5 formas reales, el par AC14/AC16 de R2 sólo se sostiene porque cada mutación rompe un lado, y AC30 de R5 necesitó partirse en estabilidad y sensibilidad porque un hash constante y uno siempre-distinto pasan uno cada sub-check.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **Alcance**: un AC es de detección cuando su condición de aprobación es *"algo falla cuando X está mal"* — guardas, validaciones, constraints, tests que afirman prevenir. Un AC que afirma un valor devuelto **no** entra: ya es falsable por construcción.
2. **Evidencia**: el triple **verde → rojo → verde**, con comando y exit code por corrida. El rojo solo no alcanza, porque un control permanentemente roto produce la misma salida que uno correcto.
3. **La mutación se declara en el contract**: cada AC de detección lleva escrito qué se rompe para probarlo. El planner la escribe, el implementador la ejecuta.
4. **Toda cifra citada va con la salida del comando que la produce**, no con su resumen.
5. **Las correcciones posteriores a `APPROVED` vuelven al loop**: un diff que corrige un artefacto ya aprobado se revisa como el cambio original.

## Out of scope

- No toques `scripts/`, `hooks/` ni `SDD/tests/` salvo el test nuevo de este brief.
- No implementes R4 (arquetipo `analysis`).
- No reabras ningún AC de R0, R1, R2 ni R5.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/standards/quality-gates.md` | (mod) DoD ítem 5 generalizado · sección nueva de prueba por mutación · §5 con el triple · regla de correcciones post-`APPROVED` |
| `plugins/sdd-flow/skills/sdd-plan/SKILL.md` | (mod) el AC de detección declara su mutación |
| `plugins/sdd-flow/agents/implementing-agent.md` | (mod) produce el triple; adjunta la salida de cada cifra |
| `plugins/sdd-flow/agents/reviewer-agent.md` | (mod) AC de detección sin triple = `BLOCKER`; cifra sin salida = `MAJOR`. **Más el MINOR de R5**, abajo |
| `plugins/sdd-flow/skills/write-pr-report/SKILL.md` | (mod) las cifras del PR report llevan su salida |
| `SDD/tests/test_mutation_rule.sh` | (NEW) |

## Pasos

- [ ] T1.1 Leer los cinco archivos antes de tocarlos. Leé también `SDD/retro.md` entero: las nueve entradas son la evidencia de campo de esta regla, escrita durante este mismo ciclo.
- [ ] T1.2 Escribir `SDD/tests/test_mutation_rule.sh` (AC19-AC24) con `SDD/tests/lib.sh`. Son ACs de contenido verificables por grep, igual que AC38 en R2 y AC32-AC35 en R5. **Corré el test antes del cambio**: tiene que salir ≠0.
- [ ] T2.1 `quality-gates.md`: sección nueva de prueba por mutación con el criterio del punto 1 y el triple del punto 2. El **DoD ítem 5 referencia esa sección** en vez de limitar la regla a `bugfix`.
- [ ] T2.2 `quality-gates.md` §5: el triple entra al contrato de evidencia, junto a las dos corridas del bugfix que ya están.
- [ ] T2.3 `quality-gates.md`: la regla de que un diff que corrige un artefacto ya `APPROVED` vuelve al loop de review (AC24).
- [ ] T3.1 Propagar a `sdd-plan/SKILL.md`, `implementing-agent.md`, `reviewer-agent.md` y `write-pr-report/SKILL.md`. **Referenciá la sección de `quality-gates.md` por su título; no recopies el texto normativo** — es AC23.
- [ ] T3.2 **MINOR heredado del review de R5**: en `plugins/sdd-flow/agents/reviewer-agent.md`, la rama "hashes distintos" de la comparación de hash del doc dice "reportalo aparte" y **nunca nombra la severidad**, y `quality-gates.md` §7.2 no tiene fila para ese caso. El reviewer termina improvisando la severidad de un hallazgo que el plugin le ordena levantar. Nombrala: `MAJOR` cuando el doc que cambió gobierna los gates que sostienen el `done`, `MINOR` cuando el cambio no toca las filas que corrieron.
- [ ] T4.1 Test verde. `bash SDD/tests/run.sh` completo (7 archivos). `shellcheck --severity=warning` en 0.
- [ ] T4.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R3-gates.md` — **commiteá primero, regenerá después**.
- [ ] T4.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent`.

## Acceptance criteria (IDs del contract v5 — no los renumeres)

- **AC19** — `quality-gates.md` tiene una sección de prueba por mutación que define el triple verde→rojo→verde y el criterio de qué AC lo requiere, y el DoD ítem 5 referencia esa sección en vez de limitar la regla al arquetipo `bugfix`.
- **AC20** — `sdd-plan/SKILL.md` exige que cada AC de detección declare su mutación en el contract.
- **AC21** — `reviewer-agent.md` clasifica como `BLOCKER` un AC de detección sin las tres corridas, y como `MAJOR` una cifra reportada sin la salida que la produce.
- **AC22** — `implementing-agent.md` y `write-pr-report/SKILL.md` exigen adjuntar la salida del comando de cada cifra reportada.
- **AC23** — Los cinco archivos referencian la sección de `quality-gates.md` **por su título**, y ninguno recopia el texto normativo del triple. Verificable con grep del título en los cinco.
- **AC24** — `quality-gates.md` declara que un diff que corrige un artefacto ya aprobado vuelve al loop de review.

**AC23 es el AC de detección de este requerimiento**: su condición de aprobación es "no hay texto normativo duplicado". Un grep que busca una frase que no existe en ningún lado pasa siempre. Probalo por mutación: recopiá el texto normativo en uno de los cinco archivos, verificá que el test se ponga rojo, y revertí. Sin eso, AC23 es exactamente el tipo de control tautológico que este requerimiento existe para prohibir.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC19 | | | | [ ] |
| AC20 | | | | [ ] |
| AC21 | | | | [ ] |
| AC22 | | | | [ ] |
| AC23 | | | | [ ] |
| AC24 | | | | [ ] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce — es la regla que estás escribiendo, aplicada a vos.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe** (`RT7`).
- **Verificá cómo se mide antes de creerle a la medición** (`RT8` y tres incidentes del ciclo).
- **No verifiques lint con `git ls-files`** (`D8`). Usá el glob del gate.
- Literales con forma clave-valor, **partidos**, o el gate 9 se pone rojo.
- Prohibidas las mitigaciones de `quality-gates.md` §6, en particular **cualquier exclusión por path**.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Riesgo declarado

La regla sube el costo de cada AC de detección de una corrida a tres. El punto 1 del alcance es lo único que evita que eso se aplique a todos los ACs. Si tu redacción del criterio deja lugar a que un AC de valor devuelto entre, el requerimiento triplica el costo del pipeline entero — escribí ese criterio con la misma dureza que las closure rules.

## Rollback

`git revert`. Todo markdown salvo el test.

## Execution Report

- **Summary**:
- **Task status**:
- **Validation executed** (comando · exit code):
- **Blockers**:
- **Files changed**:
- **Final statement**:
