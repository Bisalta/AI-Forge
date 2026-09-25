# Task brief — R2 reabierto (v16) · guarda de réplica, escritura embebida y AC45 partido

- **Agente**: `AGENT_r2` · **Modelo**: `opus` (código de seguridad: la lista blanca y la guarda son las barreras de entrada)
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v16**, ACs **AC29** (parte `manual-only`), **AC45a**, **AC45b**, **AC45c**, **AC46**, **AC47**
- **Arquetipo**: `third-party-integration`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya existe; **NO crear otra, NO commitear a `prod`**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md` (archivo nuevo; **no toques** el de v15 ni los de R1/R2 — son evidencia fechada)

## Problema

Leé primero, entera, la sección **"Cambios v15 → v16"** del contract. En corto: la lista blanca aceptaba escrituras dentro de un `WITH` en los dos dialectos (y `SELECT … INTO`, y `set_config`); el endpoint de réplica se declaraba incondicional sin que nada lo comprobara; `AC45` tenía dos mutaciones para siete cláusulas.

## Decisión de diseño (cerrada en el contract — no la re-abras)

Todo está en el texto de los ACs. En particular, **el literal de la guarda de AC46 y el texto del mensaje que se reconoce son exactos**: copialos del contract carácter por carácter. Si algo te parece ambiguo, **no elijas**: devolvé `BLOCKED` con la pregunta (orchestration.md). La ambigüedad resuelta por el implementador es exactamente lo que este ciclo no puede permitirse.

## Files — lo único que tocás

| Archivo | Para qué |
|---|---|
| `plugins/bisalta-db/scripts/conexion.js` | AC46: `--quiet`, la guarda como primer `--command`, el SQL del consumidor como segundo, y el mapeo a `fallo(9, 'no_es_replica', …)`. **El chequeo del mensaje de la guarda va primero** en la clasificación del error de psql, antes del de timeout y del genérico `conexion_fallida` |
| `plugins/bisalta-db/scripts/lista-blanca.js` | AC47: los dos chequeos, **al final** del recorrido por sentencia, después de todos los existentes |
| `plugins/bisalta-db/scripts/catalogo.js` | sólo el comentario que define los niveles: reemplazar la definición de v15 por el criterio cerrado de v16 |
| `plugins/bisalta-db/catalogo.json` | el texto de `condicion` de `sesion-read-only` en las seis entradas Postgres: tiene que decir que el plugin no la comprueba, que dentro de una llamada no se puede apagar (medido 23-sep: `transaction read-write mode must be set before any query`) y que el rol la tiene además fijada por `ALTER ROLE`. **Nada más del catálogo cambia** |
| `plugins/bisalta-db/README.md` | la tabla de niveles (hoy línea ~150, definición de v15), la tabla "Garantías por motor", la tabla de errores (código 9), y toda descripción de la lista blanca que diga o implique que alcanza con "empieza con `SELECT`/`WITH`" |
| `SDD/tests/test_servidor_mcp.sh` | AC46 (ver "Pasos"), y renombrar los asserts `AC45 …` a `AC45a …` |
| `SDD/tests/test_lista_blanca.sh` | AC47: todos los casos que el AC enumera, rechazados y aceptados |
| `SDD/tests/test_catalogo.sh` | renombrar a `AC45b …`/`AC45c …`; el assert de la cadena suelta pasa a mirar el mensaje `tiene que ser un objeto`; un assert nuevo para la mutación (b) de AC45c (SQL Server incondicional) si hoy no existe uno que la mate |
| `SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md` | la evidencia |

**No tocás**: el contract (single-writer: planner), `plugins/bisalta-db/aprovisionamiento/*`, `SDD/retro.md`, `SDD/debt.md`, `SDD/escalations.md`, `SDD/FEATURE-READY-GEN-108.md`, `CHANGELOG.md`, `SDD/tests/lib.sh`.

## Pasos

- [x] **T1** Leer el contract v16 (Cambios v15→v16 y los ACs de arriba), `quality-gates.md` §5, §6, §10 y §10.1.
- [x] **T2** AC47 en `lista-blanca.js` + sus casos en `test_lista_blanca.sh`. Correr la suite.
- [x] **T3** AC46 en `conexion.js`. En el stub de psql de `test_servidor_mcp.sh`: (a) agregar un registro **por argumento** (una línea por arg) **sin quitar** la línea `ARGS` existente, para poder assertar el orden exacto de los dos `--command`; (b) un modo `no-replica` de `BISALTA_STUB_PSQL_MODO` que escribe en stderr `ERROR:  bisalta-db: la conexion no llego a una replica de lectura` y sale 1. Asserts (a)–(d) del AC. Correr la suite.
- [x] **T4** AC45a/b/c: renombres y el assert nuevo sobre el mensaje. Correr la suite.
- [x] **T5** README, `catalogo.json`, comentario de `catalogo.js`. Barrido **por concepto**, no por nombre: `grep` de "incondicional", "empieza con", "SELECT o WITH", "lista blanca" en `plugins/bisalta-db/` y revisar cada aparición contra v16.
- [x] **T6** Commit (convención del repo, `[FIX] [GEN-108] [bisalta-db] …`). Árbol limpio.
- [x] **T7** Evidencia, en este orden:
  1. `bash plugins/sdd-flow/scripts/sdd-run-gates.sh -o SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md --full` sobre el árbol limpio. Exit 0 esperado.
  2. **Script de mutación**, versionado en el addendum (§ al final) y corrido **una sola vez**, con su salida pegada entera. Requisitos, todos obligatorios — la review de v15 los marcó uno por uno:
     - cubre **todas** las mutaciones declaradas: AC45b (1)–(5), AC45c (a)–(b), AC46 (a)–(c), AC47 (a)–(c);
     - después de aplicar cada mutación, **aborta** si `git diff --quiet -- <archivo>` sale 0 (la mutación no se aplicó). Una corrida "roja" sin mutación aplicada es una medición muerta (`RT11`, y pasó en v15);
     - imprime el **exit code** de cada una de las tres corridas del test (verde, rojo, verde), además del conteo `ok`/`FAIL` y el nombre de cada assert que cae;
     - restaura con `git checkout -- <archivo>` y al final exige árbol limpio.
  3. **Tabla de binding AC ↔ test** en el addendum: por cada AC del alcance, el nombre literal de cada assert y su archivo.
  4. **Verificación contra el motor (`manual-only`)** — la podés correr, con estos límites:
     - **Sólo lecturas**: `SELECT 1` y `SELECT current_setting('application_name')`. **Ninguna sonda de escritura**, ni siquiera con `WHERE false`: las que hacían falta ya las corrió el planner con autorización del usuario.
     - AC46: el servidor **del repo** (`node plugins/bisalta-db/scripts/servidor-mcp.js` por stdio, JSON-RPC como en `test_servidor_mcp.sh`) con un catálogo temporal (`BISALTA_DB_CATALOGO` o el mecanismo que el servidor use — leelo, no lo supongas) cuya entrada `proveedores-dev` apunta al endpoint de escritura: `cluster-` en lugar de `cluster-ro-`. `SELECT 1` → `no_es_replica`, código 9. Y con el catálogo real, `SELECT 1` → filas. Pegá **las dos respuestas literales**.
     - AC29: con el mismo servidor del repo, `SELECT current_setting('application_name')` en cada una de las seis conexiones Postgres. Pegá las seis respuestas. (La verificación a través del plugin **instalado** la agrega el planner: el tuyo es el servidor del repo, y el addendum lo tiene que decir así.)
     - El catálogo temporal va en `SDD/tests/.tmp/` o en `$TMPDIR`, **nunca versionado**, y se borra al terminar.
  5. Commit de la evidencia.

## Reglas innegociables

- **Mitigaciones prohibidas** (`quality-gates.md` §6): no ablandes un test, no bajes `--severity` de shellcheck, no uses `--no-verify` (el hook `guard-git.sh` lo bloquea igual), no metas una exclusión por path en el secret-scan.
- **Ninguna dependencia nueva.**
- Bash 3.2 es el piso de los `.sh`.
- **Un literal con forma de credencial** en un archivo hace que el secret-scan se detecte a sí mismo: armá esos strings en piezas, como ya hace el repo.
- **No declares una validación que no corriste.** Cada cifra del addendum sale de una salida pegada, no de tu resumen.
- **Nunca** imprimas, loguees ni pegues la contraseña del secreto ni el contenido del archivo de credenciales.

## Rollback

`git revert` de tus commits. No creás estado externo: las verificaciones en vivo son lecturas.

## Retorno

El último bloque de tu respuesta es el JSON `sdd.result` de `plugins/sdd-flow/standards/orchestration.md` §2, con `status` `done` o `blocked`.

## Execution Report

- **Agente**: `AGENT_r2` · tier `opus` · contract **v16 con la enmienda del planner `164d91e`**.
- **Tasks**: 7 total · 7 completadas · 0 bloqueadas · 0 salteadas. Más la enmienda pedida por el planner (caso `SET_CONFIG`, descripciones de `consultar`/`sql` y de `plugin.json`), completada.
- **Commits**: `ef47e82` (implementación de v16) · `a3a5238` (primera evidencia, sobre `ef47e82`, **reemplazada**) · `7516bad` (enmienda) · y el commit de evidencia que reescribe `SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md` sobre `7516bad` y este Execution Report.
- **Gates**: `sdd-run-gates.sh --full` sobre `7516bad` con árbol limpio (`7fb66beb`), exit 0 (lint, unit tests, security y suite completa en verde; el resto `[SKIPPED]` por el propio doc de gates). Detalle en la parte del runner del report; no se duplica acá.
- **Triples de mutación**: las trece mutaciones declaradas (AC45b 1-5, AC45c a-b, AC46 a-c, AC47 a-c), vueltas a correr enteras sobre `7516bad`: verde → rojo → verde, con exit code por corrida. La (b) de AC47 tumba también el caso nuevo `SET_CONFIG`. Salida y script en el §1 y el §6 del addendum.
- **`manual-only`**: AC46 (writer → `no_es_replica` código 9, exit del proceso 9; réplica → filas) y AC29 (seis de seis `claude_lectura`), con el servidor del repo, **de la corrida sobre `ef47e82`**: no se repitieron porque la enmienda no toca `conexion.js` ni la guarda (indicación del planner). La verificación de AC29 por el plugin instalado queda para el planner. §3 del addendum.
- **Files changed**: `plugins/bisalta-db/scripts/conexion.js`, `plugins/bisalta-db/scripts/lista-blanca.js`, `plugins/bisalta-db/scripts/catalogo.js` (sólo comentario), `plugins/bisalta-db/catalogo.json` (sólo `condicion` de `sesion-read-only`, seis entradas), `plugins/bisalta-db/README.md`, `plugins/bisalta-db/scripts/servidor-mcp.js` (sólo las dos `description`, enmienda), `plugins/bisalta-db/.claude-plugin/plugin.json` (sólo `description`, enmienda), `SDD/tests/test_servidor_mcp.sh`, `SDD/tests/test_lista_blanca.sh`, `SDD/tests/test_catalogo.sh`, `SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md`, y este brief (Execution Report).
- **Dependencias nuevas**: ninguna.
- **Abierto**: nada. Las dos preguntas de la primera entrega las cerró el planner en `164d91e`.
