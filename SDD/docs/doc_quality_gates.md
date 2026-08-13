# Quality Gates — AI-Forge

Los **comandos reales** de este repo para la escalera de `plugins/sdd-flow/standards/quality-gates.md` §4. Todo agente del ciclo SDD corre lo que dice acá, sin inventar comandos ni adivinar herramientas.

Diferencia con los otros docs de `SDD/docs/`:
- `doc_architecture.md` → dónde va el código.
- **este archivo** → la escalera obligatoria que corre siempre antes de declarar `done` (sin elección).

Generado en R0 (`SDD/contracts/2026-08-13-sicop-hardening.md`, actualizado a v3 en la ronda 3 de review) — primera escalera viva de este repo. Cada comando de acá fue corrido en esta máquina antes de escribirse (macOS, bash 3.2.57, shellcheck 0.11.0, git 2.50.1); ninguno es supuesto.

---

## Identidad del repo

- **Stack / lenguaje**: Bash 3.2 (piso macOS) + Markdown (specs, contracts, commands, skills, agents). Sin runtime de aplicación — este repo ES el marketplace de plugins de Claude Code, no un servicio que se despliega.
- **Package manager / build tool**: N/A — no hay manifiesto de dependencias (`package.json`, `pyproject.toml`, etc.). Los plugins se distribuyen como árbol de archivos vía `.claude-plugin/marketplace.json`.
- **Perfil de calidad aplicable** (`quality-gates.md` §9): ninguno de los perfiles con nombre (TS/Python/C#/SQL) aplica tal cual. El piso es el genérico de §4 + las prohibiciones de §6 con su equivalente bash — ver "Markers prohibidos" abajo.
- **Runner de tests**: `SDD/tests/run.sh` (bash puro, cero dependencias fuera de coreutils; descubre y corre `SDD/tests/test_*.sh`).

---

## Escalera de gates

| # | Gate | Comando | Obligatorio | Notas |
|---|---|---|---|---|
| 1 | format / style | `N/A — shfmt no está instalado` | N/A | Verificado: `command -v shfmt` no encuentra el binario en esta máquina. Instalarlo sólo para este gate es una dependencia nueva fuera del scope de R0 (`security.md` §4) — queda para cuando el repo lo necesite de verdad. |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` | sí | `--severity=warning` (no el default `style`) es una decisión de piso, **ratificada en el contract v2 (AC3)**, no un ablandamiento posterior: este repo no tenía shellcheck configurado antes de R0. A severidad `style` (default) siguen existiendo 3 hallazgos `SC2016` (info) en `plugins/sdd-flow/scripts/` — backticks literales dentro de strings de una comilla en plantillas markdown, uso correcto, no bug, fuera de scope de R0 (registrados en `SDD/debt.md` como `D4`). Los `cleanup()` propios de `SDD/tests/` invocados sólo vía `trap ... EXIT` que también disparaban `SC2329` (info) **ya no dependen del piso**: cada uno lleva `# shellcheck disable=SC2329  # invocada por trap EXIT` inline (AC3bis), así que a severidad default sólo quedan los 3 `SC2016` preexistentes de `plugins/` — verificable con el **mismo glob del gate**, sin `--severity`: no muestra ningún `SC2329`. **No verifiques con `git ls-files`**: no lista archivos sin `git add`, y ya produjo un verde falso medido (la ronda 1 de R1 declaró "exactamente 3 `SC2016`" cuando eran 4, porque el cuarto estaba en un archivo todavía sin trackear). Los hallazgos que esa forma pierde llegan a severidad `warning`, que es el piso real del gate. Si hace falta una lista en vez del glob, va `git ls-files --cached --others --exclude-standard -- '*.sh'`. Deuda `D8`. |
| 3 | type-check | `N/A — bash no es tipado` | N/A | |
| 4 | unit tests | `bash SDD/tests/run.sh` | sí | Corre `SDD/tests/test_*.sh` cada uno en su propio proceso. Sale 1 si algún archivo falla o si no encuentra ninguno. |
| 5 | integration | `N/A — los tests del harness ya ejercitan los scripts end-to-end` | N/A | `SDD/tests/test_run_gates.sh` corre el `sdd-run-gates.sh` real (no un mock) contra un repo git temporal — ya es integración, no unit puro. |
| 6 | build | `N/A — el plugin no compila` | N/A | Markdown + bash, nada que bundlear/transpilar. |
| 7 | e2e | `N/A` | N/A | Sin UI ni flujo de usuario con frontend. |
| 8 | cobertura del diff | `N/A — sin reporte de coverage; se verifica con el binding AC↔test` | sí (política) | No hay herramienta de coverage para bash. La política de `quality-gates.md` §4 aplica igual: cada `.sh` nuevo queda ejercitado por el binding AC↔test del brief correspondiente. |
| 9 | security | `bash SDD/tests/secret-scan.sh` | sí | Grep mínimo de `standards/security.md` §3 sobre `git ls-files`, **AC6bis (contract v3)**: `AKIA...`, header PEM `-----BEGIN...PRIVATE KEY-----`, y `password\|secret\|token\|api_key` con o SIN comillas, `SCREAMING_SNAKE` incluido, separador `:` o `=` (case-insensitive). La ronda 1 exigía comillas y sólo la palabra exacta en minúscula — dejaba pasar 4 de 5 formas reales; corregido y probado por mutación en `SDD/tests/test_secret_scan.sh` (6 formas desde ronda 3). La salida nombra archivo y línea **sin imprimir el valor detectado** (threat model contract v2). **Sin exclusión por path** (ratificación v3: la única admitida es la del propio script sobre sí mismo — ronda 2 excluyó `SDD/contracts/` completo para un falso positivo del propio contract, lo que dejaba el gate ciego a ese directorio entero; el planner corrigió el contract en vez de ensanchar la exclusión, y la forma 6 de `test_secret_scan.sh` prueba por mutación que la exclusión no vuelve). Punto ciego conocido del charset: deuda `D6` (ver comentario en el script, no se corrige — trade-off aceptado). Audit de dependencias: `N/A — no hay manifiesto de dependencias en este repo` (bash + markdown, sin package manager que auditar). |
| 10 | smoke manual | `N/A` | N/A | Sin ACs `manual-only` declarados en R0. |

**Suite completa** (obligatoria una vez antes de integrar): `bash SDD/tests/run.sh` — mismo comando que el gate 4: este repo no filtra tests por área, la suite entera corre siempre completa (3 archivos de test tras la ronda 2 de R0: `test_harness.sh`, `test_run_gates.sh`, `test_secret_scan.sh`; el duplicado con el gate 4 está registrado como deuda `D5`, no se corrige en R0). Medido: ~2s.

**Tiempo esperado de la suite completa**: menor a 5 segundos (medido: ~2s con 3 archivos de test, `test_secret_scan.sh` corre 5 formas × repo git temporal). Un timeout acá es señal real, no ruido de entorno lento.

---

## Prerequisitos de entorno

Qué tiene que estar levantado para que los gates no den falso rojo:

- `shellcheck` instalado (verificado en esta máquina: `/opt/homebrew/bin/shellcheck`, v0.11.0). Sin él, el gate 2 se marca `[SKIPPED] shellcheck no disponible`, nunca verde.
- `git` disponible (lo usan `sdd-run-gates.sh`, `SDD/tests/test_run_gates.sh` y `SDD/tests/secret-scan.sh`).
- Sin DB, sin `.env`, sin servicios externos — el repo no tiene runtime de aplicación.
- `timeout`/`gtimeout` NO está instalado en la máquina de referencia: `sdd-run-gates.sh` degrada a correr sin límite de tiempo por gate (ver su propio `run_cmd`). No es bloqueante para R0 (los gates de este repo son rápidos), pero un gate colgado no cortaría por timeout en esta máquina.

Si un prerequisito no está disponible, el gate se marca `[SKIPPED] <prereq faltante>` en la evidencia — **no** se declara verde.

---

## Política de cobertura del diff

- Herramienta / comando: `N/A — el repo no emite coverage` (no hay equivalente de istanbul/coverage.py para un harness de bash).
- Regla: todo archivo `.sh` nuevo o modificado queda ejercitado por al menos un test que recorra las líneas cambiadas — verificado con el binding AC↔test de cada brief (`quality-gates.md` §3), no con un reporte de coverage.
- Threshold actual configurado en el repo: N/A (no aplica sin herramienta).
- **Prohibido bajarlo, agregar excludes o ignorar archivos para pasar el gate** — igual que en cualquier otro stack.

---

## Convenciones de test de este repo

- Ubicación de los tests: `SDD/tests/test_*.sh`, uno por unidad de comportamiento. Los helpers de assert viven únicamente en `SDD/tests/lib.sh` (Reuse statement del contract R0) — ningún `test_*.sh` define su propio `assert_*`.
- Naming de casos: el mensaje literal pasado como último argumento a `assert_eq`/`assert_contains`/`assert_exit` (ej. `"run.sh sale 0 cuando todos los test_*.sh pasan"`). El binding AC↔test de cada brief usa ese string, literal y grepeable en el archivo — no hay framework con `it()`/`describe()` en bash puro.
- Fixtures: se generan on-the-fly bajo `SDD/tests/.tmp/<nombre>-$$` (PID para evitar colisiones) con `trap ... EXIT` para limpieza garantizada, incluso si el test falla. Nunca versionadas (`SDD/tests/.tmp/` está en `.gitignore` desde R0).
- Cómo se mockea I/O externo: N/A — no hay I/O externo que mockear. Cuando un test necesita un repo git real (`test_run_gates.sh`, `test_secret_scan.sh`), usa uno de usar-y-tirar en `.tmp/`, nunca este repo.
- Tests que ya fallan en `prod`: N/A — el harness nace en R0, no hay corridas previas.
- **Fixtures que parecen un secreto** (`test_secret_scan.sh`, y cualquier `.md` que documente un AC de detección — ej. `SDD/contracts/`): un valor tipo clave-separador-valor que quede contiguo y literal en el código fuente hace que `secret-scan.sh` se detecte a sí mismo al escanear ESE archivo — desde el contract v3, la ÚNICA exclusión admitida en `secret-scan.sh` es la del propio script sobre sí mismo; **ninguna exclusión por path** (ni `SDD/contracts/` ni ningún otro directorio). Convención, la misma para código y para prosa: armar el string en piezas bash separadas (`printf '%s%s%s' "$clave" "$separador" "$valor"`, con cada pieza como argumento independiente) para que la unión sólo exista en memoria en tiempo de ejecución, nunca contigua en el archivo; y en prosa/markdown, escribir la clave y el valor en spans separados en vez de concatenados. Ronda 2 resolvió este mismo problema con una exclusión por path — el reviewer midió que dejaba el gate ciego a un directorio entero, y ronda 3 la borró: la exclusión no es una opción, partir el literal sí.

---

## Markers prohibidos en este stack

Además de los de `quality-gates.md` §6:

- `# shellcheck disable=` genérico sin comentario en la misma línea que referencie la decisión que lo justifica. Excepciones documentadas hoy: `guard-git.sh` (`plugins/`, `# shellcheck disable=SC2254`, fuera del scope de R0) y, desde AC3bis, los `cleanup()` de `SDD/tests/test_harness.sh`, `test_run_gates.sh` y `test_secret_scan.sh` (`# shellcheck disable=SC2329  # invocada por trap EXIT`) — las tres únicas funciones de este repo invocadas exclusivamente por `trap`.
- Bajar `--severity` de shellcheck por debajo de `warning`, o agregarle `-e <código>` para silenciar un hallazgo real, sin ratificación del planner.
- `sleep`-loops para "esperar" en vez de asserts determinísticos sobre exit code/output.

---

## Hooks / CI

- Hook de Claude Code (no es un git hook tradicional): `plugins/sdd-flow/hooks/guard-git.sh`, `PreToolUse` sobre `Bash` — bloquea `--no-verify`, `push --force` sin lease, y commit directo a rama protegida. Nunca se saltea con `--no-verify`.
- Pipeline de CI: `N/A — sin .github/workflows`. Registrado como deuda en el contract (`SDD/contracts/2026-08-13-sicop-hardening.md`, sección "Deuda registrada"): crear CI cambia la política de merge del equipo, decisión de Gabriel, fuera del scope de R0.
- Checks requeridos para mergear: ninguno automatizado todavía — el gate humano de Feature Ready + `sdd-run-gates.sh` en verde (esta escalera) son la barra hoy.
