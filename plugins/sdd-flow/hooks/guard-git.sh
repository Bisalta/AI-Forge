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
# (para repos donde commitear a la default es legítimo) — NUNCA el chequeo de
# identidad de agente (sección 3 más abajo): son dos guardas independientes,
# activadas por variables distintas (ratificación v5 del contract, AC36/AC38).

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

# --- 3. Identidad de agente en el autor del commit (contract R2) -------------
# Ratificación v5 (ESCALATE ronda 1 de R2): este bloque tiene que evaluarse
# ANTES del hatch de rama protegida y de toda resolución de rama (sección 4
# de abajo) — sólo parsea $CMD, no llama a git ni depende de en qué rama
# está el repo. Ubicarlo "después" del chequeo de rama (v4) lo dejaba aguas
# abajo de cuatro salidas tempranas ajenas a identidad (el propio hatch,
# `command -v git`, `rev-parse --git-dir` y HEAD detached), así que
# SDD_ALLOW_BASE_COMMIT=1 (AC36) o un HEAD detached (AC37) apagaban el
# chequeo de identidad de contrabando — exactamente la guarda tautológica
# que R2 existe para matar (quality-gates.md, regla del AC de autoría).
git_subcommand commit || allow

# Opt-in por repo: sin SDD_AGENT_ENFORCE=1 en el entorno este bloque no
# deniega y un humano commiteando en el mismo repo no queda bloqueado (AC16,
# par de detección con AC14). Con la variable en 1, el mecanismo de
# identidad es `git -c user.name=... -c user.email=...` (decisión cerrada
# del contract: nunca GIT_AUTHOR_*/--author) — un commit que no declara las
# dos flags con el valor esperado se deniega con el mismo deny() que usa el
# chequeo de rama protegida de abajo (mismo código de denegación, AC14),
# sin importar el hatch de rama ni si HEAD está detached (AC36, AC37).
if [ "${SDD_AGENT_ENFORCE:-0}" = "1" ]; then
  EXPECTED_NAME="${SDD_AGENT_NAME:-sdd-agent}"
  EXPECTED_EMAIL="${SDD_AGENT_EMAIL:-sdd-agent@users.noreply.github.com}"
  GOT_NAME="$(printf '%s' "$CMD" | grep -oE '\-c[[:space:]]+user\.name=[^[:space:]]+' | tail -1 | sed -E 's/^-c[[:space:]]+user\.name=//')"
  GOT_EMAIL="$(printf '%s' "$CMD" | grep -oE '\-c[[:space:]]+user\.email=[^[:space:]]+' | tail -1 | sed -E 's/^-c[[:space:]]+user\.email=//')"
  if [ "$GOT_NAME" != "$EXPECTED_NAME" ] || [ "$GOT_EMAIL" != "$EXPECTED_EMAIL" ]; then
    deny "sdd-flow: este repo exige identidad de agente en los commits (SDD_AGENT_ENFORCE=1). Esperada: user.name=${EXPECTED_NAME} user.email=${EXPECTED_EMAIL}. Recibida: user.name=${GOT_NAME:-<ninguna>} user.email=${GOT_EMAIL:-<ninguna>}. Commiteá con: git -c user.name=${EXPECTED_NAME} -c user.email=${EXPECTED_EMAIL} commit ... (standards/base-standards.md, sección Git)."
  fi
fi

# --- 4. Commit directo a rama protegida --------------------------------------
if [ "${SDD_ALLOW_BASE_COMMIT:-0}" = "1" ]; then
  allow
fi

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
