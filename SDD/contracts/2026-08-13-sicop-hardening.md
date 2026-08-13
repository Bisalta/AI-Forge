# HLTC — sdd-flow v0.11.0 · hardening desde el análisis de SICOP

- **Contract version**: v3 — ratificado el 13-ago-2026 tras el `REJECTED` de la ronda 2 de R0. Cambio respecto de v2: los cuatro literales de credencial de AC6bis se escriben con clave y valor en spans separados, para que el contract deje de disparar su propio detector. Verificado con el patrón de `SDD/tests/secret-scan.sh`: cero coincidencias en este archivo. Con eso, la exclusión de `SDD/contracts/` queda **prohibida** y se elimina.
- **Contract version**: v6 — ratificado el 14-ago-2026 tras el review `APPROVED` de R3. Entran **AC39** y **AC40** (dos consumidores de la regla de mutación que faltaban en el Delta de R3) y **AC41** (cierre del hueco de closure en la forma "ausencia" de §10.1). Detalle en la ratificación de la sección R3.
- **Historial de versiones**: v5 — ratificado el 13-ago-2026 tras el `ESCALATE` de la ronda 1 de R2. La ubicación del bloque de identidad en `guard-git.sh` pasa de "tras el chequeo de rama protegida" a "por encima del escape hatch `SDD_ALLOW_BASE_COMMIT`", y entran **AC36, AC37 y AC38**. Detalle y medición en la ratificación de la sección R2.
- **Historial de versiones**: v4 — ampliado el 13-ago-2026 con **R5**, tras el consolidado externo `MD-consolidado.md` (13-ago) que reemplaza a los cinco documentos previos de SICOP. R5 es su propuesta 3 (identidad de contenido de los docs que gobiernan), que no estaba en v1-v3. Su propuesta 6 (gate mínimo portable) queda **fuera de este contract**: está planteada como oferta y necesita como insumo el script de `Bisalta/Odoo-Addons`, que este ciclo no tiene. Los ACs de R0-R4 no cambian.
- **Historial de versiones**: v2 — ratificado por el planner el 13-ago-2026 tras el `ESCALATE` de la ronda 1 de R0. Cambios respecto de v1: threat model y bloque `concerns:` agregados (eran un BLOCKER de contract); AC3 reescrito con la severidad de `shellcheck` adentro; AC5 reescrito para apuntar a `SDD/verification/` en vez de `.sdd/`; AC6bis nuevo para cubrir `secret-scan.sh`. Los IDs de AC existentes no se reciclaron.
- **Tarea madre Proxima**: `GEN-94`
- **Repo**: `Bisalta/AI-Forge` · **Rama base**: `prod` · **Branch**: `feat-GEN-94-sicop-hardening`
- **Capa de integración**: git con remote → PR contra `prod`
- **Estado**: auto-aprobado y logueado (el gate humano está en Feature Ready)
- **Origen**: `~/Downloads/propuestas-a-sdd-desde-sicop.md` (12-ago-2026), cuatro cambios propuestos tras un día de cinco ciclos en SICOP.

---

## Objective

Cerrar cuatro huecos del ciclo SDD que el proyecto SICOP midió en producción, más el prerequisito de escalera que este repo no tiene. Cada hueco es un caso donde un artefacto **afirma** una propiedad que no puede sostener: evidencia sellada contra el código equivocado, una guarda de autoría siempre verdadera, controles que no pueden ponerse rojos, y análisis que produce números de decisión sin pasar por review.

## Out of scope

- Reescribir `doc_verification_guide.md` (el documento origen lo cita, pero v0.10.0 ya lo reemplazó por `doc_quality_gates.md` + runner).
- Firmar commits con GPG. La identidad de agente de R2 previene el descuido, no a un actor decidido; el alcance criptográfico queda fuera y se registra en el ledger de deuda.
- Automatizar la corrección de los hallazgos SEO (`sdd-seo` sigue advisory).
- Migrar el marketplace ni tocar `plugins/project-foundation/`.

## Source of truth

- Método de calidad: `plugins/sdd-flow/standards/quality-gates.md`.
- Forma del requerimiento: `plugins/sdd-flow/standards/archetypes.md`.
- Escalera concreta de ESTE repo: `SDD/docs/doc_quality_gates.md` (NEW, lo crea R0).

## Threat model (`plugins/sdd-flow/standards/security.md` §6)

1. **¿Qué superficie invocable nueva se expone?** Ninguna hacia una red. Lo que cambia es tooling que corre en la máquina del desarrollador y en su repo: dos scripts de shell del plugin (`sdd-run-gates.sh`, `guard-git.sh`), un harness de tests local, y documentación normativa. No hay endpoint, puerto, ni servicio.
2. **¿Qué input no confiable se procesa, y dónde se valida?** `sdd-run-gates.sh` ejecuta con `bash -c` los comandos que lee de `doc_quality_gates.md`. Eso ya es así en v0.10.0 y R1 no lo cambia: el doc de gates es un archivo versionado del propio repo, con la misma confianza que un `Makefile`. Quien puede editarlo ya puede ejecutar código en esa máquina. `secret-scan.sh` recorre archivos versionados y sólo los lee. `guard-git.sh` parsea el comando del hook y **falla abierto**: un input que no entiende permite la operación, nunca la deniega por confusión.
3. **¿Qué dato sensible toca el cambio?** `secret-scan.sh` es el único que mira contenido con potencial de secretos, y su salida nombra archivo y línea sin imprimir el valor detectado. Ningún artefacto de evidencia (`SDD/verification/`) puede contener el secreto encontrado.
4. **¿Qué pasa si el control falla?** El modo de falla que importa es el **falso negativo**: un gate de seguridad que no detecta produce la misma salida que uno que no tenía nada que detectar. Es el patrón que este contract entero ataca, y por eso `secret-scan.sh` pasa a tener su propio AC de detección probado por mutación (AC6bis).

**Concerns** (`plugins/sdd-flow/standards/concerns.md`): `security` **blocking** — cerrado por el threat model de arriba y por AC6bis. `observability` **blocking** — cerrado por AC2, AC14 y AC18, que exigen que cada control diga qué detectó. `performance` no blocking: no hay número comprometido y la escalera corre en segundos. `a11y`, `design`, `seo`, `data-privacy` — `N/A`, no hay UI ni dataset con PII.

