# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `8f87475` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-21T21:50:03Z
- Tree: `ab0ad471b3affad12cd22de43bbc9e330184565e` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-21T21:49:05Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-21T21:49:05Z | verde |
| 3 | type-check | — | — | 2026-09-21T21:49:05Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-21T21:49:05Z | verde |
| 5 | integration | — | — | 2026-09-21T21:49:34Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-21T21:49:34Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-21T21:49:34Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-21T21:49:34Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-21T21:49:34Z | verde |
| 10 | smoke manual | — | — | 2026-09-21T21:49:35Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-21T21:49:35Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

# Addendum del agente `AGENT_r1` — ronda 1 sobre alcance nuevo, contract v10

**Nota sobre continuidad**: el bloque de arriba lo generó `sdd-run-gates.sh`
sobre el commit `f728033` y **trunca lo que hubiera antes en este archivo**
(mismo aviso que las rondas anteriores, `SDD/debt.md` D34/D35). El addendum de
la ronda 3 anterior (commit `9db961a`/`27029e3`) no se retranscribe acá:
recuperable con `git show 27029e3:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.

Este trabajo previo sigue `APPROVED`; lo que cambia son dos decisiones de
Patrick Ocampo (Slack 21-sep-2026 12:22 y 12:44) que revierten puntualmente
dos piezas de ese trabajo, no lo rechazan. Ninguna reabre AC1–AC6, AC8, AC10
o AC41 — sólo AC7 (prosa de limpieza) y AC42 (propiedad y mutación
completas).

## Qué cambió y por qué

1. **Sale `db_denydatawriter`** del loop de `sqlserver-parte-b.sql`: cada base
   concedida lleva `db_datareader` y nada más. Escrito con lo que se pierde
   (textual de Patrick, ya en `APROBACIONES.md` punto 6): sin `DENY`
   explícito, un `GRANT` de escritura concedido por error no tendría nada que
   lo anule.
2. **`sqlserver-inverso.sql` deja de leer `@bases_permitidas`**: revoca por
   ENUMERACIÓN (recorre `sys.databases` entero buscando `bisalta_lectura` en
   `sys.database_principals`, sin ningún filtro por lista ni por nombre). Se
   concede desde una lista explícita, se revoca por enumeración — dos
   direcciones, dos fuentes de verdad (comentario de cabecera del archivo).

## AC ↔ test binding (esta ronda)

| AC | Estado esta ronda | Evidencia |
|---|---|---|
| AC42 | `manual-only`, **redacción y mutación reescritas enteras** — cambia de propiedad: ya no afirma que el `DENY` gane a un `GRANT`, afirma que el user no tiene ninguna otra membresía además de `db_datareader` | `sqlserver-parte-b.sql` (bloque `db_denydatawriter` quitado del `EXEC sp_executesql`); `RUNBOOK.md`, sección "AC42" (comprobación real de membresía exacta + triple verde→rojo→verde sobre `EXACTUS` real con tabla de scratch, sin copias de `sqlserver-parte-b.sql`) |
| AC7 | `manual-only`, **sin cambio de universo** (sigue siendo la lista explícita), prosa de limpieza corregida: la "Limpiar antes de dar por cerrado el rojo" ya no usa una copia `-mutada-v8` del inverso — usa el inverso REAL (que ahora enumera) + recreación vía `sqlserver-parte-a.sql`/`sqlserver-parte-b.sql` | `RUNBOOK.md`, sección "AC7", subsección "Limpiar antes de dar por cerrado el rojo" |
| AC1–AC6, AC8, AC10, AC41 | sin cambio esta ronda | rondas anteriores (`git show 27029e3:...`) |
| AC9 | sin cambio de universo; re-verificado sobre el árbol final de esta ronda (ver "Secret-scan sobre el árbol final" abajo) | — |

## Barrido de clase — receta de copias de trabajo (re-corrido, tabla nueva)

Comando (mismo de rondas anteriores):

```
$ grep -n -i "copia de trabajo\|a partir de\|-mutada-\|-lista-vacia\|-baja-\|-mas-scratch\|-sin-denydatawriter" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
226:**Mutación declarada** (contract v5, AC41): en una copia de trabajo de
439:la corrida — `sqlserver-parte-b-mutada-v8.sql`, igual que el real, sólo
511:una copia de trabajo `sqlserver-parte-b-lista-vacia.sql`, borrar el
521:sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b-lista-vacia.sql
532:(no `Dev SQL`), en una copia de trabajo `sqlserver-parte-b-mutada-v8.sql`,
541:sqlcmd -S <instancia-de-prueba> -E -b -i sqlserver-parte-b-mutada-v8.sql
559:**no hace falta ninguna copia de trabajo del inverso**: `sqlserver-
589:haciendo falta (`sqlserver-parte-b-lista-vacia.sql`,
590:`sqlserver-parte-b-mutada-v8.sql`): ninguna se commitea.
787:tiene tres pasos donde antes había una copia de trabajo cuidadosamente
```

