#!/usr/bin/env bash
# SDD/tests/test_catalogo.sh — plugins/bisalta-db/scripts/catalogo.js y el
# empaquetado del plugin. AC11-AC14 y AC36 del contract
# SDD/contracts/2026-09-18-bisalta-db-mcp.md v3, y AC45b/AC45c de la v16.
#
# 🔴 PRODUCCIÓN ES IRREPRESENTABLE, NO RECHAZADA POR NOMBRE. `ambiente` admite
# `dev` y `qa` y nada más. Una lista de nombres prohibidos es red; esto es
# barrera.
#
# Dos clases de assert, y las dos hacen falta:
#   1. El catálogo REAL (plugins/bisalta-db/catalogo.json) valida. Es el que
#      se pone rojo con las cuatro mutaciones declaradas de AC11-AC14, que
#      mutan ese archivo.
#   2. Fixtures inválidas generadas on-the-fly bajo SDD/tests/.tmp/ prueban
#      que el validador DETECTA cada forma. Sin esto, (1) sola no distinguiría
#      un validador que siempre dice que sí.
#
# Las fixtures nunca se versionan: se derivan del catálogo real y se borran en
# el `trap ... EXIT`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDADOR="$REPO_ROOT/plugins/bisalta-db/scripts/catalogo.js"
CATALOGO_REAL="$REPO_ROOT/plugins/bisalta-db/catalogo.json"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
MANIFIESTO="$REPO_ROOT/plugins/bisalta-db/.claude-plugin/plugin.json"

TMP_DIR="$SCRIPT_DIR/.tmp/test_catalogo-$$"
# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if ! command -v node >/dev/null 2>&1; then
  echo "  FAIL  setup — node no está disponible (prerequisito de SDD/docs/doc_quality_gates.md)"
  exit 1
fi
for requerido in "$VALIDADOR" "$CATALOGO_REAL" "$MARKETPLACE" "$MANIFIESTO"; do
  if [ ! -f "$requerido" ]; then
    printf '  FAIL  setup — no existe %s\n' "$requerido"
    exit 1
  fi
done

mkdir -p "$TMP_DIR"

# Genera una fixture inválida mutando una copia del catálogo real.
#   $1 = nombre del archivo · $2 = expresión JS sobre `c` (el arreglo)
fixture() {
  node -e "const fs=require('fs');const c=JSON.parse(fs.readFileSync('$CATALOGO_REAL','utf8'));$2;fs.writeFileSync('$TMP_DIR/$1',JSON.stringify(c,null,2));"
  printf '%s' "$TMP_DIR/$1"
}

# ---------------------------------------------------------------------------
# El catálogo que se distribuye, validado por el validador que se distribuye
# ---------------------------------------------------------------------------
salida="$(node "$VALIDADOR" "$CATALOGO_REAL" 2>&1)"; ec=$?
assert_exit 0 "$ec" "el catálogo real que se distribuye con el plugin es válido"
assert_contains "$salida" "proveedores-dev" "el catálogo real nombra la conexión proveedores-dev"

# ---------------------------------------------------------------------------
# AC11 — `ambiente` fuera de dev/qa
# ---------------------------------------------------------------------------
ruta="$(fixture ambiente-stg.json "c[0].ambiente='stg'")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC11 el validador sale distinto de 0 con un ambiente que no es dev ni qa"
assert_contains "$salida" "proveedores-dev" "AC11 el rechazo nombra la entrada"
assert_contains "$salida" "ambiente" "AC11 el rechazo nombra el campo ambiente"

ruta="$(fixture ambiente-prod.json "c[1].ambiente='produccion'")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC11 tampoco admite un ambiente que nombre producción"

ruta="$(fixture ambiente-ausente.json "delete c[0].ambiente")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC11 el validador rechaza una entrada sin el campo ambiente"
assert_contains "$salida" "falta el campo requerido" "AC11 el rechazo dice qué campo falta"

# ---------------------------------------------------------------------------
# AC12 — ningún host de la cuenta de producción
# ---------------------------------------------------------------------------
# Las dos formas: la entrada agregada (mutación declarada) y una entrada
# existente reapuntada.
ruta="$(fixture host-prod-sql.json "c.push(Object.assign({},c[2],{nombre:'prod-sql',host:'192.168.252.22'}))")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC12 el validador rechaza una entrada cuyo host es el de Prod SQL"
assert_contains "$salida" "prod-sql" "AC12 el rechazo del host de Prod SQL nombra la entrada"

ruta="$(fixture host-cluster-prod.json "c[0].host='sistemas.cluster-cr4rbgr7qlr6.us-east-1.rds.amazonaws.com'")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC12 el validador rechaza un host del cluster de la cuenta de producción"
assert_contains "$salida" "producción" "AC12 el rechazo dice que el host apunta a producción"

