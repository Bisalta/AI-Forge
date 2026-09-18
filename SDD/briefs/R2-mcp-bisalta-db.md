# Task brief — R2 · third-party-integration: plugin `bisalta-db`

- **Agente**: `AGENT_r2` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v1**, ACs **AC11–AC40**
- **Arquetipo**: `third-party-integration`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya creada; **NO crear otra, NO commitear a `prod`**)
- **Proxima subtask**: `GEN-108.2`, id `ef6a48da-28b2-4877-b041-7e58c4fb633a` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md`
- **Depende de**: R1 `APPROVED` (mismo repo, mismo working tree — corren en serie, nunca a la vez)

## Problema

Para que Claude consulte una base hoy hay que leerle el archivo con la cadena de conexión, y todo lo que lee queda en el transcript: la contraseña de un usuario con permisos de escritura termina archivada. Claude Code lo bloquea con su clasificador de materialización de credenciales, y hace bien.

El paquete que resolvería esto no sirve: `@modelcontextprotocol/server-postgres` está **deprecado desde 2025 y tiene inyección SQL que se salta su propio modo de solo lectura** — pasa el SQL sin parametrizar y permite salir de la transacción read-only para ejecutar DDL/DML con todos los privilegios de la conexión. Sigue con ~21k descargas semanales.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **Cero dependencias npm.** JSON-RPC 2.0 sobre stdio escrito a mano; `psql`, `sqlcmd` y `aws` invocados como CLI. **No crees `package.json`, no corras `npm install`, no uses `npx`.** El precedente del repo es `plugins/usage-monitor/scripts/parse-usage-log.js`: Node plano, probado desde el harness bash.
2. **Lista blanca, no lista negra, y anclada al principio de la sentencia.** Un bloque `DO` puede hacer cualquier cosa y una lista negra lo deja pasar entero. Y la palabra tiene que estar **al principio**: la versión laxa pasaba once de los doce tests originales, y el caso que la mató fue `DELETE … WHERE id IN (SELECT …)`.
3. **Una lista blanca por dialecto.** Un mismo patrón estaría mal en alguna dirección.
4. **Producción irrepresentable, no rechazada.** `ambiente` admite `dev` y `qa` y nada más. Rechazar por nombre es red, no barrera.
5. **La credencial nunca por `argv`.** Postgres: archivo temporal en modo 600 apuntado por `PGPASSFILE`, borrado en un `finally`. SQL Server: `SQLCMDPASSWORD` acotada al proceso hijo. **Prohibidos `PGPASSWORD`, `PGUSER`, `PGHOST`, `--username`, `--host` y `-P `** — es la invariante que los tests de `Proveedores-Back` ya fijaban.
6. **El catálogo no tiene usuario ni contraseña.** Los dos salen del secreto, en la forma estándar de RDS.

## Material de referencia

La lógica de seguridad **ya existe y está probada**. Portala, no la reinventes. Vive en `Bisalta/Proveedores-Back`, rama `feat-PROV-131-api-comprassync` (otro repo, clonado en `../Proveedores-Back`):

- `scripts/consulta-lectura.sh` — la normalización (quitar comentarios de bloque, de línea y literales), la partición en sentencias y el anclaje.
- `tests/consultaLecturaWrapper.test.mjs` — **los doce casos, incluidos los cinco de subconsulta**. Portalos literal; son AC15–AC19.
- `scripts/CONSULTA-LECTURA.md` — por qué cada capa.

## Out of scope

- Escritura de cualquier tipo, y ampliar la lista blanca para permitirla.
- Auditoría por consulta (Lambda + API Gateway + Cognito): descartada por desproporcionada.
- Rotación de la bitácora local: sólo se agrega. Va al ledger de deuda.
- Tocar `plugins/bisalta-db/aprovisionamiento/` — es de R1, ya `APPROVED`.
- Agregar cualquier dependencia de paquete. El contract no autoriza ninguna.

## Files

| Archivo | Acción |
|---|---|
| `plugins/bisalta-db/.claude-plugin/plugin.json` | crear — SemVer `0.1.0` |
| `plugins/bisalta-db/.mcp.json` | crear — declaración del servidor stdio |
| `plugins/bisalta-db/catalogo.json` | crear — entradas de `proveedores_dev` y `proveedores_qa` (Postgres) y de `Dev SQL` (SQL Server) |
| `plugins/bisalta-db/scripts/servidor-mcp.js` | crear — bucle JSON-RPC y despacho |
| `plugins/bisalta-db/scripts/lista-blanca.js` | crear — port de la validación, por dialecto |
| `plugins/bisalta-db/scripts/catalogo.js` | crear — lectura y validación del catálogo |
| `plugins/bisalta-db/scripts/conexion.js` | crear — secreto y cliente CLI |
| `plugins/bisalta-db/README.md` | crear |
| `SDD/tests/test_lista_blanca.sh` | crear |
| `SDD/tests/test_catalogo.sh` | crear |
| `SDD/tests/test_servidor_mcp.sh` | crear |
| `.claude-plugin/marketplace.json` | modificar — quinta entrada |
| `CHANGELOG.md` | modificar — entrada al tope |
| `SDD/docs/doc_quality_gates.md` | modificar — glob del gate 2 y prerequisito de `shellcheck` |
| `SDD/docs/doc_architecture.md` | modificar — layout y reglas de ubicación |

Los tests viven **sólo** en `SDD/tests/` e invocan los scripts por su path completo, desde afuera. Los asserts salen **únicamente** de `SDD/tests/lib.sh`.

## Pasos

- [ ] T1.1 Verificar `shellcheck` instalado; si falta, `brew install shellcheck`. Sin él el gate 2 nunca sale verde.
- [ ] T1.2 **Verificar cómo un plugin de Claude Code declara un servidor MCP stdio** (ningún plugin de este repo lo hace todavía) y dejarlo escrito en el README. Si no lo podés verificar contra documentación, marcá `[BLOCKED]` y preguntá — **no lo inventes**.
- [ ] T2.1 Escribir `lista-blanca.js`: normalizar, partir en sentencias, validar por dialecto. Exporta una función que recibe el SQL y el dialecto y devuelve el veredicto.
- [ ] T2.2 Escribir `test_lista_blanca.sh` portando los doce casos, más los del dialecto `sqlserver` y el de sensibilidad entre dialectos. **AC15–AC22.**
- [ ] T2.3 Correr los triples de mutación de AC15, AC16, AC17, AC20, AC21 y AC22 — las seis mutaciones están declaradas literal en el contract. Registrar las tres corridas de cada una.
- [ ] T3.1 Escribir `catalogo.js` con el validador del contrato de datos (rechaza campo desconocido, campo faltante, `ambiente` fuera de `dev`/`qa`, `garantias` vacío, host de producción).
- [ ] T3.2 Escribir `catalogo.json` con las tres entradas y sus `garantias` reales — Postgres lleva las tres, SQL Server lleva sólo `rol-solo-lectura`.
- [ ] T3.3 Escribir `test_catalogo.sh`. **AC11–AC14.**
- [ ] T3.4 Correr los triples de mutación de AC11, AC12, AC13 y AC14.
- [ ] T4.1 Escribir `conexion.js`: resolver el secreto con `aws`, armar el comando del cliente, entregar la credencial por `PGPASSFILE` o `SQLCMDPASSWORD`, borrar el temporal en un `finally`.
- [ ] T4.2 Escribir `servidor-mcp.js`: handshake `initialize`, `tools/list`, `tools/call` para `consultar` y `listar_conexiones`, topes de filas y bytes, bitácora, y la tabla de exit codes del contract.
- [ ] T4.3 Escribir `test_servidor_mcp.sh` alimentando stdin con tramas JSON-RPC y afirmando sobre stdout. **AC23–AC37.**
- [ ] T4.4 Correr los triples de mutación de AC23, AC24, AC25, AC31, AC33 y AC35.
- [ ] T5.1 Registrar el plugin en `.claude-plugin/marketplace.json` y escribir `plugin.json` y el README. **AC36.**
- [ ] T5.2 Actualizar `SDD/docs/doc_quality_gates.md`: agregar `plugins/bisalta-db/scripts/*.sh` al glob del gate 2 si escribiste algún `.sh`, y **corregir el prerequisito de `shellcheck`** — el doc lo da por instalado en `/opt/homebrew/bin` y el 18-sep-2026 no está. Re-medir el tiempo de la suite y actualizar el umbral. **AC38.**
- [ ] T5.3 Actualizar `SDD/docs/doc_architecture.md` con `plugins/bisalta-db/` en el layout y en las reglas de ubicación. **AC39.**
- [ ] T5.4 Entrada en `CHANGELOG.md`.
- [ ] T6.1 Commitear (árbol limpio) y correr la escalera completa: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md`. **AC40.**
- [ ] T6.2 Pegar en el verification report, a mano, los **dieciséis triples** de mutación con comando literal y exit code de cada corrida.

## Acceptance criteria (IDs del contract v1 — no los renumeres)

`AC11`–`AC40`, todos tuyos. Ninguno es de R1.

**Dieciséis de los tuyos son ACs de detección y llevan triple verde → rojo → verde**: AC11, AC12, AC13, AC14, AC15, AC16, AC17, AC20, AC21, AC22, AC23, AC24, AC25, AC31, AC33 y AC35. (El contract tiene veinte en total; los otros cuatro — AC2, AC6, AC7 y AC9 — son de R1 y no te tocan.) La mutación de cada uno está **escrita literal en el contract, debajo del AC**. Ejecutala tal cual. Si un AC de detección no tiene mutación declarada, quedás `BLOCKED` y preguntás: inventarla es cerrar una decisión que el contract dejó abierta.

**Un AC es `manual-only`**: AC34 sólo se prueba contra una base real si querés verificar el handshake contra Claude Code; el resto de AC34 (responder `initialize` y `tools/list`) es automatizable y se prueba con stdin.

La mutación se aplica **sobre el sistema que el AC vigila, nunca sobre el test**. Aflojar el test para verlo fallar es la mitigación prohibida §6.2 con otro nombre.

## AC ↔ test binding (llenalo vos)

| AC | Test (nombre literal del mensaje de assert) | Archivo | Estado |
|---|---|---|---|
| AC11 | | `SDD/tests/test_catalogo.sh` | |
| AC12 | | `SDD/tests/test_catalogo.sh` | |
| AC13 | | `SDD/tests/test_catalogo.sh` | |
| AC14 | | `SDD/tests/test_catalogo.sh` | |
| AC15 | | `SDD/tests/test_lista_blanca.sh` | |
| AC16 | | `SDD/tests/test_lista_blanca.sh` | |
| AC17 | | `SDD/tests/test_lista_blanca.sh` | |
| AC18 | | `SDD/tests/test_lista_blanca.sh` | |
| AC19 | | `SDD/tests/test_lista_blanca.sh` | |
| AC20 | | `SDD/tests/test_lista_blanca.sh` | |
| AC21 | | `SDD/tests/test_lista_blanca.sh` | |
| AC22 | | `SDD/tests/test_lista_blanca.sh` | |
| AC23 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC24 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC25 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC26 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC27 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC28 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC29 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC30 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC31 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC32 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC33 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC34 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC35 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC36 | | `SDD/tests/test_catalogo.sh` | |
| AC37 | | `SDD/tests/test_servidor_mcp.sh` | |
| AC38 | | (docs — verificación por grep) | |
| AC39 | | (docs — verificación por grep) | |
| AC40 | | `SDD/tests/run.sh` | |

## Cobertura del impact set

| Archivo modificado | Consumidor existente | Cobertura |
|---|---|---|
| `.claude-plugin/marketplace.json` | Claude Code al resolver `/plugin install`. Grep de `marketplace.json` sobre `plugins/` y `SDD/`: cero coincidencias en código — ningún script lo parsea. | AC36 |
| `SDD/docs/doc_quality_gates.md` | `sdd-run-gates.sh` parsea su tabla de gates | AC38 + la corrida verde del runner en T6.1 |
| `SDD/docs/doc_architecture.md` | lectura humana y de agentes | AC39 |
| `CHANGELOG.md` | ninguno automatizado | prosa, sin test |

Los doce archivos de test preexistentes **no se modifican** y tienen que seguir verdes: es AC40.

## Advisory (no bloquean, el reviewer los reporta)

- `PERF1` — una consulta que recorre una tabla sin índice sobre `BI` o `EXACTUS` es responsabilidad de quien la escribe; el servidor la corta a los 120 s.

## Reglas innegociables

- **Mitigaciones prohibidas** (`quality-gates.md` §6): no ablandes un test, no bajes `--severity` de shellcheck, no agregues `-e <código>`, no uses `--no-verify`, no metas una exclusión por path en el secret-scan. Gate que no pasa sin uno de esos atajos → `[BLOCKED]` y preguntás al planner.
- **Ninguna dependencia nueva.** El contract no autoriza ninguna; agregar una de contrabando es `MAJOR`.
- Bash 3.2 es el piso de los `.sh` (`declare -A`, `mapfile`, `readarray`, `${var^^}`, `&>>` prohibidos).
- Fixtures on-the-fly bajo `SDD/tests/.tmp/<nombre>-$$` con `trap ... EXIT`. Nunca versionadas.
- **Un literal con forma de credencial en un archivo hace que el secret-scan se detecte a sí mismo.** Armá esos strings en piezas separadas, como ya hace `SDD/tests/test_secret_scan.sh`. La exclusión por path **no es una opción**.
- No declares una validación que no corriste. Un `done` sin evidencia con exit codes se trata como no hecho.

## Rollback

Todos los archivos del plugin son nuevos: `git rm -r plugins/bisalta-db` los saca. Los cuatro archivos modificados se revierten con `git checkout -- <archivo>`. No hay estado externo: R2 no crea nada en AWS ni en ninguna base.

## Execution Report

### Summary

### Task Status

### Validation Executed

### Blockers

### Files Changed

### Final Statement
