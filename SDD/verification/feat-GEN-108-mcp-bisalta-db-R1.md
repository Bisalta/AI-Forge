# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `b9f203b` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-21T17:17:56Z
- Tree: `570c2e3cdf9a50042dbfaff188bf8e91545dbd88` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-21T17:16:53Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-21T17:16:53Z | verde |
| 3 | type-check | — | — | 2026-09-21T17:16:54Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:16:54Z | verde |
| 5 | integration | — | — | 2026-09-21T17:17:24Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-21T17:17:24Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-21T17:17:24Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-21T17:17:24Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-21T17:17:24Z | verde |
| 10 | smoke manual | — | — | 2026-09-21T17:17:25Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-21T17:17:25Z | verde |

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

# Addendum del agente `AGENT_r1` — ronda nueva, contract v9 (alcance por pedido nombrado)

**Nota sobre continuidad**: el bloque de arriba lo generó `sdd-run-gates.sh`
sobre el commit `b9f203b` y **trunca lo que hubiera antes en este archivo**
(comportamiento conocido del runner, no un defecto de esta ronda — ver
`CHANGELOG.md` de `sdd-flow` sobre por qué el `-o` siempre reemplaza el
archivo entero). Los addenda de las rondas anteriores de R1 (rondas 1–5,
sobre v3–v8) y de R2 no se retranscriben acá: viven íntegros en el
historial de git, recuperables con `git show <commit>:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`
sobre cualquier commit anterior a este (por ejemplo `a8594cd`, el último
antes de que el contract pasara a v9). Retranscribirlos habría significado
copiar ~800 líneas de prosa sobre un mecanismo (el loop de `sys.databases`
con exclusiones) que esta ronda reemplaza — exactamente el patrón de
citar un valor que ya no describe el estado real que este mismo ciclo
viene corrigiendo.

## Qué cambió y por qué (contract v9, "Cambios v8 → v9")

Patrick Ocampo reemplazó el freno por una regla: el alcance de Dev SQL
arranca en cero y se agrega a pedido nombrado, con fecha y solicitante,
sin aprobación adicional por base. Esto invierte el default de
`sqlserver-parte-b.sql` (v4–v8: recorría `sys.databases` concediendo todo
salvo exclusiones) a uno por lista explícita (`@bases_permitidas`,
declarada al principio del script). `AC7` y `AC42` cambian de universo en
el contract (dejan de hablar de "todas las bases salvo `SSISDB`" y pasan
a hablar de "la lista"), y sus mutaciones cambian con ellos.

Archivos tocados este alcance (AC1–AC10, AC41, AC42 — este agente, R1):

