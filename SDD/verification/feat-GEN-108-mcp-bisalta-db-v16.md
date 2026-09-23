# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `ef47e82` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-23T18:19:27Z
- Tree: `3f078fec326c2afb26b1f1cc3de511e1be446c2e` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-23T18:18:28Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-23T18:18:28Z | verde |
| 3 | type-check | — | — | 2026-09-23T18:18:29Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-23T18:18:29Z | verde |
| 5 | integration | — | — | 2026-09-23T18:18:57Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-23T18:18:57Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-23T18:18:57Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-23T18:18:57Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-23T18:18:57Z | verde |
| 10 | smoke manual | — | — | 2026-09-23T18:18:58Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-23T18:18:58Z | verde |

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
secret-scan: sin hallazgos sobre 166 archivos versionados (1 excluido: self)
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

# Addendum de AGENT_r2 — contract v16 (NO lo escribió el runner)

Todo lo que sigue a esta línea lo escribió `AGENT_r2` (implementing agent, tier `opus`). Lo de arriba es del runner (`sdd-run-gates.sh --full`, exit 0, commit `ef47e82`, árbol `3f078fec` LIMPIO) y no se tocó.

- **Brief**: `SDD/briefs/R2-v16-guarda-replica-y-escritura-embebida.md` · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v16** · ACs: AC29 (parte `manual-only`), AC45a, AC45b, AC45c, AC46, AC47.
- **Commit de la implementación**: `ef47e82`. Este addendum y el reporte del runner van en un commit posterior, así que **quedan fuera del árbol que el runner selló** (misma situación que `D34`/`D35`).

## 1. Triples de mutación — salida literal del script, corrido una vez el 23-sep-2026

Cubre las trece mutaciones que el contract declara: AC45b (1)-(5), AC45c (a)-(b), AC46 (a)-(c), AC47 (a)-(c). Por cada una el script imprime el exit code de las tres corridas del archivo de test, el conteo `ok`/`FAIL` de los asserts de ese AC y el nombre de cada assert que cae. Aborta si una mutación no se aplicó (`git diff --quiet -- <archivo>` sale 0); la línea "mutación aplicada" muestra ese exit code (`1`) y las líneas tocadas. Restaura con `git checkout -- <archivo>` y al final exige árbol limpio.

Antes de la corrida medida hubo **una corrida en seco** (`SOLO_VERIFICAR=1`, el mismo script): no corre tests ni muta, sólo cuenta cuántas veces aparece el texto a mutar. Las trece dieron `1`. Se hizo para no gastar la única corrida medida en un patrón mal escrito.

Comando: `bash mutaciones-v16.sh` desde la raíz del repo (el script está en el §6). Exit del script: **0**.

