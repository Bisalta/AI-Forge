#!/usr/bin/env bash
# SDD/tests/test_servidor_mcp.sh — plugins/bisalta-db/scripts/servidor-mcp.js
# y conexion.js. AC23-AC37 del contract
# SDD/contracts/2026-09-18-bisalta-db-mcp.md v3.
#
# No hay base ni cuenta de AWS acá, y no hace falta: los binarios externos
# (`aws`, `psql`, `sqlcmd`) se sustituyen por stubs al frente del PATH que
# REGISTRAN cómo los invocaron. Así las afirmaciones son sobre el comando y el
# entorno REALES que el servidor construyó — no sobre una función que
# devuelve lo que el servidor "diría" que va a hacer.
#
# 🔴 CADA NEGATIVO VIENE CON SU CONTROL POSITIVO. "La contraseña no está en
# argv" no dice nada si la contraseña nunca llegó a existir; "no se invocó
# `aws`" no dice nada si el stub no registra invocaciones. Por eso cada
# ausencia que se afirma tiene al lado una presencia que prueba que la
# medición está viva.
#
# Fixtures y stubs: SDD/tests/.tmp/, borrados en el `trap ... EXIT`. Nunca
# versionados.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGIN_DIR="$REPO_ROOT/plugins/bisalta-db"
SERVIDOR="$PLUGIN_DIR/scripts/servidor-mcp.js"
DIR_SCRIPTS="$PLUGIN_DIR/scripts"

TMP_DIR="$SCRIPT_DIR/.tmp/test_servidor_mcp-$$"
# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if ! command -v node >/dev/null 2>&1; then
  echo "  FAIL  setup — node no está disponible (prerequisito de SDD/docs/doc_quality_gates.md)"
  exit 1
fi
NODE_BIN="$(command -v node)"
if [ ! -f "$SERVIDOR" ]; then
  printf '  FAIL  setup — no existe %s\n' "$SERVIDOR"
  exit 1
fi

BIN_DIR="$TMP_DIR/bin"
BIN_SIN_PSQL="$TMP_DIR/bin-sin-psql"
SYSTMP="$TMP_DIR/systmp"
mkdir -p "$BIN_DIR" "$BIN_SIN_PSQL" "$SYSTMP"

# El valor que hace de contraseña, armado en piezas: escrito entero y contiguo
# junto a una clave, este archivo dispararía el gate 9 contra sí mismo.
VALOR_CREDENCIAL="$(printf '%s%s' 'zzz-valor-de-prueba-' 'A1B2C3D4E5')"
CAMPO_CREDENCIAL="$(printf '%s%s' 'pass' 'word')"
USUARIO_ESPERADO='claude_lectura'
# Marcador que sólo aparece en la salida CRUDA del stub de `aws` al fallar.
MARCA_CRUDA_AWS='ARN-CRUDO-DE-LA-IDENTIDAD-LLAMANTE'

export BISALTA_STUB_DIR="$TMP_DIR"
export BISALTA_STUB_USUARIO="$USUARIO_ESPERADO"
export BISALTA_STUB_CAMPO="$CAMPO_CREDENCIAL"
export BISALTA_STUB_VALOR="$VALOR_CREDENCIAL"
export BISALTA_STUB_MARCA="$MARCA_CRUDA_AWS"
export BISALTA_STUB_AWS_FALLA=0
export BISALTA_STUB_PSQL_MODO=normal
export BISALTA_STUB_CATALOGO_NUEVO=''

CATALOGO_VIVO="$TMP_DIR/catalogo.json"
CATALOGO_SIN_QA="$TMP_DIR/catalogo-sin-qa.json"
cp "$PLUGIN_DIR/catalogo.json" "$CATALOGO_VIVO"
node -e "const fs=require('fs');const c=JSON.parse(fs.readFileSync('$CATALOGO_VIVO','utf8'));fs.writeFileSync('$CATALOGO_SIN_QA',JSON.stringify(c.filter(function(e){return e.nombre!=='proveedores-qa';}),null,2));"

export BISALTA_DB_CATALOGO="$CATALOGO_VIVO"
export BISALTA_DB_BITACORA="$TMP_DIR/bitacora.jsonl"

