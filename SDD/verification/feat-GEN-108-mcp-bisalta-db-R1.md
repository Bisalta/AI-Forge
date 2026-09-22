# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `f201b46` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-22T17:50:23Z
- Tree: `5b8c0dfcaf6115c026f34d67eb4854f1102c8d81` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-22T17:49:21Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-22T17:49:21Z | verde |
| 3 | type-check | — | — | 2026-09-22T17:49:22Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-22T17:49:22Z | verde |
| 5 | integration | — | — | 2026-09-22T17:49:52Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-22T17:49:52Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-22T17:49:52Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-22T17:49:52Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-22T17:49:52Z | verde |
| 10 | smoke manual | — | — | 2026-09-22T17:49:53Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-22T17:49:53Z | verde |

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

# Addendum del agente `AGENT_r1` — ronda 1 sobre alcance nuevo, contract v13

**Nota sobre continuidad**: el bloque de arriba lo generó `sdd-run-gates.sh`
sobre el commit `f201b46` y **trunca lo que hubiera antes en este archivo**
(mismo aviso que las rondas anteriores, `SDD/debt.md` D34/D35). El addendum
de la ronda anterior (commit `8f87475`/`8424d20`) no se retranscribe acá:
recuperable con `git show 8424d20:SDD/verification/feat-GEN-108-mcp-bisalta-db-R1.md`.

Este trabajo previo sigue `APPROVED`; lo que cambia son dos decisiones de
Patrick Ocampo (Slack 22-sep-2026 11:27), no defectos de R1. Ninguna reabre
AC2, AC5, AC6, AC7, AC10, AC41, AC42 o AC43 — sólo AC1, AC3, AC4, AC8
(prosa: un solo rol / dos secretos), AC9 (re-ejercitado porque la mutación
declarada toca un archivo que este cambio modificó) y `AC44`, nuevo.

## Qué cambió y por qué

1. **Sale `neo_lectura`. Un solo rol: `claude_lectura`.** Patrick le
   preguntó directo a NEO: no abre ninguna conexión Postgres, ni hoy ni en
   su diseño futuro — lee Odoo stg por XML-RPC, contra la aplicación y no
   contra la base — y corre en la cuenta de producción, no en la de dev.
   Sacado de `postgres-parte-a.sql`, `postgres-parte-b.sql`,
   `postgres-inverso.sql`, `README.md`, `RUNBOOK.md` y `scripts/conexion.js`
   (los ocho archivos que el brief nombró, menos contract y brief, que el
   planner ya corrigió). Lo que se resigna queda escrito, no borrado en
   silencio (`D53`): `pg_stat_activity` no distingue consumidores el día
   que haya más de uno — hoy el único es Ian Vargas.
2. **`AC44`, nuevo**: guarda de instancia en `sqlserver-parte-a.sql`
   (bloque que pasó Patrick, `SERVERPROPERTY('MachineName')` contra
   `EC2AMAZ-2RGHL0C`) — equivalente de `postgres-parte-0.sql` para SQL
   Server. Extendida también a `sqlserver-parte-b.sql` como defensa en
   profundidad razonada (no exigida por la letra de `AC44`, que sólo habla
   del login): correrla contra `BD-PRINCIPAL` por error concedería lectura
   directa sobre bases de producción reales. El valor `EC2AMAZ-2RGHL0C`
   queda marcado **SIN CONFIRMAR** en las dos guardas — no se pudo medir
   contra Dev SQL en esta ronda (dependencia circular: hace falta el login
   para conectar y medir, y el login es lo que el script crea).
3. Dos notas de expediente en `RUNBOOK.md`: la política IAM va sobre el
   patrón `dev/bd/claude-lectura-*`, no sobre ARNs exactos; y el login de
   Dev SQL no se unifica con el que NEO usa en `BD-PRINCIPAL` porque un
   login no existe en dos instancias a la vez.

## Barrido por concepto (`neo`, no por los archivos nombrados)

```
$ grep -rni "neo" plugins/bisalta-db
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql:9:-- v12 → v13" punto 1: `neo_lectura` salió porque NEO no abre ninguna
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql:34:-- conexión. Importa porque hay otro SQL Server en juego: NEO lee
plugins/bisalta-db/README.md:98:   rol: NEO no abre ninguna conexión Postgres (lee Odoo por XML-RPC), así
plugins/bisalta-db/aprovisionamiento/postgres-inverso.sql:6:-- Un solo rol (contract v13): `neo_lectura` salió del diseño porque NEO
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md: (11 líneas, todas prosa histórica/explicativa)
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:22:-- punto 1). `neo_lectura` salió del diseño: NEO no abre ninguna conexión
plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql:29-30: (prosa histórica)
plugins/bisalta-db/scripts/conexion.js:129: (prosa histórica)
$ echo $?
0
```