```
HEAD: ef47e82

### AC45b (1) — se quita el chequeo de que la garantía sea un objeto
- verde (árbol real):  exit=0 ok=10 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/catalogo.js salió 1; +0 -4 líneas)
- rojo  (mutado):      exit=1 ok=9 fail=1
    FAIL  AC45b (1) el rechazo de la cadena suelta dice que tiene que ser un objeto — no encontré [tiene que ser un objeto] en la salida
- verde (restaurado):  exit=0 ok=10 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45b (2) — se quita el chequeo del enum de nivel
- verde (árbol real):  exit=0 ok=10 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/catalogo.js salió 1; +0 -4 líneas)
- rojo  (mutado):      exit=1 ok=8 fail=2
    FAIL  AC45b (2) el validador rechaza un nivel fuera del enum cerrado — esperado [distinto-de-cero], obtenido [cero]
    FAIL  AC45b (2) el rechazo del nivel inválido nombra el enum de nivel — no encontré [`nivel` tiene que ser uno de] en la salida
- verde (restaurado):  exit=0 ok=10 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45b (3) — se quita la regla 'condicional exige condicion'
- verde (árbol real):  exit=0 ok=10 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/catalogo.js salió 1; +0 -3 líneas)
- rojo  (mutado):      exit=1 ok=8 fail=2
    FAIL  AC45b (3) una garantía condicional sin declarar de qué depende se rechaza — esperado [distinto-de-cero], obtenido [cero]
    FAIL  AC45b (3) el rechazo nombra la condicion ausente — no encontré [condicion] en la salida
- verde (restaurado):  exit=0 ok=10 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45b (4) — se quita la regla 'incondicional no lleva condicion'
- verde (árbol real):  exit=0 ok=10 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/catalogo.js salió 1; +0 -3 líneas)
- rojo  (mutado):      exit=1 ok=8 fail=2
    FAIL  AC45b (4) una garantía incondicional que declara una condicion se contradice y se rechaza — esperado [distinto-de-cero], obtenido [cero]
    FAIL  AC45b (4) el rechazo dice que una incondicional no lleva condicion — no encontré [no lleva `condicion`] en la salida
- verde (restaurado):  exit=0 ok=10 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45b (5) — se quita el chequeo de campo desconocido en la garantía
- verde (árbol real):  exit=0 ok=10 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/catalogo.js salió 1; +0 -3 líneas)
- rojo  (mutado):      exit=1 ok=8 fail=2
    FAIL  AC45b (5) el validador rechaza un campo desconocido dentro de una garantía — esperado [distinto-de-cero], obtenido [cero]
    FAIL  AC45b (5) el rechazo nombra el campo desconocido — no encontré [campo desconocido: comentario] en la salida
- verde (restaurado):  exit=0 ok=10 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45c (a) — endpoint-replica-lectura declarado condicional en proveedores-dev
- verde (árbol real):  exit=0 ok=3 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/catalogo.json salió 1; +2 -1 líneas)
- rojo  (mutado):      exit=1 ok=2 fail=1
    FAIL  AC45c cada conexión Postgres declara el endpoint de réplica como su única garantía incondicional — esperado [ok], obtenido [mal:proveedores-dev]
- verde (restaurado):  exit=0 ok=3 fail=0
- triple: OK (verde -> rojo -> verde)

### AC45c (b) — la garantía de compras (SQL Server) declarada incondicional
- verde (árbol real):  exit=0 ok=3 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/catalogo.json salió 1; +1 -2 líneas)
- rojo  (mutado):      exit=1 ok=2 fail=1
    FAIL  AC45c ninguna conexión SQL Server declara una garantía incondicional — esperado [ok], obtenido [mal:compras]
- verde (restaurado):  exit=0 ok=3 fail=0
- triple: OK (verde -> rojo -> verde)

### AC46 (a) — se quita la guarda del comando
- verde (árbol real):  exit=0 ok=9 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/conexion.js salió 1; +1 -1 líneas)
- rojo  (mutado):      exit=1 ok=6 fail=3
    FAIL  AC46 el comando lleva exactamente dos --command — esperado [2], obtenido [1]
    FAIL  AC46 el primer --command es exactamente la guarda de réplica — esperado [DO $guarda$ BEGIN IF NOT pg_is_in_recovery() THEN RAISE EXCEPTION 'bisalta-db: la conexion no llego a una replica de lectura'; END IF; END $guarda$], obtenido [SELECT 42 AS valor_del_consumidor]
    FAIL  AC46 el segundo --command es el SQL del consumidor — esperado [SELECT 42 AS valor_del_consumidor], obtenido []
- verde (restaurado):  exit=0 ok=9 fail=0
- triple: OK (verde -> rojo -> verde)

### AC46 (b) — se quita --quiet
- verde (árbol real):  exit=0 ok=9 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/conexion.js salió 1; +1 -1 líneas)
- rojo  (mutado):      exit=1 ok=8 fail=1
    FAIL  AC46 el comando lleva --quiet (sin él psql imprime DO como primera línea del CSV) — esperado [si], obtenido [no]
- verde (restaurado):  exit=0 ok=9 fail=0
- triple: OK (verde -> rojo -> verde)

### AC46 (c) — se cambia el texto que el plugin reconoce para mapear a no_es_replica
- verde (árbol real):  exit=0 ok=9 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/conexion.js salió 1; +1 -1 líneas)
- rojo  (mutado):      exit=1 ok=4 fail=5
    FAIL  AC46 si la guarda falla, la respuesta tiene código 9 — no encontré ["codigo":9] en la salida
    FAIL  AC46 si la guarda falla, el error es no_es_replica — no encontré ["error":"no_es_replica"] en la salida
    FAIL  AC46 el error no_es_replica nombra la conexión — no encontré [proveedores-dev] en la salida
    FAIL  AC46 la bitácora registra el código 9 — no encontré ["codigo":9] en la salida
    FAIL  AC46 el proceso sale 9 cuando la conexión no llegó a una réplica (exit 9) — esperado [9], obtenido [6]
- verde (restaurado):  exit=0 ok=9 fail=0
- triple: OK (verde -> rojo -> verde)

### AC47 (a) — se quita el chequeo de palabras de escritura
- verde (árbol real):  exit=0 ok=32 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/lista-blanca.js salió 1; +0 -3 líneas)
- rojo  (mutado):      exit=1 ok=12 fail=20
    FAIL  AC47 rechaza en postgres un CTE con INSERT (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un CTE con INSERT tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en postgres un CTE con DELETE (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un CTE con DELETE tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en postgres un CTE con UPDATE (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un CTE con UPDATE tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en postgres un SELECT INTO (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un SELECT INTO tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en sqlserver un CTE seguido de DELETE (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en sqlserver de un CTE seguido de DELETE tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en sqlserver un CTE seguido de UPDATE (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en sqlserver de un CTE seguido de UPDATE tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en sqlserver un CTE seguido de INSERT (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en sqlserver de un CTE seguido de INSERT tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en sqlserver un CTE seguido de MERGE (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en sqlserver de un CTE seguido de MERGE tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en sqlserver un SELECT INTO (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en sqlserver de un SELECT INTO tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
    FAIL  AC47 rechaza en postgres un SELECT FOR UPDATE (rechazo de más, a sabiendas) (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un SELECT FOR UPDATE (rechazo de más, a sabiendas) tiene motivo escritura_embebida — no encontré ["motivo":"escritura_embebida"] en la salida
- verde (restaurado):  exit=0 ok=32 fail=0
- triple: OK (verde -> rojo -> verde)

### AC47 (b) — se quita el chequeo de set_config
- verde (árbol real):  exit=0 ok=32 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/lista-blanca.js salió 1; +0 -3 líneas)
- rojo  (mutado):      exit=1 ok=28 fail=4
    FAIL  AC47 rechaza en postgres un set_config que apaga la sesión de solo lectura (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un set_config que apaga la sesión de solo lectura tiene motivo funcion_prohibida — no encontré ["motivo":"funcion_prohibida"] en la salida
    FAIL  AC47 rechaza en postgres un set_config calificado con pg_catalog (exit 4) — esperado [4], obtenido [0]
    FAIL  AC47 el rechazo en postgres de un set_config calificado con pg_catalog tiene motivo funcion_prohibida — no encontré ["motivo":"funcion_prohibida"] en la salida
- verde (restaurado):  exit=0 ok=32 fail=0
- triple: OK (verde -> rojo -> verde)

### AC47 (c) — el chequeo de palabras corre sobre el SQL sin normalizar
- verde (árbol real):  exit=0 ok=32 fail=0
  (mutación aplicada: git diff --quiet -- plugins/bisalta-db/scripts/lista-blanca.js salió 1; +1 -1 líneas)
- rojo  (mutado):      exit=1 ok=30 fail=2
    FAIL  AC47 acepta en postgres un delete que sólo vive dentro de un literal (exit 0) — esperado [0], obtenido [4]
    FAIL  AC47 acepta en sqlserver un delete que sólo vive dentro de un literal (exit 0) — esperado [0], obtenido [4]
- verde (restaurado):  exit=0 ok=32 fail=0
- triple: OK (verde -> rojo -> verde)

Árbol al terminar: limpio
Triples rotos: 0
script exit=0
```