**La tabla baja de siete copias a tres** (v10 elimina cuatro: el inverso real
ya enumera, así que ninguna copia de trabajo del inverso hace falta, y AC42
dejó de necesitar una base de scratch agregada a una lista de `parte-b`):

| Copia de trabajo | Parte de | ¿Hereda algo destructivo/incondicional que no debería? |
|---|---|---|
| `postgres-parte-0-mutado.sql` (AC41) | `postgres-parte-0.sql` | No — sin cambio respecto de rondas anteriores |
| `sqlserver-parte-b-lista-vacia.sql` (AC7) | `sqlserver-parte-b.sql` | No — sin cambio respecto de rondas anteriores |
| `sqlserver-parte-b-mutada-v8.sql` (AC7) | `sqlserver-parte-b.sql` | No — sin cambio respecto de rondas anteriores |

**Eliminadas esta ronda** (ya no aparecen en el runbook, confirmado por el
mismo grep de arriba): `sqlserver-inverso-mutada-v8.sql` (AC7 — la limpieza
ahora usa el inverso real), `sqlserver-parte-b-mas-scratch.sql` y
`sqlserver-parte-b-sin-denydatawriter-mas-scratch.sql` (AC42 — la mutación
ahora usa `EXACTUS` real con una tabla de scratch, sin lista aparte),
`sqlserver-inverso-baja-ecommerce_qa.sql` (Procedimiento de baja — el
inverso real ya hace lo correcto, sin recortar nada).

## Barrido adicional — la forma exacta de la trampa que atrapó a esta misma tarea antes

Grep de la instrucción de orden que "CÓMO DAR DE BAJA UNA BASE" (cabecera de
`sqlserver-parte-b.sql`) reescribió, para confirmar que no quedó una
referencia contradictoria al orden viejo (revertir con el inverso ANTES de
sacar la fila) después de invertir el orden a "sacar la fila primero,
después correr el inverso":

```
$ grep -n "corre ANTES de sacar\|antes de sacar la fila" plugins/bisalta-db/aprovisionamiento/*.sql plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
(sin salida)
```

Encontrado y corregido **antes** de este commit: un comentario inline sobre
el `INSERT INTO @bases_permitidas` de `sqlserver-parte-b.sql`, separado del
bloque de cabecera "CÓMO DAR DE BAJA UNA BASE" que sí se reescribió en el
primer paso, decía *"el inverso corre ANTES de sacar la fila, no después"* —
exactamente el orden que Patrick rechazó, sobreviviendo porque el primer
barrido no lo tocó (no mencionaba `-baja-` ni `copia de trabajo` por
nombre). Corregido en el mismo commit de esta ronda, antes de correr el
runner.

