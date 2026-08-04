# Quality Gates — sdd-flow

Fuente normativa de **calidad verificable** del ciclo SDD. `base-standards.md` dice *qué reglas* respeta el código; este archivo dice *cómo se prueba que se respetaron* y *qué evidencia* tiene que existir para que una tarea pueda declararse terminada.

Razón de ser: el contract se auto-aprueba (el gate humano está en Feature Ready). Si la calidad queda declarada en prosa ("tests verdes", "TDD cuando aplique"), nadie la puede auditar. Acá se convierte en artefactos: **AC numerados**, **binding AC↔test**, **escalera de gates** y **evidencia con exit codes**.

Los comandos concretos de cada repo NO viven acá: viven en `SDD/docs/doc_quality_gates.md` (lo genera `/sdd-init`). Este archivo es el método; ese archivo es el stack.

---

## 1. Definition of Done (idéntica para cualquier requerimiento)

Una tarea está `done` sólo si TODO esto es cierto. Sin excepciones por tamaño del cambio:

1. Cada acceptance criterion del brief tiene un test que lo ejercita, y el binding está escrito (§3).
2. La escalera de gates (§4) corrió completa y en verde, con evidencia registrada (§5).
3. Ninguna mitigación prohibida (§6) aparece en el diff.
4. El impact set está cubierto: cada caller/import de un símbolo cambiado tiene test de regresión o justificación explícita de por qué no lo necesita.
5. Si el requerimiento es un **bugfix**: existe un test que reproducía el bug — con evidencia del fallo **antes** del fix (exit code ≠ 0) y del verde **después**. Un bugfix sin test rojo previo no está probado, está supuesto.
6. Docs delta aplicado: si el Architectural Delta tocó capas/rutas/contratos → `SDD/docs/doc_architecture.md` actualizado; si aparecieron comandos de verificación nuevos → `doc_verification_guide.md` y `doc_quality_gates.md` actualizados.
7. Review con veredicto `APPROVED` (§7).
8. Execution Report completo, sin ninguna validación declarada que no se corrió.

Un ítem que no aplica se marca `N/A` **con razón**, no se omite en silencio.

---

## 2. Acceptance criteria numerados (los escribe el planner)

El HLTC lleva una sección `## Acceptance criteria` con IDs estables `AC1..ACn`. Cada AC:

- describe **comportamiento observable**, no implementación ("devuelve 422 con `code: INVALID_QTY`", no "valida con Zod");
- es verificable por un solo test (si necesita dos, son dos ACs);
- respeta las closure rules del contract (nada de "if needed / or / prefer").

Los IDs son estables entre versiones del contract: si un AC muere, se marca `AC4 — retirado en v2`, no se reciclan números. Cada task brief copia los ACs que le tocan **con su ID original**.

Un AC verificable sólo a mano (ej. visual, hardware ausente) se permite si el HLTC lo declara explícito como `manual-only: <razón>`; entonces el brief lleva los pasos exactos de smoke y la evidencia es el resultado escrito de esos pasos. `manual-only` sin razón declarada = contract inválido.

Los criterios **advisory** (SEO, `standards/seo-frontend.md`) NO son ACs: van en su propia sección con IDs `SEO1..SEOn`, no exigen test y no entran en la Definition of Done. Un ítem advisory se vuelve bloqueante sólo si el planner lo promueve explícitamente a `ACn` — decisión consciente, no default.

---

## 3. Trazabilidad AC ↔ test (regla dura)

Cada brief cierra con esta tabla, llenada por el implementing agent:

```md
## AC ↔ test binding
| AC  | Comportamiento              | Test                                            | Tipo        | Estado |
|-----|-----------------------------|-------------------------------------------------|-------------|--------|
| AC1 | crea la orden y devuelve 201 | tests/orders.create.spec.ts::"creates order"    | integration | [x]    |
| AC2 | rechaza qty negativa (422)   | tests/orders.create.spec.ts::"rejects negative" | unit        | [x]    |
| AC3 | badge visible en el header   | manual-only — ver Smoke steps                   | manual      | [x]    |
```

- **AC sin fila, o fila sin nombre de test real = BLOCKER.** No se aprueba.
- El nombre del test tiene que existir literal en el archivo (el reviewer lo verifica con grep).
- Un mismo test puede cubrir dos ACs sólo si asserta ambos comportamientos por separado.

---

## 4. Escalera de gates (orden fijo, corta al primer rojo)

Siempre en este orden — de lo más barato a lo más caro. El primero que falla detiene la escalera: se arregla y se reinicia desde ese escalón.

