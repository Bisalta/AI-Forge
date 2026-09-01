#!/usr/bin/env bash
# SDD/tests/test_check_self_scoping.sh — bugfix (SDD/debt.md D11 + patrón RT13):
# sdd-check.sh se detecta a sí mismo, y su loop de patrones custom no respeta
# el mismo guard `.md` que las tres reglas built-in.
#
# Medido en Bisalta/WMS-Back durante el ciclo SDD WMS-34 (2026-09-01), con la
# copia cacheada del plugin (sdd-check.sh 0.10.0). Reproducido acá contra el
# árbol real de ai-forge:
#
#   Caso A (D11): las líneas que DEFINEN las reglas `supresor`/`test-skipeado`/
#   `no-verify` necesariamente contienen, como texto plano, los mismos marcadores
#   de supresión/skip/bypass que buscan (ver el propio script). Cuando
#   sdd-check.sh se distribuye a un repo nuevo (`/sdd-init` lo copia a
#   SDD/scripts/), el primer commit que lo agrega lo pone en rojo permanente
#   contra sí mismo — el guard `.md` (AC42) no lo cubre porque el propio
#   script es `.sh`, no `.md`.
#
#   Caso B (DEFECTO 2+3, "eco creciente"): el guard `.md` sí existe para las
#   tres reglas built-in pero el loop de patrones custom
#   (SDD_CHECK_PATTERNS / SDD/scripts/sdd-check.patterns) no lo aplica —
#   `line ~ ere` corre sin ningún scoping. Un reporte de evidencia commiteado
#   (quality-gates.md §5) que CITA el literal de un patrón custom como
#   evidencia de lo que se encontró queda marcado como una violación nueva,
#   y como los reportes se commitean y se acumulan (R1, R2, R3...), la
#   superficie de falsos positivos sólo crece.
#
#   Caso C (guarda de no-regresión): una violación real en un archivo
#   normal (ni el propio script, ni `.md`) sigue detectándose — el fix no
#   puede "arreglar" el falso positivo apagando la regla entera (la lección
#   de D6: excluir de más ciega el chequeo).
#
# Bugfix (quality-gates.md §10.3): el bug ya es la mutación, dos corridas
# alcanzan — rojo con el bug en el árbol, verde con el fix. Sin tercera
# corrida.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECK_SRC="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-check.sh"
TMP_DIR="$SCRIPT_DIR/.tmp/test_check_self_scoping-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$TMP_DIR"
git init -q "$TMP_DIR"
( cd "$TMP_DIR" && git config user.email test@example.com && git config user.name test )
printf 'fixture de test_check_self_scoping.sh\n' > "$TMP_DIR/README.md"
( cd "$TMP_DIR" && git add -A && git commit -q -m baseline )
BASE_COMMIT="$(cd "$TMP_DIR" && git rev-parse HEAD)"

run_check() { ( cd "$TMP_DIR" && bash "$TMP_DIR/SDD/scripts/sdd-check.sh" "$BASE_COMMIT" 2>&1 ); }

# --- Caso A (D11): el script agregado fresco a un repo no se autodetecta ---
mkdir -p "$TMP_DIR/SDD/scripts"
cp "$CHECK_SRC" "$TMP_DIR/SDD/scripts/sdd-check.sh"
( cd "$TMP_DIR" && git add -A )

outA="$(run_check)"; ecA=$?
assert_exit 0 "$ecA" "casoA D11 - sdd-check.sh agregado fresco no se autodetecta"
case "$outA" in
  *"SDD/scripts/sdd-check.sh"*)
    printf '  FAIL  casoA D11 - no debería mencionar SDD/scripts/sdd-check.sh como BLOCKER\n'
    TEST_FAILURES=$((TEST_FAILURES + 1))
    ;;
  *) printf '  ok    casoA D11 - SDD/scripts/sdd-check.sh no aparece en la salida\n' ;;
esac

# --- Caso B (DEFECTO 2+3): patrón custom no respeta el guard .md -----------
# El patrón busca un marcador ficticio en el CÓDIGO (nunca en prosa .md); el
# archivo .md de abajo lo CITA como documentación/evidencia, no lo usa.
printf 'BLOCKER\tmarker-prohibido\tMARCADOR_PROHIBIDO_XYZ\n' > "$TMP_DIR/SDD/scripts/sdd-check.patterns"
mkdir -p "$TMP_DIR/SDD/verification"
printf '# Reporte de evidencia\n\nSe encontró `MARCADOR_PROHIBIDO_XYZ` en una corrida anterior (ya resuelto).\n' > "$TMP_DIR/SDD/verification/report-R1.md"
( cd "$TMP_DIR" && git add -A )

outB="$(run_check)"; ecB=$?
assert_exit 0 "$ecB" "casoB eco-creciente - reporte .md que cita el marcador no se marca solo"
case "$outB" in
  *"report-R1.md"*)
    printf '  FAIL  casoB eco-creciente - no debería marcar report-R1.md como BLOCKER\n'
    TEST_FAILURES=$((TEST_FAILURES + 1))
    ;;
  *) printf '  ok    casoB eco-creciente - report-R1.md no aparece en la salida\n' ;;
esac
case "$outB" in
  *"sdd-check.patterns"*)
    printf '  FAIL  casoB eco-creciente - sdd-check.patterns no debería marcarse a si mismo\n'
    TEST_FAILURES=$((TEST_FAILURES + 1))
    ;;
  *) printf '  ok    casoB eco-creciente - sdd-check.patterns (auto-definicion) no aparece en la salida\n' ;;
esac

# --- Caso C (no-regresión): una violación real sigue detectándose ----------
# (a) regla built-in `supresor` sobre un archivo normal, no-.md. El marcador
# se arma en dos piezas bash (mismo motivo que plant_kv de test_secret_scan.sh):
# contiguo en ESTE archivo fuente, sdd-check.sh se autodetectaría al escanear
# su propio test — partido, nunca aparece pegado en el .sh que lo declara.
mkdir -p "$TMP_DIR/src"
printf 'function f() {\n  // %s%s\n  return 1\n}\n' "eslint" "-disable-next-line" > "$TMP_DIR/src/real.ts"
# (b) patrón custom sobre un archivo normal, no-.md
printf 'const x = "MARCADOR_PROHIBIDO_XYZ"\n' > "$TMP_DIR/src/real2.ts"
( cd "$TMP_DIR" && git add -A )

outC="$(run_check)"; ecC=$?
assert_exit 2 "$ecC" "casoC no-regresion - violaciones reales en archivos normales siguen en rojo"
assert_contains "$outC" "src/real.ts" "casoC no-regresion - supresor built-in sigue detectando en .ts"
assert_contains "$outC" "src/real2.ts" "casoC no-regresion - patron custom sigue detectando en .ts"

test_summary
exit $?
