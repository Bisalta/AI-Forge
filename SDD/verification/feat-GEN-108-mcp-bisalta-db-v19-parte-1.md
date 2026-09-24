# Verification Report — AGENT_r1 · v19 parte 1 (timeout en el rol, ALTER ROLE, esquema public)

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5). Brief: `SDD/briefs/v19-parte-1-timeout-alter-role-public.md`. Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v19, ACs **AC28**, **AC49**, **AC50**.

- **Branch**: `feat-GEN-108-mcp-bisalta-db`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v19
- **Commit evaluado**: `b5e9239202693b993b078e3cd1542977bfa93709`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — `sha256:56736c3e5b778ea1` (tomado del encabezado del reporte generado, no recalculado a mano)

---

## Gates — evidencia GENERADA

```
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1-gates.md
```

- **Reporte generado**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1-gates.md`
- **Resumen** (línea `sdd.gates` del runner): `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1-gates.md"}`
- Corrida sobre árbol **LIMPIO** (`Tree: c598a71ad412788bead8a624d47d4835420719fc`), commit `b5e9239`, exit del runner `0`.
- No hubo rojos intermedios en esta tarea: el único rojo que existió en el ciclo es el de la prueba por mutación de AC28 (abajo), que es evidencia intencional, no un fallo real.

---

## AC ↔ test binding

| AC | Comportamiento | Test | Tipo | Estado |
|---|---|---|---|---|
| AC28 | El comando de Postgres lleva `default_transaction_read_only=on` y **no** lleva `statement_timeout` (el límite lo fija el rol, AC49) | `SDD/tests/test_servidor_mcp.sh::"AC28 el comando abre la sesión en solo lectura"` y `SDD/tests/test_servidor_mcp.sh::"AC28 PGOPTIONS no lleva statement_timeout (el límite lo fija el rol, AC49)"` | unit (harness con stub) | [x] |
| AC49 | `postgres-parte-a.sql` aplica `ALTER ROLE claude_lectura SET` con los cuatro valores, fuera del bloque condicional | `manual-only` — ver "Smoke manual" abajo; verificación contra el motor la hace el planner | manual | [x] (código + runbook escritos; verificación contra motor diferida al planner) |
| AC50 | `postgres-parte-b.sql`: `GRANT CREATE ON SCHEMA public` al dueño + roles con objetos existentes, **después** `REVOKE ... FROM PUBLIC` | `manual-only` — ver "Smoke manual" abajo; verificación contra el motor la hace el planner | manual | [x] (código + runbook escritos; verificación contra motor diferida al planner) |

El nombre de test de AC28 existe literal en `SDD/tests/test_servidor_mcp.sh` (grepeable).

---

## Prueba por mutación (AC de detección) — AC28

**Mutación declarada en el contract** (v19, debajo de AC28): *"volver a agregar `statement_timeout` a `PGOPTIONS` pone rojo el assert negativo"*.

Script del triple: `/private/tmp/claude-501/-Users-ian-vargas-Documents-GitHub-AI-Forge/369e3696-8032-4820-85a1-c41b707ef169/scratchpad/ac28-mutation.sh` (scratchpad de la sesión, no versionado — el contenido queda pegado acá completo para que la corrida sea auditable sin el archivo).

