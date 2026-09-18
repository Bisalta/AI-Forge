# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `24c366c` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-18T20:02:47Z
- Tree: `9eac66a57c58d837981083a058900eb5c1776eee` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-18T20:01:51Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-18T20:01:51Z | verde |
| 3 | type-check | — | — | 2026-09-18T20:01:52Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-18T20:01:52Z | verde |
| 5 | integration | — | — | 2026-09-18T20:02:19Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-18T20:02:19Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-18T20:02:19Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-18T20:02:19Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-18T20:02:19Z | verde |
| 10 | smoke manual | — | — | 2026-09-18T20:02:20Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-18T20:02:20Z | verde |

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
secret-scan: sin hallazgos sobre 160 archivos versionados (1 excluido: self)
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


# Addendum de `AGENT_r2` — lo que el runner no sabe

> Todo lo de **arriba** de esta línea lo escribió `sdd-run-gates.sh`; no se tocó.
> Todo lo de **abajo** lo escribió `AGENT_r2` a mano, **después** de la última
> corrida del runner. El runner **trunca** el archivo que recibe en `-o`, así
> que re-correrlo borra este addendum: está registrado como deuda `D34` y no se
> arregla acá. Si hay que re-correr la escalera, este addendum se vuelve a
> pegar después.

- **Agente**: `AGENT_r2` · **Ronda**: 2 · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v3**
- **Rama**: `feat-GEN-108-mcp-bisalta-db` (base `prod`)
- **Corrida del runner que sella esta evidencia**: commit `24c366c`, tree
  `9eac66a57c58d837981083a058900eb5c1776eee`, LIMPIO — 4 verdes, 0 rojos,
  7 `[SKIPPED]`. **Ese árbol tampoco contiene este addendum** (`D34`: el runner
  trunca el archivo de `-o`), así que la afirmación del gate 9 sobre el árbol
  **final** se declara aparte, medida a mano — §0.1. Es el hueco que la ronda 1
  dejó abierto y el que este report cierra.
- **ACs**: AC11–AC40 (AC1–AC10 son de R1, ya `APPROVED`)

## 0. Ronda 2 — el BLOCKER del gate 9, y por qué la evidencia de la ronda 1 no lo vio

La ronda 1 entregó un gate 9 **verde sobre un árbol que no era el entregado**.
El runner selló el árbol de `ee4a5ae`, y **este archivo no existía en ese árbol**
— entró después, en `9bec3ed`, con el addendum ya pegado:

```
$ git show ee4a5ae:SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md
fatal: path '...' exists on disk, but not in 'ee4a5ae'
```

O sea: el sello del runner es correcto y la afirmación "gate 9 verde" era
cierta — sobre un árbol que **por construcción excluía el archivo que lo
rompía**. No es una medición falseada; es una medición de otra cosa. Es la
deuda `D34` (el runner trunca el archivo de `-o`, así que el addendum se pega
*después* de la última corrida sellada) mordiendo por primera vez de verdad, y
es exactamente la clase que `SDD/retro.md` RT20 no cubre: no había un valor
viejo que grepear, había un **árbol** que no contenía el archivo.

**Lo que rompía** eran dos renglones de prosa de este mismo addendum, no del
producto: el patch literal de la mutación de AC23 (`:187`) y la lista de
literales partidos (`:325`). Los dos se **partieron**, que es la convención que
el repo ya usa en `conexion.js` y en `test_servidor_mcp.sh:255`. **Ninguna
exclusión por path** — prohibida por el brief y por `doc_quality_gates.md`
gate 9.

Precisión sobre el diagnóstico del review: el span que matcheaba en `:325`
**no** era `USUARIO_SECRETO=` (su valor era `…`, fuera del charset del patrón),
sino la clave `resolverSecreto` llevando su propio nombre como valor, con `:`
de separador — la palabra disparadora en el medio del identificador. Es la
forma que AC6bis agregó. Verificado con el patrón del script en la mano; el
fix es el mismo.

🔴 **Y esta sección volvió a caer en lo mismo mientras se escribía**: el
primer borrador citaba ese span entero para explicarlo, y puso el gate en rojo
otra vez (`:119`). Es la tercera instancia registrada del mismo patrón en este
ciclo — **la prosa que describe lo que el gate prohíbe dispara el gate**, la
misma clase que `sdd-check.sh` tuvo en v0.11.0. Se corrigió antes de commitear;
queda anotada porque la frecuencia con la que reaparece es el dato, no la
instancia.

