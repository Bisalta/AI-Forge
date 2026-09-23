# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `6371ac9` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-23T20:18:01Z
- Tree: `da7294379f9fc5fbd9f428486bc1062b10aeb9d0` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-23T20:16:59Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-23T20:16:59Z | verde |
| 3 | type-check | — | — | 2026-09-23T20:17:00Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-23T20:17:00Z | verde |
| 5 | integration | — | — | 2026-09-23T20:17:29Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-23T20:17:29Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-23T20:17:29Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-23T20:17:29Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-23T20:17:29Z | verde |
| 10 | smoke manual | — | — | 2026-09-23T20:17:30Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-23T20:17:30Z | verde |

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
secret-scan: sin hallazgos sobre 168 archivos versionados (1 excluido: self)
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

## Addendum — AGENT_r1 (T5 del brief, no generado por el runner)

Todo lo de arriba (hasta la línea en blanco previa a este encabezado) lo escribió `sdd-run-gates.sh`. Lo que sigue lo agrega el agente, sin tocar una sola línea de arriba.

### Alcance de esta ronda

`AC44` (precondición cerrada) y `AC48` (nuevo), contract v17. Ninguna conexión a ninguna base — este alcance no la necesita (regla innegociable del brief).

### Diff de los `.sql`

```diff
diff --git a/plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql b/plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
index 28bdcd3..19949a0 100644
--- a/plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
+++ b/plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql
@@ -62,6 +62,18 @@
 --
 -- Tolerante a que el user o el login no existan: correrlo sobre una
 -- instancia ya revertida, o dos veces seguidas, sale sin error.
+--
+-- AC48 / DENY VIEW ANY DATABASE — nada que revertir acá (revisado contract
+-- v17): este script no tiene guarda de instancia (a diferencia de
+-- sqlserver-parte-a.sql/-b.sql, que sí la tienen), así que no hay ningún
+-- `SET NOEXEC ON` ni rama condicional que salte el bloque final. El cursor
+-- de arriba recorre TODO `sys.databases` y, para cada base NO ONLINE, sólo
+-- hace `PRINT` y sigue — nunca corta la ejecución del batch. El
+-- `IF EXISTS (...) DROP LOGIN` de más abajo es, por lo tanto, el ÚNICO
+-- camino de salida del script y SIEMPRE se alcanza. Como el `DENY VIEW ANY
+-- DATABASE` es un permiso de servidor otorgado al login (no a un user de
+-- base), se va con el login cuando el `DROP LOGIN` corre: no queda ningún
+-- `DENY` huérfano que revertir a mano.
 
 DECLARE @db_name SYSNAME;
 DECLARE @sql NVARCHAR(MAX);
diff --git a/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql b/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
index 8f925b1..b36e421 100644
--- a/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
+++ b/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql
@@ -41,22 +41,29 @@
 -- `SET NOEXEC ON` — nada corre después, ni siquiera el CREATE LOGIN de
 -- abajo.
 --
--- VALOR SIN CONFIRMAR: `EC2AMAZ-2RGHL0C` sale de un registro de SSM, no de
--- una medición contra la instancia. Patrick Ocampo pidió explícitamente
--- confirmarlo corriendo `SELECT SERVERPROPERTY('MachineName')` conectado a
--- Dev SQL antes de fijarlo — textual: "si no coincide, el valor manda
--- sobre el mío". No se pudo medir en esta ronda porque el login todavía no
--- existe en esa instancia (dependencia circular: hace falta el login para
--- conectar, y el login es justamente lo que este script crea). RUNBOOK.md,
--- sección "Prerequisitos", manda medirlo como PRIMER PASO, antes de correr
--- este script contra Dev SQL — si la medición no coincide con el valor de
--- abajo, el valor medido manda y hay que actualizar esta línea antes de
--- ejecutar.
+-- VALOR MEDIDO (contract v17, "Cambios v16 → v17" punto 1): `EC2AMAZ-2RGHL0C`
+-- salió primero de un registro de SSM, y Patrick Ocampo lo MIDIÓ el
+-- 23-sep-2026 corriendo `SELECT SERVERPROPERTY('MachineName')` vía SSM
+-- contra la instancia de Dev SQL ya aprovisionada. Coincide con el valor de
+-- abajo. La precondición que pedía confirmarlo antes de fijarlo (nota de
+-- v13, ya no aplica) queda cerrada.
+--
+-- DENY DE ENUMERACIÓN (contract v17, AC48): Patrick aprovisionó y, conectado
+-- COMO EL LOGIN (no como administrador), encontró que `bisalta_lectura`
+-- podía listar los 36 nombres de base del servidor vía `sys.databases` —
+-- entra a `master` por `guest`, no por un user propio, así que ninguna
+-- verificación de membresía (AC7/AC42/AC43) lo veía. Lo cerró con
+-- `DENY VIEW ANY DATABASE TO [bisalta_lectura]`, abajo, DESPUÉS del bloque
+-- que crea el login y FUERA de su condicional: el `DENY` es idempotente, así
+-- que cada corrida de este script lo vuelve a aplicar aunque el login ya
+-- exista. No es una garantía del catálogo (`garantias` mide qué frena una
+-- escritura; esto restringe qué metadatos se ven) — vive como fila propia
+-- en "Garantías por motor" del contract y en README.md.
 
 SET NOCOUNT ON;
 
 DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
-DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — SIN CONFIRMAR, ver comentario de arriba
+DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — MEDIDO 23-sep-2026 por Patrick Ocampo vía SSM, coincide (contract v17)
 
 IF @maquina <> @esperada
 BEGIN
@@ -70,3 +77,10 @@ BEGIN
   CREATE LOGIN bisalta_lectura WITH PASSWORD = '<PASSWORD_LECTURA_SQL>', CHECK_POLICY = ON;
 END
 GO
+
+-- AC48 — fuera del IF de arriba, a propósito: DENY es idempotente, así que
+-- cada corrida de este script lo vuelve a aplicar exista o no el login de
+-- antes. Sin esto, la enumeración de bases vuelve sola si el login se
+-- recrea (DROP LOGIN + CREATE LOGIN, ver sqlserver-inverso.sql).
+DENY VIEW ANY DATABASE TO [bisalta_lectura];
+GO
diff --git a/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql b/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
index e4412b1..6aa1f2e 100644
--- a/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
+++ b/plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql
@@ -113,13 +113,13 @@
 -- profundidad, con el mismo criterio que `@bases_prohibidas` más abajo:
 -- el criterio real es otro (la lista, o el login existente), pero la
 -- guarda de instancia no cuesta nada repetir y cierra la misma clase de
--- hueco. Mismo valor sin confirmar que sqlserver-parte-a.sql — ver su
--- comentario.
+-- hueco. Mismo valor, ya medido (contract v17) — ver el comentario de
+-- sqlserver-parte-a.sql.
 
 SET NOCOUNT ON;
 
 DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
-DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — SIN CONFIRMAR, ver sqlserver-parte-a.sql
+DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — MEDIDO, ver sqlserver-parte-a.sql
 
 IF @maquina <> @esperada
 BEGIN
```