# Y el catálogo real no nombra ninguno de los dos, medido y no supuesto.
if grep -q -e 'cluster-cr4rbgr7qlr6' -e '192\.168\.252\.22' "$CATALOGO_REAL"; then
  presentes=si
else
  presentes=no
fi
assert_eq "$presentes" "no" "AC12 ninguna entrada del catálogo real nombra el cluster ni el host de producción"

# ---------------------------------------------------------------------------
# AC13 — campo no declarado en el contrato de datos
# ---------------------------------------------------------------------------
ruta="$(fixture campo-desconocido.json "c[0].usuario='claude_lectura'")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC13 el validador rechaza una entrada con un campo no declarado"
assert_contains "$salida" "campo no declarado" "AC13 el rechazo dice que el campo no está en el contrato de datos"
assert_contains "$salida" "usuario" "AC13 el rechazo nombra el campo de más"

# El campo de contraseña tampoco existe en el contrato de datos: los dos salen
# del secreto. El nombre del campo se arma en piezas para no escribir un
# literal con forma de credencial en un archivo versionado (gate 9).
campo_credencial="$(printf '%s%s' 'pass' 'word')"
ruta="$(fixture campo-credencial.json "c[0]['$campo_credencial']='xxxx'")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC13 el catálogo no admite un campo de credencial"

# ---------------------------------------------------------------------------
# AC14 — `garantias` vacío
# ---------------------------------------------------------------------------
ruta="$(fixture garantias-vacias.json "c[0].garantias=[]")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC14 el validador rechaza una entrada con garantias vacío"
assert_contains "$salida" "garantias" "AC14 el rechazo nombra el campo garantias"

ruta="$(fixture garantia-desconocida.json "c[0].garantias=[{nombre:'inventada',nivel:'incondicional'}]")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC14 el validador rechaza una garantía que no está en la lista cerrada"

# ---------------------------------------------------------------------------
# AC45b — el validador rechaza cada forma mal escrita de una garantía (v16)
#
# Declarar las tres garantías de Postgres al mismo nivel era una afirmación que
# no se sostiene: medido el 22-sep-2026, el rol apaga `sesion-read-only` con un
# SET y en PG 14 el esquema `public` traía CREATE para PUBLIC. Estos asserts son
# las barreras que impiden volver a la afirmación plana.
#
# 🔴 CADA CLÁUSULA TIENE UN ASSERT QUE SÓLO ELLA SATISFACE. En v15 el rechazo
# de la cadena suelta se afirmaba mirando que el mensaje nombrara `nivel`, y
# otra regla también lo nombra: quitar el chequeo de objeto dejaba el test
# verde (medido por la review de v15). Por eso cada mensaje se busca por el
# texto propio de su regla.
# ---------------------------------------------------------------------------
ruta="$(fixture garantia-cadena.json "c[0].garantias=['rol-solo-lectura']")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC45b (1) el validador rechaza una garantía declarada como cadena suelta"
assert_contains "$salida" "tiene que ser un objeto" "AC45b (1) el rechazo de la cadena suelta dice que tiene que ser un objeto"

ruta="$(fixture nivel-invalido.json "c[0].garantias=[{nombre:'rol-solo-lectura',nivel:'mas-o-menos'}]")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC45b (2) el validador rechaza un nivel fuera del enum cerrado"
assert_contains "$salida" '`nivel` tiene que ser uno de' "AC45b (2) el rechazo del nivel inválido nombra el enum de nivel"

ruta="$(fixture condicional-sin-condicion.json "c[0].garantias=[{nombre:'rol-solo-lectura',nivel:'condicional'}]")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC45b (3) una garantía condicional sin declarar de qué depende se rechaza"
assert_contains "$salida" "condicion" "AC45b (3) el rechazo nombra la condicion ausente"

ruta="$(fixture incondicional-con-condicion.json "c[0].garantias=[{nombre:'endpoint-replica-lectura',nivel:'incondicional',condicion:'algo'}]")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC45b (4) una garantía incondicional que declara una condicion se contradice y se rechaza"
assert_contains "$salida" 'no lleva `condicion`' "AC45b (4) el rechazo dice que una incondicional no lleva condicion"

ruta="$(fixture garantia-campo-extra.json "c[0].garantias=[{nombre:'rol-solo-lectura',nivel:'condicional',condicion:'x',comentario:'y'}]")"
salida="$(node "$VALIDADOR" "$ruta" 2>&1)"; ec=$?
assert_eq "$([ "$ec" -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "AC45b (5) el validador rechaza un campo desconocido dentro de una garantía"
assert_contains "$salida" "campo desconocido: comentario" "AC45b (5) el rechazo nombra el campo desconocido"