# --- stubs -----------------------------------------------------------------
cat > "$BIN_DIR/aws" <<'STUB'
#!/usr/bin/env bash
printf 'ARGS %s\n' "$*" >> "$BISALTA_STUB_DIR/aws-invocado.log"
if [ "${BISALTA_STUB_AWS_FALLA:-0}" = "1" ]; then
  printf 'An error occurred (AccessDeniedException): %s\n' "$BISALTA_STUB_MARCA" >&2
  exit 255
fi
printf '{"username": "%s", "%s": "%s"}\n' "$BISALTA_STUB_USUARIO" "$BISALTA_STUB_CAMPO" "$BISALTA_STUB_VALOR"
STUB

cat > "$BIN_DIR/psql" <<'STUB'
#!/usr/bin/env bash
{
  printf 'ARGS %s\n' "$*"
  printf 'PGOPTIONS %s\n' "${PGOPTIONS:-(vacio)}"
  if [ -n "${PGPASSFILE:-}" ] && [ -f "$PGPASSFILE" ]; then
    printf 'PASSFILE_EXISTE si\n'
    printf 'PASSFILE_MODO %s\n' "$(ls -l "$PGPASSFILE" | cut -c1-10)"
    if grep -qF "$BISALTA_STUB_VALOR" "$PGPASSFILE"; then
      printf 'PASSFILE_CONTIENE_CREDENCIAL si\n'
    else
      printf 'PASSFILE_CONTIENE_CREDENCIAL no\n'
    fi
  else
    printf 'PASSFILE_EXISTE no\n'
  fi
} >> "$BISALTA_STUB_DIR/psql-invocado.log"

if [ -n "${BISALTA_STUB_CATALOGO_NUEVO:-}" ]; then
  cp "$BISALTA_STUB_CATALOGO_NUEVO" "$BISALTA_DB_CATALOGO"
fi

case "${BISALTA_STUB_PSQL_MODO:-normal}" in
  normal)
    printf 'id,nombre\n1,ana\n2,"luis, el otro"\n'
    ;;
  muchas-filas)
    printf 'id\n'
    i=1
    while [ "$i" -le 1500 ]; do printf '%s\n' "$i"; i=$((i + 1)); done
    ;;
  muchos-bytes)
    printf 'texto\n'
    relleno="$(head -c 8000 /dev/zero | tr '\0' 'x')"
    i=1
    while [ "$i" -le 200 ]; do printf '%s\n' "$relleno"; i=$((i + 1)); done
    ;;
  falla)
    printf 'psql: error: connection to server at "%s" failed: no route to host\n' "10.0.0.1" >&2
    exit 2
    ;;
  timeout)
    printf 'ERROR:  canceling statement due to statement timeout\n' >&2
    exit 3
    ;;
esac
STUB

cp "$BIN_DIR/psql" "$BIN_DIR/sqlcmd"
cp "$BIN_DIR/aws" "$BIN_SIN_PSQL/aws"
chmod +x "$BIN_DIR/aws" "$BIN_DIR/psql" "$BIN_DIR/sqlcmd" "$BIN_SIN_PSQL/aws"

PATH_CON_STUBS="$BIN_DIR:/usr/bin:/bin"
PATH_SIN_PSQL="$BIN_SIN_PSQL:/usr/bin:/bin"

# Extractor de los cuerpos de `tools/call`: una línea JSON compacta por
# respuesta, en orden. Generado acá para no versionar una fixture.
cat > "$TMP_DIR/extraer.js" <<'EXTRACTOR'
let crudo = '';
process.stdin.on('data', function (c) { crudo += c; });
process.stdin.on('end', function () {
  crudo.split('\n').forEach(function (linea) {
    if (linea.replace(/\s+/g, '') === '') return;
    let m;
    try { m = JSON.parse(linea); } catch (e) { return; }
    if (m.result && m.result.content && m.result.content[0]) {
      process.stdout.write(JSON.stringify(JSON.parse(m.result.content[0].text)) + '\n');
    }
  });
});
EXTRACTOR

# Corre el servidor en modo MCP con las tramas de $1 y el PATH de $2.
servidor_jsonrpc() {
  printf '%s\n' "$1" | env PATH="$2" TMPDIR="$SYSTMP" "$NODE_BIN" "$SERVIDOR" 2>/dev/null
}

# Cuerpos de las llamadas a herramienta, uno por línea.
cuerpos() {
  printf '%s\n' "$1" | "$NODE_BIN" "$TMP_DIR/extraer.js"
}

