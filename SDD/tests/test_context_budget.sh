# shellcheck shell=bash
# SDD/tests/test_context_budget.sh
#
# AC17-AC20 y AC27bis del contract SDD/contracts/2026-08-25-consumption-optimization.md
# (R1, ratificado a v7 tras revisión externa). Arquetipo `analysis`: el AC que
# afirma una cifra se bindea a la salida de la consulta que RE-DERIVA la cifra
# desde su fuente, no a un test unitario.
#
# v7: el script pasó de una lista FILES hardcodeada a derivarla en vivo
# grepeando standards/ en los puntos de entrada de cada rol. La v0.1.0 tenía
# la lista congelada y le faltaban standards/archetypes.md y
# standards/seo-frontend.md en el rol reviewer — 23,6% de subestimación,
# encontrado por revisión externa (reviewer-agent, ronda 1 de este ciclo). Los
# tests de acá ahora verifican POBLACIÓN de forma independiente (grep propio,
# no confiar en lo que el script imprime), no sólo aritmética — es la
# corrección directa al hallazgo: "AC20 sólo suma lo que el script mismo
# imprimió" era autosatisfacible por el mismo error que pretendía detectar
# (misma clase que RT10).
#
# MUTACIÓN: sobre una copia del script en el tmpdir, nunca sobre el repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUDGET="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-context-budget.sh"
PLUGIN="$REPO_ROOT/plugins/sdd-flow"
TMP="$(mktemp -d)"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------- helper: re-derivación INDEPENDIENTE de la población de un rol ----------
# No reusa la lógica del script — grepea los mismos puntos de entrada con un
# comando separado, escrito acá, para que un bug en AMBOS lados (script y
# test) tenga que ser el mismo bug por coincidencia, no por copia.
poblacion_independiente() {
  role="$1"
  case "$role" in
    planner)      eps="commands/sdd.md skills/sdd-plan/SKILL.md skills/enrich-user-story/SKILL.md" ;;
    implementing) eps="agents/implementing-agent.md" ;;
    reviewer)     eps="agents/reviewer-agent.md" ;;
  esac
  standards="$(for ep in $eps; do grep -ohE 'standards/[a-z-]+\.md' "$PLUGIN/$ep" 2>/dev/null; done | sort -u)"
  printf '%s\n%s\n' "$eps" "$standards" | tr ' ' '\n' | grep -v '^$' | sort -u
}

# ---------- AC17 ----------
printf '\n-- test_salida_por_rol (AC17)\n'
out="$(bash "$BUDGET" reviewer "$REPO_ROOT" 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_salida_por_rol"
n_files_script="$(printf '%s\n' "$out" | grep -cE '^  +[0-9]+ +[0-9]+ +[a-z]')"
n_files_independiente="$(poblacion_independiente reviewer | grep -c .)"
assert_eq "$n_files_script" "$n_files_independiente" \
  "test_salida_por_rol — el script lista tantos archivos como la re-derivación independiente ($n_files_independiente)"
assert_contains "$out" "TOTAL" "test_salida_por_rol — trae línea TOTAL"
assert_contains "$out" "quality-gates.md" "test_salida_por_rol — nombra los archivos, no sólo el total"

# ---------- AC18 ----------
printf '\n-- test_declara_aproximacion (AC18)\n'
assert_contains "$out" "APROXIMADOS" "test_declara_aproximacion — dice que es aproximado"
assert_contains "$out" "bytes / 3.6" "test_declara_aproximacion — dice CÓMO se deriva"
assert_contains "$out" "NO mide" "test_declara_aproximacion — declara qué queda afuera"
assert_contains "$out" "turnos" "test_declara_aproximacion — nombra el factor que falta"
assert_contains "$out" "no está congelada" "test_declara_aproximacion — declara que la lista se deriva en vivo"

# ---------- AC19 ----------
printf '\n-- test_rol_invalido (AC19)\n'
out_bad="$(bash "$BUDGET" arquitecto "$REPO_ROOT" 2>&1)"; rc_bad=$?
assert_exit 2 "$rc_bad" "test_rol_invalido"
for r in planner implementing reviewer; do
  assert_contains "$out_bad" "$r" "test_rol_invalido — enumera el rol válido: $r"
done
bash "$BUDGET" >/dev/null 2>&1; rc_none=$?
assert_exit 2 "$rc_none" "test_rol_invalido — sin argumentos"

# Triple de mutación (AC19): quitar la validación de rol del bloque de argv.
# El mutante sale 1, no 0: al quitar la validación, $ROLE no matchea ningún
# case de ENTRY_POINTS, ENTRY_POINTS queda sin asignar y `set -u` corta — la
# validación es load-bearing por dos vías. Lo que el triple prueba es que la
# DETECCIÓN se pierde (deja de salir 2), no un valor particular de reemplazo
# (RT15: no se predice el exit code del mutante, se compara contra las otras
# corridas).
awk '
  /^case " \$ROLES " in$/ { skip=1 }
  skip && /^esac$/        { skip=0; next }
  skip                    { next }
                          { print }