| # | Gate | Obligatorio | Nota |
|---|---|---|---|
| 1 | format / style | sí, si el repo tiene formatter | auto-fix permitido |
| 2 | lint | sí, si el repo tiene linter | cero warnings nuevos |
| 3 | type-check | sí, si el lenguaje es tipado | proyecto entero, no sólo archivos tocados |
| 4 | unit tests | sí | los del área tocada + los nuevos |
| 5 | integration tests | sí, si el cambio cruza capas | |
| 6 | build | sí, si el repo compila/bundlea | |
| 7 | e2e | sólo si el AC lo exige o el flujo de usuario cambió | no es default |
| 8 | cobertura del diff | sí | ver abajo |
| 9 | smoke manual | sólo para ACs `manual-only` | pasos exactos, resultado escrito |

**Suite completa antes de integrar**: los escalones 4-5 pueden correrse filtrados por área durante la iteración, pero antes de abrir PR (o de mergear local) corre la suite completa al menos una vez. Un cambio "chico" que rompe otra área es el caso exacto que esto ataca.

**Cobertura del diff** (no thresholds globales, que son frágiles y se bajan solos): cada archivo de código nuevo o modificado tiene que quedar ejercitado por al menos un test que recorra las líneas cambiadas. Si el stack emite reporte de coverage, se usa para verificarlo; si no, alcanza el binding de §3 más la revisión del diff. **Prohibido bajar un threshold existente para pasar el gate** (§6).

Un gate que el repo no tiene (`doc_quality_gates.md` lo declara ausente) se registra `N/A — no existe en este repo`. Un gate que existe y no se corrió es `[SKIPPED]` y bloquea el `done`.

---

## 5. Contrato de evidencia

"Nunca declares una validación que no corriste" sólo es auditable si la corrida deja rastro. Cada agente escribe su propio verification report con `templates/verification-report.md`:

- multi-agente: `tasks/<task-slug>/verification/AGENT_<slug>.md` — un archivo por agente, para no romper el ownership 1-way del protocolo de coordinación;
- single-repo / sin coordinación file-based: `SDD/verification/<branch>.md`.

Contenido:

- una fila por gate: comando exacto · exit code · timestamp UTC · las últimas ~15 líneas de output (o el resumen del runner);
- exit code registrado siempre, también cuando es ≠ 0 y se arregló después (la historia de rojos es señal, no vergüenza);
- para bugfixes, las **dos** corridas del test de reproducción (roja antes, verde después);
- para ACs `manual-only`, pasos ejecutados y resultado observado.

El Execution Report del brief referencia este archivo; no lo duplica. **Evidencia ausente o sin exit codes = BLOCKER**: el reviewer no la infiere ni la asume.

---

## 6. Mitigaciones prohibidas (regla dura)

Estas son las formas en que un agente apurado hace pasar el gate sin resolver el problema. Todas son **BLOCKER**, sin excepción implícita:

1. Modificar, borrar, `skip`ear, marcar `todo`/`xit`/`@Disabled` o comentar un test existente — salvo que el contract declare explícitamente ese cambio de comportamiento (y entonces se cita la sección del contract en el commit).
2. Debilitar una assertion existente (aflojar un `toEqual` a `toBeTruthy`, ampliar una tolerancia, borrar un caso de un table test).
3. `@ts-ignore`, `@ts-expect-error`, `eslint-disable`, `# type: ignore`, `# noqa`, `@SuppressWarnings`, `nolint` — sin comentario en la misma línea que referencie la decisión del contract que lo justifica.
4. Introducir `any` (o su equivalente: `object`, `dynamic`, `interface{}`, cast a `unknown` y de vuelta) para callar al type-checker.
5. Bajar un threshold de coverage/lint, agregar el archivo a un `ignore`, o excluirlo de la config de tests.
6. `--no-verify`, `--force` (sin `--force-with-lease`), `--skip-checks`, `CI=false`, o cualquier bypass de hooks/CI.
7. Marcar un test como flaky y reintentarlo en lugar de arreglarlo.
8. `catch` silencioso (bloque vacío, `catch { return null }` sin política declarada) para que el flujo "no falle".
9. Hardcodear el valor esperado por el test dentro de la implementación.

Estos markers son grepeables y el reviewer los busca mecánicamente (§7.1). El camino legítimo cuando un gate no se puede pasar es **BLOCKED → preguntar al planner**, nunca ablandar el gate.

---

## 7. Review: severidades, veredicto y cota de iteración

### 7.1 Chequeo mecánico primero (antes de leer el diff con criterio)

El reviewer corre, en este orden, y todo hallazgo es objetivo:

