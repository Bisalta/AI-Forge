#!/usr/bin/env bash
# SDD/tests/run.sh — descubre y corre SDD/tests/test_*.sh, agrega resultados.
#
# Es el "unit tests" (gate 4) de SDD/docs/doc_quality_gates.md. Bash 3.2 puro
# (piso macOS), sin dependencias fuera de coreutils.
#
# Uso:   bash SDD/tests/run.sh [directorio]
#   sin argumento: descubre en el directorio donde vive este script
#   (SDD/tests/). Un argumento explícito lo usan los propios tests del
#   harness (test_harness.sh) para apuntar a un directorio aislado en
#   SDD/tests/.tmp/ sin mezclar fixtures sintéticas con la suite real.
#
# Cada test_*.sh corre en SU PROPIO proceso (bash "$f"); su exit code decide
# pass/fail — run.sh no parsea stdout para eso.
#
# Salida: una línea PASS/FAIL por archivo (nombra el archivo que falló) +
# un resumen agregado.
# Exit: 0 si todos pasan · 1 si alguno falla · 1 si no encontró ningún test
#       (un harness que reporta éxito sin haber corrido nada es exactamente
#       el modo de falla que el contract ataca — HLTC "Error/fallback global").

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$SCRIPT_DIR}"

PASS_COUNT=0
FAIL_COUNT=0
FOUND=0
FAILED_FILES=""

for f in "$TARGET_DIR"/test_*.sh; do
  [ -e "$f" ] || continue # el glob no matcheó nada (nullglob no está en bash 3.2)
  FOUND=$((FOUND + 1))
  name="$(basename "$f")"
  output="$(bash "$f" 2>&1)"
  ec=$?
  if [ "$ec" -eq 0 ]; then
    printf 'PASS  %s\n' "$name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf 'FAIL  %s (exit %s)\n' "$name" "$ec"
    printf '%s\n' "$output" | sed 's/^/      /'
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_FILES="${FAILED_FILES}${name} "
  fi
done

if [ "$FOUND" -eq 0 ]; then
  printf 'ERROR: no encontré ningún test_*.sh en %s\n' "$TARGET_DIR"
  exit 1
fi

printf -- '---\n%s passed, %s failed (%s total)\n' "$PASS_COUNT" "$FAIL_COUNT" "$FOUND"

if [ "$FAIL_COUNT" -gt 0 ]; then
  printf 'Archivos con fallos: %s\n' "$FAILED_FILES"
  exit 1
fi

exit 0