| Archivo | Cambio |
|---|---|
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` | Cursor sobre `@bases_permitidas` (lista explícita, seis nombres) en vez de `sys.databases` con filtro de exclusión. `@bases_prohibidas` como defensa en profundidad (`SSISDB`, `master`, `model`, `msdb`, `tempdb`): si aparecen en la lista, se rechazan y se avisa por `PRINT`, nunca en silencio. Un nombre de la lista ausente de `sys.databases`, o presente pero no `ONLINE`, también se reporta por `PRINT` en vez de saltearse (defecto de `sp_MSforeachdb` que el comentario original ya documentaba, ahora corregido también para el caso de la lista). Lista vacía → el bucle no itera, no crea nada, `GO` cierra en 0. |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` | Mismo cambio de cursor, misma lista (comentario de cabecera: "si se edita una, se edita la otra en el mismo cambio"), mismas guardas de defensa en profundidad y de no-saltar-en-silencio. |
| `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | Reescritas las secciones `AC7` y `AC42` (procedimiento, mutación declarada nueva de `AC7` literal del contract v9); `AC10` extendido a la doble causa de la lista (base nunca agregada / base agregada pero no re-corrida); sección "`SSISDB` queda fuera del loop" reescrita en términos de la lista en vez del filtro de exclusión; "Orden de ejecución" paso 7 y párrafo de cabecera actualizados a v9. |
| `plugins/bisalta-db/README.md` | Sección "Aprovisionamiento": agrega que el alcance arranca en cero y se agrega a pedido nombrado, y que una base pedida pero no agregada a la lista tampoco queda cubierta. |

**No tocado, por instrucción explícita del brief**: `plugins/bisalta-db/catalogo.json`, `plugins/bisalta-db/aprovisionamiento/APROBACIONES.md` (ya actualizados por el planner en `ee92605`), ni ningún archivo de Postgres.

## Ningún valor de la lista se retranscribió en prosa

Verificado con grep sobre los cuatro archivos tocados: los nombres de las
seis bases (`COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`,
`EXACTUS`, `BI`) sólo aparecen **una vez cada uno como dato vivo**: en el
`INSERT INTO @bases_permitidas` de `sqlserver-parte-b.sql` y en el
`INSERT` equivalente de `sqlserver-inverso.sql` (que el comentario de
cabecera declara explícitamente como copia intencional de la misma
lista, editada junto con la otra). Ni `RUNBOOK.md` ni `README.md` los
retranscriben — las dos veces que este ciclo señaló esa clase de defecto
(`SDD/retro.md` RT20, y la reincidencia nombrada en este mismo brief), la
corrección fue derivar o referenciar el archivo fuente, no copiar el
valor a un tercer lugar. Tampoco se congeló ninguna cifra derivada del
tamaño de la lista (GB, porcentaje del servidor, "31 bases", "seis
bases"): las menciones de conteo que tenía el borrador inicial de este
addendum y de `RUNBOOK.md` se reemplazaron por referencias a "la lista
vigente del script" durante esta misma ronda (ver commit `fa86bc8`).

```
$ grep -rn "COMPRAS_STG" plugins/bisalta-db/ | grep -v aprovisionamiento/APROBACIONES.md
plugins/bisalta-db/catalogo.json:112:    "base": "COMPRAS_STG",
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:81:  (N'COMPRAS_STG'),
plugins/bisalta-db/aprovisionamiento/INVENTARIO.md:86:| 4 | `COMPRAS_STG` | 35 | 107.09 | **2026-09-07** |
plugins/bisalta-db/aprovisionamiento/INVENTARIO.md:120:2. **`COMPRAS` y `COMPRAS_STG` pesan exactamente lo mismo: 107.09 GB**, y la segunda se
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql:40:  (N'COMPRAS_STG'),
```

Cuatro archivos, ninguno tocado por este agente salvo los dos `.sql`:
`catalogo.json` es el dato vivo del catálogo de la aplicación (planner,
commit `ee92605`); `INVENTARIO.md` es la medición fechada del 18-sep-2026
(histórico, no se actualiza por cada cambio de lista). Ninguna
coincidencia en `RUNBOOK.md` ni `README.md` — que es lo que esta sección
afirma.

## Hallazgo propio, corregido en la misma ronda (no llega a MAJOR porque no se commiteó así)

Al escribir la mutación de `AC7` por primera vez, el cierre en verde
decía "correr de nuevo `sqlserver-parte-b.sql` real" para volver del rojo
al verde — pero ese script es aditivo (`IF NOT EXISTS` antes de cada
`ALTER ROLE ADD MEMBER`) y nunca revierte lo que la corrida mutada
(`sys.databases` con exclusión) dejó de más en bases fuera de la lista.
Es la misma clase de defecto que `SDD/debt.md` D40 ya tiene registrada
para una versión anterior del procedimiento de `AC7`. Se detectó
releyendo el propio procedimiento antes de correr el runner por segunda
vez (commit `b9f203b`, mensaje del commit trae el detalle) y se corrigió
agregando el paso de reversión explícito (`sqlserver-inverso-mutada-v8.sql`,
copia de trabajo con el mismo cursor de exclusión que la mutación) antes
de re-confirmar el verde con `##ac7_check`. No se registra como MAJOR de
review porque nunca llegó a un commit que un reviewer fuera a evaluar
como cerrado: se corrigió en el mismo ciclo de escritura, antes de la
corrida de gates que sella esta ronda.

## AC ↔ test binding (R1: AC1–AC10, AC41, AC42)