# ---------------------------------------------------------------------------
# AC45c — los niveles del catálogo que se distribuye (v16)
# ---------------------------------------------------------------------------
# Cada entrada de Postgres declara exactamente UNA incondicional, y es el
# endpoint de réplica (incondicional porque AC46 la comprueba en cada
# consulta); ninguna de SQL Server declara una. Derivado del catálogo real, no
# de una cifra copiada.
#
# Control primero: los dos recorridos de abajo afirman AUSENCIAS sobre un
# conjunto ("ninguna entrada mal"), y un conjunto vacío las cumple sin mirar
# nada. Si el filtro por dialecto dejara de encontrar entradas, los dos
# pasarían igual.
conjuntos="$(node -e "
  const c=require('$CATALOGO_REAL'); const l=Array.isArray(c)?c:c.conexiones;
  const pg=l.filter(e=>e.dialecto==='postgres').length;
  const sq=l.filter(e=>e.dialecto==='sqlserver').length;
  process.stdout.write((pg>0&&sq>0)?'ok':'vacio:postgres='+pg+',sqlserver='+sq);
")"
assert_eq "$conjuntos" "ok" \
  "AC45c (control) el catálogo real tiene conexiones Postgres y SQL Server que recorrer"
incondicionales="$(node -e "
  const c=require('$CATALOGO_REAL'); const l=Array.isArray(c)?c:c.conexiones;
  const pg=l.filter(e=>e.dialecto==='postgres');
  const malas=pg.filter(e=>{
    const inc=e.garantias.filter(g=>g.nivel==='incondicional');
    return inc.length!==1 || inc[0].nombre!=='endpoint-replica-lectura';
  });
  process.stdout.write(malas.length===0?'ok':'mal:'+malas.map(e=>e.nombre).join(','));
")"
assert_eq "$incondicionales" "ok" \
  "AC45c cada conexión Postgres declara el endpoint de réplica como su única garantía incondicional"

sqlserver_condicionales="$(node -e "
  const c=require('$CATALOGO_REAL'); const l=Array.isArray(c)?c:c.conexiones;
  const sq=l.filter(e=>e.dialecto==='sqlserver');
  const malas=sq.filter(e=>e.garantias.some(g=>g.nivel==='incondicional'));
  process.stdout.write(malas.length===0?'ok':'mal:'+malas.map(e=>e.nombre).join(','));
")"
assert_eq "$sqlserver_condicionales" "ok" \
  "AC45c ninguna conexión SQL Server declara una garantía incondicional"

# ---------------------------------------------------------------------------
# Resto del contrato de datos
# ---------------------------------------------------------------------------
ruta="$(fixture puerto-invalido.json "c[0].puerto=70000")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "el validador rechaza un puerto fuera de 1..65535"

ruta="$(fixture nombre-repetido.json "c[1].nombre=c[0].nombre")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "el validador rechaza dos entradas con el mismo nombre"

ruta="$(fixture nombre-invalido.json "c[0].nombre='Proveedores_DEV'")"
node "$VALIDADOR" "$ruta" >/dev/null 2>&1
assert_eq "$([ $? -ne 0 ] && echo distinto-de-cero || echo cero)" "distinto-de-cero" \
  "el validador rechaza un nombre fuera de minúsculas, dígitos y guiones"

printf '%s' 'esto no es json' > "$TMP_DIR/roto.json"
node "$VALIDADOR" "$TMP_DIR/roto.json" >/dev/null 2>&1
assert_exit 2 "$?" "un catálogo que no es JSON sale 2, no 0"

node "$VALIDADOR" "$TMP_DIR/no-existe.json" >/dev/null 2>&1
assert_exit 2 "$?" "un catálogo inexistente sale 2, no 0"

# ---------------------------------------------------------------------------
# AC36 — empaquetado
# ---------------------------------------------------------------------------
fuente="$(node -e "const m=JSON.parse(require('fs').readFileSync('$MARKETPLACE','utf8'));const e=(m.plugins||[]).filter(function(p){return p.name==='bisalta-db';})[0];process.stdout.write(e?String(e.source):'AUSENTE');")"
assert_eq "$fuente" "./plugins/bisalta-db" "AC36 marketplace.json lista bisalta-db con source ./plugins/bisalta-db"

version="$(node -e "process.stdout.write(String(JSON.parse(require('fs').readFileSync('$MANIFIESTO','utf8')).version||''));")"
if printf '%s' "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  semver=si
else
  semver=no
fi
assert_eq "$semver" "si" "AC36 el plugin.json de bisalta-db declara una versión SemVer"

nombre_manifiesto="$(node -e "process.stdout.write(String(JSON.parse(require('fs').readFileSync('$MANIFIESTO','utf8')).name||''));")"
assert_eq "$nombre_manifiesto" "bisalta-db" "AC36 el plugin.json declara el nombre bisalta-db"

test_summary
exit $?