## Orden de integración

`R0 → R1 → R2 → R5 → R3 → R4`, en serie sobre la misma branch. R0 crea el harness de tests del que dependen los ACs de R1, R2 y R5. R5 va **antes** de R3 porque los dos tocan `plugins/sdd-flow/agents/reviewer-agent.md` y R3 construye sobre la sección que R5 agrega. R3 y R4 tocan ambos `plugins/sdd-flow/skills/sdd-plan/SKILL.md`, por lo que tampoco corren en paralelo.

---

# R0 — Escalera de gates viva para AI-Forge

- **Arquetipo**: `project-scaffold`
- **Razón**: este repo no tiene `SDD/docs/doc_quality_gates.md` ni runner de tests ni CI. `plugins/sdd-flow/standards/archetypes.md` §`project-scaffold` obliga a que sea la primera task de cualquier `/sdd` en un repo sin escalera funcional.

## Architectural Delta

| Capa | Cambio |
|---|---|
| Docs | `SDD/docs/doc_quality_gates.md` (NEW) — la escalera de §4 con los comandos reales de este repo |
| Docs | `SDD/docs/doc_architecture.md` (NEW) — layout del repo de plugins, desde `plugins/sdd-flow/templates/doc_architecture.md` |
| Tests | `SDD/tests/lib.sh` (NEW) — helpers de assert en bash puro, cero dependencias |
| Tests | `SDD/tests/run.sh` (NEW) — descubre y corre `SDD/tests/test_*.sh`, agrega resultados |
| Tests | `SDD/tests/test_run_gates.sh` (NEW) — primer test real: humo de `sdd-run-gates.sh` sobre un repo git temporal |
| Tests | `SDD/tests/test_harness.sh` (NEW) — auto-test del harness: un caso que falla tiene que reportarse como fallo |
| Config | `.gitignore` — agregar `SDD/tests/.tmp/` |

**Ownership**: los tests viven en `SDD/tests/`, nunca dentro de `plugins/`. El contenido de `plugins/` es el producto distribuible; `SDD/` es el andamiaje de ESTE repo.

**Reuse statement**: `SDD/tests/lib.sh` es el único lugar donde se definen asserts. Ningún `test_*.sh` define su propio `assert_*`.

**Perfil del stack**: bash 3.2 (el de macOS). Prohibido `declare -A`, `mapfile`, `${var^^}` y demás bashismos de 4.x — el repo se clona en máquinas con bash 3.2 y los scripts del plugin ya respetan ese piso.

## Acceptance criteria

- **AC1** — `SDD/tests/run.sh` sale con código 0 cuando todos los `test_*.sh` pasan.
- **AC2** — `SDD/tests/run.sh` sale con código 1 cuando al menos un `test_*.sh` falla, y su salida nombra el archivo que falló.
- **AC3** — `shellcheck --severity=warning` sale 0 sobre todos los `.sh` versionados del repo (`plugins/sdd-flow/scripts/`, `plugins/sdd-flow/hooks/`, `SDD/tests/`). **Ratificación v2**: el piso es `warning`, no el default `style`. Razón medida en la ronda 1: a severidad `style` salen 3 hallazgos `SC2016` (info) en scripts de `plugins/` que R0 tiene prohibido tocar, más `SC2329` (info) por funciones invocadas sólo vía `trap`. Ninguno es un defecto. Bajar el piso por debajo de `warning`, o agregar `-e <código>` para silenciar un hallazgo de severidad real, queda prohibido sin ratificación del planner. Los 3 `SC2016` de `plugins/` van al ledger de deuda.
- **AC3bis** — Los hallazgos `SC2329` que son propios de archivos creados por R0 llevan `# shellcheck disable=SC2329` **inline con el comentario que lo justifica** en la misma línea, de modo que el piso `warning` quede justificado únicamente por los hallazgos preexistentes de `plugins/`.
- **AC4** — `SDD/docs/doc_quality_gates.md` contiene la tabla de escalera en el formato que `plugins/sdd-flow/scripts/sdd-run-gates.sh` parsea (filas `| N | gate | \`cmd\` | ... |`), y cada fila con comando declarado ejecuta un binario presente en la máquina. Las filas sin comando llevan `N/A — <razón>`.
- **AC5** — `sdd-run-gates.sh -d SDD/docs/doc_quality_gates.md -o SDD/verification/feat-GEN-94-sicop-hardening-R0-gates.md` termina con `red: 0` en su línea JSON `sdd.gates`, y ningún gate queda `[SKIPPED]` por comando inexistente. **Ratificación v2**: el destino es `SDD/verification/`, no `.sdd/`. La v1 contradecía `plugins/sdd-flow/standards/quality-gates.md:95`, que prohíbe `.sdd/` para evidencia que se commitea porque ese directorio está gitignoreado y no viaja en el PR. `.sdd/gates-run.md` queda para corridas exploratorias.
- **AC6** — `SDD/tests/test_run_gates.sh` ejercita `sdd-run-gates.sh` sobre un repo git creado en `SDD/tests/.tmp/`, y asserta el campo `green` de la línea JSON `sdd.gates`. El directorio temporal se borra al terminar, incluso si el test falla.
- **AC6bis** — `SDD/tests/secret-scan.sh` detecta, cada uno en su propio caso de test en `SDD/tests/test_secret_scan.sh` (NEW), las seis formas siguientes plantadas en un repo git temporal, y sale limpio sobre un árbol sin secretos:
  1. clave `api_key`, separador `=`, valor `sk_live_51H8xQ2abcdefg` — valor **sin comillas**, clave en minúscula;
  2. clave `PASSWORD`, separador `=`, valor `"hunter2xyz"` — clave en `SCREAMING_SNAKE`, valor entre comillas;
  3. clave `AWS_SECRET_ACCESS_KEY`, separador `=`, valor `wJalrXUtnFEMI/K7MDENG` — sin comillas y en mayúsculas;
  4. clave `GITHUB_TOKEN`, separador `:` en vez de `=`, valor `ghp_16CharactersLongToken00`;
  5. una clave privada PEM (la línea de apertura `BEGIN` … `PRIVATE KEY` entre guiones);
  6. **cualquiera de las cinco anteriores plantada bajo `SDD/contracts/`**. Es el AC de detección aplicado a la exclusión misma: si alguien vuelve a agregar un path a una lista de ignore, este caso se pone rojo. Enumerada como forma normativa en v3 tras el `REJECTED` de la ronda 2.

  **Ratificación v3**: los cuatro literales de arriba se escriben con la clave y el valor en spans separados, deliberadamente. En v2 estaban contiguos, y eso hacía que este mismo contract disparara el detector — un falso positivo que el implementador resolvió excluyendo `SDD/contracts/` entero del escaneo, dejando el gate 9 ciego en un directorio completo. La causa raíz era del plan, no del código: es el planner el que tiene que escribir las fixtures de credencial partidas, igual que `plant_kv` en `SDD/tests/test_secret_scan.sh` las parte para que el archivo de test pueda escanearse a sí mismo. **Ninguna exclusión por path está autorizada en `secret-scan.sh`**: la única exclusión admitida es la del propio script, que contiene el patrón literalmente.

  **AC6bis es un AC de detección**: se prueba por mutación, con las cinco formas plantadas y removidas, y el par verde→rojo→verde registrado por caso. **Ratificación v2**: la ronda 1 midió que la implementación entregada detecta sólo las formas 5 y `password = "x"`, y deja pasar las cuatro primeras. Un gate de seguridad obligatorio que no puede ponerse rojo frente a un secreto real es precisamente el modo de falla que este contract ataca, y por eso deja de ser un detalle de implementación para volverse un AC del contract.