```bash
#!/usr/bin/env bash
# Triple de mutación AC28 — contract v19: "volver a agregar statement_timeout
# a PGOPTIONS pone rojo el assert negativo".
set -u
cd /Users/ian.vargas/Documents/GitHub/AI-Forge
ARCHIVO="plugins/bisalta-db/scripts/conexion.js"
TEST="SDD/tests/test_servidor_mcp.sh"

echo "== 1) VERDE — sistema intacto =="
bash "$TEST" >/tmp/ac28-run1.log 2>&1
EC1=$?
echo "exit=$EC1"

echo "== aplicando la mutacion (re-agregar statement_timeout a PGOPTIONS) =="
python3 - <<'PYEOF'
import re
p = "plugins/bisalta-db/scripts/conexion.js"
s = open(p).read()
old = "      PGOPTIONS: '-c default_transaction_read_only=on',"
new = "      PGOPTIONS: '-c default_transaction_read_only=on' + ' -c statement_timeout=' + TIMEOUT_SENTENCIA_MS,"
assert old in s, "no se encontro la linea a mutar"
s2 = s.replace(old, new, 1)
open(p, "w").write(s2)
PYEOF

echo "== control: git diff --quiet detecta la mutacion aplicada =="
git diff --quiet -- "$ARCHIVO"
EC_DIFF_APLICADA=$?
echo "git diff --quiet exit=$EC_DIFF_APLICADA (distinto de 0 = mutacion aplicada, esperado)"

echo "== 2) ROJO — con la mutacion aplicada =="
bash "$TEST" >/tmp/ac28-run2.log 2>&1
EC2=$?
echo "exit=$EC2"

echo "== revirtiendo la mutacion =="
git checkout -- "$ARCHIVO"

echo "== control: git diff --quiet tras revertir =="
git diff --quiet -- "$ARCHIVO"
EC_DIFF_REVERTIDA=$?
echo "git diff --quiet exit=$EC_DIFF_REVERTIDA (0 = arbol limpio, esperado)"

echo "== 3) VERDE — tras revertir =="
bash "$TEST" >/tmp/ac28-run3.log 2>&1
EC3=$?
echo "exit=$EC3"

echo
echo "RESUMEN: verde1=$EC1 diff_aplicada=$EC_DIFF_APLICADA rojo=$EC2 diff_revertida=$EC_DIFF_REVERTIDA verde2=$EC3"
```

### AC28 — PGOPTIONS no lleva `statement_timeout`

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/test_servidor_mcp.sh` | 0 | verde |
| 2 | con la mutación aplicada (re-agregado `statement_timeout` a `PGOPTIONS`) | `bash SDD/tests/test_servidor_mcp.sh` | 1 | rojo — sólo el assert negativo de AC28 cae |
| 3 | mutación revertida (`git checkout -- plugins/bisalta-db/scripts/conexion.js`) | `bash SDD/tests/test_servidor_mcp.sh` | 0 | verde |

Control de que la mutación realmente se aplicó y realmente se revirtió — `git diff --quiet` sobre el archivo mutado:

| Momento | Comando | Exit code | Significa |
|---|---|---|---|
| con la mutación aplicada | `git diff --quiet -- plugins/bisalta-db/scripts/conexion.js` | 1 | el archivo difiere de HEAD — la mutación está puesta |
| tras revertir | `git diff --quiet -- plugins/bisalta-db/scripts/conexion.js` | 0 | el archivo volvió a HEAD — la reversión es real, no supuesta |

Salida completa de la corrida del script (paste literal, corrida el 23-sep-2026):

```
== 1) VERDE — sistema intacto ==
exit=0
== aplicando la mutacion (re-agregar statement_timeout a PGOPTIONS) ==
== control: git diff --quiet detecta la mutacion aplicada ==
git diff --quiet exit=1 (distinto de 0 = mutacion aplicada, esperado)
== 2) ROJO — con la mutacion aplicada ==
exit=1
== revirtiendo la mutacion ==
== control: git diff --quiet tras revertir ==
git diff --quiet exit=0 (0 = arbol limpio, esperado)
== 3) VERDE — tras revertir ==
exit=0

RESUMEN: verde1=0 diff_aplicada=1 rojo=1 diff_revertida=0 verde2=0
```

La única línea que falló en la corrida 2 (paste literal de `/tmp/ac28-run2.log`), confirmando que es exactamente el assert negativo de AC28 y ningún otro:

```
  ok    AC28 el comando abre la sesión en solo lectura
  FAIL  AC28 PGOPTIONS no lleva statement_timeout (el límite lo fija el rol, AC49) — encontré [statement_timeout] y no debería estar