trama_consultar() {
  printf '{"jsonrpc":"2.0","id":%s,"method":"tools/call","params":{"name":"consultar","arguments":{"conexion":"%s","sql":"%s"}}}' "$1" "$2" "$3"
}

reiniciar_registros() {
  rm -f "$TMP_DIR/aws-invocado.log" "$TMP_DIR/psql-invocado.log" "$BISALTA_DB_BITACORA"
}

# ---------------------------------------------------------------------------
# AC34 — handshake y herramientas, con node y sin ningún paquete instalado
# ---------------------------------------------------------------------------
tramas="$(printf '%s\n%s\n%s' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"prueba","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}')"
salida="$(servidor_jsonrpc "$tramas" "$PATH_CON_STUBS")"

assert_contains "$salida" '"protocolVersion":"2024-11-05"' "AC34 initialize responde el protocolVersion declarado"
assert_contains "$salida" '"name":"bisalta-db"' "AC34 initialize se identifica como bisalta-db"

nombres="$(printf '%s\n' "$salida" | "$NODE_BIN" -e "
let crudo='';process.stdin.on('data',function(c){crudo+=c;});process.stdin.on('end',function(){
  crudo.split('\n').forEach(function(l){ if(l.replace(/\s+/g,'')==='')return; let m; try{m=JSON.parse(l);}catch(e){return;}
    if(m.result&&m.result.tools) process.stdout.write(m.result.tools.map(function(t){return t.name;}).join(','));});});")"
assert_eq "$nombres" "consultar,listar_conexiones" "AC34 tools/list devuelve exactamente consultar y listar_conexiones"

# Una notificación no lleva respuesta: contestarle rompe el handshake.
respuestas="$(printf '%s\n' "$salida" | grep -c '"jsonrpc"')"
assert_eq "$respuestas" "2" "AC34 la notificación initialized no genera respuesta"

for prohibido in "$PLUGIN_DIR/package.json" "$PLUGIN_DIR/package-lock.json" "$PLUGIN_DIR/node_modules"; do
  if [ -e "$prohibido" ]; then presente=si; else presente=no; fi
  assert_eq "$presente" "no" "AC34 el plugin no trae manifiesto ni árbol de dependencias ($(basename "$prohibido"))"
done

# ---------------------------------------------------------------------------
# AC35 — la proyección de listar_conexiones
# ---------------------------------------------------------------------------
salida="$(servidor_jsonrpc '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"listar_conexiones"}}' "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"nombre":"proveedores-dev"' "AC35 listar_conexiones devuelve el nombre de la conexión"
assert_contains "$cuerpo" '"garantias"' "AC35 listar_conexiones devuelve las garantías"
assert_contains "$cuerpo" '"ambiente":"dev"' "AC35 listar_conexiones devuelve el ambiente"
for campo in '"host"' '"puerto"' '"secret_id"' '"region"'; do
  case "$cuerpo" in
    *"$campo"*) filtrado=no ;;
    *) filtrado=si ;;
  esac
  assert_eq "$filtrado" "si" "AC35 listar_conexiones NO devuelve $campo"
done

