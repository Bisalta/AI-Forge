# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `e36be11` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-21T17:40:41Z
- Tree: `a714f6c143928a34d05fabddb2c5fb7c81d75c60` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-21T17:39:29Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-21T17:39:29Z | verde |
| 3 | type-check | — | — | 2026-09-21T17:39:30Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:39:30Z | verde |
| 5 | integration | — | — | 2026-09-21T17:40:05Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-21T17:40:05Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-21T17:40:05Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-21T17:40:05Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-21T17:40:05Z | verde |
| 10 | smoke manual | — | — | 2026-09-21T17:40:06Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:40:06Z | verde |

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

---

# Addendum del agente `AGENT_r1` — ronda 2 de review, contract v9 (sin cambio)

**Nota sobre continuidad**: el bloque de arriba lo generó `sdd-run-gates.sh`
sobre el commit `e36be11` y **trunca lo que hubiera antes en este archivo**
(comportamiento conocido del runner — mismo aviso que las rondas
anteriores). El addendum de la ronda 1 (v9, commit `b9f203b`/`299091f`) no
se retranscribe acá: recuperable con
`git show 299091f:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.
Esta ronda **no cambió el alcance del contract** (sigue v9): son tres
MAJOR de prosa de procedimiento sobre los mismos dos `.sql` y `RUNBOOK.md`
que la ronda 1 ya había reescrito, más dos MINOR.

## Qué se corrigió esta ronda y por qué (los tres MAJOR del reviewer)

| MAJOR | Archivo(s) | Qué estaba mal | Fix aplicado |
|---|---|---|---|
| 1 | `RUNBOOK.md` (procedimiento "Lista vacía" de AC7) | Pedía dejar un `INSERT INTO @bases_permitidas` sin `VALUES` — `INSERT ... VALUES;` o `INSERT ... VALUES` sin filas es error de sintaxis T-SQL (`Msg 102, Level 15`), `sqlcmd` sale ≠ 0, lo contrario de lo que el paso declara esperar | Reescrito: borrar el statement `INSERT INTO @bases_permitidas (nombre) VALUES (...);` **completo**, dejar sólo el `DECLARE @bases_permitidas TABLE (...);` |
| 2 | `sqlserver-inverso.sql` (comentario de cabecera), `sqlserver-parte-b.sql` (comentario junto al `INSERT`), `RUNBOOK.md` ("Inverso") | El comentario del inverso afirmaba "si la parte B sólo tocó las bases nombradas, el inverso sólo tiene que revisar esas mismas" — falso cuando la lista se achica: sacar una base de la lista no revoca nada, y `sqlserver-parte-b.sql:77` (antes del fix) prometía que la lista era el único lugar para agregar **o quitar** una base sin que el camino de quitar existiera | Documentado el procedimiento de baja completo (nueva sección "Inverso" → "Procedimiento de baja" en `RUNBOOK.md`, comentarios nuevos en la cabecera de los dos `.sql`) |
| 3 | `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md` (este archivo, versión de ronda 1) | La evidencia de AC10 citaba líneas 529/641 como "corrida esta ronda" sobre el árbol sellado (`b9f203b`/`570c2e3`), pero esas líneas eran de `fa86bc8` (el commit **anterior** al fix de AC7, que agregó ~25 líneas al runbook) — no reproducían sobre el árbol que la cabecera declaraba describir (`RT20`) | Ver sección "AC10 — corrida del grep" más abajo: se re-corrió sobre el árbol final y se dejó de citar número de línea (más robusto: la frase no se mueve con el archivo, la línea sí) |

**Hallazgo propio, corregido en la misma ronda, antes de commitear** (no
llega a MAJOR de review porque nunca se commiteó así): al escribir el fix
del MAJOR 2, la primera versión del "Procedimiento de baja" decía correr
`sqlserver-inverso.sql` (real o recortado a una sola base) para revertir
la baja. Releyendo el script antes de cerrar, `sqlserver-inverso.sql`
termina con un `DROP LOGIN` **incondicional** — no mira cuántas bases
quedan en la lista, corre siempre que el login exista. Correrlo con la
lista completa revertiría *todas* las bases, no sólo la que se quiere dar
de baja; correrlo con una copia recortada a esa única base evita eso en
el `DROP USER`/`ALTER ROLE`, pero el `DROP LOGIN` de más abajo se ejecuta
igual y deja sin login a `bisalta_lectura` para las demás bases que
seguían activas — es la misma clase de defecto que el MAJOR 2 original
(un procedimiento que, seguido literal, produce un resultado distinto del
que declara). Corregido documentando que la copia de trabajo, cuando
queda al menos otra base activa, tiene que recortar la lista **y** quitar
el bloque final de `DROP LOGIN` (los tres archivos tocados por el MAJOR 2
ya reflejan esto).

## MINOR aplicados

- `RUNBOOK.md`, paso 7 de "Orden de ejecución": agregado "revisar la
  salida por líneas `AUSENTE:` / `NO ONLINE:` / `RECHAZADA` antes de
  seguir" (el script sale 0 aunque una base nombrada no se haya podido
  cubrir).
- `RUNBOOK.md`, sección "AC7": el párrafo sobre el filtro `state = 0` del
  cursor de `##ac7_check` ahora cita `INVENTARIO.md:146` ("las 32 están
  `ONLINE`") para justificar por qué el filtro alcanza a ver el universo
  negativo entero **hoy**, y agrega que una base fuera de la lista que no
  esté `ONLINE` en el futuro se lista aparte y se declara explícitamente
  no medida por esta comprobación.