## Checklist del arquetipo `project-scaffold`

| Ítem | Resolución |
|---|---|
| Layout según `doc_architecture.md` | AC4 + el doc creado en el Delta |
| Runner de tests instalado y corriendo | AC1, AC2 |
| Lint + formatter + type-check del perfil | lint = AC3 (`shellcheck`). Formatter: `N/A — shfmt no está instalado en la máquina de referencia y agregar una dependencia nueva excede el scope`. Type-check: `N/A — bash no es tipado` |
| `doc_quality_gates.md` re-verificado contra la realidad | AC5 |
| Scripts del plugin en `SDD/scripts/` y `.sdd/` gitignoreado | `N/A — este repo ES el plugin; los scripts se invocan desde plugins/sdd-flow/scripts/ y duplicarlos crearía dos fuentes de verdad. .sdd/ ya está en .gitignore` |
| CI mínimo con remote | `N/A — registrado como deuda en SDD/debt.md; el repo no tiene .github/workflows y crearlo cambia la política de merge del equipo, que es decisión de Gabriel` |
| Design tokens como ADR si hay UI | `N/A — no hay UI` |
| Primer test real que pasa | AC6 |

---

# R1 — El runner de gates sella el árbol verificado, no `HEAD`

- **Arquetipo**: `bugfix`

## Causa raíz

`plugins/sdd-flow/scripts/sdd-run-gates.sh:120` calcula `COMMIT="$(git rev-parse --short HEAD)"` y la línea 124 lo estampa como `**Commit**:` en el encabezado del reporte. La línea 125 del mismo archivo afirma *"Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia."*

Los gates corren con `bash -c "$cmd"` (línea 80) sobre el **working tree**, que puede diferir de `HEAD` en dos direcciones: cambios sin commitear al momento de la corrida, y commits posteriores a que el reporte se escribiera. El artefacto se presenta como evidencia de un commit que no es necesariamente el código ejecutado.

Medición que lo motiva (proyecto SICOP, 12-ago-2026): cuatro ciclos produjeron una tabla sellada a un árbol que no contenía el cambio certificado. En el caso MART1 el runner estampó `623c1c5` y la implementación entró en `6766e1d`, tres minutos después de escrito el reporte.

## Decisión de diseño (cerrada)

1. El reporte estampa **siempre** el hash del árbol realmente verificado, además del commit:
   - árbol limpio → `git rev-parse HEAD^{tree}`;
   - árbol sucio → `git stash create`, que produce un objeto commit con working tree **e** índice sin tocar la branch ni el stash log; de ahí se deriva el árbol con `git rev-parse <obj>^{tree}`.
   - **`git write-tree` queda descartado**: escribe el árbol del índice, por lo que un cambio sin `git add` no quedaría representado y el hash seguiría mintiendo.
2. La estrictez se deriva del **destino del reporte**, no de una bandera que alguien tiene que acordarse de pasar:
   - `-o` dentro de `.sdd/` → uso ad-hoc: el runner escribe y sale normal, con el estado del árbol marcado en el encabezado.
   - `-o` fuera de `.sdd/` → evidencia que se commitea: el runner **exige árbol limpio**; si está sucio no escribe el reporte y sale **4**.
3. Escape hatch explícito: `--allow-dirty` permite escribir evidencia con árbol sucio, y entonces el encabezado lleva la marca `ARBOL SUCIO` y la lista de archivos sucios.

Esta derivación path→estrictez es deliberada: el modo de falla que se ataca es el olvido, y una bandera que hay que recordar reproduce el olvido.

## Architectural Delta

| Capa | Cambio |
|---|---|
| Script | `plugins/sdd-flow/scripts/sdd-run-gates.sh` — bloque de sellado (líneas 119-131), parseo de `--allow-dirty`, exit 4, bump `VERSION` a `0.11.0` |
| Docs | `plugins/sdd-flow/standards/quality-gates.md` §5 — el contrato de evidencia nombra el hash de árbol y el exit 4 |
| Docs | `plugins/sdd-flow/skills/sdd-verify/SKILL.md` — la regla de `-o` explica la estrictez derivada |
| Tests | `SDD/tests/test_run_gates_tree.sh` (NEW) |

**Ownership**: el sellado vive en `sdd-run-gates.sh`. Ningún skill ni agente recalcula hashes por su cuenta.

## Acceptance criteria