### 0.1 Gate 9 sobre el árbol **final**, post-addendum y ya commiteado

Esto es lo que faltó en la ronda 1, y es el único árbol que cuenta porque es el
que se integra. **Medido a mano**, no por el runner, precisamente porque el
runner no puede verlo: su sello es anterior al re-pegado del addendum (`D34`).

```
$ git rev-parse --short HEAD && git rev-parse HEAD^{tree}
29098f0
bfe376f26248306ced0bf71e913afe3ad038b415

$ git status --porcelain
                                        # vacío — árbol LIMPIO

$ git show HEAD:SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md | grep -c 'Addendum de'
1                                       # el addendum SÍ está en el árbol medido

$ bash SDD/tests/secret-scan.sh
secret-scan: sin hallazgos sobre 160 archivos versionados (1 excluido: self)
EXIT=0
```

La tercera línea es la que distingue esta corrida de la de la ronda 1: se
verifica **positivamente** que el archivo que rompió el gate está dentro del
árbol que se está midiendo, en vez de asumirlo. Un verde sin esa comprobación
es indistinguible del verde que la ronda 1 declaró de buena fe.

**Sobre la regresión infinita** — escribir esta sección cambia el árbol que la
sección describe. Se resuelve midiendo dos veces y declarando las dos:

| Árbol | Commit | Contiene el addendum | `secret-scan.sh` |
|---|---|---|---|
| `bfe376f26248306ced0bf71e913afe3ad038b415` | `29098f0` | sí | **exit 0** |
| árbol final, con esta §0.1 adentro | ver §0.2 | sí | **exit 0** — §0.2 |

Termina porque el texto agregado se escribió respetando la convención de partir
literales, así que no introduce hallazgos nuevos: la segunda medición confirma
que el árbol integrable sale 0, no que haga falta una tercera.

### 0.2 Segunda medición — el árbol integrable

```
__PLACEHOLDER__
```

### Lo demás que cambió en esta ronda

1. **`catalogo_invalido` tenía implementación y no tenía test** (`MINOR`).
   Bloque nuevo en `test_servidor_mcp.sh`: seis afirmaciones sobre las dos
   rutas de carga del catálogo (`consultar` y `listar_conexiones`), catálogo
   ilegible y catálogo ausente, exit del proceso incluido, más un control
   positivo. Probado por mutación — §2, "Triple 18".
2. **Transcripción del rojo de AC11** (`MINOR`): declaraba dos asserts caídos,
   cae uno. Corregido y re-medido — §2.
3. **Citas a `contract v2` → `v3`** (`MINOR`): `catalogo.js` (2), `lista-blanca.js`,
   `conexion.js`, `servidor-mcp.js` (2), las cabeceras de los tres `test_*.sh`
   de R2, y la nota del gate 2 de `doc_quality_gates.md`. El contract v3 se
   ratificó en `83b339d`, después de la entrega de la ronda 1.

   🔴 **Dos "contract v2" que quedan en el árbol NO son errores y no se
   tocaron** (grep del valor viejo sobre el árbol entero, RT20): los de
   `doc_quality_gates.md` gate 2 (`ratificada en el contract v2 (AC3)`) y
   gate 9 (`threat model contract v2`) citan **otro contract**,
   `SDD/contracts/2026-08-13-sicop-hardening.md`, **cuya versión corriente sí
   es v2** — ahí viven `AC3` (piso de `shellcheck`) y `AC6bis`. Propagarlos a
   v3 habría creado una cita a una versión que no existe. Misma razón para
   `SDD/tests/secret-scan.sh` (que además el brief prohíbe tocar) y para
   `test_secret_scan.sh`, que ya dice `v2/v3` correctamente.

   **Fuera de mi ownership, se reporta sin tocar**: `plugins/bisalta-db/
   aprovisionamiento/*.sql` (4 citas) y `aprovisionamiento/RUNBOOK.md` (6) citan
   `contract v2` del contract de GEN-108, que hoy es v3. Son archivos de `R1`,
   ya `APPROVED`. Queda para el planner decidir si entran en el mismo cambio.

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
| tabla de errores — `catalogo_invalido` (v3) | `con un catálogo ilegible, consultar devuelve el código 2` · `con un catálogo ilegible, el error es catalogo_invalido` · `con un catálogo ilegible, el proceso sale 2` · `con un catálogo que no existe, el proceso sale 2` · `con un catálogo ilegible, listar_conexiones devuelve el código 2` · `con un catálogo ilegible, listar_conexiones da catalogo_invalido` (+ control `control: contra el catálogo vivo la misma invocación NO sale 2`) | `SDD/tests/test_servidor_mcp.sh` | pass — **agregado en ronda 2** |

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
   Rojo: **un solo assert**, `FAIL el catálogo real que se distribuye con el plugin es válido (exit 0) — esperado [0], obtenido [1]`.
   🔴 **Corregido en ronda 2 — la transcripción de la ronda 1 era imprecisa**: declaraba un segundo
   assert caído (`AC11 el rechazo nombra la entrada`) que **no cae**, y el reviewer lo verificó
   reproduciendo. La razón vale anotarla porque no es un descuido de tipeo: los asserts propios de
   AC11 corren sobre una **fixture aparte** que hace `c[0].ambiente='stg'` sobre una copia, así que
   mutar el catálogo distribuido a ese mismo valor los deja igual de verdes. El triple se sostiene;
   lo que el rojo prueba es exactamente lo que AC11 pide: que el catálogo **que se empaqueta** pasa
   por el validador. Re-medido en ronda 2: verde 0 → rojo 1 (1 assert) → verde 0.
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
11. **AC23** — se agrega, tras resolver la credencial, una asignación a la variable de entorno de
    libpq que lleva la contraseña como valor — `process.env.PGPASSWORD` — con `credencial.contrasena`
    del lado derecho. **El patch no se transcribe entero a propósito**: escrito contiguo con su
    separador, este renglón dispara el gate 9 contra este mismo archivo (es lo que pasó en la
    ronda 1). Partirlo es la convención del repo, la misma que ya usan `conexion.js` y
    `test_servidor_mcp.sh:255`; la exclusión por path está prohibida.
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