```

`SDD/tests/test_servidor_mcp.sh::"un statement_timeout alcanzado devuelve tiempo_agotado"` no se movió por esta mutación: esa aserción sólo mira el código de error (`"error":"tiempo_agotado"`), no el mensaje de texto ni el contenido de `PGOPTIONS`, así que no era la que este AC vigila.

Después de la corrida, el árbol quedó en el estado post-mutación revertida — confirmado arriba (`git diff --quiet` exit 0) y con la suite completa corrida de nuevo (`bash SDD/tests/run.sh` → `17 passed, 0 failed (17 total)`), y con el runner de gates corrido sobre ese mismo árbol limpio (sección "Gates" arriba, `Tree: c598a71...`, exit `0`).

---

## Smoke manual (ACs `manual-only`) — AC49 y AC50

**Regla del brief: ninguna conexión a ninguna base.** `AC49` y `AC50` son `manual-only` y el contract dice explícito: *"su verificación contra el motor la hace el planner"*. Este agente no ejecutó ningún paso contra el cluster real. Lo que se entrega acá es el código y la documentación (`postgres-parte-a.sql`, `postgres-parte-b.sql`, `RUNBOOK.md` secciones "AC49" y "AC50") con los comandos exactos que el runbook deja escritos para que el planner los corra.

### AC49 — pasos que el runbook deja listos (no ejecutados por este agente)

1. Correr `postgres-parte-a.sql` contra el cluster (ya contiene el `ALTER ROLE` de los cuatro valores, fuera del bloque condicional).
2. Conectarse **como el rol** y correr el `SELECT current_setting(...)` de los cuatro parámetros que el runbook especifica (`RUNBOOK.md`, sección "AC49").
3. Esperado: `on`, `60s`, `30s`, `5s`.

**Evidencia mínima ya aceptada por el contract** (no generada por este agente, citada del contract): la lectura de `pg_db_role_setting` del 23-sep-2026 que Patrick Ocampo hizo y que ya muestra los cuatro valores sobre el rol.

**No ejecutado por AGENT_r1** — código y documentación listos; paso 1 y 2 quedan para el planner.

### AC50 — pasos que el runbook deja listos (no ejecutados por este agente)

1. Correr `postgres-parte-b.sql` contra cada base del catálogo (ya contiene el `GRANT` al dueño + roles con objetos existentes en `public`, seguido del `REVOKE ... FROM PUBLIC`).
2. Conectarse como `claude_lectura` e intentar `CREATE TABLE` en `public` (`RUNBOOK.md`, sección "AC50") — esperado: `permission denied for schema public`.
3. Control positivo: el mismo `CREATE TABLE` de scratch, conectado como el dueño de la base (o un rol que ya crea ahí), tiene que pasar.
4. `REVOKE CONNECT ON DATABASE postgres FROM PUBLIC` — paso explícito del runbook, no de ningún script — y su verificación (conectar como `claude_lectura` a `postgres` tiene que fallar con `permission denied for database "postgres"`).

**No ejecutado por AGENT_r1** — código y documentación listos; los cuatro pasos quedan para el planner.

---

## Impact set

| Símbolo cambiado | Caller | Cobertura |
|---|---|---|
| `construirComandoPostgres()` (`plugins/bisalta-db/scripts/conexion.js`) — `PGOPTIONS` ya no lleva `statement_timeout` | `ejecutarConsulta()` en el mismo archivo (única invocación) | AC28, `test_servidor_mcp.sh` (verifica `PGOPTIONS` vía el log del stub de `psql`) |
| `ejecutarConsulta()` (`plugins/bisalta-db/scripts/conexion.js`) — mensajes de `tiempo_agotado` distintos según corte de motor o de proceso | `plugins/bisalta-db/scripts/servidor-mcp.js:171` (única invocación) | `test_servidor_mcp.sh::"un statement_timeout alcanzado devuelve el código 7"` y `"...devuelve tiempo_agotado"` — cubren el código, no el texto del mensaje (el contract no exige un test de texto exacto para estos dos mensajes); mutación AC28 (arriba) confirma que el cambio de `PGOPTIONS` no rompe esas dos aserciones |
| `postgres-parte-a.sql` — `ALTER ROLE` nuevo | ninguno (script standalone, ejecución manual contra el cluster) | `manual-only`, AC49 |
| `postgres-parte-b.sql` — bloque `GRANT`/`REVOKE` de `public` nuevo | ninguno (script standalone, ejecución manual contra el cluster) | `manual-only`, AC50 |
| `RUNBOOK.md`, `README.md` | ninguno (prosa) | revisadas por el barrido de T4 (abajo) |

No hay callers automatizados de los `.sql` (son ejecutados a mano contra la infraestructura real, fuera del harness de este repo) — consistente con su clasificación `manual-only` en el contract.

---

## Barrido T4 (README/description) — `grep -rn -i "120000\|120 s\|statement_timeout\|guarda que decide\|lista blanca" plugins/bisalta-db/`

```
plugins/bisalta-db/README.md:106:   `statement_timeout=120000` por `PGOPTIONS`, y le ganaba al del rol): lo
plugins/bisalta-db/README.md:107:   fija el rol (`ALTER ROLE claude_lectura SET statement_timeout = '60s'`,
plugins/bisalta-db/README.md:110:3. **La lista blanca** exige que *cada* sentencia empiece con `SELECT` o
plugins/bisalta-db/README.md:124:### Por qué lista blanca y no lista negra
plugins/bisalta-db/README.md:145:Si de verdad hace falta escribir, **no se amplía la lista blanca**: se corre a
plugins/bisalta-db/README.md:297:| Sentencia rechazada por la lista blanca | 4 | `no_es_lectura`, con los primeros 90 caracteres de la sentencia ofensora |
plugins/bisalta-db/README.md:300:| Tiempo agotado: el motor corta por su propio límite de sentencia (Postgres: `statement_timeout` del rol, 60s — v19), o el plugin corta el proceso (125 s, los dos motores) | 7 | `tiempo_agotado` |
plugins/bisalta-db/README.md:379:(`bash SDD/tests/run.sh`). Ninguno necesita una base: la lista blanca se
plugins/bisalta-db/scripts/conexion.js:29:const TIMEOUT_SENTENCIA_MS = 120000;
plugins/bisalta-db/scripts/conexion.js:30:// Desde v19 (AC28) esto ya NO se manda al motor como `statement_timeout`: el
plugins/bisalta-db/scripts/conexion.js:142: * AC28 (sesión de solo lectura; el `statement_timeout` ya no viaja por acá,
plugins/bisalta-db/scripts/conexion.js:165:      // AC28 (v19): PGOPTIONS deja de llevar `statement_timeout` — el rol lo
plugins/bisalta-db/scripts/conexion.js:263: * Corre la consulta y devuelve las filas. La lista blanca ya la validó: acá
plugins/bisalta-db/scripts/conexion.js:317:      // lo fija, no el plugin). No cita 120000 ms: ese ya no es el límite
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:1161:`default_transaction_read_only = on`, `statement_timeout = '60s'`,
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:1170:psql -h sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com -U claude_lectura -d proveedores_dev -c "SELECT current_setting('default_transaction_read_only'), current_setting('statement_timeout'), current_setting('idle_in_transaction_session_timeout'), current_setting('lock_timeout');"
plugins/bisalta-db/scripts/servidor-mcp.js:160:  // La lista blanca corre ANTES de conectar: una validación que corriera
plugins/bisalta-db/.claude-plugin/plugin.json:4:  "description": "Consulta de solo lectura a las bases de dev/qa de Bisalta desde Claude Code, sin que ninguna credencial entre en el contexto de la sesion. Servidor MCP propio sobre stdio, cero dependencias npm: lista blanca por dialecto anclada al principio de cada sentencia que ademas rechaza escrituras embebidas (INSERT, UPDATE, DELETE, MERGE o INTO en cualquier posicion, incluido SELECT ... INTO y un WITH con escritura adentro), catalogo donde produccion es irrepresentable, y la credencial resuelta desde AWS Secrets Manager en cada invocacion.",
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:84:ALTER ROLE claude_lectura SET statement_timeout = '60s';
plugins/bisalta-db/scripts/lista-blanca.js:11:// 🔴 LISTA BLANCA, NO LISTA NEGRA, Y ANCLADA AL PRINCIPIO DE LA SENTENCIA.
plugins/bisalta-db/scripts/lista-blanca.js:18:// Una lista blanca por dialecto: un mismo patrón estaría mal en alguna
plugins/bisalta-db/scripts/lista-blanca.js:97: * Veredicto de la lista blanca.
```

Revisión de cada aparición contra v19:

- `README.md:106-107` — contexto histórico ("hasta v18 mandaba... y le ganaba al del rol"), no presenta el valor viejo como vigente. Corregido en este ciclo (era la línea que citaba `statement_timeout=120000` sin contexto).
- `README.md:110` — reescrito: ya no dice "primera barrera, no la única" en abstracto; dice explícito **"no es la barrera que impide una escritura"** y nombra las capas que sí (réplica, sesión, rol), citando la revisión de Patrick (v19 punto 4/5).
- `README.md:124, 145, 297, 379` — menciones de "lista blanca" que describen mecánica (por qué lista blanca y no negra, qué rechaza, qué prueba el harness) sin afirmar que es la barrera que impide el daño. Sin cambio necesario.
- `README.md:300` — reescrito: ya no dice "`statement_timeout` (120 s)" como si fuera el límite vigente; ahora distingue corte de motor (rol, 60s) de corte de proceso (125s, ambos motores), consistente con `conexion.js`.
- `conexion.js:29-30, 142, 165, 317` — comentarios nuevos/actualizados de este mismo ciclo, ya consistentes con v19 (declaran que `TIMEOUT_SENTENCIA_MS` ya no se manda como `statement_timeout`, y que el mensaje de corte de motor no cita `120000`).
- `conexion.js:263` — "la lista blanca ya la validó" es una afirmación de orden de ejecución (corre antes), no una afirmación de que sea la barrera que impide el daño. Sin cambio necesario.
- `RUNBOOK.md:1161, 1170` — sección nueva de AC49 de este mismo ciclo, con el valor correcto (`60s`, fijado por el rol). Consistente con v19.
- `servidor-mcp.js:160` — comentario de orden de ejecución ("corre ANTES de conectar"), no una afirmación de barrera contra el daño, y el brief exige revisar sólo la `description` de la herramienta `consultar` y su parámetro `sql` (ver abajo) — ese comentario no es ninguna de las dos. Sin cambio necesario.
- `servidor-mcp.js` — `description` de `consultar` (línea 223) y de su parámetro `sql` (línea 233): revisadas íntegras. Ninguna cita `120` ni presenta la lista blanca como barrera — describen qué rechaza (comportamiento observable), no una garantía de que sea lo único que lo hace. **No se tocó el archivo** (el brief dice "sólo si... nada más del archivo", y ninguna condición se cumplió).
- `plugin.json:4` — fuera del alcance de este brief (no está en la tabla de archivos a tocar); describe funcionalidad sin citar `120` ni presentar la lista blanca como barrera de daño. Sin cambio.
- `postgres-parte-a.sql:84` — el `ALTER ROLE` nuevo de este mismo ciclo, valor correcto (`60s`).
- `lista-blanca.js:11,18,97` — **no tocado**, fuera de alcance de este brief (`AC51`/`AC52`, reservado para el archivo de casos de Patrick Ocampo). Ninguna de las tres líneas afirma que sea la barrera que impide el daño; son nombres/comentarios de diseño ("lista blanca, no lista negra", "veredicto de la lista blanca").

---

## Rojos preexistentes

Ninguno. La suite completa (`bash SDD/tests/run.sh`) corrió en verde antes de empezar esta tarea (commit `ba4ff79`, HEAD de partida) y después de terminarla (commit `b5e9239`): `17 passed, 0 failed (17 total)` en las dos corridas.

---

# Sección del planner — `AC28`, `AC49` y `AC50` contra el motor (no lo escribió `AGENT_r1`)

Corrido el 23-sep-2026 con el servidor **del repo** (`node plugins/bisalta-db/scripts/servidor-mcp.js` por stdio), sobre `f3d15ca`. No con el plugin instalado: esa copia todavía manda `statement_timeout=120000` y no sirve para verificar `AC28`. Sólo lecturas.

Consulta, en las seis conexiones Postgres del catálogo:

```
SELECT current_database() AS base, current_setting('default_transaction_read_only') AS ro, current_setting('statement_timeout') AS stmt, current_setting('idle_in_transaction_session_timeout') AS idle, current_setting('lock_timeout') AS lock, has_schema_privilege('public','CREATE') AS crea_en_public
```

Respuestas literales, campo `filas`:

- `proveedores-dev` → `{"base":"proveedores_dev","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`
- `proveedores-qa` → `{"base":"proveedores_qa","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`
- `smartcheck-dev` → `{"base":"smartcheck_dev","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`
- `smartcheck-qa` → `{"base":"smartcheck_qa","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`
- `smartfleet-dev` → `{"base":"smartfleet_dev","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`
- `smartfleet-qa` → `{"base":"smartfleet_qa","ro":"on","stmt":"1min","idle":"30s","lock":"5s","crea_en_public":"f"}`

**Qué prueba:**
- `AC28` — **efecto**, no sólo la forma del comando: sin `statement_timeout` en `PGOPTIONS`, rige el del rol (`1min` = 60 s). Con la copia instalada de v18, que todavía lo manda, la misma consulta devolvía `2min` (medido el 23-sep).
- `AC49` — los cuatro valores del rol vigentes cuando el cliente no manda ninguno.
- `AC50` — `claude_lectura` no tiene `CREATE` en `public` en ninguna de las seis. Se verificó con `has_schema_privilege`, **sin intentar crear nada**: prueba el privilegio sin una escritura.

**Qué NO prueba:** lo aplicado hoy en el motor es lo que Patrick hizo **a mano** (el `ALTER ROLE` y el `REVOKE CREATE` del 22-sep). Coincide con lo que `postgres-parte-a.sql` y `postgres-parte-b.sql` ahora mandan, pero **los scripts nuevos no los corrió nadie**. Su primera corrida real —otro cluster, o recrear el rol— es la que va a probar que el script reproduce el estado.

---

# Agregado del planner en v21 (24-sep-2026) — respuesta a la review de v19 y v20

**Corrección a la sección anterior.** Decía que rigen "los cuatro valores del rol cuando el cliente no manda ninguno". No era exacto: el servidor manda `default_transaction_read_only=on` por `PGOPTIONS` (lo exige `AC28`), así que en esa lectura ese valor no distinguía rol de cliente. Medía tres de cuatro del lado del rol.

**`AC49` — la configuración del rol, leída del catálogo** (a través del plugin, 24-sep):

```
SELECT r.rolname AS rol, s.setconfig FROM pg_db_role_setting s JOIN pg_roles r ON r.oid = s.setrole WHERE r.rolname = 'claude_lectura' AND s.setdatabase = 0
→ {"rol":"claude_lectura","setconfig":"{default_transaction_read_only=on,statement_timeout=60s,idle_in_transaction_session_timeout=30s,lock_timeout=5s}"}
```

Los cuatro valores, configurados en el rol y no en la sesión.

**`AC50` — la enumeración de dueños de la Parte B, corrida en lectura** contra `proveedores_dev`, 24-sep. Por dueño, antes del cambio de v21:

```
AurAwsDbMaster  superusuario=f  relaciones=0  funciones=1   tipos=2
proveedores     superusuario=f  relaciones=8  funciones=0   tipos=4
rdsadmin        superusuario=t  relaciones=0  funciones=41  tipos=2
```

Con sólo `pg_class` recibía el `GRANT` únicamente `proveedores`; el usuario maestro quedaba afuera. La consulta de v21 —relaciones, funciones y tipos, sin superusuarios— devuelve `AurAwsDbMaster` y `proveedores`. Se corrió **sólo la consulta de enumeración**, en lectura; el script completo sigue sin correrse contra ninguna base.