**Lectura**: los trece triples son verde → rojo → verde, las tres corridas se distinguen por exit code (`0` → `1` → `0`) y por el nombre del assert que cae. Cada mutación pone rojo el assert que el contract le asigna:

| Mutación del contract | Assert que el contract dice que se pone rojo | Cayó |
|---|---|---|
| AC45b (1) quitar el chequeo de objeto | el del mensaje `tiene que ser un objeto`, **no** el de `nivel` | sólo `AC45b (1) el rechazo de la cadena suelta dice que tiene que ser un objeto` — el exit distinto de cero se sostiene por otras reglas, que es exactamente lo que la review de v15 midió |
| AC45b (2)-(5) | el de su cláusula | los dos asserts de su cláusula (exit + mensaje) y ninguno de otra |
| AC45c (a) endpoint condicional en una entrada Postgres | el de Postgres | sólo `AC45c cada conexión Postgres …` (`mal:proveedores-dev`) |
| AC45c (b) incondicional en una entrada SQL Server | el de SQL Server | sólo `AC45c ninguna conexión SQL Server …` (`mal:compras`). **Ya existía un assert que la mata**, así que no se agregó uno nuevo (el brief lo pedía sólo si no existía) |
| AC46 (a) quitar la guarda | (b) | (b), y además "exactamente dos `--command`" y (c), que dependen del mismo orden |
| AC46 (b) quitar `--quiet` | (a) | sólo (a) |
| AC46 (c) cambiar el texto reconocido | (d) | los cinco asserts de (d); la respuesta cae a `conexion_fallida` (el CLI sale `6`) |
| AC47 (a) quitar el chequeo de palabras | el caso del CTE con `INSERT` | ese y todos los de `escritura_embebida` (20 asserts) |
| AC47 (b) quitar el chequeo de `set_config` | su caso | los dos casos de `set_config` (4 asserts) |
| AC47 (c) chequeo sobre SQL sin normalizar | `SELECT 'delete' AS x` | ese caso en los dos dialectos, y nada más |

**Cómo se aplicaron las dos mutaciones de AC45c**: la (a) cambia `nivel` a `condicional` **y agrega** una `condicion`; la (b) cambia `nivel` a `incondicional` **y quita** la `condicion`. Sin eso, el validador rechazaría el catálogo entero y caería también "el catálogo real que se distribuye con el plugin es válido", que no es lo que la mutación mide. La salida muestra que en los dos casos cayó un único assert.

## 2. Binding AC ↔ test

Nombres literales, tal como los imprime el harness. Las cantidades de asserts por AC salen de la columna `ok=` de la corrida verde del §1 (AC45b 10, AC45c 3, AC46 9, AC47 32).