# ---------------------------------------------------------------------------
# AC31 — conexión desconocida, sin invocar el binario `aws`
# ---------------------------------------------------------------------------
reiniciar_registros
salida="$(servidor_jsonrpc "$(trama_consultar 1 'no-existe' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":3' "AC31 una conexión ausente del catálogo devuelve el código 3"
assert_contains "$cuerpo" '"error":"conexion_desconocida"' "AC31 el error es conexion_desconocida"
assert_contains "$cuerpo" 'proveedores-dev' "AC31 el error trae la lista de nombres válidos"

if [ -s "$TMP_DIR/aws-invocado.log" ]; then invocado=si; else invocado=no; fi
assert_eq "$invocado" "no" "AC31 con una conexión desconocida no se invoca el binario aws"

# Control positivo: el registro del stub sí se escribe cuando `aws` se invoca
# de verdad. Sin esto, el assert de arriba se cumpliría igual con un stub roto.
reiniciar_registros
servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS" >/dev/null
if [ -s "$TMP_DIR/aws-invocado.log" ]; then invocado=si; else invocado=no; fi
assert_eq "$invocado" "si" "AC31 (control) con una conexión válida el stub de aws sí registra la invocación"

# El mismo camino por el modo de una sola consulta, que sale con el código de
# la tabla de errores del contract.
env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" "$NODE_BIN" "$SERVIDOR" --consultar 'no-existe' --sql 'SELECT 1' >/dev/null 2>&1
assert_exit 3 "$?" "AC31 el proceso sale 3 con una conexión desconocida"

# ---------------------------------------------------------------------------
# AC23 — la credencial no vuelve al contexto por ninguna de las formas viejas
# ---------------------------------------------------------------------------
# Estático: el código fuente del plugin no nombra ninguna de las seis formas.
while IFS= read -r prohibido; do
  [ -z "$prohibido" ] && continue
  if grep -rF -e "$prohibido" "$DIR_SCRIPTS" >/dev/null 2>&1; then hallado=si; else hallado=no; fi
  assert_eq "$hallado" "no" "AC23 el código fuente de scripts/ no contiene [$prohibido]"
done <<'PROHIBIDOS'
PGPASSWORD
PGUSER
PGHOST
--username
--host
-P 
PROHIBIDOS

# Control positivo del grep: una forma que SÍ está en el código se encuentra.
# Sin esto, los seis asserts de arriba pasarían igual con un grep mal escrito.
if grep -rF -e 'PGPASSFILE' "$DIR_SCRIPTS" >/dev/null 2>&1; then hallado=si; else hallado=no; fi
assert_eq "$hallado" "si" "AC23 (control) el grep sí encuentra la forma que el plugin sí usa"

# En ejecución: la contraseña no aparece en argv, y sí llega por el archivo.
reiniciar_registros
servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS" >/dev/null
argumentos="$(grep '^ARGS ' "$TMP_DIR/psql-invocado.log")"
case "$argumentos" in
  *"$VALOR_CREDENCIAL"*) en_argv=si ;;
  *) en_argv=no ;;
esac
assert_eq "$en_argv" "no" "AC23 la contraseña no viaja en la línea de comandos del cliente"
assert_contains "$(cat "$TMP_DIR/psql-invocado.log")" "PASSFILE_CONTIENE_CREDENCIAL si" \
  "AC23 (control) la contraseña sí llega al cliente por el archivo de credenciales"
assert_contains "$(cat "$TMP_DIR/psql-invocado.log")" "PASSFILE_MODO -rw-------" \
  "AC23 el archivo de credenciales queda en modo 600"

# ---------------------------------------------------------------------------
# AC28 y AC29 — la sesión que el servidor abre
# ---------------------------------------------------------------------------
opciones="$(grep '^PGOPTIONS ' "$TMP_DIR/psql-invocado.log")"
assert_contains "$opciones" "default_transaction_read_only=on" "AC28 el comando abre la sesión en solo lectura"
assert_contains "$opciones" "statement_timeout=120000" "AC28 el comando fija el statement_timeout en 120000"
assert_contains "$opciones" "application_name=$USUARIO_ESPERADO" "AC29 el comando lleva el application_name del usuario del secreto"

# ---------------------------------------------------------------------------
# AC30 — la bitácora
# ---------------------------------------------------------------------------
bitacora="$(cat "$BISALTA_DB_BITACORA" 2>/dev/null)"
assert_contains "$bitacora" '"conexion":"proveedores-dev"' "AC30 la bitácora registra la conexión"
assert_contains "$bitacora" '"dialecto":"postgres"' "AC30 la bitácora registra el dialecto"
assert_contains "$bitacora" '"hash_consulta":"sha256:' "AC30 la bitácora registra el hash de la consulta"
assert_contains "$bitacora" '"filas_devueltas":2' "AC30 la bitácora registra las filas devueltas"
assert_contains "$bitacora" '"truncado":false' "AC30 la bitácora registra si truncó"
assert_contains "$bitacora" '"duracion_ms":' "AC30 la bitácora registra la duración"
assert_contains "$bitacora" '"codigo":0' "AC30 la bitácora registra el código de salida"
# La consulta va por hash, nunca en claro: el SQL puede llevar valores de
# negocio y la bitácora sobrevive a la sesión.
case "$bitacora" in
  *'SELECT 1'*) en_claro=si ;;
  *) en_claro=no ;;