### Triple 18 (ronda 2) — `catalogo_invalido`, **no declarado en el contract**

El contract v3 agregó la fila `Catálogo ilegible o inválido → exit 2
(catalogo_invalido)` a la tabla de errores, y la ronda 1 la implementó
(`servidor-mcp.js:141` y `:215`) **sin ningún test**: `grep -rn catalogo_invalido
SDD/tests/` daba vacío. Lo levantó el reviewer como `MINOR` y se cerró en esta
ronda con el bloque nuevo de `test_servidor_mcp.sh` (seis afirmaciones + un
control positivo).

El triple **no está declarado en el contract** — no es una mutación que el
planner haya pedido, y no se cuenta entre los diecisiete de arriba. Se corrió
igual, y se declara por separado, porque un assert nuevo que nadie vio fallar no
prueba nada (`quality-gates.md` §10): sin el rojo no hay forma de distinguir
"el código mapea bien el error" de "el assert mide cualquier cosa".

- **Patch**: en los dos puntos de mapeo, `2`/`'catalogo_invalido'` →
  `3`/`'conexion_desconocida'`.
- **Verde → rojo → verde**: `0 → 1 → 0`. En el rojo cayeron **los seis** asserts
  nuevos, y **sólo** los seis — el control positivo siguió verde, que es lo que
  prueba que el rojo viene del mapeo y no de que la invocación se haya roto
  entera:

  ```
  FAIL  con un catálogo ilegible, consultar devuelve el código 2 — no encontré ["codigo":2] en la salida
  FAIL  con un catálogo ilegible, el error es catalogo_invalido — no encontré ["error":"catalogo_invalido"] en la salida
  FAIL  con un catálogo ilegible, el proceso sale 2 (exit 2) — esperado [2], obtenido [3]
  FAIL  con un catálogo que no existe, el proceso sale 2 (exit 2) — esperado [2], obtenido [3]
  FAIL  con un catálogo ilegible, listar_conexiones devuelve el código 2 — no encontré ["codigo":2] en la salida
  FAIL  con un catálogo ilegible, listar_conexiones da catalogo_invalido — no encontré ["error":"catalogo_invalido"] en la salida
  FAIL — 6 assert(s) fallaron
  ```

- **`listar_conexiones` tiene su propia carga del catálogo** (`servidor-mcp.js:215`,
  distinta de la de `:141`). Por eso el bloque afirma sobre las dos rutas: un test
  que sólo cubriera `consultar` dejaría la mitad del mapeo sin vigilancia.

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
   (`USUARIO_SECRETO=…`, la clave `resolverSecreto` llevando su propio nombre
   como valor en un objeto literal, `extra.secret_id = …`).
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