| AC | Archivo | Asserts |
|---|---|---|
| AC29 (harness, sin cambios en v16) | `SDD/tests/test_servidor_mcp.sh` | "AC29 el comando lleva el usuario del secreto en PGAPPNAME" · "AC29 PGOPTIONS no lleva application_name (psql le gana al -c)" |
| AC29 (`manual-only`, v16) | — | §3.2 de este addendum, **con el servidor del repo** |
| AC45a | `SDD/tests/test_servidor_mcp.sh` | "AC45a listar_conexiones propaga el nivel de cada garantía" · "AC45a listar_conexiones distingue la garantía incondicional" |
| AC45b (1) | `SDD/tests/test_catalogo.sh` | "AC45b (1) el validador rechaza una garantía declarada como cadena suelta" · "AC45b (1) el rechazo de la cadena suelta dice que tiene que ser un objeto" |
| AC45b (2) | `SDD/tests/test_catalogo.sh` | "AC45b (2) el validador rechaza un nivel fuera del enum cerrado" · "AC45b (2) el rechazo del nivel inválido nombra el enum de nivel" |
| AC45b (3) | `SDD/tests/test_catalogo.sh` | "AC45b (3) una garantía condicional sin declarar de qué depende se rechaza" · "AC45b (3) el rechazo nombra la condicion ausente" |
| AC45b (4) | `SDD/tests/test_catalogo.sh` | "AC45b (4) una garantía incondicional que declara una condicion se contradice y se rechaza" · "AC45b (4) el rechazo dice que una incondicional no lleva condicion" |
| AC45b (5) | `SDD/tests/test_catalogo.sh` | "AC45b (5) el validador rechaza un campo desconocido dentro de una garantía" · "AC45b (5) el rechazo nombra el campo desconocido" |
| AC45c | `SDD/tests/test_catalogo.sh` | "AC45c (control) el catálogo real tiene conexiones Postgres y SQL Server que recorrer" · "AC45c cada conexión Postgres declara el endpoint de réplica como su única garantía incondicional" · "AC45c ninguna conexión SQL Server declara una garantía incondicional" |
| AC46 (a) | `SDD/tests/test_servidor_mcp.sh` | "AC46 el comando lleva --quiet (sin él psql imprime DO como primera línea del CSV)" |
| AC46 (b) | `SDD/tests/test_servidor_mcp.sh` | "AC46 el comando lleva exactamente dos --command" · "AC46 el primer --command es exactamente la guarda de réplica" |
| AC46 (c) | `SDD/tests/test_servidor_mcp.sh` | "AC46 el segundo --command es el SQL del consumidor" |
| AC46 (d) | `SDD/tests/test_servidor_mcp.sh` | "AC46 si la guarda falla, la respuesta tiene código 9" · "AC46 si la guarda falla, el error es no_es_replica" · "AC46 el error no_es_replica nombra la conexión" · "AC46 la bitácora registra el código 9" · "AC46 el proceso sale 9 cuando la conexión no llegó a una réplica (exit 9)" |
| AC46 (`manual-only`) | — | §3.1 de este addendum |
| AC47 rechazados, `postgres` | `SDD/tests/test_lista_blanca.sh` | por cada caso, dos asserts: "AC47 rechaza en postgres <caso> (exit 4)" y "AC47 el rechazo en postgres de <caso> tiene motivo <motivo>". Casos: "un CTE con INSERT", "un CTE con DELETE", "un CTE con UPDATE", "un SELECT INTO" (`escritura_embebida`); "un set_config que apaga la sesión de solo lectura", "un set_config calificado con pg_catalog" (`funcion_prohibida`); "un SELECT FOR UPDATE (rechazo de más, a sabiendas)" (`escritura_embebida`) |
| AC47 rechazados, `sqlserver` | `SDD/tests/test_lista_blanca.sh` | mismos dos asserts por caso. Casos: "un CTE seguido de DELETE", "un CTE seguido de UPDATE", "un CTE seguido de INSERT", "un CTE seguido de MERGE", "un SELECT INTO" (`escritura_embebida`) |
| AC47 aceptados | `SDD/tests/test_lista_blanca.sh` | "AC47 acepta en postgres el CTE de lectura de AC19 (exit 0)" · "AC47 acepta en sqlserver el CTE de lectura de AC19 (exit 0)" · "AC47 acepta en postgres un delete que sólo vive dentro de un literal (exit 0)" · "AC47 acepta en sqlserver un delete que sólo vive dentro de un literal (exit 0)" |
| AC47 "al final del recorrido" | `SDD/tests/test_lista_blanca.sh` | "AC47 un rechazo existente no cambia de motivo: un DELETE a secas sigue siendo no_empieza_con_select_ni_with" · "… una comilla de dólar con INTO sigue siendo comilla_de_dolar" · "… un EXEC con INSERT sigue siendo ejecucion_de_procedimiento" · "… un sp_ con DELETE sigue siendo procedimiento_de_sistema" |

## 3. Verificación contra el motor (`manual-only`) — 23-sep-2026, 18:22 UTC

**Con el servidor del repo, no con el plugin instalado**: `node plugins/bisalta-db/scripts/servidor-mcp.js` por stdio, sobre el commit `ef47e82`, alimentado con tramas JSON-RPC `tools/call` como las de `test_servidor_mcp.sh`. La verificación a través del plugin **instalado** (la que AC29 pide textualmente) la agrega el planner.

**Sólo lecturas**: `SELECT 1` y `SELECT current_setting('application_name')`. Ninguna sonda de escritura. La guarda es un bloque `DO` que sólo lee `pg_is_in_recovery()`.

El catálogo lo elige la variable `BISALTA_DB_CATALOGO` (leída en `servidor-mcp.js`, `rutaCatalogo()`); la bitácora, `BISALTA_DB_BITACORA`, que apunté al mismo directorio temporal para no mezclar estas corridas con la bitácora del plugin instalado. Directorio: `SDD/tests/.tmp/verificacion-motor-v16/` (gitignoreado), **borrado al terminar**. El catálogo temporal es una copia del real con un solo cambio, verificado con `diff`:

```
6c6
<     "host": "sistemas-costruplaza-db.cluster-ro-cfrl3owqzwof.us-east-1.rds.amazonaws.com",
---
>     "host": "sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com",
```

### 3.1 AC46 — writer contra réplica

Catálogo temporal (`proveedores-dev` → endpoint **de escritura**), `SELECT 1`, respuesta literal del servidor:

```
{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"{\n  \"error\": \"no_es_replica\",\n  \"codigo\": 9,\n  \"mensaje\": \"la conexión `proveedores-dev` no llegó a una réplica de lectura; la consulta no se ejecutó\"\n}"}],"isError":true}}
```

Bitácora de esa corrida:

```
{"ts":"2026-09-23T18:22:33.952Z","conexion":"proveedores-dev","dialecto":"postgres","hash_consulta":"sha256:e004ebd5b5532a4b","filas_devueltas":0,"truncado":false,"duracion_ms":1944,"codigo":9}
```

El mismo caso por el modo de una sola consulta (`--consultar proveedores-dev --sql 'SELECT 1'`), para ver el exit del proceso:

```
{
  "error": "no_es_replica",
  "codigo": 9,
  "mensaje": "la conexión `proveedores-dev` no llegó a una réplica de lectura; la consulta no se ejecutó"
}
(exit del proceso: 9)
```

Catálogo **real** (`cluster-ro-`), `SELECT 1`, respuesta literal:

```
{"jsonrpc":"2.0","id":2,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"proveedores-dev\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"?column?\": \"1\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
```

Contra la réplica la guarda es invisible: una sola fila, sin una fila `DO` por delante (lo que `--quiet` evita).

### 3.2 AC29 — `application_name` en las seis conexiones Postgres (servidor del repo)

`SELECT current_setting('application_name')`, catálogo real, respuestas literales:

```
-- proveedores-dev
{"jsonrpc":"2.0","id":11,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"proveedores-dev\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
-- proveedores-qa
{"jsonrpc":"2.0","id":12,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"proveedores-qa\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
-- smartcheck-dev
{"jsonrpc":"2.0","id":13,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"smartcheck-dev\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
-- smartcheck-qa
{"jsonrpc":"2.0","id":14,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"smartcheck-qa\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
-- smartfleet-dev
{"jsonrpc":"2.0","id":15,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"smartfleet-dev\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
-- smartfleet-qa
{"jsonrpc":"2.0","id":16,"result":{"content":[{"type":"text","text":"{\n  \"conexion\": \"smartfleet-qa\",\n  \"dialecto\": \"postgres\",\n  \"filas\": [\n    {\n      \"current_setting\": \"claude_lectura\"\n    }\n  ],\n  \"filas_devueltas\": 1,\n  \"truncado\": false,\n  \"motivo_truncado\": null\n}"}],"isError":false}}
```

Las seis devuelven `claude_lectura`. Que esas seis consultas pasaran también es evidencia de AC46 del lado positivo: las seis cruzaron la guarda, así que las seis sesiones cayeron en una réplica.

## 4. Impact set

Consumidores de cada símbolo cambiado, por `grep` sobre `plugins/` y `SDD/tests/` (sin `.tmp`):

| Símbolo / archivo | Cambio | Consumidores | Cobertura |
|---|---|---|---|
| `construirComandoPostgres` (`conexion.js`) | `--quiet` + guarda como primer `--command` | sólo `ejecutarConsulta` del mismo archivo (y su export, que no importa nadie más) | AC46 (a)-(c), AC23/AC28/AC29 siguen verdes |
| `ejecutarConsulta` (`conexion.js`) | nuevo `fallo(9, 'no_es_replica', …)`, clasificado antes del tiempo agotado y del genérico | `servidor-mcp.js::manejarConsultar`, que ya mapea cualquier `e.codigo` numérico a `cuerpoDeError(codigo, e.error, { mensaje })` — **no hizo falta tocarlo** | AC46 (d); tiempo agotado (código 7), `conexion_fallida` (6) y `cliente_ausente` (8) siguen verdes |
| `validarSql` (`lista-blanca.js`) | dos chequeos al final del recorrido | `servidor-mcp.js::manejarConsultar` y el CLI del mismo archivo | AC47; AC15-AC22 siguen verdes con el mismo motivo (los cuatro asserts de "no cambia de motivo") |
| `catalogo.json` | texto de `condicion` de `sesion-read-only` (6 entradas) | `catalogo.js`, `servidor-mcp.js`, `test_catalogo.sh`, `test_servidor_mcp.sh` (copia el catálogo), README, `aprovisionamiento/RUNBOOK.md` (lo nombra, no lo parsea) | "el catálogo real que se distribuye con el plugin es válido"; AC45a/AC45c |
| comentario de `catalogo.js`, README | prosa | lectura humana | sin test — es prosa |

**Rojos preexistentes**: ninguno medido. Antes de tocar nada corrí las tres suites del plugin sobre `5e13ef7`: `test_lista_blanca.sh` exit 0 (42 ok), `test_catalogo.sh` exit 0 (37 ok), `test_servidor_mcp.sh` exit 0 (98 ok). La suite completa no la corrí sobre la base: el único registro de la suite entera es el del runner, arriba, ya con los cambios.

