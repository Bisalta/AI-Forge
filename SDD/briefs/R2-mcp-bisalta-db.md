# Task brief — R2 · third-party-integration: plugin `bisalta-db`

- **Agente**: `AGENT_r2` · **Modelo**: `opus`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v2**, ACs **AC11–AC40**
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

- [x] T1.1 Verificar `shellcheck` instalado; si falta, `brew install shellcheck`. Sin él el gate 2 nunca sale verde.
- [x] T1.2 **Verificar cómo un plugin de Claude Code declara un servidor MCP stdio** (ningún plugin de este repo lo hace todavía) y dejarlo escrito en el README. Si no lo podés verificar contra documentación, marcá `[BLOCKED]` y preguntá — **no lo inventes**.
- [x] T2.1 Escribir `lista-blanca.js`: normalizar, partir en sentencias, validar por dialecto. Exporta una función que recibe el SQL y el dialecto y devuelve el veredicto.
- [x] T2.2 Escribir `test_lista_blanca.sh` portando los doce casos, más los del dialecto `sqlserver` y el de sensibilidad entre dialectos. **AC15–AC22.**
- [x] T2.3 Correr los triples de mutación de AC15, AC16, AC17, AC20, AC21 y AC22 — las seis mutaciones están declaradas literal en el contract. Registrar las tres corridas de cada una.
- [x] T3.1 Escribir `catalogo.js` con el validador del contrato de datos (rechaza campo desconocido, campo faltante, `ambiente` fuera de `dev`/`qa`, `garantias` vacío, host de producción).
- [x] T3.2 Escribir `catalogo.json` con las tres entradas y sus `garantias` reales — Postgres lleva las tres, SQL Server lleva sólo `rol-solo-lectura`.
- [x] T3.3 Escribir `test_catalogo.sh`. **AC11–AC14.**
- [x] T3.4 Correr los triples de mutación de AC11, AC12, AC13 y AC14.
- [x] T4.1 Escribir `conexion.js`: resolver el secreto con `aws`, armar el comando del cliente, entregar la credencial por `PGPASSFILE` o `SQLCMDPASSWORD`, borrar el temporal en un `finally`.
- [x] T4.2 Escribir `servidor-mcp.js`: handshake `initialize`, `tools/list`, `tools/call` para `consultar` y `listar_conexiones`, topes de filas y bytes, bitácora, y la tabla de exit codes del contract.
- [x] T4.3 Escribir `test_servidor_mcp.sh` alimentando stdin con tramas JSON-RPC y afirmando sobre stdout. **AC23–AC37.**
- [x] T4.4 Correr los triples de mutación de AC23, AC24, AC25, AC31, AC33 y AC35.
- [x] T5.1 Registrar el plugin en `.claude-plugin/marketplace.json` y escribir `plugin.json` y el README. **AC36.**
- [x] T5.2 Actualizar `SDD/docs/doc_quality_gates.md` — **AC38**, tres puntos, cada uno medido:
  (a) **[N/A — medido]** no se escribió ningún `.sh` en el plugin (el código de producto es Node plano), y agregar el glob con cero coincidencias pone el gate 2 en rojo: `shellcheck` sale **2** (`openBinaryFile: does not exist`). La razón quedó escrita en la nota del gate 2 del doc;
  (b) la sección "Suite completa" declara **12 archivos de test** y hay **14** — reemplazá la cifra por la derivación, no por otro número congelado;
  (c) re-medir el tiempo de la suite con los tres tests nuevos y escribirlo con su fecha.
  Sobre `shellcheck`: el 18-sep-2026 a las 11:26 **no estaba en el PATH** y a las 11:37 **sí** — el binario llevaba un año en el Cellar y lo que faltaba era el symlink, que `brew install` recreó. O sea que el doc no mentía: describía un estado que se rompió y volvió. Corregí la redacción para que **nombre la verificación en vez de prometer la presencia** (`command -v shellcheck`), que es lo único que no envejece.