esac
assert_eq "$en_claro" "no" "AC30 la bitácora NO guarda el texto de la consulta"

lineas_bitacora="$(wc -l < "$BISALTA_DB_BITACORA" | tr -d ' ')"
assert_eq "$lineas_bitacora" "1" "AC30 la bitácora escribe una línea por invocación"

# ---------------------------------------------------------------------------
# AC25 — ni la bitácora, ni la respuesta, ni los errores llevan la credencial
# ---------------------------------------------------------------------------
reiniciar_registros
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
bitacora="$(cat "$BISALTA_DB_BITACORA" 2>/dev/null)"
for texto_nombre in "respuesta:$salida" "bitacora:$bitacora"; do
  donde="${texto_nombre%%:*}"
  texto="${texto_nombre#*:}"
  case "$texto" in
    *"$VALOR_CREDENCIAL"*) filtra=si ;;
    *) filtra=no ;;
  esac
  assert_eq "$filtra" "no" "AC25 la $donde de una consulta exitosa no contiene el valor de la contraseña"
  case "$texto" in
    *"$CAMPO_CREDENCIAL"*) carga=si ;;
    *) carga=no ;;
  esac
  assert_eq "$carga" "no" "AC25 la $donde no contiene la carga cruda del secreto"
done

# El mismo chequeo sobre el camino de error del cliente, que es donde es fácil
# arrastrar el entorno entero a un mensaje.
BISALTA_STUB_PSQL_MODO=falla
export BISALTA_STUB_PSQL_MODO
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":6' "AC25 una conexión que falla devuelve el código 6"
assert_contains "$cuerpo" 'no route to host' "AC25 el error de conexión trae el mensaje del cliente"
case "$salida" in
  *"$VALOR_CREDENCIAL"*) filtra=si ;;
  *) filtra=no ;;
esac
assert_eq "$filtra" "no" "AC25 el mensaje de una conexión fallida no contiene la contraseña"

# ---------------------------------------------------------------------------
# AC24 — el directorio temporal no sobrevive a una consulta que falla
# ---------------------------------------------------------------------------
# Control primero: el archivo de credenciales existió DURANTE la corrida que
# acaba de fallar. Sin esto, "no quedó nada" se cumpliría también si el
# servidor nunca hubiera creado nada.
assert_contains "$(cat "$TMP_DIR/psql-invocado.log")" "PASSFILE_EXISTE si" \
  "AC24 (control) el archivo de credenciales existía mientras corría la consulta que falló"
restos="$(find "$SYSTMP" -maxdepth 1 -name 'bisalta-db-*' | wc -l | tr -d ' ')"
assert_eq "$restos" "0" "AC24 tras una consulta que falla al conectar no queda ningún directorio temporal"

BISALTA_STUB_PSQL_MODO=normal
export BISALTA_STUB_PSQL_MODO
servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS" >/dev/null
restos="$(find "$SYSTMP" -maxdepth 1 -name 'bisalta-db-*' | wc -l | tr -d ' ')"
assert_eq "$restos" "0" "AC24 tampoco queda un directorio temporal tras una consulta exitosa"

# ---------------------------------------------------------------------------
# AC33 — el secreto que no resuelve
# ---------------------------------------------------------------------------
BISALTA_STUB_AWS_FALLA=1
export BISALTA_STUB_AWS_FALLA
reiniciar_registros
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":5' "AC33 un secreto que no resuelve devuelve el código 5"
assert_contains "$cuerpo" '"error":"secreto_inaccesible"' "AC33 el error es secreto_inaccesible"
assert_contains "$cuerpo" 'proveedores-dev' "AC33 el error nombra la conexión"
# GEN-108: el secret_id se DERIVA del catálogo. Estaba congelado literal y se
# puso rojo el día que Patrick Ocampo eligió los nombres reales
# (dev/bd/claude-lectura-*) — un cambio de datos legítimo. Es la TERCERA vez en
# este ciclo que un test congela un valor que vive en un archivo de datos: antes
# fueron el total del ledger de escalaciones y el nombre de conexión `dev-sql`.
# Lo que el AC afirma no es un nombre concreto: es que el error NOMBRE el
# identificador del secreto de esa conexión, sea cual sea.
SECRET_ID_ESPERADO="$(node -e "
  const c = require('$PLUGIN_DIR/catalogo.json');
  const e = c.find(x => x.nombre === 'proveedores-dev');
  if (!e) { console.error('el catálogo no tiene proveedores-dev'); process.exitCode = 1; }
  else { process.stdout.write(e.secret_id); }