### Diff de `RUNBOOK.md`

```diff
@@ Prerequisitos — MachineName ya medido @@
-- **Medir `SERVERPROPERTY('MachineName')` contra Dev SQL ANTES de correr
-  `sqlserver-parte-a.sql` o `sqlserver-parte-b.sql` (contract v13, AC44)**:
-  ... está **sin confirmar**. ...
+- **`SERVERPROPERTY('MachineName')` ya está medido (contract v17, "Cambios
+  v16 → v17" punto 1, AC44)**: Patrick Ocampo lo corrió el 23-sep-2026 vía
+  SSM contra la instancia de Dev SQL aprovisionada → `EC2AMAZ-2RGHL0C`,
+  coincide con `@esperada`.

@@ Orden de ejecución, paso 6 @@
-6. **Antes de correr nada de SQL Server**: medir `SERVERPROPERTY('MachineName')`
-   contra `Dev SQL` ... y confirmar o corregir `@esperada` ...
+6. **Antes de correr nada de SQL Server**: `SERVERPROPERTY('MachineName')`
+   ya está medido contra `Dev SQL` y coincide con `@esperada` (contract v17).
+   Si se apunta a una instancia distinta, medir ahí y corregir.

@@ Orden de ejecución, paso 7 (AC48 en la parte A) y paso 9 (AC48 al verificar) @@
+   El mismo script aplica el `DENY VIEW ANY DATABASE` de **AC48**.
...
-9. **Verificar AC5** contra `EXACTUS` y **AC42** (ver abajo).
+9. **Verificar AC5** contra `EXACTUS`, **AC42** (ver abajo) y **AC48** (ver
+   abajo) — AC42 mide membresía, AC48 mide qué ve el login conectado como tal.

@@ Sección AC7 — nota nueva @@
+**Nota (contract v17, punto 2)**: esta verificación mide membresía, no
+visibilidad. Lo que el login ve lo verifica AC48, no esta sección.

@@ Sección AC42 — nota nueva @@
+**Nota (contract v17, punto 2)**: ídem — membresía, no visibilidad. AC48
+verifica lo que el login ve.

@@ Sección AC43 — nota nueva @@
+**Nota (contract v17, punto 2)**: ídem. El inverso no toca el DENY: se va
+con el login al DROP LOGIN final.

@@ Sección AC44 — "Valor sin confirmar" reescrito a "Valor medido" @@
-**Valor sin confirmar**: ... esa medición **no se hizo en esta ronda** ...
+**Valor medido (contract v17)**: ... Patrick Ocampo lo midió el 23-sep-2026
+... y **coincide** ... la precondición ... queda cerrada.

@@ Sección AC48 — nueva, íntegra @@
+### AC48 — el login no enumera las bases del servidor
+(comprobación real conectado como el login, mutación declarada con el par
+antes/después de Patrick Ocampo, manual-only)
```

