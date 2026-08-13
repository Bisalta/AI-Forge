#!/usr/bin/env bash
# SDD/tests/test_run_gates.sh — humo de plugins/sdd-flow/scripts/sdd-run-gates.sh
# sobre un repo git temporal (AC6 del contract R0).
#
# Ejercita el runner REAL del plugin (no un mock ni una copia): crea un repo
# git en SDD/tests/.tmp/, le escribe una escalera mínima con dos gates que
# salen 0, corre sdd-run-gates.sh contra él y asserta el campo "green" de su
# línea JSON `sdd.gates`. Limpieza garantizada con `trap ... EXIT`, incluso
# si el test falla.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_GATES="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-run-gates.sh"

TMP_DIR="$SCRIPT_DIR/.tmp/test_run_gates-$$"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [ ! -f "$RUN_GATES" ]; then
  echo "  FAIL  setup — no existe $RUN_GATES"
  exit 1
fi

mkdir -p "$TMP_DIR/SDD/docs"
git init -q "$TMP_DIR"

cat > "$TMP_DIR/SDD/docs/doc_quality_gates.md" <<'EOF'
# Escalera de gates — fixture de SDD/tests/test_run_gates.sh (repo temporal, nunca versionado)

| # | Gate | Comando | Obligatorio | Notas |
|---|---|---|---|---|
| 1 | unit tests | `true` | sí | fixture: siempre sale 0 |
| 2 | security | `true` | sí | fixture: siempre sale 0 |
EOF

OUT_REPORT="$TMP_DIR/.sdd/gates-run.md"

# Ojo con pipefail: si se lee el JSON con un pipe (`bash ... | grep ...`), "$?"
# queda con el exit code de grep, no el del runner. Se captura la salida
# completa primero y se grepea aparte para no perder el exit code real.
raw_output="$(cd "$TMP_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o "$OUT_REPORT" 2>&1)"
ec=$?
json_line="$(printf '%s\n' "$raw_output" | grep '"type":"sdd.gates"')"

assert_exit 0 "$ec" "sdd-run-gates.sh sale 0 con dos gates que salen 0"
assert_contains "$json_line" '"green":2' "el JSON sdd.gates reporta green:2"
assert_contains "$json_line" '"red":0' "el JSON sdd.gates reporta red:0 con dos gates verdes"

if [ ! -f "$OUT_REPORT" ]; then
  printf '  FAIL  el runner no escribió el reporte en %s\n' "$OUT_REPORT"
  TEST_FAILURES=$((TEST_FAILURES + 1))
fi

test_summary
exit $?
