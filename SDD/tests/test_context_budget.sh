# shellcheck shell=bash
# SDD/tests/test_context_budget.sh
#
# AC17-AC20 del contract SDD/contracts/2026-08-25-consumption-optimization.md (R1).
# Arquetipo `analysis`: el AC que afirma una cifra se bindea a la salida de la
# consulta que RE-DERIVA la cifra desde su fuente, no a un test unitario.
#
# MUTACIÓN: sobre una copia del script en el tmpdir, nunca sobre el repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUDGET="$REPO_ROOT/SDD/scripts/sdd-context-budget.sh"
TMP="$(mktemp -d)"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------- AC17 ----------
printf '\n-- test_salida_por_rol (AC17)\n'
out="$(bash "$BUDGET" planner "$REPO_ROOT" 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_salida_por_rol"
# una línea por archivo: empiezan con dos espacios y traen dos números y un path
n_files="$(printf '%s\n' "$out" | grep -cE '^  +[0-9]+ +[0-9]+ +[a-z]')"
assert_eq "$n_files" "9" "test_salida_por_rol — nueve archivos listados para planner"
assert_contains "$out" "TOTAL" "test_salida_por_rol — trae línea TOTAL"
assert_contains "$out" "quality-gates.md" "test_salida_por_rol — nombra los archivos, no sólo el total"

# ---------- AC18 ----------
printf '\n-- test_declara_aproximacion (AC18)\n'
assert_contains "$out" "APROXIMADOS" "test_declara_aproximacion — dice que es aproximado"
assert_contains "$out" "bytes / 3.6" "test_declara_aproximacion — dice CÓMO se deriva"
assert_contains "$out" "NO mide" "test_declara_aproximacion — declara qué queda afuera"
assert_contains "$out" "turnos" "test_declara_aproximacion — nombra el factor que falta"

# ---------- AC19 ----------
printf '\n-- test_rol_invalido (AC19)\n'
out_bad="$(bash "$BUDGET" arquitecto "$REPO_ROOT" 2>&1)"; rc_bad=$?
assert_exit 2 "$rc_bad" "test_rol_invalido"
for r in planner implementing reviewer; do
  assert_contains "$out_bad" "$r" "test_rol_invalido — enumera el rol válido: $r"
done
# sin argumentos: también rol desconocido
bash "$BUDGET" >/dev/null 2>&1; rc_none=$?
assert_exit 2 "$rc_none" "test_rol_invalido — sin argumentos"

# Triple de mutación (AC19): quitar la validación de rol del bloque de argv.
awk '
  /^case " \$ROLES " in$/ { skip=1 }
  skip && /^esac$/        { skip=0; next }
  skip                    { next }
                          { print }
' "$BUDGET" > "$TMP/mut_rol.sh"
bash "$TMP/mut_rol.sh" arquitecto "$REPO_ROOT" >/dev/null 2>&1; rc_m=$?
# El mutante sale 1, no 0. Al quitar la validación, $ROLE no matchea ningún case
# de FILES, FILES queda sin asignar y `set -u` corta — la validación es
# load-bearing por dos vías: el exit 2 limpio y el binding de FILES.
# Lo que el triple prueba es que la DETECCIÓN se pierde (deja de salir 2), no un
# valor particular de reemplazo. Predecir el exit code del mutante es
# exactamente el error que RT11 advierte: se compara contra las otras corridas,
# no contra una expectativa escrita de antemano.
assert_eq "$(awk -v m="$rc_m" 'BEGIN{print (m==2)?"detecta":"no-detecta"}')" "no-detecta" \
  "test_rol_invalido — MUTANTE pierde la detección (rojo esperado)"
assert_eq "$rc_bad-$rc_m-$rc_bad" "2-1-2" \
  "test_rol_invalido — las tres corridas se distinguen"

# ---------- AC20 ----------
printf '\n-- test_total_rederivado (AC20)\n'
out_i="$(bash "$BUDGET" implementing "$REPO_ROOT" 2>&1)"
# re-derivación INDEPENDIENTE: sumo la columna de bytes de las filas de archivo
suma="$(printf '%s\n' "$out_i" | awk '/^  +[0-9]+ +[0-9]+ +[a-z]/ { s += $1 } END { printf "%d", s }')"
total="$(printf '%s\n' "$out_i" | awk '/^TOTAL/ { printf "%d", $2 }')"
assert_eq "$total" "$suma" "test_total_rederivado — el TOTAL es la suma de lo que el propio script lista"
# y la cifra no es trivialmente cero
assert_eq "$(awk -v t="$total" 'BEGIN{print (t>1000)?"si":"no"}')" "si" \
  "test_total_rederivado — el total es una cifra real, no cero"

# Triple de mutación (AC20): sumar dos veces el primer archivo.
sed 's/^  TOTAL_BYTES=\$((TOTAL_BYTES + b))$/  TOTAL_BYTES=$((TOTAL_BYTES + b)); [ "$TOTAL_BYTES" = "$b" ] \&\& TOTAL_BYTES=$((TOTAL_BYTES + b))/' \
  "$BUDGET" > "$TMP/mut_total.sh"
out_mt="$(bash "$TMP/mut_total.sh" implementing "$REPO_ROOT" 2>&1)"
suma_m="$(printf '%s\n' "$out_mt" | awk '/^  +[0-9]+ +[0-9]+ +[a-z]/ { s += $1 } END { printf "%d", s }')"
total_m="$(printf '%s\n' "$out_mt" | awk '/^TOTAL/ { printf "%d", $2 }')"
assert_eq "$(awk -v a="$total_m" -v b="$suma_m" 'BEGIN{print (a==b)?"coincide":"difiere"}')" "difiere" \
  "test_total_rederivado — MUTANTE rompe la coincidencia (rojo esperado)"
out_r="$(bash "$BUDGET" implementing "$REPO_ROOT" 2>&1)"
total_r="$(printf '%s\n' "$out_r" | awk '/^TOTAL/ { printf "%d", $2 }')"
assert_eq "$total_r" "$total" "test_total_rederivado — revertido vuelve al total correcto"
assert_eq "$(awk -v a="$total" -v b="$total_m" 'BEGIN{print (a==b)?"iguales":"distintos"}')" "distintos" \
  "test_total_rederivado — las corridas se distinguen (RT11)"

printf '\n'
test_summary; exit $?