- **AC7** — Con árbol limpio, el encabezado del reporte incluye una línea con `Tree:` seguida del hash que devuelve `git rev-parse HEAD^{tree}` en ese repo, y el runner sale 0.
- **AC8** — Con árbol sucio y `-o .sdd/gates-run.md`, el reporte se escribe, su encabezado marca el árbol como sucio, el hash de `Tree:` difiere de `git rev-parse HEAD^{tree}`, y el runner sale 0.
- **AC9** — Con árbol sucio y `-o SDD/verification/x-gates.md`, el runner no crea el archivo y sale 4.
- **AC10** — Con árbol sucio, `-o SDD/verification/x-gates.md` y `--allow-dirty`, el archivo se crea, su encabezado contiene la marca `ARBOL SUCIO`, y el runner sale 0.
- **AC11** — `sdd-run-gates.sh --version` imprime `0.11.0`.
- **AC12** — En un directorio que no es repo git, el runner escribe el reporte con `Tree:` en `-` y sale con el código que corresponde al resultado de los gates, sin abortar por el sellado.

## Evidencia exigida por la DoD §5 (bugfix)

El test de reproducción se escribe **antes** del fix y se registra su corrida roja contra el `sdd-run-gates.sh` actual (que no emite `Tree:`), más la corrida verde después. Las dos corridas van con comando y exit code en el verification report.

## Checklist del arquetipo `bugfix`

| Ítem | Resolución |
|---|---|
| Causa raíz escrita | Sección "Causa raíz" de este R1 |
| Búsqueda de hermanos | **AC13** — grep de `rev-parse HEAD` y `rev-parse --short HEAD` sobre `plugins/sdd-flow/scripts/` y `plugins/sdd-flow/hooks/`; cada aparición se clasifica como evidencia sellada (se corrige) o uso legítimo (se justifica en una línea). El resultado del grep va al verification report |
| Diff mínimo, sin cambios no relacionados | El diff de R1 toca el bloque de sellado, el parseo de argumentos y la constante `VERSION`. Ningún cambio al parser de la tabla ni a `run_gate` |

---

# R2 — Identidad propia del agente en los commits

- **Arquetipo**: `infra`

## Problema

`git log -1 --format='%an'` sobre un archivo es la forma canónica de escribir una guarda "esto lo hizo una persona, no el agente". Hoy es inexpresable: el agente commitea con la identidad git del usuario, así que la guarda es verdadera siempre, la llene quien la llene. Medición en SICOP: `git log --format='%an <%ae>' -14` devolvió una sola identidad humana para commits de agente y de PO.

`plugins/sdd-flow/hooks/guard-git.sh` ya intercepta todo `git commit` como hook `PreToolUse` sobre Bash, ya tolera las formas `git -c user.email=x commit` y `git -C /path commit` (líneas 50-54), y ya resuelve el repo destino (líneas 78-91). Es el punto de enforcement disponible.

## Decisión de diseño (cerrada)

1. **Identidad**: nombre `sdd-agent`, email `sdd-agent@users.noreply.github.com`. Se sobreescriben con `SDD_AGENT_NAME` y `SDD_AGENT_EMAIL`.
2. **Mecanismo de commit**: el implementing-agent commitea con `git -c user.name=... -c user.email=...`. Va en su brief y en `plugins/sdd-flow/agents/implementing-agent.md`.
3. **Enforcement**: `guard-git.sh` gana un chequeo que **deniega** un `git commit` cuyo autor no sea la identidad de agente, activo únicamente cuando `SDD_AGENT_ENFORCE=1` está en el entorno. Con la variable ausente el hook no opina, de modo que un humano commiteando en el mismo repo no queda bloqueado.
4. **Regla de contract**: `quality-gates.md` gana la regla de que un AC que distingue trabajo humano de trabajo de agente sólo es válido si el repo tiene el enforcement activo. Un AC de autoría sin enforcement es tautológico, y un AC tautológico es `BLOCKER` de contract.

El punto 3 es enforcement opt-in por repo. La alternativa de detectar al subagente desde el hook se descarta: el payload del hook no distingue subagente de sesión principal, y una heurística invisible es peor que una variable declarada.

## Architectural Delta

| Capa | Cambio |
|---|---|
| Hook | `plugins/sdd-flow/hooks/guard-git.sh` — bloque nuevo de identidad, **por encima del escape hatch `SDD_ALLOW_BASE_COMMIT`** (ratificación v5, ver abajo) |
| Agente | `plugins/sdd-flow/agents/implementing-agent.md` — la regla de commit con identidad |
| Docs | `plugins/sdd-flow/standards/base-standards.md` — sección Git, la identidad de agente |
| Docs | `plugins/sdd-flow/standards/quality-gates.md` — la regla de AC de autoría |
| Tests | `SDD/tests/test_guard_identity.sh` (NEW) |

## Acceptance criteria

- **AC14** — Con `SDD_AGENT_ENFORCE=1` y un `git commit` sin `-c user.name`/`-c user.email`, `guard-git.sh` sale con el código de denegación que ya usa para rama protegida, y su mensaje nombra la identidad esperada.
- **AC15** — Con `SDD_AGENT_ENFORCE=1` y un `git commit -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com`, el hook permite el commit.
- **AC16** — Sin `SDD_AGENT_ENFORCE` en el entorno, un `git commit` sin identidad de agente pasa: el hook no lo deniega.
- **AC17** — Con `SDD_AGENT_ENFORCE=1`, `SDD_AGENT_NAME=otro-agente` y un commit que declara `user.name=otro-agente`, el hook permite el commit.
- **AC18** — Tras un commit hecho con la identidad de agente, `git log -1 --format='%an'` devuelve `sdd-agent`. Este AC es la prueba de que la guarda de autoría dejó de ser tautológica.
- **AC36** — Con `SDD_AGENT_ENFORCE=1` **y** `SDD_ALLOW_BASE_COMMIT=1` a la vez, un commit sin identidad de agente **sigue siendo denegado**. El hatch desactiva el chequeo de rama protegida, nunca el de identidad.
- **AC37** — Con `SDD_AGENT_ENFORCE=1` y el repo en `HEAD` detached, un commit sin identidad de agente **sigue siendo denegado**.
- **AC38** — Los tres textos que describen el alcance del hatch dicen la verdad: `plugins/sdd-flow/standards/quality-gates.md`, el encabezado de `plugins/sdd-flow/hooks/guard-git.sh` y `SDD/docs/doc_architecture.md`. Ninguno afirma que `SDD_ALLOW_BASE_COMMIT` desactive únicamente el chequeo de rama sin decir que el de identidad sigue activo. `doc_architecture.md` además lista las tres variables nuevas con su default. Verificable con grep.

