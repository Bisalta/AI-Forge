#!/usr/bin/env bash
# sdd-flow — PreToolUse guard sobre Bash.
#
# Bloquea las tres cosas que el plugin declara regla dura y que un agente apurado
# hace igual: commit directo a una rama protegida, bypass de hooks/CI, y push
# destructivo. Todo lo demás pasa sin tocarse.
#
# Diseño: FAIL-OPEN. Cualquier cosa inesperada (sin jq, sin git, JSON raro,
# working dir desconocido) => exit 0 y el flujo sigue normal. Un guard que
# rompe sesiones es peor que no tener guard.
#
# Escape hatch: SDD_ALLOW_BASE_COMMIT=1 desactiva el chequeo de rama protegida
# (para repos donde commitear a la default es legítimo).

set -uo pipefail

allow() { exit 0; }

deny() {
  # permissionDecision=deny: Claude recibe la razón y no ejecuta el comando.
  local reason="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg r "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $r
      }
    }'
    exit 0
  fi
  echo "$reason" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || allow

INPUT="$(cat)" || allow
[ -n "$INPUT" ] || allow

TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)" || allow
[ "$TOOL" = "Bash" ] || allow

CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)" || allow
[ -n "$CMD" ] || allow

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)"
[ -n "$CWD" ] || CWD="$PWD"

# Reconoce `git <subcomando>` tolerando flags globales con y sin valor:
#   git commit · git -C /path commit · git -c user.email=x commit · git --git-dir=/x commit
git_subcommand() {
  printf '%s' "$CMD" | grep -qE "(^|[;&|[:space:]])git([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|exec-path)=[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+$1(\$|[[:space:]])"
}

# --- 1. Bypass de hooks / CI --------------------------------------------------
if printf '%s' "$CMD" | grep -qE '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  deny "sdd-flow: --no-verify saltea los hooks del repo. Es una mitigación prohibida (standards/quality-gates.md §6). Arreglá lo que el hook detecta, o marcá BLOCKED y preguntá al planner."
fi

# --- 2. Push destructivo (--force-with-lease sí está permitido) ---------------
if git_subcommand push; then
  if printf '%s' "$CMD" | grep -qE '(^|[[:space:]])(--force|-f)([[:space:]]|$)' \
     && ! printf '%s' "$CMD" | grep -qE '(^|[[:space:]])--force-with-lease'; then
    deny "sdd-flow: 'git push --force' puede borrar trabajo de otro agente. Usá --force-with-lease si el rewrite es intencional (quality-gates.md §6)."
  fi
fi

# --- 3. Commit directo a rama protegida --------------------------------------
if [ "${SDD_ALLOW_BASE_COMMIT:-0}" = "1" ]; then
  allow
fi

git_subcommand commit || allow

command -v git >/dev/null 2>&1 || allow

# El repo target puede no ser el cwd de la sesión: `git -C /path commit` y
# `cd /path && git commit` son evasiones reales. Resolución best-effort:
# 1) -C explícito gana; 2) el último `cd <path>` del comando compuesto gana;
# 3) fallback: cwd de la sesión. Path inexistente → fallback al cwd.
TARGET="$CWD"
C_PATH="$(printf '%s' "$CMD" | grep -oE '(^|[;&|[:space:]])git[[:space:]]+-C[[:space:]]+[^[:space:]]+' | tail -1 | sed -E 's/.*-C[[:space:]]+//')"
if [ -n "$C_PATH" ]; then
  TARGET="$C_PATH"
else
  CD_PATH="$(printf '%s' "$CMD" | grep -oE '(^|[;&|[:space:]])cd[[:space:]]+[^;&|[:space:]]+' | tail -1 | sed -E 's/.*cd[[:space:]]+//' | tr -d '"'"'"'')"
  [ -n "$CD_PATH" ] && TARGET="$CD_PATH"
fi
case "$TARGET" in /*) ;; "~"*) TARGET="${HOME}${TARGET#\~}" ;; *) TARGET="$CWD/$TARGET" ;; esac
[ -d "$TARGET" ] || TARGET="$CWD"

git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 || allow

BRANCH="$(git -C "$TARGET" rev-parse --abbrev-ref HEAD 2>/dev/null)" || allow
[ -n "$BRANCH" ] || allow
[ "$BRANCH" != "HEAD" ] || allow   # detached HEAD: rebase/bisect en curso, no molestar

# Lista de ramas protegidas: SDD_PROTECTED_BRANCHES la REEMPLAZA (patrones glob,
# separados por coma) — p.ej. "main,trunk,release/*,hotfix/*".
PROTECTED="${SDD_PROTECTED_BRANCHES:-main,master,dev,develop,qa,test,staging,stage,pre-prod,preprod,prod,production,release,release/*,hotfix/*}"
OLD_IFS="$IFS"; IFS=','
for pat in $PROTECTED; do
  # shellcheck disable=SC2254  # el glob sin comillas es intencional (case pattern)
  case "$BRANCH" in
    $pat)
      IFS="$OLD_IFS"
      deny "sdd-flow: '$BRANCH' es una rama protegida y todo trabajo nace en branch propia (standards/base-standards.md). Creá la branch desde la base confirmada (con Proxima: {action}-{KEY}-{desc}; sin Proxima: <MODULO>-<TICKET>) y commiteá ahí; la integración va por PR o merge --no-ff. Si commitear acá es legítimo en este repo, corré con SDD_ALLOW_BASE_COMMIT=1 (o ajustá SDD_PROTECTED_BRANCHES)."
      ;;
  esac
done
IFS="$OLD_IFS"

allow