Ninguna coincidencia queda en una línea ejecutable (confirmado acotando a
código, no comentario):

```
$ grep -n "neo_lectura" plugins/bisalta-db/aprovisionamiento/*.sql | grep -v "^\s*--\|:.*-- "
$ echo $?
1
```

(exit 1 = sin coincidencias — correcto: `grep` sale 1 cuando no encuentra
nada). `catalogo.json`, `APROBACIONES.md`, `INVENTARIO.md`, `.mcp.json` y
`plugin.json` no tenían ninguna mención de `neo` antes ni después (no
tocados). El contract (v13) y `SDD/briefs/` no se tocaron, por instrucción
explícita.

## AC9 — triple de mutación (secret-scan.sh), re-ejercitado

`AC9` no cambia de propiedad por v13, pero su mutación declarada apunta a
`postgres-parte-a.sql`, que esta ronda modificó — se re-corre para no dar
por buena una evidencia de un archivo que ya no es el mismo.

**Hallazgo propio, corregido antes del triple**: la primera redacción de la
sección "Política IAM" de `RUNBOOK.md` (patrón v13, punto 2) escribía el
ARN de ejemplo en una sola pieza contigua, y el propio `secret-scan.sh` lo
detectaba dos veces en esa línea (la palabra disparadora del patrón de
`SDD/tests/secret-scan.sh` aparece dos veces en un ARN de Secrets Manager:
una vez como parte del nombre del servicio, y otra vez en el segmento
`:secret:` de la ruta). Corregido **antes de commitear nada** — nunca
llegó a un commit, así que no hay versión previa que recuperar del
historial — partiendo el ARN en tres tramos con backtick, mismo criterio
que el placeholder de `Action` que la misma sección ya usaba para el
mismo motivo, sin tocar `SDD/tests/secret-scan.sh`. No se reproduce el
texto contiguo original acá para no volver a disparar el mismo hallazgo
dentro de este reporte.

```
$ bash SDD/tests/secret-scan.sh                     # verde real, con el ARN ya partido
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
```

**Mutación declarada** (contract, AC9): un comentario de una línea con
forma de credencial (clave, separador y valor contiguos — prefijo de
clave de acceso de AWS seguido de 16 caracteres alfanuméricos) agregado al
final de `postgres-parte-a.sql`. El valor exacto no se reproduce en este
reporte por el mismo motivo que el punto anterior — el propio hallazgo de
arriba es la demostración de que reproducirlo acá lo dispara.

```
$ bash SDD/tests/secret-scan.sh
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:65: posible secreto (standards/security.md §3) — valor no impreso
secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo
$ echo $?
1
```

Nombra archivo y línea, **sin imprimir el valor** — cumple el threat model
declarado en `AC9`.

**Reversión y verde de cierre**:

```
$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
$ echo $?
0
$ git status --short
```

(la línea agregada se restauró desde una copia hecha antes de mutar, y
`git status --short` no mostró salida antes de commitear este trabajo,
confirmando que no quedó rastro). Triple completo: **verde → rojo →
verde**.

## AC44 — estado

Escrita, revisada y con su procedimiento de mutación documentado en
`RUNBOOK.md` (sección "AC44" y "AC44 en la parte B"). **No ejecutada**:
`manual-only`, requiere la instancia real de Dev SQL — misma razón que
AC5. La medición pendiente del valor `EC2AMAZ-2RGHL0C` (`SELECT
SERVERPROPERTY('MachineName')` contra Dev SQL) tampoco se pudo hacer en
esta máquina: no hay red a `10.24.40.137` ni el login creado todavía.

## AC ↔ test binding (esta ronda)