## Barrido de clase antes de cerrar (pedido explícito del brief de ronda 2)

Tres preguntas, cada una con el comando que se corrió:

1. **¿Queda otro procedimiento que, seguido literal, produzca un
   resultado distinto del que declara?** Sí — el hallazgo propio del
   `DROP LOGIN` incondicional de arriba, encontrado releyendo el propio
   fix del MAJOR 2 antes de commitear, y corregido en el mismo commit
   (`e36be11`). Grep de otras trampas de sintaxis del mismo tipo (`INSERT
   ... VALUES` sin filas, bloques que si se recortan a medias dejan
   T-SQL inválido):
   ```
   $ grep -n "sin ninguna fila\|sin filas\|VALUES sin" plugins/bisalta-db/aprovisionamiento/*.sql plugins/bisalta-db/aprovisionamiento/*.md
   plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:465:SYSNAME PRIMARY KEY);` — un `INSERT ... VALUES` sin ninguna fila (ya sea
   ```
   Única coincidencia: la frase que el propio MAJOR 1 corrigió esta
   ronda (ahora describe el fix, no el defecto). Ninguna otra instancia.
2. **¿Otra justificación que valga sólo bajo un supuesto no dicho?**
   Grep de las formas "único lugar" / "la única forma" sobre los archivos
   de este directorio:
   ```
   $ grep -rn "único lugar\|ÚNICO lugar\|la única forma" plugins/bisalta-db/aprovisionamiento/*.sql plugins/bisalta-db/aprovisionamiento/*.md
   plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:88:-- Lista explícita de bases con acceso concedido. ÚNICO lugar del script
   ```
   Esa es la misma línea que el MAJOR 2 corrigió (ahora referencia
   también el procedimiento de baja, en vez de callarlo). El otro caso
   señalado por el reviewer ("universo negativo entero", MINOR) ya se
   corrigió arriba citando `INVENTARIO.md:146` en vez de asumirlo sin
   decirlo. No se encontró una tercera instancia.
3. **¿Otra salida pegada con números de línea de un árbol que ya no es
   el sellado?** Grep sobre este mismo archivo de verification antes de
   escribir este addendum (sobre la versión de ronda 1, recuperada de
   `299091f`, antes de que el runner la truncara):
   ```
   $ git show 299091f:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md | grep -n "línea [0-9]\|líneas [0-9]"
   180:| AC10 | verificable por grep, no `manual-only` | **reescrito** (doble causa: no agregada / agregada pero no re-corrida) sin perder la frase literal que el AC exige | `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → exit 0, línea 641 (ver corrida abajo) |
   201:La coincidencia de la línea 641 es la del texto de `AC10` propiamente
   202:dicho; la de la línea 529 es una mención de la misma idea dentro del
   ```
   Es exactamente el MAJOR 3 que este addendum corrige más abajo. No se
   encontró una segunda instancia del patrón en el resto del árbol
   (`SDD/debt.md`, `SDD/briefs/`, `plugins/bisalta-db/README.md` no citan
   líneas de `RUNBOOK.md`).

## AC10 — corrida del grep, ronda 2 (MAJOR 3 corregido)

La versión de ronda 1 de esta sección citaba las líneas **529 y 641**
como si describieran el árbol que ese report sellaba (`b9f203b` /
`570c2e3`) — pero esas líneas eran de `fa86bc8`, el commit **anterior**
al fix de AC7 (`b9f203b`), que agregó ~25 líneas al runbook y corrió el
número real a 554/666 sobre ese árbol (y a 569/681 sobre el árbol de esta
ronda, después de los fixes de MAJOR 1/2 — confirmando que el número
efectivamente se mueve con cada edición del archivo, que es el motivo del
fix). Esta ronda deja de citar línea y cita sólo la frase, que es lo que
`AC10` exige textualmente y no se mueve con el archivo:

```
$ git rev-parse HEAD
e36be11a5ffdb2e7029cb6c0eba4f04c18da0bbf
$ grep -i "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
**Con la lista explícita (v9), una base de scratch no queda cubierta
todavía no escrita en `@bases_permitidas`, NO queda cubierta
$ echo $?
0
```

Dos coincidencias, ninguna es ruido: la primera es una mención de la
misma idea dentro del procedimiento de `AC42`; la segunda es el texto de
`AC10` propiamente dicho (la frase que el AC exige literalmente, "NO
queda cubierta").

## Impact set (re-corrido esta ronda, sin cambios respecto de ronda 1)

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/'
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
SDD/debt.md
SDD/briefs/R1-infra-accesos-lectura.md
```

Mismo conjunto que la ronda 1 (ver análisis por archivo en el addendum de
esa ronda, recuperable con `git show 299091f:...`): `sqlserver-parte-a.sql`
sólo menciona a `sqlserver-parte-b.sql` en su comentario de cabecera, sin
necesitar cambio; `SDD/debt.md` y `SDD/briefs/R1-infra-accesos-lectura.md`
son históricos, no se editan. Ningún archivo `.js` de runtime referencia
estos `.sql` — sin regresión de callers en el servidor MCP; la suite de
`SDD/tests/` (17 archivos) sigue verde sin cambios (ver gate 4/suite
completa de arriba).

## AC ↔ test binding (esta ronda: sin cambio de universo, corrección de prosa)

| AC | Estado esta ronda | Evidencia |
|---|---|---|
| AC7 | `manual-only`, procedimiento corregido (MAJOR 1: lista vacía ya no es error de sintaxis) | `RUNBOOK.md`, sección "AC7", subsección "Lista vacía, parte del mismo AC" |
| AC10 | verificable por grep, re-verificado sin cambio de universo (MAJOR 3: evidencia corregida) | `grep -i "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → exit 0 (ver corrida arriba) |
| AC42 | `manual-only`, sin cambio de universo — el procedimiento de scratch de AC42 no usa `sqlserver-inverso.sql`, no le aplica el MAJOR 2 | sin cambios respecto de ronda 1 |

El resto de los ACs (AC1-AC6, AC8, AC9, AC41) no se tocaron esta ronda:
ninguno de los tres MAJOR ni los dos MINOR los menciona. Ver la tabla
completa de ronda 1 (`git show 299091f:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`)
para su estado, sin cambios.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`e36be11`, ver escalera de arriba).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verification queda fuera del árbol que el runner
selló (el `Tree:` de la cabecera es anterior a este addendum). Corrida
sobre el árbol final, **después** de commitear el addendum de arriba
(commit `dd73de9`, árbol limpio confirmado con `git status --short` antes
de correr):

```
$ git rev-parse HEAD
dd73de9b2ed67748241bb439dfc62085d819c602
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Este párrafo final se agrega en un commit posterior a `dd73de9`, ya que
el propio archivo de evidencia no puede documentar su propio hash de
commit sin haberse commiteado primero — mismo patrón en cascada que
`D34`/`D35` describen para este runner.