| AC | Naturaleza | Estado esta ronda | Evidencia / procedimiento |
|---|---|---|---|
| AC1 | `manual-only` | sin cambio — no tocado este alcance | `RUNBOOK.md`, sección "AC1" (sin cambios) |
| AC2 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC2" (sin cambios) |
| AC3 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC3" (sin cambios) |
| AC4 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC4" (sin cambios) |
| AC5 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC5" (sin cambios) |
| AC6 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC6" (sin cambios) |
| AC7 | `manual-only` | **reescrito** (universo v9: lista explícita, incluida la lista vacía) | `RUNBOOK.md`, sección "AC7 — el user existe exactamente en las bases de la lista y en ninguna otra"; procedimiento y mutación declarada nueva escritos, no ejecutados (requiere instancia real) |
| AC8 | `manual-only` | sin cambio | `RUNBOOK.md`, sección "AC8" (sin cambios) |
| AC9 | automatizable | sin cambio de contenido — re-verificado en este árbol | `bash SDD/tests/secret-scan.sh` → exit 0 (gate 9 de arriba, commit `b9f203b`); mutación original del contract sigue documentada en el historial de git (rondas anteriores) porque el archivo que muta (`postgres-parte-a.sql`) no se tocó este alcance |
| AC10 | verificable por grep, no `manual-only` | **reescrito** (doble causa: no agregada / agregada pero no re-corrida) sin perder la frase literal que el AC exige | `grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` → exit 0, línea 641 (ver corrida abajo) |
| AC41 | `manual-only` | sin cambio — Postgres no se tocó este alcance | `RUNBOOK.md`, sección "AC41" (sin cambios) |
| AC42 | `manual-only` | **reescrito** (universo v9: cada base de la lista; procedimiento de scratch adaptado a que agregar una base de prueba exige una copia de trabajo de la lista, nunca el archivo real) | `RUNBOOK.md`, sección "AC42 — el user tiene las dos membresías en cada base de la lista, y el `DENY` gana"; procedimiento y mutación reescritos, no ejecutados (requiere instancia real) |

Diez de los doce siguen `manual-only`/`pendiente-de-ejecucion`: ningún
harness de este repo puede crear un rol de SQL Server, alcanzar la VPC de
dev/qa, o alcanzar `10.24.40.137` — mismo motivo declarado desde la ronda
1 de R1, sin cambios. Declarar un "observado" acá sin haber corrido nada
contra una instancia real sería la validación no corrida que las reglas
del ciclo prohíben.

### AC10 — corrida del grep, esta ronda

```
$ grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
529:**Con la lista explícita (v9), una base de scratch no queda cubierta
641:todavía no escrita en `@bases_permitidas`, NO queda cubierta
$ echo $?
0
```

La coincidencia de la línea 641 es la del texto de `AC10` propiamente
dicho; la de la línea 529 es una mención de la misma idea dentro del
procedimiento de `AC42` — ambas válidas, ninguna es ruido.

## Impact set

Símbolos/archivos que referencian los dos `.sql` tocados, grepeados sobre
el árbol completo (excluyendo este mismo directorio de verificación):

```
$ grep -rl "sqlserver-parte-b.sql\|sqlserver-inverso.sql" . 2>/dev/null | grep -v '^\./\.git' | grep -v '/verification/'
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
SDD/debt.md
SDD/briefs/R1-infra-accesos-lectura.md
```

- `sqlserver-parte-a.sql`: menciona a `sqlserver-parte-b.sql` en su
  comentario de cabecera (que `db_denydatawriter` "va junto con
  `db_datareader` en `sqlserver-parte-b.sql`") — cita la relación entre
  los dos scripts, no el mecanismo de recorrido; no necesita cambio y no
  se tocó.
- `RUNBOOK.md`: cubierto arriba, es el propio archivo reescrito.
- `SDD/debt.md`: D40 referencia el AC7 de una ronda anterior — no se
  edita (no es un archivo de este brief) pero se lo cita en este
  addendum para dejar constancia de que el defecto que describe no se
  repitió en el procedimiento nuevo (ver sección de arriba).
- `SDD/briefs/R1-infra-accesos-lectura.md`: brief de una ronda anterior,
  histórico — no se edita.

Ningún símbolo de código ejecutable (`.js`) referencia estos dos `.sql`;
son artefactos de infraestructura que ejecuta una persona con
`sysadmin`, no el servidor MCP. Por eso no hay regresión de callers en
runtime que verificar con la suite — la suite de `SDD/tests/` (17
archivos) sigue verde sin cambios, como muestra el gate 4/suite completa
de arriba.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes desde el primer
commit de esta ronda (`fa86bc8`) hasta el commit sellado (`b9f203b`).

## Secret-scan sobre el árbol final ya commiteado (fuera del sellado del runner)

Este mismo archivo de verificación queda fuera del árbol que el runner
selló (el `Tree:` de la cabecera es anterior a este addendum). Corrida
sobre el árbol final, **después** de commitear el addendum de arriba
(commit `299091f`, árbol limpio confirmado con `git status --short` antes
de correr):

```
$ git rev-parse HEAD
299091fcf069a1d53c90cde533d5fee6f18eff23
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

Este párrafo final se agrega en un commit posterior a `299091f`, ya que
el propio archivo de evidencia no puede documentar su propio hash de
commit sin haberse commiteado primero — el mismo patrón en cascada que
`D34`/`D35` describen para este runner.

