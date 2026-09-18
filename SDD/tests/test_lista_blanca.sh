#!/usr/bin/env bash
# SDD/tests/test_lista_blanca.sh — plugins/bisalta-db/scripts/lista-blanca.js.
# AC15-AC22 del contract SDD/contracts/2026-09-18-bisalta-db-mcp.md v2.
#
# Port de tests/consultaLecturaWrapper.test.mjs de Bisalta/Proveedores-Back
# (rama feat-PROV-131-api-comprassync): los doce casos, incluidos los cinco de
# subconsulta, que allá encontró una mutación y no la lectura.
#
# 🔴 EL VALOR ENTERO DE ESTA CAPA ES LO QUE RECHAZA. Una lista blanca que deja
# de rechazar en silencio es peor que no tenerla: da sensación de barrera que
# ya no existe, y nadie se entera hasta que algo escribe.
#
# No hay base acá, y no hace falta: se afirma el código de salida de la
# validación, que corre ANTES de conectar — una validación que corriera
# después ya habría mandado la sentencia.
#
# 🔴 SOBRE LOS CASOS "DISCRIMINANTES" DE AC21. Un input como `EXEC algo` a
# secas cae igual por el ancla común (no empieza con SELECT ni WITH), así que
# afirmarlo NO distingue la regla del dialecto de la regla común: con las
# reglas de sqlserver borradas seguiría dando 4, y la mutación declarada no
# podría ponerlo rojo — una medición muerta. Por eso cada regla de sqlserver
# se afirma DOS veces: con el input literal del AC, y con uno que las reglas
# comunes aceptan (se verifica que postgres lo acepta) y que sólo el dialecto
# rechaza.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LISTA_BLANCA="$REPO_ROOT/plugins/bisalta-db/scripts/lista-blanca.js"

if ! command -v node >/dev/null 2>&1; then
  echo "  FAIL  setup — node no está disponible (prerequisito de SDD/docs/doc_quality_gates.md)"
  exit 1
fi
if [ ! -f "$LISTA_BLANCA" ]; then
  echo "  FAIL  setup — no existe $LISTA_BLANCA"
  exit 1
fi

# Corre la validación y devuelve SÓLO su código de salida. El SQL entra por
# stdin: nunca por argv.
validar() {
  printf '%s' "$2" | node "$LISTA_BLANCA" "$1" >/dev/null 2>&1
  echo $?
}

# ---------------------------------------------------------------------------
# AC15 — las diez escrituras simples
# ---------------------------------------------------------------------------
# 🔴 ES LISTA BLANCA Y NO LISTA NEGRA, Y EL CASO QUE LO JUSTIFICA ES `DO`. Un
# bloque `DO $$ ... $$` puede hacer cualquier cosa, y una lista negra de
# INSERT/UPDATE/DELETE lo deja pasar entero.
while IFS='|' read -r etiqueta sql; do
  [ -z "$etiqueta" ] && continue
  ec="$(validar postgres "$sql")"
  assert_exit 4 "$ec" "AC15 rechaza $etiqueta"
done <<'CASOS'
un UPDATE|UPDATE proveedores.orden_compra SET moneda = 'X'
un DELETE|DELETE FROM proveedores.usuario
un INSERT|INSERT INTO proveedores.bitacora_proveedor (id) VALUES (1)
un TRUNCATE|TRUNCATE proveedores.logs
un DROP|DROP TABLE proveedores.orden_compra
un ALTER|ALTER TABLE proveedores.usuario ADD COLUMN x int
un GRANT|GRANT ALL ON proveedores.usuario TO alguien
un bloque DO|DO $bloque$ BEGIN INSERT INTO t VALUES (1); END $bloque$
un CALL|CALL algun_procedimiento()
un COPY|COPY proveedores.usuario FROM '/tmp/x.csv'
CASOS