- [x] T5.3 Actualizar `SDD/docs/doc_architecture.md` con `plugins/bisalta-db/` en el layout y en las reglas de ubicación. **AC39.**
- [x] T5.4 Entrada en `CHANGELOG.md`.
- [x] T6.1 Commitear (árbol limpio) y correr la escalera completa: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md`. **AC40.**
- [x] T6.2 Pegar en el verification report, a mano, los **dieciséis triples** de mutación con comando literal y exit code de cada corrida.

## Acceptance criteria (IDs del contract v1 — no los renumeres)

`AC11`–`AC40`, todos tuyos. Ninguno es de R1.

**Dieciséis de los tuyos son ACs de detección y llevan triple verde → rojo → verde**: AC11, AC12, AC13, AC14, AC15, AC16, AC17, AC20, AC21, AC22, AC23, AC24, AC25, AC31, AC33 y AC35. (El contract tiene veinte en total; los otros cuatro — AC2, AC6, AC7 y AC9 — son de R1 y no te tocan.) La mutación de cada uno está **escrita literal en el contract, debajo del AC**. Ejecutala tal cual. Si un AC de detección no tiene mutación declarada, quedás `BLOCKED` y preguntás: inventarla es cerrar una decisión que el contract dejó abierta.

**Un AC es `manual-only`**: AC34 sólo se prueba contra una base real si querés verificar el handshake contra Claude Code; el resto de AC34 (responder `initialize` y `tools/list`) es automatizable y se prueba con stdin.

La mutación se aplica **sobre el sistema que el AC vigila, nunca sobre el test**. Aflojar el test para verlo fallar es la mitigación prohibida §6.2 con otro nombre.

## AC ↔ test binding (llenalo vos)

| AC | Test (nombre literal del mensaje de assert) | Archivo | Estado |
|---|---|---|---|
| AC11 | `AC11 el validador sale distinto de 0 con un ambiente que no es dev ni qa` (+5) | `SDD/tests/test_catalogo.sh` | pass |
| AC12 | `AC12 el validador rechaza una entrada cuyo host es el de Prod SQL` (+4) | `SDD/tests/test_catalogo.sh` | pass |
| AC13 | `AC13 el validador rechaza una entrada con un campo no declarado` (+3) | `SDD/tests/test_catalogo.sh` | pass |
| AC14 | `AC14 el validador rechaza una entrada con garantias vacío` (+2) | `SDD/tests/test_catalogo.sh` | pass |
| AC15 | `AC15 rechaza un UPDATE` … `un COPY` (los diez) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC16 | `AC16 rechaza DELETE ... WHERE id IN (SELECT` … (los cinco) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC17 | `AC17 rechaza una escritura escondida detrás de un SELECT` (+2) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC18 | `AC18 acepta un UPDATE que sólo aparece dentro de un comentario` (+1) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC19 | `AC19 acepta un CTE` · `AC19 acepta tres sentencias de lectura seguidas` (+2) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC20 | `AC20 rechaza una apertura de comilla de dólar sin etiqueta` (+1) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC21 | `AC21 rechaza un EXEC en sqlserver` … `AC21 rechaza cualquier punto y coma en sqlserver` (+4 de control) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC22 | `AC22 dos lecturas encadenadas con punto y coma se aceptan en postgres` · `AC22 la misma entrada se rechaza en sqlserver` | `SDD/tests/test_lista_blanca.sh` | pass |
| AC23 | `AC23 el código fuente de scripts/ no contiene [PGPASSWORD]` (+5 formas, +1 de control, +3 en ejecución) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC24 | `AC24 tras una consulta que falla al conectar no queda ningún directorio temporal` (+1 de control, +1) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC25 | `AC25 la bitacora de una consulta exitosa no contiene el valor de la contraseña` (+4) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC26 | `AC26 un resultado de más de 1000 filas devuelve exactamente 1000` (+2) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC27 | `AC27 un resultado de más de 1 MiB marca truncado en true` (+2) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC28 | `AC28 el comando abre la sesión en solo lectura` · `AC28 el comando fija el statement_timeout en 120000` | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC29 | `AC29 el comando lleva el application_name del usuario del secreto` | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC30 | `AC30 la bitácora registra la conexión` … `el código de salida` (+2) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC31 | `AC31 con una conexión desconocida no se invoca el binario aws` (+1 de control, +4) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC32 | `AC32 con el cliente ausente del PATH la consulta devuelve el código 8` (+3) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC33 | `AC33 la respuesta NO contiene la salida cruda del binario aws` (+1 de control, +5) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC34 | `AC34 tools/list devuelve exactamente consultar y listar_conexiones` (+6) | `SDD/tests/test_servidor_mcp.sh` | pass (automatizado) · **manual** el handshake contra Claude Code real |
| AC35 | `AC35 listar_conexiones NO devuelve "host"` (+3 negativos, +3 positivos) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC36 | `AC36 marketplace.json lista bisalta-db con source ./plugins/bisalta-db` (+2) | `SDD/tests/test_catalogo.sh` | pass |
| AC37 | `AC37 quitar la entrada del catálogo devuelve el código 3 sin reiniciar el servidor` (+2) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC38 | grep + triple de mutación — `verification/…-R2.md` §3 y §2 nº17 | (docs — verificación por grep) | pass |
| AC39 | grep (`grep -c bisalta-db SDD/docs/doc_architecture.md` → 6) | (docs — verificación por grep) | pass |
| AC40 | `bash SDD/tests/run.sh` (exit 0, 17 archivos) + `git diff --name-only origin/prod..HEAD -- 'SDD/tests/test_*.sh'` → sólo los tres nuevos | `SDD/tests/run.sh` | pass |

La lista completa de nombres de assert por AC está en
`SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md` §1.

## Cobertura del impact set

| Archivo modificado | Consumidor existente | Cobertura |
|---|---|---|
| `.claude-plugin/marketplace.json` | Claude Code al resolver `/plugin install`. Grep de `marketplace.json` sobre `plugins/` y `SDD/`: cero coincidencias en código — ningún script lo parsea. | AC36 |
| `SDD/docs/doc_quality_gates.md` | `sdd-run-gates.sh` parsea su tabla de gates | AC38 + la corrida verde del runner en T6.1 |
| `SDD/docs/doc_architecture.md` | lectura humana y de agentes | AC39 |
| `CHANGELOG.md` | ninguno automatizado | prosa, sin test |

Los archivos de test preexistentes **no se modifican** y tienen que seguir verdes: es AC40, que se verifica derivando del árbol (`git diff --name-only origin/prod..HEAD -- 'SDD/tests/test_*.sh'` lista sólo tus tres nuevos). **No escribas la cantidad de tests como constante en ningún archivo** — es el defecto que motivó el bump v1 → v2.

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

Plugin `bisalta-db` completo: servidor MCP propio sobre stdio (JSON-RPC 2.0 escrito a
mano, **cero dependencias npm**), lista blanca por dialecto portada de
`Bisalta/Proveedores-Back` con sus doce casos, catálogo con contrato de datos cerrado
donde **producción es irrepresentable**, y entrega de la credencial que nunca pasa por
`argv`. 30 ACs (AC11–AC40), **ninguno `missing`**; el único parcialmente manual es AC34
(el handshake contra Claude Code real). 11 archivos nuevos y 4 modificados.

Se corrieron **diecisiete** triples de mutación verde → rojo → verde: los dieciséis del
brief más el de AC38, que el contract declara y el brief no lista. Los diecisiete dieron
`0 → 1 → 0`.

**Riesgo #1 del contract cerrado**: cómo declara un plugin un servidor MCP stdio quedó
verificado contra la documentación oficial (`plugin-dev` del marketplace
`anthropics/claude-plugins-official`) y contra el catálogo que el propio Claude Code
deriva; escrito en el README del plugin. No hizo falta `BLOCKED`.

### Task Status

Total: 20 pasos · completados: **19** · `[N/A]` con medición: **1** (T5.2 punto (a)) ·
bloqueados: **0**.

T5.2(a) no se aplicó porque el plugin no tiene ningún `.sh`, y agregar
`plugins/bisalta-db/scripts/*.sh` al glob del gate 2 lo pone en rojo permanente
(`shellcheck` sale **2**, medido). El propio paso lo condiciona a *"si escribiste algún
`.sh`"*. La razón quedó escrita en la nota del gate 2 del doc.

### Validation Executed

Escalera completa por el runner, **sin editar su salida**:
`bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md`
→ **exit 0**, `{"green":4,"red":0,"skipped":7}`, árbol **LIMPIO** sobre el commit `ee4a5ae`.

| Gate | Comando | Exit |
|---|---|---|
| 2 lint | `shellcheck --severity=warning …` | 0 |
| 4 unit tests | `bash SDD/tests/run.sh` | 0 (17 archivos, 0 fallos) |
| 9 security | `bash SDD/tests/secret-scan.sh` | 0 (159 archivos versionados) |
| — suite completa | `bash SDD/tests/run.sh` | 0 |
| 1, 3, 5, 6, 7, 8, 10 | `[SKIPPED]` — sin comando en el doc (`N/A` declarado) | — |

Los diecisiete triples, el impact set, los `manual-only` y los desvíos están en
`SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md`, §2 a §6. **Rojos preexistentes de
la base: ninguno.**

### Blockers

Ninguno.

Para ratificar (no bloquean, ningún AC depende de ellos) — detalle en
`verification/…-R2.md` §6: los `nombre` del catálogo llevan guion y no guion bajo porque
el contrato de datos lo fija; el `host` de las entradas de Postgres es el endpoint
`cluster-ro-` derivado del que documenta el runbook de R1 y **no se pudo verificar contra
AWS** desde acá; `catalogo_invalido` se mapeó al código 2; y el brief pide dieciséis
triples donde el contract declara diecisiete.

### Files Changed

**Nuevos (11)**: `plugins/bisalta-db/.claude-plugin/plugin.json` · `.mcp.json` ·
`catalogo.json` · `README.md` · `scripts/servidor-mcp.js` · `scripts/lista-blanca.js` ·
`scripts/catalogo.js` · `scripts/conexion.js` · `SDD/tests/test_lista_blanca.sh` ·
`SDD/tests/test_catalogo.sh` · `SDD/tests/test_servidor_mcp.sh`

**Modificados (4)**: `.claude-plugin/marketplace.json` · `CHANGELOG.md` ·
`SDD/docs/doc_quality_gates.md` · `SDD/docs/doc_architecture.md`

**No se modificó ningún archivo de test preexistente** (AC40, derivado del árbol).

### Final Statement

R2 queda listo para review. Dos defectos aparecieron en el propio código y se
arreglaron **por clase y no por instancia**: `process.exit()` cortando `stdout` hacia un
pipe (lo encontró el test del tope de 1 MiB; el mismo patrón estaba en los otros dos CLI,
que todavía no lo habían manifestado) y tres literales que hacían que el gate 9 se
detectara a sí mismo — partidos, nunca excluidos por path. El comentario que escribí para
explicar el primero de esos tres reprodujo el problema al citarlo, que es exactamente la
clase de `sdd-check.sh` en v0.11.0.
