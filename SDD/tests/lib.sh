# shellcheck shell=bash
# SDD/tests/lib.sh — helpers de assert del harness de SDD/tests/run.sh.
#
# Único lugar donde se definen `assert_*` (Reuse statement del contract R0,
# ver SDD/contracts/2026-08-13-sicop-hardening.md). Ningún test_*.sh define
# su propio assert.
#
# Bash 3.2 puro (piso macOS): sin `declare -A`, sin `mapfile`/`readarray`,
# sin `${var^^}`. Sin dependencias fuera de coreutils.
#
# Uso: sourcealo al principio de cada SDD/tests/test_*.sh —
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   . "$SCRIPT_DIR/lib.sh"
# Cada test_*.sh corre en su propio proceso (run.sh lo invoca con `bash
# archivo`), así que TEST_FAILURES nace en 0 en cada corrida: no hace falta
# resetearlo entre archivos.
#
# Al final de cada test_*.sh, llamar a `test_summary` y propagar su exit code
# (`test_summary; exit $?`) — es lo que le da a run.sh un exit code real por
# archivo.

TEST_FAILURES=0
export TEST_FAILURES

# assert_eq <actual> <esperado> [mensaje]
# Compara con `=` (string). El mensaje es el nombre del caso: literal,
# grepeable, y es lo que va en la columna "Test" del binding AC↔test.
assert_eq() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-assert_eq}"
  if [ "$actual" = "$expected" ]; then
    printf '  ok    %s\n' "$msg"
  else
    printf '  FAIL  %s — esperado [%s], obtenido [%s]\n' "$msg" "$expected" "$actual"
    TEST_FAILURES=$((TEST_FAILURES + 1))
  fi
}

# assert_contains <haystack> <needle> [mensaje]
# Substring literal (no regex) vía `case`, portable a bash 3.2.
assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-assert_contains}"
  case "$haystack" in
    *"$needle"*)
      printf '  ok    %s\n' "$msg"
      ;;
    *)
      printf '  FAIL  %s — no encontré [%s] en la salida\n' "$msg" "$needle"
      TEST_FAILURES=$((TEST_FAILURES + 1))
      ;;
  esac
}

# assert_exit <exit_code_esperado> <exit_code_obtenido> [mensaje]
# No corre ningún comando: el caller ya lo corrió y capturó "$?" (así el
# caller puede además inspeccionar stdout/stderr por separado con
# assert_contains, sin que este helper se lo trague).
assert_exit() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-assert_exit}"
  assert_eq "$actual" "$expected" "$msg (exit $expected)"
}

# test_summary — se llama al final de cada test_*.sh. Imprime el resumen y
# devuelve 0 si TEST_FAILURES es 0, 1 si no. run.sh decide pass/fail por el
# exit code del proceso, nunca parseando stdout.
test_summary() {
  if [ "$TEST_FAILURES" -eq 0 ]; then
    printf 'PASS\n'
    return 0
  fi
  printf 'FAIL — %s assert(s) fallaron\n' "$TEST_FAILURES"
  return 1
}