**Piso bash 3.2** (el heredoc dentro de `$(...)` que arma `GUARDA_ESPERADA` es el punto frágil en 3.2): las tres suites del plugin corridas con `/bin/bash`, después del commit `ef47e82`:

```
GNU bash, version 3.2.57(1)-release (arm64-apple-darwin25)
test_lista_blanca (bash 3.2) exit=0 ok=74 fail=0
test_catalogo (bash 3.2) exit=0 ok=41 fail=0
test_servidor_mcp (bash 3.2) exit=0 ok=107 fail=0
  ok    AC46 el primer --command es exactamente la guarda de réplica
```

## 5. Decisiones de lectura que el reviewer tiene que ver

Ninguna reabre el contract, pero en las cuatro primeras elegí una lectura, y lo digo:

1. **`set_config` sin distinguir mayúsculas.** AC47 dice "sin distinguir mayúsculas" en la oración de `INSERT`/`UPDATE`/…; para `set_config` sólo dice "la palabra". Lo implementé **sin distinguir mayúsculas** (`/i`): un identificador sin comillas en Postgres no distingue mayúsculas, así que `SELECT SET_CONFIG(...)` es la misma llamada, y una barrera que distinguiera mayúsculas se saltaría con cambiarlas. **No agregué un caso de test para la mayúscula**, porque el contract no lo enumera. Si el planner quiere fijarlo, es un caso más en `test_lista_blanca.sh`.
2. **"Como palabra"** = delimitada por un carácter fuera de `[A-Za-z0-9_]` o por el borde. Es el mismo criterio que ya usaba la regla de `EXEC` del mismo archivo; no introduje uno nuevo.
3. **La clasificación de `no_es_replica`** exige `entrada.dialecto === 'postgres'` y `r.status !== 0`, además del mensaje en stderr: es la condición del AC ("si psql sale distinto de cero y su stderr contiene…"), y psql sólo se usa en Postgres. Va antes de los dos chequeos de tiempo agotado y del genérico, como pide el brief.
4. **El literal de la guarda y el texto reconocido son dos constantes distintas** (`GUARDA_REPLICA` y `MENSAJE_NO_REPLICA`), las dos copiadas del contract. Así la mutación (c) cambia **sólo** el texto reconocido, y no la guarda (si compartieran constante, la (c) pondría rojo también el (b)). Comparación carácter por carácter contra el bloque de código del contract: `conexion.js == contract` y `test == contract`.
5. **Asserts agregados más allá del mínimo del brief**, todos para que el AC quede cubierto entero: el mensaje en AC45b (2), (4) y (5) (el AC exige "un mensaje que nombra la regla" y antes sólo se miraba el exit); el control de conjunto no vacío en AC45c (sin él, un filtro por dialecto roto dejaría los dos asserts verdes sin mirar nada); "exactamente dos `--command`" y el exit 9 del proceso en AC46; el motivo de cada rechazo en AC47, los cuatro de "no cambia de motivo" (la cláusula "al final del recorrido") y el `FOR UPDATE` que el AC declara como rechazo de más.

**Fuera de mi lista de archivos, para el planner** (barrido por concepto del T5, `grep` de "incondicional", "empieza con", "SELECT o WITH" y "lista blanca" en `plugins/bisalta-db/`):

- `plugins/bisalta-db/scripts/servidor-mcp.js:224` — la descripción de la herramienta `consultar` que ve el modelo dice *"Rechaza cualquier sentencia que no empiece con SELECT o WITH"*, y la del parámetro `sql` (línea 230), *"SQL de solo lectura (SELECT o WITH)"*. No es falso —es una condición necesaria— pero **no menciona el rechazo de escrituras embebidas**, y es el texto que le dice al consumidor qué puede mandar.
- `plugins/bisalta-db/.claude-plugin/plugin.json:4` — la descripción dice *"lista blanca por dialecto anclada al principio de cada sentencia"*. Misma situación.
- `aprovisionamiento/*`: las apariciones de "incondicional" hablan del `DROP LOGIN` del inverso, no de niveles de garantía. No aplican.

Ninguno de los dos primeros está en la tabla "Files" del brief, así que no los toqué.

## 6. El script, para re-correrlo

Desde la raíz del repo, con el árbol limpio. `SOLO_VERIFICAR=1` hace la corrida en seco del §1.

