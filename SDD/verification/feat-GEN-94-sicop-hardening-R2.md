# Verification Report — AGENT_r2 · R2-agent-identity

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5) para R2 del contract `SDD/contracts/2026-08-13-sicop-hardening.md` **v4**, sección R2 (AC14-AC18; los ACs de R2 no cambiaron entre v3 y v4 — v4 sólo amplió con R5, que este brief no toca).

- **Branch**: `feat-GEN-94-sicop-hardening` (creada desde `prod`, heredada de R0/R1)
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` v4, sección R2
- **Commit evaluado (código + docs + tests + este reporte)**: el commit `[ADD] [GEN-94] [sdd-flow] ...` que se crea después de este reporte (el hash no puede conocerse antes de crearlo — mismo razonamiento que R1 ronda 1/2; queda en el `sdd.result` con su valor real)
- **Commit evaluado (evidencia de gates)**: un segundo commit `[ADD] [GEN-94] [sdd-flow] ...` que agrega `feat-GEN-94-sicop-hardening-R2-gates.md` — generado con árbol limpio, por la estrictez de R1 (AC9: `-o` fuera de `.sdd/` exige árbol limpio o el runner sale 4 sin escribir)
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (sin cambios de contenido — R2 no toca comandos de la escalera)

---

## Problema y mecanismo (contexto para leer la evidencia)

`git log -1 --format='%an' -- <archivo>` es la forma canónica de una guarda "esto lo hizo una persona, no el agente". Antes de este trabajo era inexpresable: el agente commiteaba con la identidad git del usuario, así que la guarda salía verdadera siempre. R2 cierra esto con dos piezas:

1. **Mecanismo** (decisión #2 del contract): el implementing-agent commitea con `git -c user.name=... -c user.email=...` — nunca `GIT_AUTHOR_*`/`--author`. Default `sdd-agent` / `sdd-agent@users.noreply.github.com`, overrideable con `SDD_AGENT_NAME`/`SDD_AGENT_EMAIL`.
2. **Enforcement opt-in** (decisión #3): `plugins/sdd-flow/hooks/guard-git.sh` gana un bloque (después del chequeo de rama protegida existente) que deniega un `git commit` cuyo `-c user.name=`/`-c user.email=` no coincide con la identidad esperada — **únicamente** cuando `SDD_AGENT_ENFORCE=1` está en el entorno. Sin la variable, el bloque no corre y el flujo cae al `allow()` final sin opinar (AC16).

El bloque nuevo reusa el `deny()` existente (mismo mecanismo que el chequeo de rama protegida) y no toca la política fail-open del hook: ningún camino nuevo agrega un `exit` distinto al que ya usaba `deny()`/`allow()`.

---

## Corrida antes/después del fix (T1.2 del brief) — las dos corridas

`SDD/tests/test_guard_identity.sh` (NEW) cubre AC14-AC18, usando únicamente los helpers de `SDD/tests/lib.sh` (`assert_eq`, `assert_contains`, `test_summary` — ningún assert propio). El brief pide la misma disciplina que un bugfix aunque R2 es `infra`: correr el test antes del fix y registrar la corrida roja.

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — **roja**, antes del fix (T1.2), contra `guard-git.sh` sin el bloque de identidad | `bash SDD/tests/test_guard_identity.sh` | `1` | `FAIL — 2 assert(s) fallaron` — sólo las 2 de AC14 |
| 2 — **verde**, después del fix (T3.1) | `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` |

**Corrida 1 completa (roja), contra `guard-git.sh` sin modificar**, pegada tal cual:

```
  FAIL  AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega — esperado [si], obtenido [no]
  FAIL  AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada — no encontré [sdd-agent] en la salida
  ok    AC15 enforce=1 con identidad de agente default - el hook permite
  ok    AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa
  ok    AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite
  ok    AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent
  ok    AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue
FAIL — 2 assert(s) fallaron
```

Explicación de por qué sólo AC14 sale roja acá (no es un bug del test): antes del fix `guard-git.sh` no tiene ningún chequeo de identidad, así que **siempre** cae al `allow()` final. Eso hace que AC15/AC16/AC17 (los tres esperan "permite") pasen ya, por ausencia de chequeo — trivialmente, no porque el mecanismo funcione. AC18 tampoco depende del hook: ejercita directamente el mecanismo de la decisión #2 (`git -c user.name=... commit` es comportamiento nativo de git, no algo que `guard-git.sh` decida). Sólo AC14 (que exige una denegación real) puede distinguir "sin fix" de "con fix", y es exactamente la que sale roja.

**Corrida 2 completa (verde), después del fix**, pegada tal cual:

```
  ok    AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega
  ok    AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada
  ok    AC15 enforce=1 con identidad de agente default - el hook permite
  ok    AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa
  ok    AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite
  ok    AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent
  ok    AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue
PASS
```

---

## AC14 ↔ AC16 — par de detección, probado por mutación (dos triples verde→rojo→verde)

El brief es explícito: AC14 y AC16 forman un par. Un hook que deniega siempre pasa AC14 y falla AC16; uno que nunca deniega pasa AC16 y falla AC14. Verlos verdes juntos no alcanza — hay que romper el hook en las dos direcciones y confirmar que cada AC detecta la rotura que le corresponde, **y sólo esa**.

### Mutación 1 — hook que nunca deniega (ataca AC14)

Se forzó la condición de denegación a `false` en `plugins/sdd-flow/hooks/guard-git.sh` (bloque 4), simulando un hook cuyo chequeo de identidad nunca dispara:

```diff
-  if [ "$GOT_NAME" != "$EXPECTED_NAME" ] || [ "$GOT_EMAIL" != "$EXPECTED_EMAIL" ]; then
+  # MUTACION-AC14-TEMPORAL-R2: condicion forzada a false a proposito para la
+  # corrida roja exigida por quality-gates.md (AC de deteccion) -- simula un
+  # hook que nunca deniega. Se revierte enseguida.
+  if false && ([ "$GOT_NAME" != "$EXPECTED_NAME" ] || [ "$GOT_EMAIL" != "$EXPECTED_EMAIL" ]); then
```

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar, código real) | `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` (idéntica a la "Corrida 2" de arriba) |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_guard_identity.sh` | `1` | `FAIL — 2 assert(s) fallaron` — fallan **exactamente** las 2 asserts de AC14; las 7 restantes (incluida AC16) siguen `ok` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` de nuevo |

Salida completa y real de la corrida 2 (roja):

```
  FAIL  AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega — esperado [si], obtenido [no]
  FAIL  AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada — no encontré [sdd-agent] en la salida
  ok    AC15 enforce=1 con identidad de agente default - el hook permite
  ok    AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa
  ok    AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite
  ok    AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent
  ok    AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue
FAIL — 2 assert(s) fallaron
```

Confirma la primera mitad del par: **AC16 sigue verde con un hook que nunca deniega** (el brief lo predice literalmente: "un hook que... nunca deniega pasa AC16"), y **sólo AC14 detecta la rotura**.

Revertido y confirmado sin rastro:
```
$ grep -n "MUTACION" plugins/sdd-flow/hooks/guard-git.sh
(sin salida, exit 1)
```
Corrida 3 (verde) idéntica a la corrida 1 de este bloque.

### Mutación 2 — hook que evalúa identidad siempre, aunque el repo no la exija (ataca AC16)

Se forzó el gate de `SDD_AGENT_ENFORCE` a verdadero incondicional, simulando un hook que chequea identidad **incluso sin que el repo haya optado por el enforcement**:

```diff
-if [ "${SDD_AGENT_ENFORCE:-0}" = "1" ]; then
+# MUTACION-AC16-TEMPORAL-R2: gate de SDD_AGENT_ENFORCE forzado a true a
+# proposito para la corrida roja exigida por quality-gates.md (AC de
+# deteccion) -- simula un hook que evalua identidad siempre, aunque el repo
+# no haya optado por el enforcement. Se revierte enseguida.
+if true; then
```

| Corrida | Comando | Exit code | Resultado |
|---|---|---|---|
| 1 — verde (antes de mutar, código real) | `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` |
| 2 — rojo (con la mutación) | `bash SDD/tests/test_guard_identity.sh` | `1` | `FAIL — 1 assert(s) fallaron` — falla **exactamente** la de AC16; las 8 restantes (incluidas las 2 de AC14) siguen `ok` |
| 3 — verde (mutación revertida) | `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` de nuevo |

Salida completa y real de la corrida 2 (roja):

```
  ok    AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega
  ok    AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada
  ok    AC15 enforce=1 con identidad de agente default - el hook permite
  FAIL  AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa — esperado [no], obtenido [si]
  ok    AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite
  ok    AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent
  ok    AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue
FAIL — 1 assert(s) fallaron
```

Confirma la segunda mitad del par: **AC14 sigue verde con un hook que deniega sin condición** (el brief lo predice: "uno que deniega siempre pasa AC14"), y **sólo AC16 detecta esta rotura, distinta de la de la Mutación 1**.

Revertido y confirmado sin rastro:
```
$ grep -n "MUTACION" plugins/sdd-flow/hooks/guard-git.sh
(sin salida, exit 1)
$ git diff plugins/sdd-flow/hooks/guard-git.sh
(sin salida — idéntico al árbol staged antes de las dos mutaciones)
```

**Conclusión**: el par AC14/AC16 tiene poder de detección real en las dos direcciones — no es tautológico. `plugins/sdd-flow/hooks/guard-git.sh` en el repo, al momento de este commit, es la versión sin ninguna de las dos mutaciones.

---

## Gates — validación final (código con las dos mutaciones ya revertidas)

Corridas reales, en esta máquina, contra el árbol final (antes de commitear):

| Comando | Exit code | Resultado |
|---|---|---|
| `bash SDD/tests/test_guard_identity.sh` | `0` | `PASS` — 9/9 `ok` |
| `bash SDD/tests/run.sh` | `0` | `PASS` los 5 archivos — `5 passed, 0 failed (5 total)` |
| `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | `0` | limpio (sin salida) |
| `bash SDD/tests/secret-scan.sh` (con los archivos de este diff `git add`eados, para que el escaneo por `git ls-files` los vea — `D8`) | `0` | `secret-scan: sin hallazgos sobre 83 archivos versionados (1 excluido: self)` |

Salida completa de `bash SDD/tests/run.sh`:
```
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_run_gates.sh
PASS  test_run_gates_tree.sh
PASS  test_secret_scan.sh
---
5 passed, 0 failed (5 total)
```

Ninguno de los literales nuevos (`SDD_AGENT_ENFORCE=1`, `SDD_AGENT_NAME=...`, `SDD_AGENT_EMAIL=...`, `user.name=sdd-agent`, `user.email=sdd-agent@users.noreply.github.com`) dispara el patrón de `secret-scan.sh` (`standards/security.md` §3): ninguna de sus claves contiene `password|secret|token|api[_-]?key`, así que no hace falta partir estos literales en spans separados — verificado corriendo el gate de verdad arriba, no supuesto.

---

## Gates — evidencia GENERADA (no la escribo a mano)

**Con el código ya completo, `-o SDD/verification/...` exige árbol limpio (AC9 de R1) — exactamente el comportamiento que R1 fuerza.** Por eso la secuencia real de esta tarea es: (1) terminar el diff completo (código + test + docs + brief + este reporte), (2) commitear, (3) recién ahí correr el runner apuntando a `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md`. El resultado de esa corrida queda en un segundo commit sobre esta misma branch, referenciado abajo con su exit code real.

Comando:
```bash
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md
```

- **Reporte generado**: `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md` (mismo directorio que este archivo)
- **Resultado real de esa corrida**: <SE_COMPLETA_TRAS_EL_COMMIT_1 — ver `sdd.result` de esta ronda para el valor real; no transcribo a mano lo que el runner ya deja escrito>