# ---------------------------------------------------------------------------
# AC16 — las cinco escrituras que llevan una subconsulta adentro
# ---------------------------------------------------------------------------
# 🔴 EL CASO QUE SE LE HABÍA ESCAPADO AL ORIGINAL. Ninguna de las diez de
# arriba nombra SELECT ni WITH, así que una comprobación que buscara esas
# palabras en cualquier parte de la sentencia —en vez de exigirlas al
# principio— pasaba los once tests igual. Estas cinco son las que matan esa
# versión laxa.
while IFS='|' read -r etiqueta sql; do
  [ -z "$etiqueta" ] && continue
  ec="$(validar postgres "$sql")"
  assert_exit 4 "$ec" "AC16 rechaza $etiqueta"
done <<'CASOS'
DELETE ... WHERE id IN (SELECT|DELETE FROM proveedores.usuario WHERE id IN (SELECT id FROM proveedores.baja)
INSERT ... SELECT|INSERT INTO proveedores.logs SELECT * FROM proveedores.origen
UPDATE ... = (SELECT|UPDATE proveedores.orden_compra SET moneda = (SELECT 'X') WHERE id = 1
CREATE TABLE ... AS SELECT|CREATE TABLE copia AS SELECT * FROM proveedores.usuario
CREATE VIEW ... WITH (...) AS SELECT|CREATE VIEW v WITH (x) AS SELECT 1
CASOS

# ---------------------------------------------------------------------------
# AC17 — una escritura detrás de una lectura
# ---------------------------------------------------------------------------
# El caso que una comprobación ingenua se pierde: la primera sentencia es
# inocente.
ec="$(validar postgres "SELECT 1; DELETE FROM proveedores.usuario")"
assert_exit 4 "$ec" "AC17 rechaza una escritura escondida detrás de un SELECT"

ec="$(validar postgres "$(printf 'SELECT 1\n  FROM proveedores.orden_compra\n LIMIT 1;\n\nDELETE FROM proveedores.usuario\n WHERE id = 1;')")"
assert_exit 4 "$ec" "AC17 rechaza una escritura multilínea escondida detrás de una lectura multilínea"

ec="$(validar postgres "DROP TABLE proveedores.usuario")"
assert_exit 4 "$ec" "AC17 revisa la última sentencia aunque no termine en punto y coma"

# ---------------------------------------------------------------------------
# AC18 — los falsos rechazos, que también importan
# ---------------------------------------------------------------------------
# Una barrera que rechaza consultas legítimas se termina desactivando. Por eso
# se quitan comentarios y literales antes de mirar.
ec="$(validar postgres "$(printf -- '-- ojo: esto NO hace UPDATE de nada\n/* ni DELETE */\nSELECT 1')")"
assert_exit 0 "$ec" "AC18 acepta un UPDATE que sólo aparece dentro de un comentario"

ec="$(validar postgres "SELECT 'DELETE FROM x' AS texto, 'DROP TABLE y' AS otro")"
assert_exit 0 "$ec" "AC18 acepta un DELETE que sólo aparece dentro de un literal de texto"

# ---------------------------------------------------------------------------
# AC19 — lo que sí tiene que pasar
# ---------------------------------------------------------------------------
ec="$(validar postgres "WITH a AS (SELECT 1 AS n) SELECT * FROM a;")"
assert_exit 0 "$ec" "AC19 acepta un CTE"

ec="$(validar postgres "$(printf 'SELECT 1;\nSELECT 2;\nWITH a AS (SELECT 3) SELECT * FROM a;\n')")"
assert_exit 0 "$ec" "AC19 acepta tres sentencias de lectura seguidas"

# 🔴 ESTE CASO EXISTE POR UN BUG QUE LOS OTROS ONCE NO VIERON: el splitter
# original partía por `;` y después leía UNA LÍNEA, así que cada renglón de
# una consulta multilínea se evaluaba como sentencia suelta y una consulta
# válida se rechazaba en su segundo renglón. Ningún test lo notó porque todos
# usaban SQL de una sola línea; lo encontró el primer uso real.
ec="$(validar postgres "$(printf 'WITH lineas AS (\n  SELECT ol.id,\n         ol.descripcion\n    FROM proveedores.orden_compra_linea ol\n   WHERE ol.id_orden_compra = 1\n)\nSELECT count(*)\n  FROM lineas;')")"
assert_exit 0 "$ec" "AC19 acepta una consulta multilínea, que es como son las de verdad"

# Y el complemento, que es lo que impide "arreglar" ese bug abriendo un
# agujero: una escritura multilínea tiene que seguir cayendo.
ec="$(validar postgres "$(printf 'UPDATE proveedores.orden_compra\n   SET moneda = %s\n WHERE id = 1;' "'X'")")"
assert_exit 4 "$ec" "AC19 sigue rechazando una escritura multilínea"

# ---------------------------------------------------------------------------
# AC20 — comilla de dólar en postgres
# ---------------------------------------------------------------------------
# Un cuerpo entre comillas de dólar no es un literal de comilla simple: la
# normalización no lo toca, y adentro puede ir cualquier cosa, incluido un
# `;`. El caso arranca con SELECT a propósito: así lo ÚNICO que lo rechaza es
# la regla de comilla de dólar, y quitarla lo pone verde.
ec="$(validar postgres 'SELECT $$texto$$ AS x')"
assert_exit 4 "$ec" "AC20 rechaza una apertura de comilla de dólar sin etiqueta"

ec="$(validar postgres 'SELECT $cuerpo$ hola $cuerpo$ AS x')"
assert_exit 4 "$ec" "AC20 rechaza una apertura de comilla de dólar con etiqueta"

# ---------------------------------------------------------------------------
# AC21 — las reglas propias de sqlserver
# ---------------------------------------------------------------------------
ec="$(validar sqlserver 'EXEC dbo.algun_procedimiento')"
assert_exit 4 "$ec" "AC21 rechaza un EXEC en sqlserver"

ec="$(validar sqlserver 'EXECUTE dbo.algun_procedimiento')"
assert_exit 4 "$ec" "AC21 rechaza un EXECUTE en sqlserver"

# Los cuatro discriminantes: las reglas comunes los aceptan (se verifica
# abajo), así que el 4 sólo puede venir de la regla del dialecto.
while IFS='|' read -r etiqueta sql; do
  [ -z "$etiqueta" ] && continue
  ec="$(validar sqlserver "$sql")"
  assert_exit 4 "$ec" "AC21 rechaza $etiqueta en sqlserver"
  ec="$(validar postgres "$sql")"
  assert_exit 0 "$ec" "AC21 (control) postgres acepta $etiqueta — el rechazo de arriba es del dialecto, no del ancla"
done <<'CASOS'
un EXEC detrás de una lectura|SELECT 1 EXEC dbo.algun_procedimiento
un EXECUTE detrás de una lectura|SELECT 1 EXECUTE dbo.algun_procedimiento
un identificador que empieza con sp_|SELECT * FROM sp_helpdb
un identificador que empieza con xp_|SELECT * FROM xp_cmdshell
CASOS

ec="$(validar sqlserver 'SELECT 1; SELECT 2')"
assert_exit 4 "$ec" "AC21 rechaza cualquier punto y coma en sqlserver"

# El punto y coma se mira DESPUÉS de quitar comentarios y literales: uno que
# sólo vive dentro de una cadena no rechaza nada.
ec="$(validar sqlserver "SELECT 'a;b' AS texto")"
assert_exit 0 "$ec" "AC21 acepta un punto y coma que sólo vive dentro de un literal de texto"

# ---------------------------------------------------------------------------
# AC22 — la misma entrada, distinto veredicto según el dialecto
# ---------------------------------------------------------------------------
ENCADENADAS='SELECT 1; SELECT 2'
ec="$(validar postgres "$ENCADENADAS")"
assert_exit 0 "$ec" "AC22 dos lecturas encadenadas con punto y coma se aceptan en postgres"
ec="$(validar sqlserver "$ENCADENADAS")"
assert_exit 4 "$ec" "AC22 la misma entrada se rechaza en sqlserver"

# ---------------------------------------------------------------------------
# Uso
# ---------------------------------------------------------------------------
printf '%s' 'SELECT 1' | node "$LISTA_BLANCA" >/dev/null 2>&1
assert_exit 2 "$?" "sin dialecto, explica el uso"

printf '%s' 'SELECT 1' | node "$LISTA_BLANCA" mysql >/dev/null 2>&1
assert_exit 2 "$?" "con un dialecto desconocido, explica el uso"

test_summary
exit $?