**Ratificación v5** (tras el `ESCALATE` de la ronda 1 de R2). El Delta de v4 ordenaba poner el bloque de identidad *después* del chequeo de rama protegida, y el implementador cumplió al pie de la letra. Medido por el reviewer contra el payload real del hook, esa ubicación deja el bloque aguas abajo de cuatro salidas tempranas que pertenecen al chequeo de rama —el `allow` del hatch, el `command -v git`, el `rev-parse --git-dir` y el `HEAD` detached—, ninguna de las cuales tiene que ver con identidad: el bloque nuevo sólo parsea el comando.

El resultado contradice la decisión 3, que dice que el chequeo está activo *únicamente* cuando `SDD_AGENT_ENFORCE=1` está en el entorno, y agrega tres condiciones implícitas de apagado. Y es **circular**: R2 existe para matar una guarda tautológica, y esta ubicación introduce una forma nueva de la misma tautología — un repo con las dos variables puestas cree tener enforcement y no lo tiene, que es exactamente lo que `quality-gates.md` le pide al reviewer dar por válido. `SDD_ALLOW_BASE_COMMIT=1` es justo lo que exporta un repo donde commitear a la default es legítimo, y `HEAD` detached pasa en cualquier rebase o bisect: los dos casos son alcanzables, no teóricos.

**AC36 y AC37 son ACs de detección** y se prueban por mutación, con el triple registrado por cada uno.

**AC38 es la parte que no es código**: tres documentos normativos afirman hoy que el hatch desactiva *sólo* el chequeo de rama. Una afirmación falsa en un documento de gobierno es del mismo tipo que el defecto que este contract entero ataca, y por eso entra como AC y no como nota.

## Checklist del arquetipo `infra`

| Ítem | Resolución |
|---|---|
| Reversible | El cambio es aditivo y se desactiva quitando `SDD_AGENT_ENFORCE` del entorno, sin revert de código. Registrado como AC16 |
| Sin secretos nuevos en texto plano | `N/A — no se introducen credenciales; el email es una dirección noreply pública` |
| Efecto sobre los devs declarado | AC16 cubre que un dev sin la variable no cambia su flujo. La sección Git de `base-standards.md` documenta el knob |
| Probado en entorno no productivo con evidencia | AC14-AC17 corren contra repos git temporales en `SDD/tests/.tmp/`, nunca contra el repo real |
| NFR `rollout` | El enforcement nace apagado; se activa por repo con la variable de entorno |
| NFR `observability` | El mensaje de denegación nombra la identidad esperada y la recibida |

---

# R3 — Prueba por mutación de todo AC que afirme detectar algo

- **Arquetipo**: `infra` (cambia el tooling normativo del pipeline: standards, skill del planner y briefs de los agentes)

## Problema

Cuatro controles medidos en SICOP tenían forma de control y ningún poder: un test de partición que nada ejecutaba y que salía 0 con y sin violación; una comparación donde cuatro de veinticinco casos comparaban un build contra una copia de sí mismo; un criterio que exigía `LEFT JOIN` y pasaba igual con `INNER` porque el lookup contiene las claves sin familia; y la guarda de autoría de R2. Ninguno era un error de lógica: los cuatro se veían bien y no podían fallar. Los cuatro se detectaron rompiendo el sistema a propósito y mirando si el control se ponía rojo.

La regla ya existe en el plugin con alcance angosto: `quality-gates.md:19` (DoD ítem 5) exige, **para el arquetipo `bugfix`**, evidencia del rojo antes y del verde después. R3 generaliza esa regla a todo AC de detección, en cualquier arquetipo.

## Decisión de diseño (cerrada)

1. **Alcance del AC de detección**: un AC es de detección cuando su condición de aprobación es *"algo falla cuando X está mal"* — guardas, validaciones, constraints, tests que afirman prevenir. Un AC que afirma un valor devuelto no entra: ya es falsable por construcción.
2. **Evidencia**: el triple **verde → rojo → verde**, con comando y exit code por corrida. El rojo solo no alcanza, porque un control permanentemente roto produce la misma salida que uno correcto.
3. **La mutación se declara en el contract**: cada AC de detección lleva escrito qué se rompe para probarlo. El planner la escribe; el implementador la ejecuta.
4. **Toda cifra citada en un reporte va con la salida del comando que la produce**, no con su resumen. Una cifra copiada de otro documento es una cita, no una medición.
5. **Las correcciones posteriores a `APPROVED` vuelven a entrar al loop**: un diff que corrige un artefacto ya aprobado se revisa como el cambio original.

## Architectural Delta

| Capa | Cambio |
|---|---|
| Docs | `plugins/sdd-flow/standards/quality-gates.md` — DoD ítem 5 generalizado, sección nueva de prueba por mutación, contrato de evidencia §5 con el triple, regla de correcciones post-`APPROVED` |
| Skill | `plugins/sdd-flow/skills/sdd-plan/SKILL.md` — sección de Acceptance criteria: el AC de detección declara su mutación |
| Agente | `plugins/sdd-flow/agents/implementing-agent.md` — produce el triple y adjunta la salida de cada cifra que reporta |
| Agente | `plugins/sdd-flow/agents/reviewer-agent.md` — Fase 1: AC de detección sin triple es `BLOCKER`; cifra sin salida adjunta es `MAJOR` |
| Skill | `plugins/sdd-flow/skills/write-pr-report/SKILL.md` — las cifras del PR report llevan su salida |
| Template | `plugins/sdd-flow/templates/verification-report.md` — sección para el triple (**agregado en v6**) |
| Command | `plugins/sdd-flow/commands/sdd-fixes.md` — quién declara la mutación en la vía corta (**agregado en v6**) |