")"
assert_eq "$([ -n "$SECRET_ID_ESPERADO" ] && echo si || echo no)" "si" "AC33 el catálogo declara el secret_id de proveedores-dev"
assert_contains "$cuerpo" "$SECRET_ID_ESPERADO" "AC33 el error nombra el identificador del secreto" 
case "$salida" in
  *"$MARCA_CRUDA_AWS"*) cruda=si ;;
  *) cruda=no ;;
esac
assert_eq "$cruda" "no" "AC33 la respuesta NO contiene la salida cruda del binario aws"

# Control: el stub sí emitió esa salida cruda en la corrida que se acaba de
# medir. Sin esto, "no aparece" no distingue redacción de silencio.
if [ -s "$TMP_DIR/aws-invocado.log" ]; then hubo=si; else hubo=no; fi
assert_eq "$hubo" "si" "AC33 (control) el stub de aws corrió y falló en esa misma invocación"

env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" "$NODE_BIN" "$SERVIDOR" --consultar 'proveedores-dev' --sql 'SELECT 1' >/dev/null 2>&1
assert_exit 5 "$?" "AC33 el proceso sale 5 cuando el secreto no resuelve"

BISALTA_STUB_AWS_FALLA=0
export BISALTA_STUB_AWS_FALLA

# ---------------------------------------------------------------------------
# AC32 — el binario del cliente ausente del PATH
# ---------------------------------------------------------------------------
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_SIN_PSQL")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":8' "AC32 con el cliente ausente del PATH la consulta devuelve el código 8"
assert_contains "$cuerpo" '"error":"cliente_ausente"' "AC32 el error es cliente_ausente"
assert_contains "$cuerpo" 'psql' "AC32 el error nombra el binario que falta"

env PATH="$PATH_SIN_PSQL" TMPDIR="$SYSTMP" "$NODE_BIN" "$SERVIDOR" --consultar 'proveedores-dev' --sql 'SELECT 1' >/dev/null 2>&1
assert_exit 8 "$?" "AC32 el proceso sale 8 cuando falta el binario del cliente"

# ---------------------------------------------------------------------------
# El resto de la tabla de errores: uso y tiempo agotado
# ---------------------------------------------------------------------------
salida="$(servidor_jsonrpc '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"consultar","arguments":{"conexion":"proveedores-dev"}}}' "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":2' "sin el argumento sql, la herramienta devuelve el código 2"
assert_contains "$cuerpo" '"error":"uso"' "sin el argumento sql, el error es uso"

# ---------------------------------------------------------------------------
# Catálogo ilegible → código 2 `catalogo_invalido` (contract v3, tabla de
# errores). El catálogo vivo NO se toca: se apunta la variable de entorno a
# una ruta aparte, así el resto del archivo sigue corriendo contra el fixture
# bueno.
#
# 🔴 CONTROL POSITIVO AL LADO. Un "sale 2" no dice nada si esa misma
# invocación saliera 2 por cualquier otro motivo: la última afirmación del
# bloque corre el MISMO comando contra el catálogo vivo y exige que NO salga
# 2 y que NO nombre `catalogo_invalido`.
# ---------------------------------------------------------------------------
CATALOGO_ILEGIBLE="$TMP_DIR/catalogo-ilegible.json"
printf '%s\n' '{ esto no es json valido' > "$CATALOGO_ILEGIBLE"
CATALOGO_AUSENTE="$TMP_DIR/catalogo-que-no-existe.json"
rm -f "$CATALOGO_AUSENTE"

# consultar, por la herramienta MCP
salida="$(printf '%s\n' "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" \
  | env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" BISALTA_DB_CATALOGO="$CATALOGO_ILEGIBLE" \
        "$NODE_BIN" "$SERVIDOR" 2>/dev/null)"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":2' "con un catálogo ilegible, consultar devuelve el código 2"
assert_contains "$cuerpo" '"error":"catalogo_invalido"' "con un catálogo ilegible, el error es catalogo_invalido"

