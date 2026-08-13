#!/usr/bin/env bash
# SDD/tests/test_guard_identity.sh — AC14 a AC18 del contract R2
# (SDD/contracts/2026-08-13-sicop-hardening.md): identidad propia del agente
# en los commits, exigida por plugins/sdd-flow/hooks/guard-git.sh SOLO cuando
# el repo exporta SDD_AGENT_ENFORCE=1 (AC14, AC15, AC17); sin la variable el
# hook no opina (AC16 — par de deteccion de AC14). AC18 prueba el mecanismo
# de la decision #2 del contract (`git -c user.name=... -c user.email=...
# commit`), sin pasar por el hook: es la prueba de que la guarda de autoria
# de un archivo (`git log -1 --format='%an'`) deja de ser tautologica.
#
# Corrida contra guard-git.sh SIN el bloque de identidad (T1.2 del brief):
# tiene que salir en rojo, porque AC14 no puede denegar todavia — el hook no
# tiene ningun chequeo de identidad y cae al `allow` final igual.
#
# Cada caso vive en su propio repo git temporal bajo SDD/tests/.tmp/, con un
# commit inicial de identidad "humana" (nunca la del agente) ANTES del commit
# que se prueba: guard-git.sh hace `|| allow` si
# `git rev-parse --abbrev-ref HEAD` falla (repo sin commits, HEAD unborn —
# medido), asi que un repo recien `git init` sin commit previo pasaria
# siempre, mutase o no el bloque de identidad, y no probaria nada. La branch
# de cada repo se renombra a "agent-branch" (ninguna de las protegidas de
# guard-git.sh — main/master/dev/develop/qa/test/staging/...; "main" es el
# default de esta maquina, medido) para que el chequeo de rama protegida no
# dispare antes de llegar al bloque nuevo y confunda un rechazo por rama con
# un rechazo por identidad.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$REPO_ROOT/plugins/sdd-flow/hooks/guard-git.sh"

TMP_BASE="$SCRIPT_DIR/.tmp/test_guard_identity-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() {
  rm -rf "$TMP_BASE"
  unset SDD_AGENT_ENFORCE SDD_AGENT_NAME SDD_AGENT_EMAIL
  return 0
}
trap cleanup EXIT

if [ ! -f "$GUARD" ]; then
  echo "  FAIL  setup — no existe $GUARD"
  exit 1
fi

# guard-git.sh es fail-open sin jq (allow silencioso): sin jq este test no
# puede distinguir deny de allow, así que falla en setup en vez de reportar
# un falso verde.
command -v jq >/dev/null 2>&1 || { echo "  FAIL  setup — jq no disponible: guard-git.sh falla abierto sin el, este test no puede probar la deteccion"; exit 1; }

# new_repo <dir> — repo git aislado, identidad local "humana" (nunca la del
# agente) y un primer commit en una branch NO protegida, para que la
# resolucion de rama de guard-git.sh llegue hasta el bloque nuevo.
new_repo() {
  dir="$1"
  mkdir -p "$dir"
  git init -q "$dir"
  ( cd "$dir" && git checkout -q -b agent-branch )
  ( cd "$dir" && git config user.email "human@example.com" && git config user.name "human" && git config commit.gpgsign false )
  printf 'linea inicial\n' > "$dir/tracked.txt"
  ( cd "$dir" && git add -A && git commit -qm "init" )
}

# run_hook <cwd> <cmd> — arma el payload PreToolUse/Bash exacto que consume
# guard-git.sh y lo corre contra el hook real (nunca un mock). Los env vars
# SDD_AGENT_* los pone/saca cada caso antes de llamar a esta funcion, para
# que el proceso hijo los herede tal como estan exportados en ese momento.
run_hook() {
  jq -n --arg cmd "$2" --arg cwd "$1" '{tool_name:"Bash", tool_input:{command:$cmd}, cwd:$cwd}' | bash "$GUARD" 2>&1
}

# is_denied <salida-del-hook> — "si"/"no" segun si el cuerpo JSON de deny()
# aparece en la salida. Con jq disponible, deny() Y allow() salen exit 0 los
# dos (ver hooks/guard-git.sh) — la unica diferencia observable es este
# cuerpo permissionDecision: "deny" en stdout, nunca el exit code del
# proceso.
is_denied() {
  case "$1" in
    *'"permissionDecision": "deny"'*) printf 'si' ;;
    *) printf 'no' ;;
  esac
}