**Reuse statement**: la regla se escribe una sola vez en `quality-gates.md`; los otros cuatro archivos la referencian por sección, sin recopiar el texto normativo.

## Acceptance criteria

- **AC19** — `quality-gates.md` contiene una sección de prueba por mutación que define el triple verde→rojo→verde y el criterio de qué AC lo requiere, y el DoD ítem 5 referencia esa sección en lugar de limitar la regla al arquetipo `bugfix`.
- **AC20** — `plugins/sdd-flow/skills/sdd-plan/SKILL.md` exige que cada AC de detección declare su mutación en el contract.
- **AC21** — `plugins/sdd-flow/agents/reviewer-agent.md` clasifica como `BLOCKER` un AC de detección sin las tres corridas, y como `MAJOR` una cifra reportada sin la salida que la produce.
- **AC22** — `plugins/sdd-flow/agents/implementing-agent.md` y `plugins/sdd-flow/skills/write-pr-report/SKILL.md` exigen adjuntar la salida del comando de cada cifra reportada.
- **AC23** — Los cinco archivos del Delta referencian la sección de `quality-gates.md` por su título, y ninguno recopia el texto normativo del triple. Verificable con grep del título en los cinco archivos.
- **AC24** — `quality-gates.md` declara que un diff que corrige un artefacto ya aprobado vuelve al loop de review.
- **AC39** — `plugins/sdd-flow/templates/verification-report.md` tiene una sección donde registrar el triple, con una fila por corrida (comando, exit code, resultado) y un campo para la mutación que declaró el contract.
- **AC40** — `plugins/sdd-flow/commands/sdd-fixes.md` declara quién escribe la mutación en la vía corta: cuando un ítem de fix es un control de detección, la mutación la declara **el propio ítem de `fixes.md` en el triage**, y el triple va en la evidencia de ese ítem.
- **AC41** — El criterio de §10.1 clasifica de forma cerrada el AC16 de R2 (*"un commit sin identidad de agente pasa: el hook **no** lo deniega"*): la forma "ausencia" queda acotada a la ausencia **sobre un conjunto que hay que recorrer**, y no cubre el desenlace negativo de un comportamiento que el propio test ejercita.

**Ratificación v6** (tras el review de R3, que fue `APPROVED`). Tres correcciones, dos de ellas gaps de mi Architectural Delta:

- **AC39 y AC40 son gaps del plan.** El Delta de R3 listó cinco consumidores de la regla y hay siete. R3 convierte "AC de detección sin las tres corridas" en `BLOCKER` que rechaza, mientras el template que el implementing agent tiene instrucción de usar no tiene dónde ponerlas — la asimetría fabrica rechazos evitables. Y `/sdd-fixes` es por diseño un carril sin contract, así que §10.2 se queda sin declarante y lo que queda escrito es que la vía corta está exceptuada de §10: el molde exacto de escape hatch que este contract viene encontrando en `D7`, `D8` y en el hatch de R2. El intake de `fixes.md` ya existe y puede ser el declarante, sin inventar un contract.
- **AC41 cierra un hueco de closure medido.** El reviewer corrió el criterio de §10.1 contra nueve ACs reales del ciclo: ocho clasifican solos y coinciden con lo que el pipeline ya venía haciendo. El noveno, AC16 de R2, entra en la forma "ausencia" por su cláusula de entrada pero no por la justificación de esa misma viñeta —el día que el hook empieza a denegar, AC16 **falla**, lo cual quedó demostrado en R2 con la mutación "deniega siempre"— y la no-detección lo reclama por ser falsable por construcción. Dos ingenieros lo clasificarían distinto, que es exactamente el test que imponen las closure rules. El desempate lo atrapa y el error va en la dirección segura, pero rebota al planner un AC sano.

## Checklist del arquetipo `infra`

| Ítem | Resolución |
|---|---|
| Reversible | Cambios sólo en markdown; `git revert` del commit alcanza |
| Sin secretos nuevos | `N/A — sólo documentación normativa` |
| Efecto sobre los devs declarado | El costo por AC de detección sube: tres corridas en vez de una. El alcance del punto 1 acota a quién le aplica |
| Probado en entorno no productivo | AC19-AC24 se verifican con grep sobre los archivos, en `SDD/tests/test_mutation_rule.sh` (NEW) |
| NFR `rollout` | La regla aplica a contracts nuevos. Los contracts ya aprobados no se re-abren |
| NFR `observability` | El reviewer reporta el hallazgo con `archivo:línea`, como el resto de su Fase 1 |

---

# R4 — Arquetipo `analysis`: el flujo aplica al análisis, no sólo al código

- **Arquetipo**: `infra`

## Problema

Dos trabajos de SICOP no eran ciclos de código —un backtest sobre 19 ofertas y un barrido de consistencia documental— y los dos estuvieron a punto de mergearse sin review porque "no eran un ciclo". Los dos tenían conclusiones falsas: el backtest concluía que el precio no es la palanca apoyado en una brecha de 0,215 que se invierte a −0,048 al excluir seis líneas con defecto de datos, cuatro de ellas de un mismo concurso; el test de permutación a nivel de concurso, que nunca se había corrido, da p = 0,533.

La causa es mecánica, no cultural. `plugins/sdd-flow/standards/archetypes.md` tiene nueve arquetipos y ninguno cubre trabajo cuyo producto es un número usado para decidir. `skills/enrich-user-story/SKILL.md:92` fuerza exactamente uno y devuelve al refinement cualquier requerimiento sin arquetipo. Hoy un backtest no puede entrar al pipeline aunque alguien quiera meterlo.

## Decisión de diseño (cerrada)

Décimo arquetipo `analysis`, con la misma estructura que los otros nueve: NFR obligatorias, tests exigidos y checklist→ACs. Cubre trabajo cuyo entregable es una conclusión o una cifra que alimenta una decisión, con producto en documentos o notebooks en vez de código de aplicación.