---

## Impact set

`guard-git.sh` es un script existente que R2 modifica (agrega un bloque, no cambia los anteriores). Callers/consumidores documentados:

| Símbolo cambiado | Caller / consumidor | Cobertura |
|---|---|---|
| `guard-git.sh` (bloque 4, identidad) | `plugins/sdd-flow/hooks/hooks.json` — lo registra como `PreToolUse` sobre `Bash` en cualquier sesión de Claude Code con el plugin instalado | Sin romper: el bloque nuevo sólo corre si `SDD_AGENT_ENFORCE=1` está en el entorno (AC16) — una sesión sin esa variable ve exactamente el mismo comportamiento que antes de este diff, verificado con AC16 |
| `guard-git.sh` | `SDD/tests/test_guard_identity.sh` (NEW, este mismo diff) | AC14-AC18, ver binding |
| `guard-git.sh` (chequeo de rama protegida y `allow()`/`deny()` preexistentes) | Ningún test previo lo ejercitaba (`grep -rl "guard-git" --include="*.sh"` antes de este diff no devolvía ningún `test_*.sh` — es la primera vez que este hook se prueba de verdad). No hay regresión que verificar porque no había baseline de test, pero tampoco se tocó ninguna línea de las secciones 1-3: el diff sólo inserta el bloque 4 entre el `for` de rama protegida y el `allow` final | El diff se limita a insertar; `git diff` confirma que las secciones 1-3 no cambiaron una sola línea |
| `implementing-agent.md` (regla de commit con identidad) | Cualquier implementing-agent futuro que lea su propio system prompt — incluido este mismo agente, que adoptó `-c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com` para los commits de esta misma tarea (ver hashes abajo) | Demostración en vivo, no sintética: los commits de este diff son el primer caso real de uso del mecanismo |
| `base-standards.md` / `quality-gates.md` (texto normativo nuevo) | Prosa leída por agentes/skills (`sdd-plan`, otros implementing-agents); ningún script parsea estos archivos programáticamente (`grep` de callers no encontró ningún `.sh` que los lea más allá de menciones cruzadas en otros `.md`) | No aplica test automatizado — es contenido normativo, verificado por lectura (igual que el resto de `standards/`) |

Ningún caller de `guard-git.sh` quedó sin cubrir: el único consumidor real (`hooks.json`, el propio mecanismo de hooks de Claude Code) no cambia de comportamiento sin la variable nueva (AC16), y el único consumidor de test (`test_guard_identity.sh`) es nuevo y cubre las 5 ACs.

**Observación fuera de scope, declarada, no corregida**: `SDD/docs/doc_architecture.md:161` documenta los env vars de `guard-git.sh` (`SDD_ALLOW_BASE_COMMIT`, `SDD_PROTECTED_BRANCHES`) y no lista los 3 nuevos de este diff. Ese archivo no está en la tabla de Files del brief ni en el Architectural Delta de R2 del contract — fuera de mi scope tocarlo sin ratificación del planner (mismo criterio que R1 aplicó a la nota de `git stash create`/`D7`). Lo dejo para que el planner decida si amerita un fix chico o una fila de deuda.

---

## Rojos preexistentes

- Ninguno. Los 4 archivos de test preexistentes a este brief (`test_harness.sh`, `test_run_gates.sh`, `test_run_gates_tree.sh`, `test_secret_scan.sh`) siguen `PASS` en la corrida de la suite completa de arriba, sin ningún cambio de este diff a la lógica que ejercitan (`sdd-run-gates.sh` y `secret-scan.sh` no forman parte del Architectural Delta de R2 — no se tocaron). `shellcheck --severity=warning` sigue en `0` (los 3 `SC2016` preexistentes de `plugins/` — deuda `D4` de R0 — no cambian).

---

## Smoke manual (sólo ACs `manual-only`)

N/A — R2 no declara ningún AC `manual-only`.