# consultar, por CLI — acá se mide el EXIT del proceso, que es lo que pide la
# tabla de errores del contract.
env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" BISALTA_DB_CATALOGO="$CATALOGO_ILEGIBLE" \
  "$NODE_BIN" "$SERVIDOR" --consultar 'proveedores-dev' --sql 'SELECT 1' >/dev/null 2>&1
assert_exit 2 "$?" "con un catálogo ilegible, el proceso sale 2"

env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" BISALTA_DB_CATALOGO="$CATALOGO_AUSENTE" \
  "$NODE_BIN" "$SERVIDOR" --consultar 'proveedores-dev' --sql 'SELECT 1' >/dev/null 2>&1
assert_exit 2 "$?" "con un catálogo que no existe, el proceso sale 2"

# listar_conexiones tiene su propia carga del catálogo, y su propio mapeo.
salida="$(printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"listar_conexiones","arguments":{}}}' \
  | env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" BISALTA_DB_CATALOGO="$CATALOGO_ILEGIBLE" \
        "$NODE_BIN" "$SERVIDOR" 2>/dev/null)"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":2' "con un catálogo ilegible, listar_conexiones devuelve el código 2"
assert_contains "$cuerpo" '"error":"catalogo_invalido"' "con un catálogo ilegible, listar_conexiones da catalogo_invalido"

# Control positivo: el mismo comando contra el catálogo vivo no sale 2.
env PATH="$PATH_CON_STUBS" TMPDIR="$SYSTMP" BISALTA_DB_CATALOGO="$CATALOGO_VIVO" \
  "$NODE_BIN" "$SERVIDOR" --consultar 'proveedores-dev' --sql 'SELECT 1' >/dev/null 2>&1
ec_control=$?
assert_eq "$([ "$ec_control" -eq 2 ] && echo sale-2 || echo no-sale-2)" "no-sale-2" \
  "control: contra el catálogo vivo la misma invocación NO sale 2"

BISALTA_STUB_PSQL_MODO=timeout
export BISALTA_STUB_PSQL_MODO
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":7' "un statement_timeout alcanzado devuelve el código 7"
assert_contains "$cuerpo" '"error":"tiempo_agotado"' "un statement_timeout alcanzado devuelve tiempo_agotado"
BISALTA_STUB_PSQL_MODO=normal
export BISALTA_STUB_PSQL_MODO

# La lista blanca corre dentro del servidor y antes de conectar.
reiniciar_registros
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'DELETE FROM x')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"codigo":4' "una escritura devuelve el código 4"
assert_contains "$cuerpo" '"error":"no_es_lectura"' "una escritura devuelve no_es_lectura"
assert_contains "$cuerpo" 'DELETE FROM x' "el rechazo trae la sentencia ofensora"
if [ -s "$TMP_DIR/aws-invocado.log" ]; then invocado=si; else invocado=no; fi
assert_eq "$invocado" "no" "una escritura se rechaza ANTES de resolver el secreto y de conectar"

# ---------------------------------------------------------------------------
# AC26 y AC27 — los topes
# ---------------------------------------------------------------------------
BISALTA_STUB_PSQL_MODO=muchas-filas
export BISALTA_STUB_PSQL_MODO
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"filas_devueltas":1000' "AC26 un resultado de más de 1000 filas devuelve exactamente 1000"
assert_contains "$cuerpo" '"truncado":true' "AC26 el tope de filas marca truncado en true"
assert_contains "$cuerpo" '"motivo_truncado":"limite_filas"' "AC26 el motivo del truncado es limite_filas"

BISALTA_STUB_PSQL_MODO=muchos-bytes
export BISALTA_STUB_PSQL_MODO
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"truncado":true' "AC27 un resultado de más de 1 MiB marca truncado en true"
assert_contains "$cuerpo" '"motivo_truncado":"limite_bytes"' "AC27 el motivo del truncado es limite_bytes"
devueltas="$("$NODE_BIN" -e "
let crudo='';process.stdin.on('data',function(c){crudo+=c;});process.stdin.on('end',function(){
  process.stdout.write(String(JSON.parse(crudo).filas_devueltas));});" <<< "$cuerpo")"
if [ "$devueltas" -gt 0 ] && [ "$devueltas" -lt 200 ]; then corte=si; else corte=no; fi
assert_eq "$corte" "si" "AC27 el tope de bytes devuelve las filas que caben, ni cero ni todas"