El caso del barrido documental queda cubierto por la regla de correcciones post-`APPROVED` de R3, no por un arquetipo aparte: corregir un documento aprobado es una corrección, no un tipo de trabajo nuevo.

## Architectural Delta

| Capa | Cambio |
|---|---|
| Docs | `plugins/sdd-flow/standards/archetypes.md` — sección `analysis` entre `infra` y "Cómo lo usa el pipeline" |
| Skill | `plugins/sdd-flow/skills/enrich-user-story/SKILL.md:92` — `analysis` entra a la lista de arquetipos |
| Skill | `plugins/sdd-flow/skills/sdd-plan/SKILL.md` — el binding AC↔test admite la forma de evidencia del arquetipo `analysis` |
| Tests | `SDD/tests/test_analysis_archetype.sh` (NEW) |

## Contenido normativo del arquetipo `analysis`

- **NFR obligatorias**: `observability` (la corrida que produce la cifra es reproducible por otro) y `data-privacy` cuando el dataset tiene PII.
- **Tests exigidos**: el test estadístico que **falsaría** la conclusión, corrido y reportado con su valor; más la re-derivación de cada cifra citada desde su fuente.
- **Checklist → ACs**:
  - Hipótesis nula declarada antes de mirar el resultado.
  - El test que falsaría la conclusión, nombrado y corrido; su resultado se reporta gane o pierda.
  - Toda cifra re-derivada desde la fuente, con la salida de la consulta adjunta (regla de R3).
  - Sensibilidad declarada: qué pasa con la conclusión al excluir las filas defectuosas, y si las exclusiones se concentran en pocas unidades.
  - Unidad de análisis declarada, y el test a esa unidad cuando las observaciones se agrupan.
  - Tamaño de muestra y potencia declarados, con el número.
  - La conclusión se escribe con su incertidumbre, no como afirmación categórica.

## Acceptance criteria

- **AC25** — `plugins/sdd-flow/standards/archetypes.md` contiene la sección `analysis` con las tres partes que tienen los otros nueve arquetipos: NFR obligatorias, tests exigidos y checklist→ACs.
- **AC26** — La sección `analysis` incluye los siete ítems de checklist del contenido normativo de arriba.
- **AC27** — `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` incluye `analysis` en la lista de arquetipos de su dimensión 7.
- **AC28** — El total de arquetipos declarado en `archetypes.md` y en `enrich-user-story` coincide: diez en ambos. Verificable con grep.

## Checklist del arquetipo `infra`

| Ítem | Resolución |
|---|---|
| Reversible | Cambios sólo en markdown; `git revert` del commit alcanza |
| Sin secretos nuevos | `N/A — sólo documentación normativa` |
| Efecto sobre los devs declarado | Un requerimiento de análisis deja de ser rechazado por el refinement. `enrich-user-story` gana una rama de preguntas |
| Probado en entorno no productivo | AC25-AC28 con grep, en `SDD/tests/test_analysis_archetype.sh` |
| NFR `rollout` | Aditivo: los nueve arquetipos existentes no cambian |
| NFR `observability` | `N/A — cambio documental sin runtime` |

---

# R5 — Identidad de contenido de los docs que gobiernan

- **Arquetipo**: `infra`
- **Origen**: propuesta 3 del consolidado externo `MD-consolidado.md` (13-ago-2026), la que más evidencia trae: cuatro documentos, cuatro repos, dos llegadas independientes más dos confirmaciones.

## Problema

El ciclo versiona el contract con rigor —se declara, se propaga y **se valida**, porque un `done` con `contract_version` viejo se rechaza— pero los tres documentos de `SDD/docs/` contra los que se escribe ese contract no declaran identidad ninguna. El runner estampa `**Doc**: <ruta>` (`plugins/sdd-flow/scripts/sdd-run-gates.sh:220`), y **una ruta no identifica un contenido**.

La consecuencia no es perder historial: es que la afirmación "este ciclo cumplió" se queda sin sujeto. Como `.sdd/` está gitignoreado por diseño, el verification report es el único registro durable del ciclo, y es justo donde falta la identidad del doc que definió los gates.

El sustituto razonable —"total está en git, y el contract tiene fecha"— quedó medido y no alcanza: en un repo de 8 días, `doc_quality_gates.md` acumuló 31 cambios, 8 de ellos en un solo día. Los contracts llevan fecha, no hora, así que "la guía como estaba el 12 de agosto" identifica ocho textos. Y no es patológico: desde la v0.7.0 el docs delta es parte del `done`, o sea **el ciclo modifica sus propios documentos de gobierno en cada vuelta, por diseño**. Cuanto mejor funciona el docs delta, menos identifica un texto la fecha del contract.

Este ciclo aporta una razón más, medida por su cuenta y registrada en `SDD/retro.md` como `RT8`: fijar el **commit** del doc tampoco sirve, porque un archivo modificado sin commitear hace que el sha del último commit mienta. Es la misma clase que `HEAD` en R1, que `git ls-files` en `D8` y que `git stash create` en `D7`. El hash de contenido describe el texto que se leyó, commiteado o no.

## Decisión de diseño (cerrada)

1. **Función de hash**: `sha256`, estampado como `sha256:` seguido de los **primeros 16 caracteres hexadecimales**. Se calcula con `shasum -a 256`; si ese binario no está, con `sha256sum`. Si no está ninguno de los dos, se estampa `sha256:-` y la corrida sigue.
2. **El sellado nunca aborta**: misma política que el sellado de árbol de R1. Un runner que no puede hashear reporta que no pudo, no falla.
3. **Manifiesto de generación**: `sdd-init` escribe `SDD/docs/doc-manifest.md`, una fila por doc generado con su hash al momento de generarse. El hash **no** va dentro del propio documento, porque escribirlo ahí cambiaría el hash que declara.
4. **Protección al regenerar**: `sdd-init` corrido de nuevo compara cada doc contra el manifiesto. Hash distinto significa que alguien trabajó ese documento a mano, y entonces no se sobrescribe sin mostrar el diff y pedir confirmación. Esto **no es una regla nueva**: `plugins/sdd-flow/skills/sdd-init/SKILL.md:70` ya la exige para los scripts. Lo que faltaba era la identidad que la regla necesita para poder correr.
5. **La review compara**: el reviewer contrasta el hash del reporte contra el doc en el árbol. Hashes iguales y evidencia que no reproduce significa evidencia podrida. Hashes distintos significa que los gates se movieron durante el ciclo, y eso lleva un mensaje propio. Hoy los dos casos producen salida idéntica y el reviewer está obligado a leer el segundo como el primero.
6. **Versión legible además del hash**: `N/A — el consolidado externo retiró su propio pedido de un campo de versión manual, porque un campo que se bumpea a mano se olvida y un campo desactualizado afirma algo falso con cara de dato. El hash no depende de que nadie se acuerde.`

