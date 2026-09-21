# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `f728033` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-21T21:01:20Z
- Tree: `743b2b16e3d3caa35bf6c4750734c0ad255f3bdd` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-21T21:00:15Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-21T21:00:15Z | verde |
| 3 | type-check | — | — | 2026-09-21T21:00:16Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-21T21:00:16Z | verde |
| 5 | integration | — | — | 2026-09-21T21:00:47Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-21T21:00:47Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-21T21:00:47Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-21T21:00:47Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-21T21:00:47Z | verde |
| 10 | smoke manual | — | — | 2026-09-21T21:00:48Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-21T21:00:48Z | verde |

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