1. `git diff` de los tests: ¿se borró/skipeó/aflojó algo? (§6.1, §6.2)
2. grep del diff por los markers de §6.3-§6.6.
3. grep de cada nombre de test del binding (§3) en el archivo declarado: ¿existe literal?
4. `verification.md`: ¿están todos los gates de §4 con exit code? ¿alguno ≠ 0 sin corrida verde posterior?
5. **Re-corre por su cuenta el subset barato** (type-check + unit del área tocada). Si difiere de la evidencia, la evidencia está podrida → BLOCKER.

### 7.2 Severidades

| Severidad | Qué cae acá | Efecto |
|---|---|---|
| `BLOCKER` | infidelidad al contract · AC sin test · gate rojo o sin evidencia · mitigación prohibida · secreto en código · SQL concatenado · código en la capa incorrecta | rechaza |
| `MAJOR` | test que no asserta el comportamiento del AC (asserts vacíos, snapshot-only para lógica, mock que se testea a sí mismo) · caller impactado sin regresión ni justificación · error handling ausente frente al "expected behavior" del contract · lógica duplicada existiendo ya una implementación (viola el Reuse statement del Architectural Delta) | rechaza |
| `MINOR` | naming inconsistente · dead code · comentario obsoleto · falta un edge case no exigido por ningún AC | no rechaza |
| `ADVISORY` | SEO · sugerencias fuera del scope del brief · deuda técnica preexistente | no rechaza, informa |

### 7.3 Veredicto

- `APPROVED` = cero `BLOCKER` y cero `MAJOR`. Los `MINOR` se listan; el agente los arregla si son triviales (≤3 líneas cada uno), y si no van al PR report como *known minors*.
- `REJECTED` = hay `BLOCKER` o `MAJOR`. Cada hallazgo con ubicación (`archivo:línea`) · severidad · problema · fix sugerido en una línea.
- `ESCALATE` = el hallazgo requiere una decisión que no está en el contract, o se agotaron las rondas.

### 7.4 Cota de iteración (máximo 3 rondas)

Implementar → review es un loop acotado: **3 rondas por brief**. Si la ronda 3 no cierra en `APPROVED`, el reviewer emite `ESCALATE` al planner con: qué hallazgo no se cierra, qué intentó el agente en cada ronda, y qué decisión falta. El planner ratifica contract, corta el scope, o lo eleva al gate humano de Feature Ready.

Sin cota, el failure mode conocido aparece solo: en la ronda 5 el agente empieza a ablandar tests para salir del loop.

---

## 8. Capas de enforcement

Este archivo es prompt: describe qué tiene que pasar y confía en que el agente lo cumpla. Tres de las prohibiciones de §6 no dependen de eso — las bloquea un hook determinístico (`hooks/guard-git.sh`, `PreToolUse` sobre `Bash`):

| Qué bloquea | Por qué acá y no sólo en prosa |
|---|---|
| `git commit` con HEAD en rama protegida (`main`, `master`, `dev`, `develop`, `qa`, `test`, `staging`, `pre-prod`, `prod`, `release`) | es la regla de branching del plugin, y es el error más caro de deshacer |
| `--no-verify` | saltea los hooks del repo — el bypass más silencioso de todos |
| `git push --force` sin `--force-with-lease` | puede borrar el trabajo de otro agente del ciclo |

El hook es **fail-open**: sin `jq`, sin git, JSON inesperado o cwd desconocido → deja pasar. Un guard que rompe sesiones es peor que no tener guard. Detección best-effort: si el comando hace `cd` a otro repo antes del commit, el chequeo de rama mira la rama del cwd de la sesión.

Escape hatch: `SDD_ALLOW_BASE_COMMIT=1` desactiva sólo el chequeo de rama protegida, para repos donde commitear a la default es legítimo.

Todo lo demás de §6 (tests aflojados, `@ts-ignore`, thresholds bajados) se detecta en el chequeo mecánico del review (§7.1), que es donde el grep tiene el diff completo a la vista.

## 9. Perfiles por stack

El método de este archivo es agnóstico. Las reglas con forma de lenguaje viven en un perfil, y el repo declara el suyo en `SDD/docs/doc_quality_gates.md`:

- **TypeScript/JS**: sin `any`, validación de bordes con Zod (o equivalente), `strict` prendido, sin `@ts-ignore` (§6.3).
- **Python**: type hints en firmas públicas, validación con Pydantic (o equivalente), sin `# type: ignore` desnudo.
- **C#/.NET**: nullable reference types prendido, sin `dynamic` para callar el compilador.
- **SQL**: siempre parametrizado, nunca concatenación de strings.

Si el stack del repo no tiene perfil escrito, el gate mínimo sigue siendo el de §4 y las prohibiciones de §6 aplican con el equivalente del lenguaje.