(diff completo de `RUNBOOK.md`: 125 líneas insertadas/eliminadas sobre el archivo real, capturado con `git diff` antes del commit `6371ac9`; el extracto de arriba resume cada hunk por concepto para no duplicar el archivo entero acá.)

### Barrido T3 — `grep -rn -i "sin confirmar\|MachineName" plugins/bisalta-db/`

Comando y salida, corridos después del commit, sobre el árbol ya modificado:

```
$ grep -rn -i "sin confirmar\|MachineName" plugins/bisalta-db/
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql:46:-- 23-sep-2026 corriendo `SELECT SERVERPROPERTY('MachineName')` vía SSM
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql:65:DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql:121:DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:167:- **`SERVERPROPERTY('MachineName')` ya está medido (contract v17, "Cambios
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:170:  `SELECT SERVERPROPERTY('MachineName');` → `EC2AMAZ-2RGHL0C`, que **coincide**
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:200:6. **Antes de correr nada de SQL Server**: `SERVERPROPERTY('MachineName')`
plugins/bisalta-db/aprovisionamiento/RUNBOOK.md:1040:**Valor medido (contract v17)**: la guarda compara `SERVERPROPERTY('MachineName')`
```

Cero apariciones de "sin confirmar" en todo `plugins/bisalta-db/`. Las siete apariciones restantes de `MachineName` son todas menciones del propio valor ya medido (código, comentarios y RUNBOOK) — ninguna dice que falte medirse. Barrido limpio.

### `sqlserver-inverso.sql` — el `DROP LOGIN`, ¿se alcanza en todos los caminos?

Revisado el script completo (no tiene guarda de instancia, a diferencia de las partes A y B). El cursor recorre `sys.databases` entero; para cada base con `state <> 0` (no `ONLINE`) sólo hace `PRINT` y continúa el bucle — nunca `RETURN`, `GOTO` ni `SET NOEXEC ON`. Al salir del bucle, el bloque final:

```sql
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bisalta_lectura')
BEGIN
  DROP LOGIN bisalta_lectura;
END
```

no está dentro de ninguna rama condicional que el resto del script pueda saltear — es el único camino de salida y **siempre se alcanza** (asumiendo que el batch no aborta por un error de ejecución, igual que cualquier script).

**Conclusión (el primer caso del brief, línea 29 de la tabla de archivos)**: el `DROP LOGIN` se alcanza siempre → el `DENY VIEW ANY DATABASE` se va con el login (permiso de servidor otorgado al principal `bisalta_lectura`, no a un user de base) → no hay nada que revertir en `sqlserver-inverso.sql`. Se agregó un comentario en el propio archivo (ver diff arriba) documentando este análisis; no hizo falta ningún cambio de código.

### Cifras de Patrick Ocampo — reportadas por él, no medidas por este agente

Citadas del brief (Slack, 23-sep-2026 13:04 y 13:05), tal como el planner las trasladó. Este agente no se conectó a ninguna base — regla innegociable del brief:

- `SERVERPROPERTY('MachineName')`, **medido por Patrick Ocampo** vía SSM contra la instancia: `EC2AMAZ-2RGHL0C`.
- Login `bisalta_lectura` con `db_datareader` en `COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`, `EXACTUS`, `BI`: **reportado por Patrick Ocampo**, en cada una `lee=1 escribe=0`.
- **Reportado por Patrick Ocampo**, verificado como el login: lee `COMPRAS` (84 tablas); `CREATE TABLE` → `Msg 262: CREATE TABLE permission denied in database 'COMPRAS'.`; `SSISDB` no la puede abrir; `CONSTRUPLAZA_EFLOW` (267 GB) no la puede abrir.
- Antes del `DENY` (**reportado por Patrick Ocampo**): el login listaba **36** nombres de base. Después de `DENY VIEW ANY DATABASE TO [bisalta_lectura];`: ve `master` y `tempdb`, y sigue leyendo las seis.
- **Reportado por Patrick Ocampo**: las cuatro tablas de usuario de `master` son `spt_fallback_*` y `spt_monitor`, de fábrica.

Ninguna de estas cifras fue medida por `AGENT_r1`: llegan del planner citando a Patrick, y este agente no tiene ni tuvo conexión a `Dev SQL` en ningún momento de esta tarea.

### Impact set

- `sqlserver-parte-a.sql`: sin callers dentro del repo (script standalone, se corre manualmente vía `sqlcmd` según RUNBOOK.md). Ningún test lo invoca — `doc_quality_gates.md` gate 4 lista `test_lista_blanca.sh`, `test_catalogo.sh`, `test_servidor_mcp.sh` como los únicos tests de `bisalta-db`, y ninguno lee `aprovisionamiento/` (confirmado en el brief, línea 35: "ningún test lee `aprovisionamiento/`, y v17 no pide uno"). Cubierto por: RUNBOOK.md sección AC44/AC48 (verificación manual-only) y este verification report.
- `sqlserver-parte-b.sql`, `sqlserver-inverso.sql`: mismo caso — sin callers en código, sin tests, cubiertos por RUNBOOK.md.
- `catalogo.json`: si tiene caller — `test_catalogo.sh` valida la forma del catálogo (nivel/condicion/objeto), no el contenido textual de `condicion`. Corrida como parte de la suite completa arriba (17/17 verde), sin cambios de comportamiento esperados: el cambio es sólo el texto de `condicion` en las seis entradas SQL Server, no su estructura (`nombre`/`nivel` no cambiaron).
- `README.md`: documentación, sin caller de código.

### Rojos preexistentes

Ninguno — la suite completa corrió 17/17 verde (ver tabla del runner arriba) sobre el árbol limpio en el commit `6371ac9`.


---

# Sección del planner — `AC44` y `AC48` a través del plugin **instalado** (no lo escribió `AGENT_r1`)

Corrido el 23-sep-2026 con la herramienta MCP `consultar` en una sesión de Claude Code reiniciada **después** de reinstalar el plugin. Qué código corría, medido antes de consultar: la copia instalada es de las 14:29:47, tiene la guarda de v16 (`no_es_replica` aparece 2 veces en su `conexion.js`) y el catálogo de v17 (`Msg 262` aparece en las 6 entradas de SQL Server); los cuatro procesos del servidor MCP arrancaron entre 14:30:14 y 14:30:34, o sea después de la copia.

Es la **primera consulta a SQL Server** a través del plugin. Respuestas literales, completas:

**`AC44` desde el consumidor** — la instancia a la que llega el login es la que la guarda espera:

```
{"conexion":"compras","dialecto":"sqlserver","filas":[{"login":"bisalta_lectura","base":"COMPRAS","maquina":"EC2AMAZ-2RGHL0C"}],"filas_devueltas":1,"truncado":false,"motivo_truncado":null}
```

**`AC48` desde el consumidor** — `SELECT name FROM sys.databases ORDER BY name`:

```
{"conexion":"compras","dialecto":"sqlserver","filas":[{"name":"COMPRAS"},{"name":"master"},{"name":"tempdb"}],"filas_devueltas":3,"truncado":false,"motivo_truncado":null}
{"conexion":"exactus","dialecto":"sqlserver","filas":[{"name":"EXACTUS"},{"name":"master"},{"name":"tempdb"}],"filas_devueltas":3,"truncado":false,"motivo_truncado":null}
```

**Esto contradijo el texto de `AC48`**, que decía "exactamente `master` y `tempdb`". La propiedad se cumple —el login no enumera las otras bases del servidor, ni siquiera las otras cinco que tiene concedidas—, pero cada conexión se ve también a sí misma. El texto venía del reporte de Patrick, medido desde `master` (la base por omisión del login, donde la lista sí es `master` y `tempdb`), y se volvió normativo sin ese contexto. Enmendado dentro de v17 en el contract, el README y el runbook: la propiedad es "`master`, `tempdb` y la base de la propia conexión, y ninguna otra".