```bash
#!/usr/bin/env bash
# Triples de mutación del contract v16: AC45b (1)-(5), AC45c (a)-(b),
# AC46 (a)-(c), AC47 (a)-(c). Cada mutación: verde -> rojo -> verde.
#
# Reglas (review de v15):
#  - cada mutación la aplica python3 con reemplazo EXACTO y exige una sola
#    coincidencia: si el texto a mutar no está, aborta (sin comillas de shell
#    que se coman caracteres, que es lo que pasó en v15);
#  - después de aplicarla, aborta si `git diff --quiet -- <archivo>` sale 0
#    (la mutación no se aplicó: el rojo sería una medición muerta);
#  - imprime el exit code de las tres corridas del test, el conteo ok/FAIL del
#    AC y el nombre de cada assert que cae;
#  - restaura con `git checkout -- <archivo>` y al final exige árbol limpio.
# Bash 3.2 compatible.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2

CON=plugins/bisalta-db/scripts/conexion.js
LB=plugins/bisalta-db/scripts/lista-blanca.js
VAL=plugins/bisalta-db/scripts/catalogo.js
CAT=plugins/bisalta-db/catalogo.json
SALIDA="$(mktemp -t mutaciones-v16)"
ROTOS=0

arbol_limpio() {
  git diff --quiet HEAD -- && [ -z "$(git status --porcelain -- plugins SDD/tests)" ]
}

if ! arbol_limpio; then
  echo "ABORTO: el árbol no está limpio antes de empezar"; exit 2
fi
echo "HEAD: $(git rev-parse --short HEAD)"
echo

# corre <test>, deja su salida en $SALIDA y devuelve su exit code
correr() { bash "SDD/tests/$1" > "$SALIDA" 2>&1; }

# imprime "exit=E ok=N fail=M" para el prefijo de AC $1 sobre $SALIDA
cuenta() {
  printf 'ok=%s fail=%s' "$(grep -cE "^  ok +$1 " "$SALIDA")" "$(grep -cE "^  FAIL +$1 " "$SALIDA")"
}

# aplica: python3 reemplaza EXACTAMENTE una aparición de $2 por $3 en $1
aplicar() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys
p, viejo, nuevo = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(p, encoding='utf-8').read()
n = s.count(viejo)
if n != 1:
    sys.stderr.write('el texto a mutar aparece %d veces en %s (esperaba 1)\n' % (n, p))
    sys.exit(3)
open(p, 'w', encoding='utf-8').write(s.replace(viejo, nuevo, 1))
PY
}

# triple <titulo> <test> <prefijo AC> <archivo> <viejo> <nuevo>
# Con SOLO_VERIFICAR=1 no corre tests ni muta: sólo comprueba que el texto a
# mutar aparezca exactamente una vez (chequeo en seco, previo a la corrida).
triple() {
  local titulo="$1" test="$2" ac="$3" archivo="$4" viejo="$5" nuevo="$6"
  local e1 e2 e3 f2
  if [ "${SOLO_VERIFICAR:-0}" = "1" ]; then
    printf '%s: %s\n' "$(python3 -c 'import sys;print(open(sys.argv[1],encoding="utf-8").read().count(sys.argv[2]))' "$archivo" "$viejo")" "$titulo"
    return 0
  fi
  echo "### $titulo"
  correr "$test"; e1=$?
  echo "- verde (árbol real):  exit=$e1 $(cuenta "$ac")"
  if ! aplicar "$archivo" "$viejo" "$nuevo"; then
    echo "ABORTO: la mutación no se pudo aplicar en $archivo"; git checkout -q -- "$archivo"; exit 3
  fi
  if git diff --quiet -- "$archivo"; then
    echo "ABORTO: git diff --quiet -- $archivo salió 0 — la mutación NO se aplicó"; exit 3
  fi
  echo "  (mutación aplicada: git diff --quiet -- $archivo salió $(git diff --quiet -- "$archivo"; echo $?); $(git diff --numstat -- "$archivo" | awk '{print "+"$1" -"$2}') líneas)"
  correr "$test"; e2=$?
  f2="$(grep -cE "^  FAIL +$ac " "$SALIDA")"
  echo "- rojo  (mutado):      exit=$e2 $(cuenta "$ac")"
  grep -E "^  FAIL +$ac " "$SALIDA" | sed 's/^  /    /'
  git checkout -q -- "$archivo"
  correr "$test"; e3=$?
  echo "- verde (restaurado):  exit=$e3 $(cuenta "$ac")"
  if [ "$e1" -eq 0 ] && [ "$e2" -ne 0 ] && [ "$f2" -gt 0 ] && [ "$e3" -eq 0 ]; then
    echo "- triple: OK (verde -> rojo -> verde)"
  else
    echo "- triple: ROTO"; ROTOS=$((ROTOS + 1))
  fi
  echo
}

NL='
'

# --- AC45b: cada cláusula del validador ------------------------------------
triple "AC45b (1) — se quita el chequeo de que la garantía sea un objeto" test_catalogo.sh AC45b "$VAL" \
"        if (garantia === null || typeof garantia !== 'object' || Array.isArray(garantia)) {${NL}          problemas.push(donde + ': tiene que ser un objeto con \`nombre\` y \`nivel\`');${NL}          continue;${NL}        }${NL}" ""

triple "AC45b (2) — se quita el chequeo del enum de nivel" test_catalogo.sh AC45b "$VAL" \
"        if (NIVELES.indexOf(garantia.nivel) === -1) {${NL}          problemas.push(donde + ': \`nivel\` tiene que ser uno de ' + NIVELES.join(', '));${NL}          continue;${NL}        }${NL}" ""

triple "AC45b (3) — se quita la regla 'condicional exige condicion'" test_catalogo.sh AC45b "$VAL" \
"        if (garantia.nivel === 'condicional' && !esCadenaNoVacia(garantia.condicion)) {${NL}          problemas.push(donde + ': una garantía \`condicional\` tiene que declarar \`condicion\`');${NL}        }${NL}" ""

triple "AC45b (4) — se quita la regla 'incondicional no lleva condicion'" test_catalogo.sh AC45b "$VAL" \
"        if (garantia.nivel === 'incondicional' && garantia.condicion !== undefined) {${NL}          problemas.push(donde + ': una garantía \`incondicional\` no lleva \`condicion\`');${NL}        }${NL}" ""

triple "AC45b (5) — se quita el chequeo de campo desconocido en la garantía" test_catalogo.sh AC45b "$VAL" \
"          if (CAMPOS_GARANTIA.indexOf(claves[k]) === -1) {${NL}            problemas.push(donde + ': campo desconocido: ' + claves[k]);${NL}          }${NL}" ""

# --- AC45c: el catálogo distribuido -----------------------------------------
# (a) proveedores-dev: el endpoint pasa a condicional. Se le agrega una
# condicion para que el catálogo siga siendo VÁLIDO: así el único assert que
# puede caer es el de AC45c, no el de "el catálogo real es válido".
triple "AC45c (a) — endpoint-replica-lectura declarado condicional en proveedores-dev" test_catalogo.sh AC45c "$CAT" \
"    \"base\": \"proveedores_dev\",${NL}    \"secret_id\": \"dev/bd/claude-lectura-postgres\",${NL}    \"region\": \"us-east-1\",${NL}    \"garantias\": [${NL}      {${NL}        \"nombre\": \"endpoint-replica-lectura\",${NL}        \"nivel\": \"incondicional\"${NL}      },${NL}" \
"    \"base\": \"proveedores_dev\",${NL}    \"secret_id\": \"dev/bd/claude-lectura-postgres\",${NL}    \"region\": \"us-east-1\",${NL}    \"garantias\": [${NL}      {${NL}        \"nombre\": \"endpoint-replica-lectura\",${NL}        \"nivel\": \"condicional\",${NL}        \"condicion\": \"mutacion\"${NL}      },${NL}"

# (b) compras: la única garantía pasa a incondicional. Se le quita la
# condicion por la misma razón: una incondicional con condicion la rechazaría
# el validador y caería otro assert.
triple "AC45c (b) — la garantía de compras (SQL Server) declarada incondicional" test_catalogo.sh AC45c "$CAT" \
"    \"base\": \"COMPRAS\",${NL}    \"secret_id\": \"dev/bd/claude-lectura-sqlserver\",${NL}    \"region\": \"us-east-1\",${NL}    \"garantias\": [${NL}      {${NL}        \"nombre\": \"rol-solo-lectura\",${NL}        \"nivel\": \"condicional\",${NL}        \"condicion\": \"db_datareader es la única barrera. Sin db_denydatawriter no queda un DENY que anule un GRANT de escritura concedido por error en el futuro (contract v10, deuda D48).\"${NL}" \
"    \"base\": \"COMPRAS\",${NL}    \"secret_id\": \"dev/bd/claude-lectura-sqlserver\",${NL}    \"region\": \"us-east-1\",${NL}    \"garantias\": [${NL}      {${NL}        \"nombre\": \"rol-solo-lectura\",${NL}        \"nivel\": \"incondicional\"${NL}"

# --- AC46: la guarda de réplica ---------------------------------------------
triple "AC46 (a) — se quita la guarda del comando" test_servidor_mcp.sh AC46 "$CON" \
"      '--command', GUARDA_REPLICA, '--command', sql, conninfo]," \
"      '--command', sql, conninfo],"

triple "AC46 (b) — se quita --quiet" test_servidor_mcp.sh AC46 "$CON" \
"'--csv', '--quiet', '--variable=ON_ERROR_STOP=1'," \
"'--csv', '--variable=ON_ERROR_STOP=1',"

triple "AC46 (c) — se cambia el texto que el plugin reconoce para mapear a no_es_replica" test_servidor_mcp.sh AC46 "$CON" \
"const MENSAJE_NO_REPLICA = 'bisalta-db: la conexion no llego a una replica de lectura';" \
"const MENSAJE_NO_REPLICA = 'bisalta-db: la sesion no llego a una replica';"

# --- AC47: escritura embebida y set_config ----------------------------------
triple "AC47 (a) — se quita el chequeo de palabras de escritura" test_lista_blanca.sh AC47 "$LB" \
"    if (ESCRITURA_EMBEBIDA.test(sentencia)) {${NL}      return rechazo('escritura_embebida', sentencia);${NL}    }${NL}" ""

triple "AC47 (b) — se quita el chequeo de set_config" test_lista_blanca.sh AC47 "$LB" \
"    if (dialecto === 'postgres' && FUNCION_PROHIBIDA_POSTGRES.test(sentencia)) {${NL}      return rechazo('funcion_prohibida', sentencia);${NL}    }${NL}" ""

triple "AC47 (c) — el chequeo de palabras corre sobre el SQL sin normalizar" test_lista_blanca.sh AC47 "$LB" \
"    if (ESCRITURA_EMBEBIDA.test(sentencia)) {" \
"    if (ESCRITURA_EMBEBIDA.test(sql)) {"

rm -f "$SALIDA"
if arbol_limpio; then echo "Árbol al terminar: limpio"; else echo "Árbol al terminar: SUCIO"; ROTOS=$((ROTOS + 1)); fi
echo "Triples rotos: $ROTOS"
[ "$ROTOS" -eq 0 ]
```
