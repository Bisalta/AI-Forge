#!/usr/bin/env bash
# sdd-flow — linter de closure del contract (standards/quality-gates.md, closure rules).
#
# Dos chequeos determinísticos sobre un HLTC/contract:
#  1. Frases prohibidas por las closure rules ("if needed", "prefer", "por definir"...)
#     — si dos ingenieros lo implementarían distinto, el contract es inválido.
#  2. Artifact inventory: cada path citado en backticks existe en el repo, o la
#     línea lo marca como nuevo (NEW / nuevo / a crear). Un contract que cita
#     símbolos inexistentes fue alucinado, no derivado.
#
# Uso:   sdd-lint-contract.sh <contract.md> [repo-root]
# Salida: SEVERIDAD<TAB>línea<TAB>regla<TAB>extracto
# Exit:  0 = limpio o solo WARN · 2 = hay BLOCKER · 3 = no pude leer el contract
#
# Limitaciones asumidas: se saltean los bloques de código y las líneas que citan
# las propias closure rules (contienen "prohibido"/"closure"/"banned") — el
# contract legítimamente las transcribe. Paths de OTROS repos (multi-agente) van
# a WARN, no BLOCKER: el linter corre desde un solo repo-root.

set -uo pipefail

VERSION="0.10.0"
[ "${1:-}" = "--version" ] && { echo "sdd-lint-contract $VERSION"; exit 0; }

CONTRACT="${1:-}"
ROOT="${2:-.}"
[ -n "$CONTRACT" ] && [ -f "$CONTRACT" ] || { echo "uso: sdd-lint-contract.sh <contract.md> [repo-root]" >&2; exit 3; }

BLOCKERS=0
WARNS=0

# Frases prohibidas (ES + EN), case-insensitive, con boundaries donde importa.
BANNED='if needed|if applicable|if necessary|when available|if present|may be|might be|to be defined|to be decided|tbd|or equivalent|or similar|as appropriate|por definir|a definir|si aplica|si es necesario|de ser necesario|si hace falta|según convenga|cuando esté disponible|podría ser|preferentemente|o equivalente|o similar|se verá|a confirmar'

in_code=0
lineno=0
while IFS= read -r line; do
  lineno=$((lineno+1))
  case "$line" in '```'*) in_code=$((1-in_code)); continue ;; esac
  [ "$in_code" = 1 ] && continue
  # líneas que citan las reglas, no las violan
  printf '%s' "$line" | grep -qiE 'prohibido|closure|banned|forbidden' && continue

  # 1) frases prohibidas
  hit="$(printf '%s' "$line" | grep -oiE "(^|[^a-záéíóú-])($BANNED)([^a-záéíóú-]|$)" | head -1)"
  if [ -n "$hit" ]; then
    excerpt="$(printf '%s' "$line" | sed 's/\t/ /g' | cut -c1-140)"
    printf 'BLOCKER\t%s\tfrase-abierta\t%s\n' "$lineno" "$excerpt"
    BLOCKERS=$((BLOCKERS+1))
  fi

  # 2) inventory: paths en backticks con extensión o slash
  if ! printf '%s' "$line" | grep -qiE '\(?(NEW|nuevo|a crear|to create)\)?'; then
    for p in $(printf '%s' "$line" | grep -oE '`[A-Za-z0-9_./-]+`' | tr -d '\`'); do
      # solo lo que parece path de archivo: tiene / y extensión corta; no URLs ni versiones
      printf '%s' "$p" | grep -qE '^[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+\.[a-z]{1,5}$' || continue
      if [ ! -e "$ROOT/$p" ]; then
        printf 'WARN\t%s\tpath-inexistente\t%s (¿alucinado, de otro repo, o falta marcar NEW?)\n' "$lineno" "$p"
        WARNS=$((WARNS+1))
      fi
    done
  fi
done < "$CONTRACT"

[ "$BLOCKERS" -gt 0 ] && exit 2
exit 0
