# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `ee4a5ae` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:2478fcac35a40aaf`) · **Fecha**: 2026-09-18T19:36:12Z
- Tree: `ae92622029227a55f833e8dc5ce9cbabe782bb15` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-18T19:35:16Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-18T19:35:16Z | verde |
| 3 | type-check | — | — | 2026-09-18T19:35:17Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-18T19:35:17Z | verde |
| 5 | integration | — | — | 2026-09-18T19:35:44Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-18T19:35:44Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-18T19:35:44Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-18T19:35:44Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-18T19:35:44Z | verde |
| 10 | smoke manual | — | — | 2026-09-18T19:35:45Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-18T19:35:45Z | verde |

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
secret-scan: sin hallazgos sobre 159 archivos versionados (1 excluido: self)
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

# Addendum de `AGENT_r2` — lo que el runner no sabe

> Todo lo de **arriba** de esta línea lo escribió `sdd-run-gates.sh`; no se tocó.
> Todo lo de **abajo** lo escribió `AGENT_r2` a mano, **después** de la última
> corrida del runner. El runner **trunca** el archivo que recibe en `-o`, así
> que re-correrlo borra este addendum: está registrado como deuda `D34` y no se
> arregla acá. Si hay que re-correr la escalera, este addendum se vuelve a
> pegar después.

- **Agente**: `AGENT_r2` · **Ronda**: 1 · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v2**
- **Rama**: `feat-GEN-108-mcp-bisalta-db` (base `prod`) · **Commit de la evidencia**: `ee4a5ae`
- **ACs**: AC11–AC40 (AC1–AC10 son de R1, ya `APPROVED`)

## 1. AC ↔ test binding

Cada nombre de caso es el **string literal** del último argumento del assert:
grepeable en el archivo que lo acompaña.

