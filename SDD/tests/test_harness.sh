#!/usr/bin/env bash
# SDD/tests/test_harness.sh — auto-test del harness: un test que falla tiene
# que reportarse como fallo (AC1, AC2 del contract R0).
#
# Genera test_*.sh sintéticos en directorios aislados bajo SDD/tests/.tmp/
# (nunca versionados — SDD/tests/.tmp/ está en .gitignore) y corre run.sh
# apuntado a ESE directorio, nunca al SDD/tests real: así la corrida
# sintética no se mezcla con la suite verdadera. Limpieza garantizada con
# `trap ... EXIT`, incluso si algún assert falla.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

RUN_SH="$SCRIPT_DIR/run.sh"
WORK_DIR="$SCRIPT_DIR/.tmp/test_harness-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

# --- caso: "run.sh sale 0 cuando todos los test_*.sh pasan" ---------------
PASS_DIR="$WORK_DIR/all-pass"
mkdir -p "$PASS_DIR"
cat > "$PASS_DIR/test_fake_ok.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

out_pass="$(bash "$RUN_SH" "$PASS_DIR" 2>&1)"
ec_pass=$?
assert_exit 0 "$ec_pass" "run.sh sale 0 cuando todos los test_*.sh pasan"
assert_contains "$out_pass" "1 passed, 0 failed" "run.sh sale 0 cuando todos los test_*.sh pasan"

# --- caso: "run.sh sale 1 y nombra el archivo que falló" ------------------
FAIL_DIR="$WORK_DIR/one-fails"
mkdir -p "$FAIL_DIR"
cat > "$FAIL_DIR/test_fake_ok.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$FAIL_DIR/test_fake_broken.sh" <<'EOF'
#!/usr/bin/env bash
echo "esto falla a proposito"
exit 7
EOF

out_fail="$(bash "$RUN_SH" "$FAIL_DIR" 2>&1)"
ec_fail=$?
assert_exit 1 "$ec_fail" "run.sh sale 1 y nombra el archivo que falló"
assert_contains "$out_fail" "test_fake_broken.sh" "run.sh sale 1 y nombra el archivo que falló"

# --- caso: "run.sh sale 1 cuando no encuentra ningun test_*.sh" -----------
# (comportamiento de fallback global del contract: un harness que reporta
# éxito sin haber corrido nada es el modo de falla que este contract ataca)
EMPTY_DIR="$WORK_DIR/empty"
mkdir -p "$EMPTY_DIR"

out_empty="$(bash "$RUN_SH" "$EMPTY_DIR" 2>&1)"
ec_empty=$?
assert_exit 1 "$ec_empty" "run.sh sale 1 cuando no encuentra ningun test_*.sh"
assert_contains "$out_empty" "ERROR" "run.sh sale 1 cuando no encuentra ningun test_*.sh"

test_summary
exit $?