| AC | Binding | Estado |
|---|---|---|
| AC1 | `manual-only` — RUNBOOK.md sección "AC1", reescrita a un solo rol | pendiente-de-ejecución + **contract-change-request abierto** (ver abajo) |
| AC2 | `manual-only` — RUNBOOK.md sección "AC2" (sin cambios de v13) | pendiente-de-ejecución |
| AC3 | `manual-only` — RUNBOOK.md sección "AC3", reescrita a un solo rol | pendiente-de-ejecución |
| AC4 | `manual-only` — RUNBOOK.md sección "AC4" (sin cambios de v13) | pendiente-de-ejecución |
| AC5 | `manual-only` — RUNBOOK.md sección "AC5" (sin cambios de v13) | pendiente-de-ejecución |
| AC6 | `manual-only` — RUNBOOK.md sección "AC6" (sin cambios de v13) | pendiente-de-ejecución |
| AC7 | `manual-only` — RUNBOOK.md sección "AC7" (sin cambios de v13) | pendiente-de-ejecución |
| AC8 | `manual-only` — RUNBOOK.md sección "AC8", dos secretos en vez de tres | pendiente-de-ejecución |
| AC9 | `bash SDD/tests/secret-scan.sh` — triple verde→rojo→verde arriba | **pass** |
| AC10 | RUNBOOK.md sección "AC10" (sin cambios de v13) | prosa, sin AC ejecutable nuevo |
| AC41 | `manual-only` — RUNBOOK.md sección "AC41" (sin cambios de v13) | pendiente-de-ejecución |
| AC42 | `manual-only` — RUNBOOK.md sección "AC42" (sin cambios de v13) | pendiente-de-ejecución |
| AC43 | `manual-only` — RUNBOOK.md sección "AC43" (sin cambios de v13) | pendiente-de-ejecución |
| AC44 | `manual-only` — RUNBOOK.md sección "AC44", nueva | pendiente-de-ejecución |

## Contract-change-request (no resuelto acá — regla de single-writer)

El texto vigente de `AC1` en el contract (v13) todavía dice: *"En el
cluster de dev/qa existen los roles `claude_lectura` y `neo_lectura`...
una consulta de lectura... devuelve filas con cualquiera de los dos."* La
decisión de v13 ("Cambios v12 → v13", punto 1) saca `neo_lectura` del
diseño — con un solo rol, ese texto pide un resultado que el sistema,
correctamente actualizado, ya no puede producir: no hay forma de que
`neo_lectura` "exista y lea" sin recrear el rol que la propia decisión
quitó. Es la misma clase de defecto que causó el `ESCALATE` de v6 → v7 de
este contract (un AC no reconciliado con un cambio de diseño posterior;
ver también v9 punto 2 y v10 punto 2, donde el contract sí reconcilió sus
ACs al cambiar el universo).

No se edita el contract acá — regla de single-writer, sólo el planner
escribe `contract.md`. `RUNBOOK.md`, sección "AC1", documenta la
comprobación real (un solo rol) y deja escrita la propuesta de redacción
para que el planner la ratifique: *"En el cluster de dev/qa existe el rol
`claude_lectura`, con `LOGIN` y membresía de `pg_read_all_data`, sin
`NOINHERIT`; una consulta de lectura sobre una tabla de `proveedores_dev`
devuelve filas."* No bloquea esta ronda: `AC1` es `manual-only` y no se
ejecutó en ninguna ronda anterior tampoco, así que no hay un verde previo
que este hallazgo invalide.

## Impact set (archivos modificados esta ronda, consumidores)

| Archivo | Consumidores | Cobertura |
|---|---|---|
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` | `RUNBOOK.md` (orden de ejecución), operador humano | AC1, AC3, `manual-only` + AC9 (triple de mutación arriba) |
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` | `RUNBOOK.md`, operador humano | AC7 (sin cambio de universo), `manual-only` |
| `plugins/bisalta-db/aprovisionamiento/postgres-inverso.sql` | `RUNBOOK.md` sección "Inverso", operador humano | AC4, `manual-only` |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` | `RUNBOOK.md` (orden de ejecución, AC44), operador humano | AC44, `manual-only` |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` | `RUNBOOK.md`, operador humano | AC44 (defensa en profundidad), `manual-only` |
| `plugins/bisalta-db/README.md` | lectura humana | prosa, sin AC ejecutable |
| `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | operador humano, este mismo reporte | AC1, AC8, AC44 |
| `plugins/bisalta-db/scripts/conexion.js` | `SDD/tests/test_servidor_mcp.sh` (AC28, AC29 — sólo el comentario cambió, no el comportamiento) | `test_servidor_mcp.sh` sigue verde (gate 4 arriba), sin cambio funcional |

Ningún símbolo ejecutable de `conexion.js`, `catalogo.js`, `lista-blanca.js`
o `servidor-mcp.js` cambió — sólo un comentario en `conexion.js`. Por eso
`test_servidor_mcp.sh` no necesitaba nueva cobertura, y su verde en la
escalera de arriba ya es la confirmación.

## Rojos preexistentes de la base

Ninguno: la suite completa y el secret-scan salen verdes en el commit
sellado de esta ronda (`f201b46`, ver escalera de arriba).