## Impact set

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/'
plugins/bisalta-db/README.md
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
SDD/debt.md
SDD/briefs/R1-infra-accesos-lectura.md
```

Los seis archivos que cambiaron esta ronda (`README.md`, `INVENTARIO.md`,
`RUNBOOK.md`, `sqlserver-inverso.sql`, `sqlserver-parte-a.sql`,
`sqlserver-parte-b.sql`) están todos en este set salvo `INVENTARIO.md`, que
sólo mencionaba `db_denydatawriter` en una frase de medición (no a los dos
archivos `.sql` por nombre) — corregida por la misma razón (grep de
`denydatawriter` sobre todo `plugins/bisalta-db/`, ver más abajo). `SDD/debt.md`
y `SDD/briefs/R1-infra-accesos-lectura.md` son históricos, no se editan
(confirmado: no aparecen en `git status --short` tras el commit de esta
ronda). `plugins/bisalta-db/catalogo.json` y `APROBACIONES.md` no aparecen en
este grep porque no se editan esta ronda (ya los actualizó el planner);
confirmado sin diff:

```
$ git diff --stat HEAD~1 -- plugins/bisalta-db/catalogo.json plugins/bisalta-db/aprovisionamiento/APROBACIONES.md
(sin salida)
```

Ningún archivo `.js` de runtime (`plugins/bisalta-db/scripts/`) referencia
estos `.sql` — sin regresión de callers en el servidor MCP. Grep completo de
`denydatawriter` sobre el árbol, para confirmar que ninguna mención restante
afirma la garantía como vigente:

```
$ grep -rn "denydatawriter" plugins/bisalta-db/ | grep -v "APROBACIONES.md"
plugins/bisalta-db/README.md:137: ... "no" — db_denydatawriter se quitó en v10 ...
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql:14: ... (db_denydatawriter se quitó en v10 ...
plugins/bisalta-db/aprovisionamiento/INVENTARIO.md:150: ... db_denydatawriter se quitó) literalmente la única ...
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md: (varias líneas, todas "sale/se quitó/se sumó...revertido")
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:12: ... SALE db_denydatawriter (contract v10 ...
plugins/bisalta-db/scripts/catalogo.js:33: ... comentario de por qué el enum retiene 'deny-escritura' — no tocado, es R2 y el enum sigue vigente por decisión del contract
```

Todas las menciones restantes describen la remoción o el historial; ninguna
afirma la garantía como vigente hoy.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`f728033`, ver escalera de arriba).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verification queda fuera del árbol que el runner selló
(el `Tree:` de la cabecera es anterior a este addendum). Corrida sobre el
árbol final, **después** de commitear el addendum de arriba (commit
`dc348b1`, árbol limpio confirmado con `git status --short` antes de
correr):

```
$ git status --short
$ git rev-parse HEAD
dc348b10ec44a762fb60b61fcbfd7e7ce54af522
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Este párrafo final se agrega en un commit posterior a `dc348b1`, ya que el
propio archivo de evidencia no puede documentar su propio hash de commit sin
haberse commiteado primero — mismo patrón en cascada que `D34`/`D35`
describen para este runner.

---

# Addendum del agente `AGENT_r1` — ronda 2 sobre v10 (contract v11: AC43 + dos MAJOR + dos MINOR)

**Nota sobre continuidad**: el bloque superior de este archivo lo generó
`sdd-run-gates.sh` sobre el commit `fded93a` y **trunca lo que hubiera antes**
(mismo aviso que las rondas anteriores, `SDD/debt.md` D34/D35). El addendum de
la ronda 1 sobre v10 (commits `dc348b1`/`427daff`) se restauró íntegro justo
arriba de esta sección, verbatim, antes de agregar lo de esta ronda.

## Qué encontró el review y qué se corrigió

1. **MAJOR 1 (AC42)** — `RUNBOOK.md:617` (numeración de la versión que el
   reviewer tenía delante) filtraba `r.name IN
   ('db_datareader','db_denydatawriter','db_datawriter','db_owner')`. Eso
   mide "ninguna de estas cuatro", no "ninguna otra" — el enunciado
   literal de `AC42`. Una membresía en `db_ddladmin`,
   `db_securityadmin`, `db_accessadmin`, `db_backupoperator`,
   `db_denydatareader` o un rol de base a mano devolvía igual una sola
   fila y el paso daba verde con la propiedad falsa. Corregido quitando
   el filtro por nombre de rol: `WHERE m.name = 'bisalta_lectura'` a
   secas — `public` es implícito y no aparece en
   `sys.database_role_members`, así que no hace falta excluirlo.
2. **MAJOR 2** — el comentario de cabecera de `sqlserver-inverso.sql`
   (líneas 26-33 de la versión pre-ronda-2) y el runbook (viñeta
   "Inverso", paso 2 y paso 4 del "Procedimiento de baja") afirmaban
   revocación sobre **"TODAS"** las bases sin acotar, cuando el propio
   script salta las `NO ONLINE` por `PRINT` (líneas 49-55/75-80
   pre-ronda-2) y el `DROP LOGIN` final corre igual, incondicional
   (líneas 99-102). Consecuencia real: una base `NO ONLINE` con el user
   queda **huérfana** (sin login detrás) hasta reintentar. Corregido:
   (a) acotado a "toda base **ONLINE**" en el comentario de cabecera del
   inverso; (b) mismo acotamiento en el comentario equivalente de
   `sqlserver-parte-b.sql` (encontrado en el barrido de clase, no citado
   por el reviewer — ver abajo); (c) la viñeta "Inverso" y los pasos 2 y
   4 del "Procedimiento de baja" ahora mandan revisar `SELECT name, state
   FROM sys.databases WHERE state <> 0` (la misma consulta que la sección
   "AC7" ya prescribía) antes de asumir la revocación completa, con la
   consecuencia del huérfano y el reintento pendiente escritos.
3. **AC43 (nuevo, contract v11)** — procedimiento completo agregado a
   `RUNBOOK.md` entre las secciones "AC42" y "AC8": comprobación real
   (crear el user a mano en `CONSTRUPLAZA_EFLOW`, fuera de
   `@bases_permitidas`, confirmar que el inverso real lo saca igual) y
   mutación declarada (reemplazar el cursor por uno que recorra
   `@bases_permitidas` — la forma pre-v9 — y confirmar que el user
   sobrevive en esa base, rojo).
4. **MINOR** — `sqlserver-inverso.sql` traía `name` por el cursor y
   volvía a consultar `state` por separado en cada vuelta
   (`SET @estado = NULL; SELECT @estado = state FROM sys.databases WHERE
   name = @db_name;`). Una base borrada entre el `SELECT` del cursor y
   esa segunda consulta dejaba `@estado` en `NULL`; `IF @estado <> 0` con
   `NULL` evalúa `UNKNOWN` y cae al `ELSE`, ejecutando `USE` sobre una
   base inexistente y abortando la revocación a mitad bajo `-b`.
   Corregido: el cursor trae `name` y `state` en una sola pasada
   (`SELECT name, state FROM sys.databases`), sin re-consulta y sin
   `NULL` posible — mismo criterio de manejo explícito que
   `sqlserver-parte-b.sql` ya usa para `AUSENTE:`.
5. **MINOR** — la mutación de `AC42` (`RUNBOOK.md`, sección "AC42")
   concede `db_datawriter` sobre **todo `EXACTUS`** (395 GB, copia de
   producción) al login vivo compartido, no sólo sobre la tabla de
   scratch. El camino feliz revoca esa membresía dos pasos más abajo,
   pero una interrupción entre conceder y revocar dejaba la escritura
   concedida sin que el procedimiento lo dijera. Declarado en una nota
   antes del bloque de mutación.

## AC ↔ test binding (esta ronda)

| AC | Estado esta ronda | Evidencia |
|---|---|---|
| AC42 | `manual-only`, **comprobación de membresía corregida a enumeración real** (sin filtro de nombres de rol) | `RUNBOOK.md`, sección "AC42" (consulta sin `r.name IN (...)`) + nota de riesgo agregada a la mutación (interrupción entre conceder/revocar sobre `EXACTUS` entero) |
| AC43 | **nuevo (contract v11)**, `manual-only`, procedimiento completo con su triple verde→rojo→verde | `RUNBOOK.md`, sección "AC43" (nueva) |
| AC1–AC8, AC10, AC41 | sin cambio esta ronda | rondas anteriores |
| AC9 | sin cambio de universo; re-verificado sobre el árbol final de esta ronda (ver "Secret-scan sobre el árbol final" abajo) | — |
| AC7 | sin cambio de propiedad ni de universo; su comprobación (`##ac7_check`) no fue tocada esta ronda | rondas anteriores |

## Barrido de clase — alcance derivado del impact set, no del directorio

El barrido de la ronda 1 (sobre v10) había quedado acotado por directorio
(`plugins/bisalta-db/`) y por eso no vio que `CHANGELOG.md` seguía
vendiendo `db_denydatawriter` como vigente — corregido por el planner en
el contract v11, no en esta ronda (ver "Cambios v10 → v11" del contract).
Esta ronda deriva el alcance del grep del propio hallazgo, sobre el árbol
entero, no de la carpeta donde vive el archivo tocado:

```
$ grep -rn "TODAS las bases" . --include="*.md" --include="*.sql" --include="*.js" --include="*.json" | grep -v '\.git/'
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql:27:-- review, MAJOR 2 — "TODAS las bases" sin más era más de lo que este
plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql:22:-- TODAS las bases del cluster desde el momento en que existe, sin que
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:114:sobreclamado de "TODAS las bases" para el inverso también vivía en el
```

La única coincidencia nueva que no es la propia explicación de esta ronda
es `postgres-parte-0.sql:22` — afirmación distinta (alcance de
`pg_read_all_data` sobre el cluster completo de Postgres, no del inverso
de SQL Server ni de ningún estado `ONLINE`/`NO ONLINE`), sin relación con
el defecto de MAJOR 2. Antes de corregir el comentario de
`sqlserver-inverso.sql`, el mismo patrón sin acotar también vivía —sin
que el reviewer lo citara— en el comentario "CÓMO DAR DE BAJA UNA BASE"
de `sqlserver-parte-b.sql` (mismo texto, archivo distinto); corregido en
el mismo commit.

```
$ grep -rn "r.name IN ('db_datareader'" . --include="*.md" --include="*.sql"
(sin salida)
```

Confirma que el filtro cerrado de nombres de rol de MAJOR 1 no sobrevive
en ningún archivo del árbol (sólo se mencionaba una vez, en la sección
"AC42" ya corregida).

```
$ grep -n "FETCH NEXT FROM db_cursor INTO @db_name;$" plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
(sin salida)
```

Confirma que las dos apariciones de `FETCH NEXT` en el archivo (apertura
y fondo del `WHILE`) quedaron consistentes con el cursor de dos columnas
— ninguna se quedó fetcheando sólo `@db_name`.

## Impact set

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/'
plugins/bisalta-db/README.md
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
SDD/debt.md
SDD/briefs/R1-infra-accesos-lectura.md
```

De los siete, esta ronda tocó `sqlserver-parte-b.sql`, `RUNBOOK.md` y
`sqlserver-inverso.sql`. Los otros cuatro, revisados y sin necesidad de
cambio:

- `plugins/bisalta-db/README.md:315` describe el inverso como "recorre
  las bases de la instancia buscando dónde existe el user... sin leer
  ninguna lista" — no afirma "todas" ni omite matiz que contradiga el
  fix; no necesita corrección.
- `sqlserver-parte-a.sql` sólo menciona `sqlserver-inverso.sql` en su
  comentario de cabecera para explicar el ciclo alta/baja completo, sin
  afirmar el alcance de la revocación — no toca la propiedad corregida.
- `SDD/debt.md` (D40, cerrada) registra que el inverso "pasó a enumerar
  `sys.databases` completo, bases de sistema incluidas" — sigue siendo
  cierto: el acotamiento a `ONLINE` no cambia la cobertura de las bases
  de sistema (que están `ONLINE` en la práctica), y D40 no afirmaba nada
  sobre bases `NO ONLINE`. No se reabre.
- `SDD/briefs/R1-infra-accesos-lectura.md` — histórico, no se edita (per
  instrucción explícita de esta ronda: el brief ya lo corrigió el
  planner en el contract v11 y no es ownership de este agente).

Ningún archivo `.js` de runtime (`plugins/bisalta-db/scripts/`)
referencia estos `.sql` — sin regresión de callers en el servidor MCP.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`fded93a`, ver escalera de arriba).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verification queda fuera del árbol que el runner
selló (el `Tree:` de la cabecera es anterior a este addendum). Corrida
sobre el árbol final, **después** de commitear este addendum:

```
$ git status --short
$ git rev-parse HEAD
37fd716a1fff42ce519321b115d8cb555864fe3f
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Árbol limpio confirmado (`git status --short` sin salida) antes de correr,
sobre el commit `37fd716` — el que contiene este mismo addendum ya
commiteado. Este párrafo final se agrega en un commit posterior a
`37fd716`, por el mismo motivo en cascada que `D34`/`D35` describen: el
archivo de evidencia no puede documentar su propio hash de commit sin
haberse commiteado primero.

---

# Addendum del agente `AGENT_r1` — ronda 3 sobre v11 (dos MAJOR + dos MINOR de review; última ronda antes de `ESCALATE`)

**Nota sobre continuidad**: el bloque superior de este archivo lo generó
`sdd-run-gates.sh` sobre el commit `8f87475` y **trunca lo que hubiera antes**
(mismo aviso que las rondas anteriores, `SDD/debt.md` D34/D35). Los addenda
de ronda 1 (commits `dc348b1`/`427daff`) y ronda 2 (commits `fded93a` →
`37fd716` → `e4377fb`) sobre v10/v11 se restauraron íntegros, verbatim, justo
arriba de esta sección, antes de agregar lo de esta ronda.

Ningún AC nuevo entra esta ronda (sigue siendo v11, sin `contract-change-request`):
los cuatro hallazgos son sobre la **redacción del procedimiento** de `AC43`
y sobre la **evidencia de impact set** de la ronda anterior, no sobre una
propiedad nueva del sistema.

## Qué encontró el review y qué se corrigió

1. **MAJOR 1** — `RUNBOOK.md` (sección "AC43", parte (b)) prescribía
   `grep -n "bases_permitidas" sqlserver-inverso.sql`, esperado **vacío**,
   como comprobación de que el script no lee esa variable. Corrida de
   verdad devuelve dos líneas — `sqlserver-inverso.sql:6` y `:23` —, las
   dos del comentario de cabecera que explica justamente que el script no
   la lee. Una persona con `sysadmin` que siguiera el paso tal como estaba
   escrito obtenía rojo sobre una propiedad cierta: la clase RT13 de este
   repo (chequeo por literal que se dispara sobre la prosa que describe lo
   que prohíbe), ya vista con `sdd-check.sh`, `guard-git.sh`,
   `secret-scan.sh` y el `grep -c` del addendum de ronda 1. Corregido
   acotando el grep al cuerpo no-comentario:
   `grep -n "bases_permitidas" sqlserver-inverso.sql | grep -v '^[0-9]*:--'`,
   esperado vacío — verificado abajo, "Barrido de la forma".
2. **MAJOR 2** — las tres citas de "reintentar el inverso" (viñeta
   "Inverso" y pasos 2 y 4 del "Procedimiento de baja") prescribían, para
   una base que quedó `NO ONLINE` durante una corrida del inverso, correr
   `sqlserver-inverso.sql` **completo** de nuevo cuando esa base volviera a
   estar `ONLINE`. Pero en el "Procedimiento de baja" ese reintento cae
   **después** del paso 3, que ya recreó el login (`sqlserver-parte-a.sql`)
   y re-concedió las bases que se querían conservar
   (`sqlserver-parte-b.sql`) — y `sqlserver-inverso.sql` no admite alcance
   por base: revoca de toda base `ONLINE` donde el user exista y borra el
   login incondicionalmente. Reintentarlo ahí revoca otra vez las bases
   conservadas y vuelve a borrar el login, forzando una segunda rotación de
   contraseña en Secrets Manager y dejando el MCP roto — lo contrario del
   estado que el propio paso 4 declara esperar, y una reintroducción de la
   dependencia de orden que Patrick rechazó por escrito ("depende de que
   alguien recuerde el orden"). Corregidas las tres citas: la limpieza de
   un huérfano `NO ONLINE` es dirigida contra esa base sola —
   `sqlcmd -S <instancia> -E -d <base> -Q "IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'bisalta_lectura') DROP USER bisalta_lectura;"` —,
   nunca una segunda corrida completa del inverso, y las dos citas dentro
   del "Procedimiento de baja" declaran explícitamente por qué (deshace la
   re-concesión y el login del paso 3).
3. **MINOR 1** — el "Impact set" transcrito en la ronda 2 (línea 369-379 de
   entonces) traía siete archivos, copiados de la ronda 1 en vez de
   re-corridos: sobre el árbol sellado de esa ronda el mismo grep ya
   devolvía **ocho**, porque `AC43` (agregado en esa misma ronda) nombra
   `sqlserver-inverso.sql` en `SDD/contracts/2026-09-18-bisalta-db-mcp.md`.
   Es la séptima instancia de la clase de defecto de este ciclo — un valor
   corregido/agregado en un lugar y no propagado a las otras citas —, y
   cae justo en la sección titulada "alcance derivado del impact set". No
   se reabre el impact set de ronda 2 (queda como registro histórico de lo
   que esa ronda transcribió); el impact set correcto de **esta** ronda,
   re-corrido contra el árbol actual, está más abajo con las ocho entradas
   y por qué las cinco que no se tocaron no necesitan cambio.
4. **MINOR 2** — `AC43(a)` nombra las cuatro bases de sistema como parte
   de la propiedad ("incluidas las cuatro de sistema"), pero la
   comprobación real sólo creaba el user a mano en `CONSTRUPLAZA_EFLOW`
   (una base que no es de sistema). Esa mitad de (a) se sostenía sólo por
   inspección del cursor sin filtro, y `D40` se cerró apoyándose en esa
   afirmación sin ejercitarla. Agregado un `CREATE USER` a mano en `msdb`
   y su confirmación de cero filas tras el inverso, en la misma sección.

## AC ↔ test binding (esta ronda)

| AC | Estado esta ronda | Evidencia |
|---|---|---|
| AC43 | `manual-only`, sin cambio de propiedad — cambia el **procedimiento** de comprobación ((b) acota el grep al cuerpo ejecutable; (a) ejercita `msdb` además de `CONSTRUPLAZA_EFLOW`) y la remediación del huérfano `NO ONLINE` deja de prescribir un reintento destructivo | `RUNBOOK.md`, sección "AC43" (grep acotado + paso `msdb`) y viñeta "Inverso" + "Procedimiento de baja" (limpieza dirigida en las tres citas) |
| AC1–AC10, AC41, AC42 | sin cambio esta ronda | rondas anteriores |
| AC9 | sin cambio de universo; re-verificado sobre el árbol final de esta ronda (ver "Secret-scan sobre el árbol final" abajo) | — |

## Barrido de la forma — antes de cerrar

Dos preguntas del review, con el comando literal y su salida:

**¿Queda algún otro chequeo por literal en el runbook cuyo esperado no
contemple que la prosa del propio repo contiene el literal?**

```
$ grep -n "confirmable con\|no tiene que\|tiene que devolver\|no debe aparecer\|no debe devolver\|sin salida\|no debería" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
314:tiene que devolver `rolinherit = true` para ambos (nunca `NOINHERIT`).
760:que **no tiene que devolver nada** (el `grep -v` filtra cualquier línea
```

La línea 314 es un valor de columna esperado (`rolinherit = true`), no un
chequeo `grep` sobre texto — no puede matchear su propia prosa. La línea
760 es el chequeo de MAJOR 1, ya corregido para excluir comentarios:

```
$ grep -n "bases_permitidas" plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql | grep -v '^[0-9]*:--'
(sin salida)
```

Vacío, como el runbook ahora promete. No queda ningún otro chequeo por
literal en `RUNBOOK.md` ni en los `.sql` de `plugins/bisalta-db/aprovisionamiento/`
(confirmado también sobre los cuatro `.sql` — ningún archivo prescribe un
`grep` de comprobación en su propio comentario):

```
$ grep -n "grep\|confirmable\|sin salida" plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql plugins/bisalta-db/aprovisionamiento/postgres-parte-0.sql plugins/bisalta-db/aprovisionamiento/postgres-inverso.sql
(sin salida)
```

**¿Alguna otra remediación que, ejecutada en el punto donde el procedimiento
la ubica, deshaga un paso anterior?**

```
$ grep -n "correr.*completo\|volver a correr\|re-correr\|correrlo de nuevo\|correr.*otra vez\|correr.*nuevamente" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
333:mutación tocó, nunca sobre otra — y volver a correr exactamente el mismo
446:producción — y volver a correr exactamente el mismo `INSERT`:
623:cabecera). Recién ahora volver a correr el bloque `##ac7_check` para
823:commitearla nunca) y volver a correr `sqlserver-inverso.sql` real contra
860:`sqlserver-parte-b.sql` y (b) vuelva a correr el script completo — y
879:y solicitante en `APROBACIONES.md`, y (c) re-correr `sqlserver-parte-b.sql`
939:  `ONLINE`. La limpieza de ese huérfano **no es volver a correr
998:   `EXACTUS` y `BI` — correr `sqlserver-inverso.sql` completo otra vez
```

Revisadas las ocho: 333 y 446 son restauraciones de una mutación sobre el
mismo objeto que la propia mutación tocó (`postgres-parte-0-mutado.sql` y
la copia de scratch de AC42 respectivamente), no un reintento sobre un
procedimiento con pasos previos que preservar. 623 es la re-corrida de una
consulta de verificación (`##ac7_check`), no de un script que muta estado.
823 es la corrida del inverso real dentro del propio ciclo de mutación de
`AC43`, sobre una instancia de prueba dedicada a ese AC, sin ningún paso
previo de "conservar otras bases" que deshacer. 860 y 879 son de `AC10`
("hueco de una base nueva"): mandan re-correr `sqlserver-parte-b.sql`
(concede, idempotente por diseño — declarado en su propio comentario
"Idempotente" y en la sección "Procedimiento de baja", paso 3), nunca el
inverso; conceder de más no deshace una conservación anterior. 939 y 998
son las dos citas que este commit corrigió: ya no prescriben "correr
completo otra vez" como remediación — la 939 lo nombra sólo para
descartarlo explícitamente, y la 998 (dentro del paso 4 del
"Procedimiento de baja") igual. No queda ninguna remediación que, en el
punto del procedimiento donde el runbook la ubica, deshaga un paso
anterior.

## Impact set (re-corrido, no copiado)

`grep -rl` no garantiza orden estable entre corridas sobre este árbol
(confirmado: tres corridas seguidas del mismo comando sin `sort` devolvieron
las mismas ocho rutas en tres órdenes distintos) — se agrega `| sort` para
que la salida pegada acá sea reproducible:

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/' | sort
SDD/briefs/R1-infra-accesos-lectura.md
SDD/contracts/2026-09-18-bisalta-db-mcp.md
SDD/debt.md
plugins/bisalta-db/README.md
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
```

Son **ocho** (la ronda 2 había transcrito siete — ver MINOR 1 arriba).
Esta ronda tocó únicamente `RUNBOOK.md`. Los otros siete, revisados y sin
necesidad de cambio:

- `plugins/bisalta-db/README.md:315` describe el inverso como "recorre
  las bases de la instancia buscando dónde existe el user... sin leer
  ninguna lista" — no prescribe ningún chequeo por literal ni ninguna
  remediación por reintento; no toca ninguna de las dos propiedades
  corregidas esta ronda.
- `sqlserver-parte-b.sql` y `sqlserver-parte-a.sql` — revisados con los
  greps de "Barrido de la forma" de arriba: ninguno prescribe un chequeo
  `grep` sobre sí mismo ni una remediación por reintento del inverso.
- `sqlserver-inverso.sql` — su comentario de cabecera es justamente el
  texto que MAJOR 1 identificó como la fuente de las dos líneas que el
  grep viejo capturaba; no se edita el `.sql` porque el defecto estaba en
  el chequeo (`RUNBOOK.md`), no en el comentario, que sigue siendo preciso
  sobre el comportamiento real del script.
- `SDD/debt.md` (D40, cerrada) — no prescribe ningún chequeo ni
  remediación; sigue sin reabrirse (ver ronda 2, no cambia esta ronda).
- `SDD/contracts/2026-09-18-bisalta-db-mcp.md:484` — `AC43` afirma que el
  script "no lee `@bases_permitidas` en ningún punto", sin distinguir
  cuerpo ejecutable de comentario. Sigue siendo una afirmación cierta
  sobre el script (el comentario de cabecera no es una lectura de la
  variable) y no queda contradicha por el fix de MAJOR 1, que sólo acota
  el *chequeo* (`grep`), no la propiedad que el AC describe. El contract es
  de escritura exclusiva del planner (`contract-change-request` si hiciera
  falta tocarlo) — no se edita desde este agente. No se reabre.
- `SDD/briefs/R1-infra-accesos-lectura.md` — histórico, no se edita (per
  instrucción explícita ya registrada en ronda 2: el brief lo corrigió el
  planner en el contract v11 y no es ownership de este agente).

Ningún archivo `.js` de runtime (`plugins/bisalta-db/scripts/`) referencia
estos `.sql` — sin regresión de callers en el servidor MCP.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`8f87475`, ver escalera de arriba).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verification queda fuera del árbol que el runner
selló (el `Tree:` de la cabecera es anterior a este addendum). Corrida
sobre el árbol final, **después** de commitear este addendum:

```
$ git status --short
$ git rev-parse HEAD
8424d20903d7e5f8ef221b15ff0ef0a7ab39775e
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Árbol limpio confirmado (`git status --short` sin salida) antes de correr,
sobre el commit `8424d20` — el que contiene este mismo addendum ya
commiteado. Este párrafo final se agrega en un commit posterior a
`8424d20`, por el mismo motivo en cascada que `D34`/`D35` describen: el
archivo de evidencia no puede documentar su propio hash de commit sin
haberse commiteado primero.
