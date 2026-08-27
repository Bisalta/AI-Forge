#!/usr/bin/env bash
# sdd-escalation-tally.sh — cuenta SDD/escalations.md por Clase.
#
# Contesta "cuántos ESCALATE/REJECTED fueron defecto de plan" sin releer el
# ciclo entero: es un conteo mecánico sobre una tabla ya clasificada, no un
# clasificador. La clasificación la escribe el planner al resolver cada
# evento (ver la cabecera de escalations.md) — este script sólo suma lo que
# ya está escrito, y avisa si algo quedó sin escribir.
#
# Uso:   sdd-escalation-tally.sh [ledger.md]   (default: SDD/escalations.md)
# Salida: TOTAL + una línea por Clase presente + INVALIDA si hay filas con
#         Clase vacía o fuera del enum cerrado.
# Exit:  0 = ok · 2 = no encuentro el ledger · 3 = hay fila(s) con Clase
#        inválida (silenciarlas en el conteo sería el mismo defecto que
#        `secret-scan.sh` D6: un charset que deja pasar la forma que no
#        anticipó — acá la forma es una fila sin clasificar).

set -uo pipefail

VERSION="0.1.0"
[ "${1:-}" = "--version" ] && { echo "sdd-escalation-tally $VERSION"; exit 0; }

LEDGER="${1:-SDD/escalations.md}"
[ -f "$LEDGER" ] || { printf 'ERROR: no encuentro %s\n' "$LEDGER" >&2; exit 2; }

VALID_PLAN="plan"
VALID_DECISION="decisión"
VALID_MEDICION="medición"
VALID_OTRO="otro"

n_plan=0; n_decision=0; n_medicion=0; n_otro=0; n_invalid=0; total=0
INVALID_ROWS=""

OLDIFS="$IFS"; IFS='
'
for line in $(grep -E '^\| E[0-9]+ \|' "$LEDGER" 2>/dev/null); do
  total=$((total+1))
  # Clase es el campo 6 al partir por '|': "" E1 fecha ciclo evento CLASE retro-ref ""
  clase="$(printf '%s' "$line" | awk -F'|' '{print $6}')"
  clase="$(printf '%s' "$clase" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  case "$clase" in
    "$VALID_PLAN")     n_plan=$((n_plan+1)) ;;
    "$VALID_DECISION") n_decision=$((n_decision+1)) ;;
    "$VALID_MEDICION") n_medicion=$((n_medicion+1)) ;;
    "$VALID_OTRO")     n_otro=$((n_otro+1)) ;;
    *)
      n_invalid=$((n_invalid+1))
      id="$(printf '%s' "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      INVALID_ROWS="$INVALID_ROWS $id(clase='$clase')"
      ;;
  esac
done
IFS="$OLDIFS"

printf 'TOTAL %d\n' "$total"
printf '  plan       %d\n' "$n_plan"
printf '  decisión   %d\n' "$n_decision"
printf '  medición   %d\n' "$n_medicion"
printf '  otro       %d\n' "$n_otro"

if [ "$n_invalid" -gt 0 ]; then
  printf 'INVALIDA %d fila(s) sin Clase reconocida:%s\n' "$n_invalid" "$INVALID_ROWS"
  exit 3
fi

exit 0