BISALTA_STUB_PSQL_MODO=normal
export BISALTA_STUB_PSQL_MODO

# Una consulta que entra holgada en los dos topes no se marca truncada, y el
# motivo es null exactamente cuando truncado es false.
salida="$(servidor_jsonrpc "$(trama_consultar 1 'proveedores-dev' 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"truncado":false' "un resultado chico no se marca truncado"
assert_contains "$cuerpo" '"motivo_truncado":null' "motivo_truncado es null exactamente cuando truncado es false"
assert_contains "$cuerpo" '"luis, el otro"' "las filas se parsean respetando las comas dentro de un campo"

# ---------------------------------------------------------------------------
# AC37 — kill switch: sacar la entrada del catálogo, sin reiniciar el servidor
# ---------------------------------------------------------------------------
# El stub reemplaza el catálogo DURANTE la primera consulta, así que las dos
# tramas viajan en la misma sesión del mismo proceso y el orden está
# garantizado por el despacho secuencial, no por una espera.
cp "$PLUGIN_DIR/catalogo.json" "$CATALOGO_VIVO"
BISALTA_STUB_CATALOGO_NUEVO="$CATALOGO_SIN_QA"
export BISALTA_STUB_CATALOGO_NUEVO
tramas="$(printf '%s\n%s' "$(trama_consultar 1 'proveedores-qa' 'SELECT 1')" "$(trama_consultar 2 'proveedores-qa' 'SELECT 1')")"
salida="$(servidor_jsonrpc "$tramas" "$PATH_CON_STUBS")"
primera="$(cuerpos "$salida" | sed -n '1p')"
segunda="$(cuerpos "$salida" | sed -n '2p')"
assert_contains "$primera" '"conexion":"proveedores-qa"' "AC37 la conexión responde mientras está en el catálogo"
assert_contains "$segunda" '"codigo":3' "AC37 quitar la entrada del catálogo devuelve el código 3 sin reiniciar el servidor"
assert_contains "$segunda" '"error":"conexion_desconocida"' "AC37 el kill switch responde conexion_desconocida"
BISALTA_STUB_CATALOGO_NUEVO=''
export BISALTA_STUB_CATALOGO_NUEVO
cp "$PLUGIN_DIR/catalogo.json" "$CATALOGO_VIVO"

# ---------------------------------------------------------------------------
# El dialecto sqlserver llega hasta el cliente con su propio comando
# ---------------------------------------------------------------------------
reiniciar_registros
# GEN-108: el nombre de la conexión se DERIVA del catálogo, no se congela. La
# versión anterior escribía 'dev-sql' literal y se puso roja el día que el
# catálogo pasó de una entrada por instancia a una por base (contract v9,
# regla de Patrick Ocampo: alcance por pedido nombrado). El test no probaba
# ese nombre: probaba que el dialecto sqlserver llega hasta el cliente con su
# propio comando. Congelar el nombre convertía un cambio de datos legítimo en
# un rojo. Misma clase que el total congelado de test_escalation_ledger.sh.
CONEXION_MSSQL="$(node -e "
  const c = require('$PLUGIN_DIR/catalogo.json');
  const e = c.find(x => x.dialecto === 'sqlserver');
  if (!e) { console.error('el catálogo no tiene ninguna conexión sqlserver'); process.exitCode = 1; }
  else { process.stdout.write(e.nombre); }
")"
assert_eq "$([ -n "$CONEXION_MSSQL" ] && echo si || echo no)" "si" "el catálogo declara al menos una conexión sqlserver"
salida="$(servidor_jsonrpc "$(trama_consultar 1 "$CONEXION_MSSQL" 'SELECT 1')" "$PATH_CON_STUBS")"
cuerpo="$(cuerpos "$salida")"
assert_contains "$cuerpo" '"dialecto":"sqlserver"' "una conexión sqlserver responde con su dialecto"
argumentos="$(grep '^ARGS ' "$TMP_DIR/psql-invocado.log")"
assert_contains "$argumentos" "10.24.40.137,1433" "el comando de sqlserver apunta al host y puerto de la entrada"
case "$argumentos" in
  *"$VALOR_CREDENCIAL"*) en_argv=si ;;
  *) en_argv=no ;;
esac
assert_eq "$en_argv" "no" "la contraseña de sqlserver tampoco viaja en la línea de comandos"

test_summary
exit $?