# =========================================================================
# AC14 — enforce=1, commit SIN -c user.name/-c user.email: el hook deniega
# y el mensaje nombra la identidad esperada. Par de deteccion con AC16.
# =========================================================================
AC14_DIR="$TMP_BASE/ac14"
new_repo "$AC14_DIR"

export SDD_AGENT_ENFORCE=1
unset SDD_AGENT_NAME SDD_AGENT_EMAIL
out14="$(run_hook "$AC14_DIR" 'git commit -m "sin identidad de agente"')"
unset SDD_AGENT_ENFORCE

assert_eq "$(is_denied "$out14")" "si" "AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega"
assert_contains "$out14" "sdd-agent" "AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada"

# =========================================================================
# AC15 — enforce=1, commit CON la identidad de agente default declarada via
# -c user.name=.../-c user.email=...: el hook permite.
# =========================================================================
AC15_DIR="$TMP_BASE/ac15"
new_repo "$AC15_DIR"

export SDD_AGENT_ENFORCE=1
unset SDD_AGENT_NAME SDD_AGENT_EMAIL
out15="$(run_hook "$AC15_DIR" 'git -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com commit -m "con identidad de agente"')"
unset SDD_AGENT_ENFORCE

assert_eq "$(is_denied "$out15")" "no" "AC15 enforce=1 con identidad de agente default - el hook permite"

# =========================================================================
# AC16 — SIN SDD_AGENT_ENFORCE en el entorno, un commit sin identidad de
# agente pasa: el hook no opina. Par de deteccion con AC14.
# =========================================================================
AC16_DIR="$TMP_BASE/ac16"
new_repo "$AC16_DIR"

unset SDD_AGENT_ENFORCE SDD_AGENT_NAME SDD_AGENT_EMAIL
out16="$(run_hook "$AC16_DIR" 'git commit -m "sin identidad de agente, sin enforcement"')"

assert_eq "$(is_denied "$out16")" "no" "AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa"

# =========================================================================
# AC17 — enforce=1, SDD_AGENT_NAME=otro-agente, commit que declara
# user.name=otro-agente (mas el user.email default, que no se overridea):
# el hook permite. Prueba que el nombre esperado se deriva de la variable de
# entorno, no de un literal fijo "sdd-agent".
# =========================================================================
AC17_DIR="$TMP_BASE/ac17"
new_repo "$AC17_DIR"

export SDD_AGENT_ENFORCE=1
export SDD_AGENT_NAME=otro-agente
unset SDD_AGENT_EMAIL
out17="$(run_hook "$AC17_DIR" 'git -c user.name=otro-agente -c user.email=sdd-agent@users.noreply.github.com commit -m "otro agente"')"
unset SDD_AGENT_ENFORCE SDD_AGENT_NAME

assert_eq "$(is_denied "$out17")" "no" "AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite"

# =========================================================================
# AC18 — mecanismo de la decision #2 del contract (no pasa por el hook): un
# commit real con -c user.name=sdd-agent -c user.email=... deja
# `git log -1 --format='%an'` en "sdd-agent". Es la prueba de que la guarda
# de autoria de un archivo dejo de ser tautologica: el commit inicial de
# new_repo (autor "human") sigue con su propio autor, y este segundo commit
# (autor "sdd-agent") cambia lo que la MISMA guarda devuelve — no es el
# mismo valor sea quien sea que commiteo.
# =========================================================================
AC18_DIR="$TMP_BASE/ac18"
new_repo "$AC18_DIR"
printf 'cambio del agente\n' >> "$AC18_DIR/tracked.txt"
( cd "$AC18_DIR" && git add -A )
( cd "$AC18_DIR" && git -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com commit -qm "commit de agente" )

AUTHOR18="$(cd "$AC18_DIR" && git log -1 --format='%an')"
PREV_AUTHOR18="$(cd "$AC18_DIR" && git log -1 --format='%an' HEAD~1)"

assert_eq "$AUTHOR18" "sdd-agent" "AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent"
assert_eq "$PREV_AUTHOR18" "human" "AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue"

test_summary
exit $?