' "$BUDGET" > "$TMP/mut_rol.sh"
# tercera pata GENUINA: una corrida nueva, en su propia variable — no se
# reusa rc_bad (BLOCKER encontrado por revisión externa en la versión previa
# de este mismo test: la pata "revertido" reusaba $rc_bad en vez de
# re-ejecutar, así que el assert no podía fallar en esa posición).
bash "$TMP/mut_rol.sh" arquitecto "$REPO_ROOT" >/dev/null 2>&1; rc_m=$?
assert_eq "$(awk -v m="$rc_m" 'BEGIN{print (m==2)?"detecta":"no-detecta"}')" "no-detecta" \
  "test_rol_invalido — MUTANTE pierde la detección (rojo esperado)"
bash "$BUDGET" arquitecto "$REPO_ROOT" >/dev/null 2>&1; rc_rev=$?
assert_eq "$rc_rev" "2" "test_rol_invalido — revertido: corrida NUEVA, no la primera reusada"
# No se predice el valor exacto de rc_m (RT15: eso es una predicción, no una
# medición) — se compara contra las otras dos corridas: limpio y revertido
# tienen que coincidir entre sí (ambos detectan), y el mutante tiene que
# diferir de los dos (no detecta, sea cual sea su código real).
assert_eq "$rc_bad" "$rc_rev" "test_rol_invalido — limpio y revertido coinciden (los dos detectan)"
assert_eq "$(awk -v a="$rc_bad" -v b="$rc_m" 'BEGIN{print (a==b)?"igual":"distinto"}')" "distinto" \
  "test_rol_invalido — el mutante difiere de las corridas limpias (las tres se distinguen)"

# ---------- AC20 ----------
printf '\n-- test_total_rederivado (AC20)\n'
out_i="$(bash "$BUDGET" implementing "$REPO_ROOT" 2>&1)"
suma="$(printf '%s\n' "$out_i" | awk '/^  +[0-9]+ +[0-9]+ +[a-z]/ { s += $1 } END { printf "%d", s }')"
total="$(printf '%s\n' "$out_i" | awk '/^TOTAL/ { printf "%d", $2 }')"
assert_eq "$total" "$suma" "test_total_rederivado — el TOTAL es la suma de lo que el propio script lista (aritmética)"
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

# ---------- AC27bis (v7 — hallazgo de revisión externa, MAJOR 10) ----------
printf '\n-- test_poblacion_no_congelada (AC27bis)\n'
# Este es el test que MAJOR 10 pedía y no existía: verificar MIEMBROS, no sólo
# aritmética. Reproduce el hallazgo exacto — antes del fix, reviewer perdía
# archetypes.md y seo-frontend.md — como regresión, y agrega una prueba de
# que un standards/ NUEVO en un punto de entrada aparece solo, sin tocar el
# script.
out_rev="$(bash "$BUDGET" reviewer "$REPO_ROOT" 2>&1)"
assert_contains "$out_rev" "archetypes.md" \
  "test_poblacion_no_congelada — reviewer incluye archetypes.md (regresión del hallazgo real)"
assert_contains "$out_rev" "seo-frontend.md" \
  "test_poblacion_no_congelada — reviewer incluye seo-frontend.md (regresión del hallazgo real)"

# Triple: un standards/ nuevo agregado a un punto de entrada, en una copia,
# aparece en la salida sin editar el script.
cp -R "$PLUGIN" "$TMP/plugin_copia"
printf '\nVer standards/nuevo-inventado.md para más detalle.\n' >> "$TMP/plugin_copia/agents/reviewer-agent.md"
touch "$TMP/plugin_copia/standards/nuevo-inventado.md"
out_antes="$(bash "$BUDGET" reviewer "$REPO_ROOT" 2>&1 | grep -c 'nuevo-inventado')"
out_con_ref="$(sed "s#PLUGIN=\"\$ROOT/plugins/sdd-flow\"#PLUGIN=\"$TMP/plugin_copia\"#" "$BUDGET" > "$TMP/budget_copia.sh"; bash "$TMP/budget_copia.sh" reviewer "$REPO_ROOT" 2>&1 | grep -c 'nuevo-inventado')"
assert_eq "$out_antes" "0" "test_poblacion_no_congelada — el repo real no tiene el archivo inventado"
assert_eq "$out_con_ref" "1" "test_poblacion_no_congelada — la copia con la referencia nueva lo detecta solo (sin tocar el script)"

printf '\n'
test_summary; exit $?