## Architectural Delta

| Capa | Cambio |
|---|---|
| Script | `plugins/sdd-flow/scripts/sdd-run-gates.sh` — helper de hash portable, estampado del doc en el encabezado (línea 220), y **bump de `VERSION` a `0.12.0`**. El bump arrastra el literal que AC11 de R1 assertea en `SDD/tests/test_run_gates_tree.sh`: se actualiza el valor esperado, nunca el assert |
| Template | `plugins/sdd-flow/templates/verification-report.md` — el doc de gates se registra con su hash |
| Skill | `plugins/sdd-flow/skills/sdd-init/SKILL.md` — escribe el manifiesto y protege los docs al regenerar |
| Template | `plugins/sdd-flow/templates/doc-manifest.md` (NEW) |
| Agente | `plugins/sdd-flow/agents/reviewer-agent.md` — Fase 1: comparar hashes y distinguir los dos casos |
| Tests | `SDD/tests/test_doc_hash.sh` (NEW) |

**Reuse statement**: el helper de hash se define una sola vez en `sdd-run-gates.sh`. Ningún otro script recalcula hashes por su cuenta.

## Acceptance criteria

- **AC29** — El encabezado del reporte estampa el doc con su ruta **y** su hash, y ese hash coincide con los primeros 16 caracteres hexadecimales de `shasum -a 256 <doc>` sobre el mismo archivo.
- **AC30** — Cambiar un byte del doc de gates entre dos corridas produce dos hashes distintos en los dos reportes. **Es un AC de detección**: se prueba por mutación, con el triple registrado.
- **AC31** — Sin `shasum` ni `sha256sum` en el `PATH`, el runner estampa `sha256:-` y sale con el código que corresponde al resultado de los gates, sin abortar.
- **AC32** — `plugins/sdd-flow/templates/verification-report.md` registra el doc de gates con hash, no sólo con ruta. Verificable con grep.
- **AC33** — `plugins/sdd-flow/skills/sdd-init/SKILL.md` exige escribir `SDD/docs/doc-manifest.md` con el hash de cada doc generado, y exige comparar antes de sobrescribir, mostrando el diff cuando el hash difiere. Verificable con grep.
- **AC34** — `plugins/sdd-flow/agents/reviewer-agent.md` distingue los dos casos con mensajes distintos: hashes iguales con evidencia que no reproduce es `BLOCKER` de evidencia podrida; hashes distintos es un hallazgo propio de que los gates cambiaron durante el ciclo. Verificable con grep.
- **AC35** — `plugins/sdd-flow/templates/doc-manifest.md` existe y tiene una fila por cada uno de los tres docs de `SDD/docs/`.

## Checklist del arquetipo `infra`

| Ítem | Resolución |
|---|---|
| Reversible | `git revert`. El estampado es aditivo: un reporte sin hash sigue siendo legible |
| Sin secretos nuevos | `N/A — sólo se hashean documentos versionados del propio repo` |
| Efecto sobre los devs declarado | `sdd-init` deja de sobrescribir en silencio un doc trabajado a mano. Es un cambio de comportamiento visible y es el punto de la pieza 4 |
| Probado en entorno no productivo | AC29-AC31 en repos temporales de `SDD/tests/.tmp/`; AC32-AC35 con grep |
| NFR `rollout` | Aditivo. Los reportes viejos sin hash no se invalidan |
| NFR `observability` | El hallazgo del reviewer nombra los dos hashes y el doc |

## Error / fallback behavior (global)

- `sdd-run-gates.sh` sin git disponible: el sellado degrada a `Tree: -` y la corrida sigue (AC12). El runner nunca aborta por no poder sellar.
- `guard-git.sh` mantiene su política fail-open: cualquier fallo del propio hook permite la operación. Un hook roto no puede frenar el trabajo del equipo.
- `SDD/tests/run.sh` con cero archivos de test: sale 1 y lo dice. Un harness que reporta éxito sin haber corrido nada es el modo de falla que este contract entero ataca.

## Validation strategy

Escalera de `SDD/docs/doc_quality_gates.md` (la crea R0), corrida por `sdd-run-gates.sh` con `-o SDD/verification/feat-GEN-94-sicop-hardening-gates.md`. Por la decisión de R1, ese path exige árbol limpio, de modo que la evidencia final se genera después del último commit de código.

## Risks

1. **R1 se prueba a sí mismo**: los tests de R1 corren contra el script que R1 modifica. Mitigación: el test de reproducción se escribe antes del fix y su corrida roja queda registrada (DoD §5).
2. **bash 3.2**: `git stash create` existe desde git 2.x y no depende de la versión de bash, pero los helpers de `lib.sh` sí. El perfil del stack de R0 lo fija.
3. **R3 sube el costo por AC**: el alcance del punto 1 de R3 lo acota a los ACs de detección. Si el alcance se lee mal, cada AC pasa a costar tres corridas.
4. **R2 nace apagado**: el enforcement no protege nada hasta que un repo exporte `SDD_AGENT_ENFORCE=1`. Es deliberado, y queda registrado en el ledger de deuda.

## Deuda registrada

El ledger vive en `SDD/debt.md` (formato `plugins/sdd-flow/templates/debt-ledger.md`). Filas abiertas de este contract: `D1` CI ausente · `D2` sin firma GPG · `D3` enforcement de identidad apagado por default · `D4` los 3 `SC2016` preexistentes que fuerzan el piso de shellcheck · `D5` la suite completa duplica el gate 4.