| AC | Test (nombre literal del assert) | Archivo | Estado |
|---|---|---|---|
| AC11 | `AC11 el validador sale distinto de 0 con un ambiente que no es dev ni qa` (+ `AC11 el rechazo nombra la entrada`, `AC11 el rechazo nombra el campo ambiente`, `AC11 tampoco admite un ambiente que nombre producción`, `AC11 el validador rechaza una entrada sin el campo ambiente`, `AC11 el rechazo dice qué campo falta`) | `SDD/tests/test_catalogo.sh` | pass |
| AC12 | `AC12 el validador rechaza una entrada cuyo host es el de Prod SQL` (+ `AC12 el rechazo del host de Prod SQL nombra la entrada`, `AC12 el validador rechaza un host del cluster de la cuenta de producción`, `AC12 el rechazo dice que el host apunta a producción`, `AC12 ninguna entrada del catálogo real nombra el cluster ni el host de producción`) | `SDD/tests/test_catalogo.sh` | pass |
| AC13 | `AC13 el validador rechaza una entrada con un campo no declarado` (+ `AC13 el rechazo dice que el campo no está en el contrato de datos`, `AC13 el rechazo nombra el campo de más`, `AC13 el catálogo no admite un campo de credencial`) | `SDD/tests/test_catalogo.sh` | pass |
| AC14 | `AC14 el validador rechaza una entrada con garantias vacío` (+ `AC14 el rechazo nombra el campo garantias`, `AC14 el validador rechaza una garantía que no está en la lista cerrada`) | `SDD/tests/test_catalogo.sh` | pass |
| AC15 | `AC15 rechaza un UPDATE` · `un DELETE` · `un INSERT` · `un TRUNCATE` · `un DROP` · `un ALTER` · `un GRANT` · `un bloque DO` · `un CALL` · `un COPY` (diez casos) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC16 | `AC16 rechaza DELETE ... WHERE id IN (SELECT` · `INSERT ... SELECT` · `UPDATE ... = (SELECT` · `CREATE TABLE ... AS SELECT` · `CREATE VIEW ... WITH (...) AS SELECT` (cinco casos) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC17 | `AC17 rechaza una escritura escondida detrás de un SELECT` (+ `AC17 rechaza una escritura multilínea escondida detrás de una lectura multilínea`, `AC17 revisa la última sentencia aunque no termine en punto y coma`) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC18 | `AC18 acepta un UPDATE que sólo aparece dentro de un comentario` · `AC18 acepta un DELETE que sólo aparece dentro de un literal de texto` | `SDD/tests/test_lista_blanca.sh` | pass |
| AC19 | `AC19 acepta un CTE` · `AC19 acepta tres sentencias de lectura seguidas` (+ `AC19 acepta una consulta multilínea, que es como son las de verdad`, `AC19 sigue rechazando una escritura multilínea`) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC20 | `AC20 rechaza una apertura de comilla de dólar sin etiqueta` · `AC20 rechaza una apertura de comilla de dólar con etiqueta` | `SDD/tests/test_lista_blanca.sh` | pass |
| AC21 | `AC21 rechaza un EXEC en sqlserver` · `un EXECUTE en sqlserver` · `un EXEC detrás de una lectura en sqlserver` · `un EXECUTE detrás de una lectura en sqlserver` · `un identificador que empieza con sp_ en sqlserver` · `un identificador que empieza con xp_ en sqlserver` · `AC21 rechaza cualquier punto y coma en sqlserver` (+ los cuatro `AC21 (control) postgres acepta …` y `AC21 acepta un punto y coma que sólo vive dentro de un literal de texto`) | `SDD/tests/test_lista_blanca.sh` | pass |
| AC22 | `AC22 dos lecturas encadenadas con punto y coma se aceptan en postgres` · `AC22 la misma entrada se rechaza en sqlserver` | `SDD/tests/test_lista_blanca.sh` | pass |
| AC23 | `AC23 el código fuente de scripts/ no contiene [PGPASSWORD]` y sus cinco hermanos (`[PGUSER]`, `[PGHOST]`, `[--username]`, `[--host]`, `[-P ]`), + `AC23 (control) el grep sí encuentra la forma que el plugin sí usa`, `AC23 la contraseña no viaja en la línea de comandos del cliente`, `AC23 (control) la contraseña sí llega al cliente por el archivo de credenciales`, `AC23 el archivo de credenciales queda en modo 600` | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC24 | `AC24 tras una consulta que falla al conectar no queda ningún directorio temporal` (+ `AC24 (control) el archivo de credenciales existía mientras corría la consulta que falló`, `AC24 tampoco queda un directorio temporal tras una consulta exitosa`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC25 | `AC25 la respuesta de una consulta exitosa no contiene el valor de la contraseña` · `AC25 la bitacora de una consulta exitosa no contiene el valor de la contraseña` · `AC25 la respuesta no contiene la carga cruda del secreto` · `AC25 la bitacora no contiene la carga cruda del secreto` · `AC25 el mensaje de una conexión fallida no contiene la contraseña` (+ `AC25 una conexión que falla devuelve el código 6`, `AC25 el error de conexión trae el mensaje del cliente`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC26 | `AC26 un resultado de más de 1000 filas devuelve exactamente 1000` (+ `AC26 el tope de filas marca truncado en true`, `AC26 el motivo del truncado es limite_filas`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC27 | `AC27 un resultado de más de 1 MiB marca truncado en true` (+ `AC27 el motivo del truncado es limite_bytes`, `AC27 el tope de bytes devuelve las filas que caben, ni cero ni todas`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC28 | `AC28 el comando abre la sesión en solo lectura` · `AC28 el comando fija el statement_timeout en 120000` | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC29 | `AC29 el comando lleva el application_name del usuario del secreto` | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC30 | `AC30 la bitácora registra la conexión` · `el dialecto` · `el hash de la consulta` · `las filas devueltas` · `si truncó` · `la duración` · `el código de salida` (+ `AC30 la bitácora NO guarda el texto de la consulta`, `AC30 la bitácora escribe una línea por invocación`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC31 | `AC31 con una conexión desconocida no se invoca el binario aws` (+ `AC31 una conexión ausente del catálogo devuelve el código 3`, `AC31 el error es conexion_desconocida`, `AC31 el error trae la lista de nombres válidos`, `AC31 (control) con una conexión válida el stub de aws sí registra la invocación`, `AC31 el proceso sale 3 con una conexión desconocida`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC32 | `AC32 con el cliente ausente del PATH la consulta devuelve el código 8` (+ `AC32 el error es cliente_ausente`, `AC32 el error nombra el binario que falta`, `AC32 el proceso sale 8 cuando falta el binario del cliente`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC33 | `AC33 la respuesta NO contiene la salida cruda del binario aws` (+ `AC33 un secreto que no resuelve devuelve el código 5`, `AC33 el error es secreto_inaccesible`, `AC33 el error nombra la conexión`, `AC33 el error nombra el identificador del secreto`, `AC33 (control) el stub de aws corrió y falló en esa misma invocación`, `AC33 el proceso sale 5 cuando el secreto no resuelve`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC34 | `AC34 initialize responde el protocolVersion declarado` · `AC34 tools/list devuelve exactamente consultar y listar_conexiones` · `AC34 initialize se identifica como bisalta-db` · `AC34 la notificación initialized no genera respuesta` · `AC34 el plugin no trae manifiesto ni árbol de dependencias (package.json / package-lock.json / node_modules)` | `SDD/tests/test_servidor_mcp.sh` | pass (parte automatizada) · **manual** (handshake contra Claude Code real) — ver §4 |
| AC35 | `AC35 listar_conexiones NO devuelve "host"` · `"puerto"` · `"secret_id"` · `"region"` (+ los tres positivos `AC35 listar_conexiones devuelve …`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC36 | `AC36 marketplace.json lista bisalta-db con source ./plugins/bisalta-db` · `AC36 el plugin.json de bisalta-db declara una versión SemVer` · `AC36 el plugin.json declara el nombre bisalta-db` | `SDD/tests/test_catalogo.sh` | pass |
| AC37 | `AC37 quitar la entrada del catálogo devuelve el código 3 sin reiniciar el servidor` (+ `AC37 la conexión responde mientras está en el catálogo`, `AC37 el kill switch responde conexion_desconocida`) | `SDD/tests/test_servidor_mcp.sh` | pass |
| AC38 | verificación por grep + triple de mutación — ver §3 y §5(a) | `SDD/docs/doc_quality_gates.md` | pass |
| AC39 | verificación por grep — ver §3 | `SDD/docs/doc_architecture.md` | pass |
| AC40 | `bash SDD/tests/run.sh` (gate 4 y suite completa del runner, exit 0) + derivación del árbol — ver §3 | `SDD/tests/run.sh` | pass |

**Ningún AC quedó `missing`.** El único parcialmente manual es AC34 (§4).

## 2. Los diecisiete triples de mutación (verde → rojo → verde)

Cada mutación es **la declarada literal en el contract**, aplicada **sobre el
sistema que el AC vigila, nunca sobre el test**. El driver aborta si el texto a
mutar no aparece tal cual: una mutación que no se aplica produciría un "rojo"
que en realidad es un verde — la medición muerta que hay que evitar. Tras cada
triple se corre `git checkout -- .` y se verifica `git status --porcelain` vacío.

Las tres corridas de cada triple son `bash <archivo de test>`; se listan los
exit codes reales y, en el rojo, los asserts que cayeron.

| # | AC | Mutación aplicada (contract) | Archivo mutado | Test | verde | **rojo** | verde |
|---|---|---|---|---|---|---|---|
| 1 | AC11 | `ambiente` de la primera entrada → `stg` | `catalogo.json` | `test_catalogo.sh` | 0 | **1** | 0 |
| 2 | AC12 | se agrega una entrada con `host` `192.168.252.22` | `catalogo.json` | `test_catalogo.sh` | 0 | **1** | 0 |
| 3 | AC13 | se agrega un campo `usuario` a una entrada | `catalogo.json` | `test_catalogo.sh` | 0 | **1** | 0 |
| 4 | AC14 | se vacía el arreglo `garantias` de una entrada | `catalogo.json` | `test_catalogo.sh` | 0 | **1** | 0 |
| 5 | AC15 | `validarSql` devuelve siempre aceptado | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 6 | AC16 | el anclaje `^` → búsqueda de SELECT/WITH en cualquier posición | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 7 | AC17 | se valida únicamente la primera sentencia | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 8 | AC20 | se quita la regla de comilla de dólar del dialecto `postgres` | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 9 | AC21 | se quitan las reglas del dialecto `sqlserver` (cae en las comunes) | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 10 | AC22 | `validarSql` ignora el dialecto y aplica siempre las reglas comunes | `lista-blanca.js` | `test_lista_blanca.sh` | 0 | **1** | 0 |
| 11 | AC23 | se agrega una línea que exporta la variable de contraseña de libpq | `conexion.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 12 | AC24 | se quita el `finally` que borra el directorio temporal | `conexion.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 13 | AC25 | la bitácora escribe la carga del secreto | `conexion.js` + `servidor-mcp.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 14 | AC31 | la existencia de la conexión se comprueba **después** de resolver el secreto | `servidor-mcp.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 15 | AC33 | el mensaje de error concatena la salida cruda de `aws` | `conexion.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 16 | AC35 | se agrega `host` a la proyección de `listar_conexiones` | `catalogo.js` | `test_servidor_mcp.sh` | 0 | **1** | 0 |
| 17 | AC38 | se declara `99 archivos de test` en el doc | `doc_quality_gates.md` | chequeo de §5(a) | 0 | **1** | 0 |

### El patch exacto de cada mutación, y el assert que cayó

Reproducible a mano: el texto de la izquierda es lo único que se cambió.

1. **AC11** — `"ambiente": "dev"` → `"ambiente": "stg"` en la entrada `proveedores-dev`.
   Rojo: `FAIL el catálogo real que se distribuye con el plugin es válido — esperado [0], obtenido [1]`, `FAIL AC11 el rechazo nombra la entrada`.
2. **AC12** — se inserta al principio del arreglo una entrada `prod-sql` con `"host": "192.168.252.22"`.
   Rojo: `FAIL el catálogo real …`, `FAIL AC12 ninguna entrada del catálogo real nombra el cluster ni el host de producción — esperado [no], obtenido [si]`.
3. **AC13** — se agrega `"usuario": "claude_lectura",` a `proveedores-dev`.
   Rojo: `FAIL el catálogo real que se distribuye con el plugin es válido — esperado [0], obtenido [1]`.
4. **AC14** — `"garantias": [ … ]` → `"garantias": []`.
   Rojo: `FAIL el catálogo real que se distribuye con el plugin es válido — esperado [0], obtenido [1]`.
5. **AC15** — se inserta `return { aceptado: true, motivo: null, sentencia: null };` como primera línea de `validarSql`.
   Rojo: los **diez** casos de AC15 (`FAIL AC15 rechaza un UPDATE — esperado [4], obtenido [0]`, …), más los de AC16/AC17/AC20/AC21/AC22.
6. **AC16** — `const ANCLA_LECTURA = /^(SELECT|WITH)[\s(]/i;` → `/(SELECT|WITH)[\s(]/i;` (se borra el `^`).
   Rojo: los **cinco** casos de AC16 (`FAIL AC16 rechaza DELETE ... WHERE id IN (SELECT — esperado [4], obtenido [0]`, …). Es la versión laxa que pasaba once de los doce tests originales.
7. **AC17** — `for (let i = 0; i < sentencias.length; i += 1)` → `for (let i = 0; i < 1; i += 1)`.
   Rojo: `FAIL AC17 rechaza una escritura escondida detrás de un SELECT`, `FAIL AC17 rechaza una escritura multilínea escondida detrás de una lectura multilínea`.
8. **AC20** — se borra el bloque `if (dialecto === 'postgres' && COMILLA_DOLAR.test(sentencia)) { … }`.
   Rojo: `FAIL AC20 rechaza una apertura de comilla de dólar sin etiqueta`, `… con etiqueta`.
9. **AC21** — se borran los dos bloques del dialecto: el del `;` y el de `EXEC`/`EXECUTE`/`sp_`/`xp_`.
   Rojo: `FAIL AC21 rechaza un EXEC detrás de una lectura en sqlserver`, `… un EXECUTE …`, `… sp_ …`, `… xp_ …`, `FAIL AC21 rechaza cualquier punto y coma en sqlserver`.
   🔴 **Los cuatro casos "detrás de una lectura" existen por esta mutación**: un input `EXEC algo` a secas cae igual por el ancla común, así que con las reglas del dialecto borradas seguiría dando 4 y el triple no podría ponerse rojo. Los casos discriminantes empiezan con `SELECT` (y un assert de control verifica que `postgres` los acepta), así que su rechazo sólo puede venir de la regla del dialecto.
10. **AC22** — se inserta `dialecto = 'comun';` antes de normalizar, de modo que ninguna rama de dialecto se evalúa.
    Rojo, **verificado que cae el assert propio de AC22** y no sólo los vecinos: `FAIL AC22 la misma entrada se rechaza en sqlserver — esperado [4], obtenido [0]` (8 asserts en rojo en total).
11. **AC23** — se agrega `process.env.PGPASSWORD = credencial.contrasena;` tras resolver la credencial.
    Rojo: `FAIL AC23 el código fuente de scripts/ no contiene [PGPASSWORD] — esperado [no], obtenido [si]`.
12. **AC24** — el cuerpo del `finally` se reemplaza por un comentario (deja de borrar el directorio).
    Rojo: `FAIL AC24 tras una consulta que falla al conectar no queda ningún directorio temporal — esperado [0], obtenido [4]` y `… tras una consulta exitosa — esperado [0], obtenido [5]`.
13. **AC25** — `ejecutarConsulta` devuelve también `credencial`, y la bitácora agrega `carga_del_secreto`.
    Rojo: `FAIL AC25 la bitacora de una consulta exitosa no contiene el valor de la contraseña — esperado [no], obtenido [si]`.
14. **AC31** — se antepone `try { conexion.resolverCredencial(entrada || entradas[0]); } catch (e) {}` a la comprobación de existencia.
    Rojo: `FAIL AC31 con una conexión desconocida no se invoca el binario aws — esperado [no], obtenido [si]` y `FAIL una escritura se rechaza ANTES de resolver el secreto y de conectar`.
15. **AC33** — el mensaje de `secreto_inaccesible` concatena `String(r.stderr)`.
    Rojo: `FAIL AC33 la respuesta NO contiene la salida cruda del binario aws — esperado [no], obtenido [si]`.
16. **AC35** — se agrega `host: entrada.host,` a `proyectar`.
    Rojo: `FAIL AC35 listar_conexiones NO devuelve "host" — esperado [si], obtenido [no]`.
17. **AC38** — se reemplaza la frase de derivación por `La suite tiene 99 archivos de test.`
    Rojo: `AC38(b) ROJO — el doc declara 99 y el árbol tiene 17` (exit 1).

**Sobre el número diecisiete.** El brief pide dieciséis triples y no incluye
AC38 en su lista; el contract v2 **sí** declara una mutación bajo AC38. Se
corrió igual: ejecutar una mutación declarada nunca puede sobrar, y omitirla
por una discrepancia entre brief y contract sería elegir cuál de los dos
ignorar. Queda señalado para el planner en §6.

## 3. Verificaciones que no son un `test_*.sh`

**AC38 (a)** — el glob del gate 2 **no** incluye `plugins/bisalta-db/scripts/*.sh`,
y es correcto que no lo incluya: ese plugin **no tiene ningún `.sh`** (su código
de producto es Node plano). Medido, no supuesto:

```
$ bash -c 'shellcheck --severity=warning plugins/bisalta-db/scripts/*.sh'
plugins/bisalta-db/scripts/*.sh: … openBinaryFile: does not exist (No such file or directory)
EXIT=2
```

Agregarlo pondría el gate en **rojo permanente**. El paso T5.2(a) del brief ya
lo condiciona (*"si escribiste algún `.sh`"*). Los tres archivos de test nuevos
sí son bash y ya entran por `SDD/tests/*.sh`, que está en el glob. La razón y la
medición quedaron escritas en la nota del gate 2 del doc.

**AC38 (b)** — la cifra congelada se reemplazó por la derivación:

```
$ grep -nE '[0-9]+ archivos de test' SDD/docs/doc_quality_gates.md
(sin coincidencias — la cifra se derivó)
$ ls SDD/tests/test_*.sh | wc -l
17
```

**AC38 (c)** — tiempo de la suite re-medido el **18-sep-2026**: **27 s**, tres
corridas consecutivas, las tres en 27 s. Escrito con su fecha en el doc. El
umbral de 90 s se mantiene (y se explicó por qué no se ajusta al último valor:
la medición de GEN-101 fue ~62 s con **menos** archivos, o sea que el número
depende de la carga de la máquina).

**AC39** — `SDD/docs/doc_architecture.md` incluye `plugins/bisalta-db/` en el
layout (con `catalogo.json`, `.mcp.json`, `scripts/` y `aprovisionamiento/`) y
en las reglas de ubicación, donde se agregaron las reglas 7, 8 y 9 (dónde va el
código ejecutable de un plugin, dónde va su test, y dónde van sus datos de
configuración). `grep -c bisalta-db` → 6 líneas.

**AC40** — la suite entera sale 0 (gate 4 y "suite completa" del runner, arriba)
y **ningún archivo de test preexistente se modificó**, derivado del árbol y no
citado como constante:

```
$ git diff --name-only origin/prod..HEAD -- 'SDD/tests/test_*.sh'
SDD/tests/test_catalogo.sh
SDD/tests/test_lista_blanca.sh
SDD/tests/test_servidor_mcp.sh
```

Exactamente los tres nuevos y ninguno más.

## 4. `manual-only` y lo que NO se probó contra el mundo real

- **AC34, parte manual**: el handshake contra Claude Code real (instalar el
  plugin y ver las dos herramientas en `/mcp`) **no se corrió**: exige instalar
  el plugin en una sesión y reiniciarla. Lo automatizado —`initialize`,
  `notifications/initialized` sin respuesta, y `tools/list` con exactamente las
  dos herramientas— sí corre en el harness alimentando stdin con las tramas.
  El riesgo que el contract nombra (que el `protocolVersion` declarado no sea el
  que Claude Code negocia hoy) **queda abierto** hasta ese smoke.
- **La forma de declarar el servidor MCP sí está verificada** contra
  documentación (era el riesgo #1 del contract, T1.2 del brief). Fuente: el
  plugin oficial `plugin-dev` del marketplace `anthropics/claude-plugins-official`
  instalado en esta máquina — `skills/mcp-integration/SKILL.md` ("Method 1:
  Dedicated .mcp.json (Recommended)", sección "stdio (Local Process)") y
  `skills/plugin-structure/references/manifest-reference.md` §`mcpServers`
  (default `./.mcp.json`). Además se midió que Claude Code acepta **las dos
  formas** del archivo (con y sin la envoltura `mcpServers`): de los catorce
  `.mcp.json` de los plugins oficiales, cinco usan la envoltura y nueve no, y el
  catálogo que el propio Claude Code deriva
  (`~/.claude/plugins/plugin-catalog-cache.json`, `components.mcpServers`)
  resuelve el mismo nombre de servidor para ambas (`context7 → ["context7"]`,
  `serena → ["serena"]`). Escrito en `plugins/bisalta-db/README.md`.
- **Ninguna base, ninguna cuenta de AWS**: `aws`, `psql` y `sqlcmd` se
  sustituyen por stubs al frente del `PATH` que registran argv y entorno. Lo que
  se afirma es el comando **real** que el servidor construyó, no lo que una
  función diga que construiría. Los caminos contra motores reales son AC1–AC10
  (de R1, `manual-only`).
- **`sqlcmd` no está instalado en esta máquina** (ya declarado en el contract).
  Las reglas del dialecto `sqlserver` quedan mutation-tested sin base (AC21,
  AC22), y la construcción del comando y el parser de su salida se ejercitan
  contra un stub que emite el formato tabular documentado. **El parser de la
  salida real de `sqlcmd` no está verificado contra el binario real** — queda
  cubierto por AC5/AC6, que son `manual-only` y dependen de R1.

## 5. Impact set — callers de lo que se tocó

Todo el código nuevo es aditivo, en archivos nuevos: **no se modificó ningún
símbolo ejecutable existente**, así que no hay regresión de callers que analizar.
Los cuatro archivos existentes que sí cambiaron:

| Archivo | Consumidor existente (grepeado) | Cómo quedó cubierto |
|---|---|---|
| `.claude-plugin/marketplace.json` | Claude Code al resolver `/plugin install`. `grep -rn marketplace.json plugins/ SDD/` → cero coincidencias en código: **ningún script del repo lo parsea**. | AC36 (`test_catalogo.sh` lo parsea y afirma nombre + `source`) |
| `SDD/docs/doc_quality_gates.md` | `plugins/sdd-flow/scripts/sdd-run-gates.sh` parsea su tabla de gates | El runner corrió contra el doc modificado y salió **0**, con el `sha256:2478fcac35a40aaf` del doc nuevo estampado arriba. `test_doc_hash.sh` sigue verde. |
| `SDD/docs/doc_architecture.md` | lectura humana y de agentes; ningún parser | AC39 (grep) |
| `CHANGELOG.md` | ninguno automatizado | prosa, sin test |

Los tres archivos de test nuevos los descubre `SDD/tests/run.sh` por su glob
`test_*.sh`: **el runner de tests no se tocó** (17 archivos descubiertos, antes 14).

## 6. Rojos preexistentes, desvíos y decisiones que el planner debería mirar

**Rojos preexistentes de la base: ninguno.** La suite salía 0 antes de este
trabajo y sale 0 después.

Dos defectos encontrados y arreglados **en el código propio** (no eran de la
base):

1. **`process.exit()` corta `process.stdout` cuando la salida va a un pipe.** Lo
   encontró el test de AC27: la respuesta que llega al tope de 1 MiB se perdía
   entera y el cuerpo llegaba vacío. Arreglado con `process.exitCode`. 🔴 **Se
   cerró la clase, no la instancia**: el mismo patrón estaba en los otros dos
   CLI del plugin (`lista-blanca.js`, `catalogo.js`), que todavía no lo habían
   manifestado porque escriben poco. `grep -rn 'process\.exit(' plugins/bisalta-db/`
   hoy sólo devuelve los comentarios que explican por qué no se usa.
2. **Tres literales del propio código disparaban el gate 9 contra sí mismos**
   (`USUARIO_SECRETO=…`, `resolverSecreto: resolverSecreto`, `extra.secret_id = …`).
   Se **partieron los literales** (renombres + clave computada), que es la
   convención del repo; **ninguna exclusión por path**, que es la única
   mitigación prohibida ahí. Nota: el comentario que escribí para explicar el
   primer caso **reprodujo el problema** al citar la forma completa — la prosa
   que describe lo que prohíbe dispara la misma detección. Es la misma clase que
   `sdd-check.sh` tuvo en v0.11.0.

Desvíos y lecturas del contract que conviene ratificar (**ninguno cambia un AC**):

- **AC38(a) no se aplicó, a propósito** y con medición: ver §3. Agregar el glob
  pondría el gate 2 en rojo permanente.
- **Los `nombre` del catálogo llevan guion, no guion bajo** (`proveedores-dev`,
  no `proveedores_dev`). El brief los menciona informalmente con guion bajo,
  pero el contrato de datos del contract fija `nombre` a "minúsculas, dígitos y
  guiones". Se siguió el contrato de datos; el nombre real de la base queda en
  el campo `base`. Escrito en el README.
- **El `host` de las dos entradas de Postgres es el endpoint de réplica de
  lectura** (`cluster-ro-`), derivado del endpoint de escritura que documenta el
  runbook de R1, porque es lo que sostiene la garantía `endpoint-replica-lectura`
  que el brief manda declarar. **No se pudo verificar contra la cuenta AWS**
  (sin credenciales acá). Si el cluster no tuviera réplica, lo que hay que
  corregir es la garantía de la entrada, no el host. Anotado en el README como
  comprobación previa al primer uso real (`describe-db-clusters`,
  `ReaderEndpoint`).
- **`catalogo_invalido` se mapeó al código 2.** La tabla de errores del contract
  no cubre "el catálogo no se puede leer o no valida"; se lo trató como error de
  configuración, del mismo lado que el uso incorrecto. Ningún AC depende de esa
  elección. Documentado en el README.
- **El modo de una sola consulta (`--consultar`) existe para que los exit codes
  de la tabla sean observables de verdad.** El servidor MCP vive toda la sesión
  y no puede salir por consulta, así que en modo servidor el código viaja en el
  campo `codigo` del cuerpo. Los tests afirman **los dos** caminos, y dan el
  mismo código.
- **El brief pide dieciséis triples; el contract declara diecisiete** (incluye
  AC38). Se corrieron los diecisiete.
- **El layout de `doc_architecture.md` no lista `ver-video` ni `usage-monitor`**
  (omisión **preexistente**, no introducida acá). No se tocó: está fuera del
  alcance de AC39, que pide `bisalta-db`. Queda señalado.

## 7. Deuda que este trabajo deja registrada

- La **bitácora no rota**: sólo crece. Ya estaba declarado como deuda en el
  contract ("Out of scope").
- **`D34`** (el runner trunca el archivo de `-o` y obliga a re-pegar este
  addendum a mano) se confirmó otra vez en este ciclo.
