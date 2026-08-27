#!/usr/bin/env bash
# sdd-flow — linter de closure del contract (standards/quality-gates.md, closure rules).
#
# Tres chequeos determinísticos sobre un HLTC/contract:
#  1. Frases prohibidas por las closure rules ("if needed", "prefer", "por definir"...)
#     — si dos ingenieros lo implementarían distinto, el contract es inválido.
#  2. Artifact inventory: cada path citado en backticks existe en el repo, o la
#     línea lo marca como nuevo (NEW / nuevo / a crear). Un contract que cita
#     símbolos inexistentes fue alucinado, no derivado.
#  3. Secciones obligatorias presentes: la lista es cerrada y enumerativa, con dos
#     ámbitos — contract (Objective, Out of scope, Threat model, bloque `concerns:`)
#     y requerimiento (Architectural Delta, Acceptance criteria, Checklist del
#     arquetipo). Un requerimiento es un bloque que abre con `# R<dígitos>` en H1;
#     sin ninguno, el documento entero cuenta como un requerimiento único.
#     Motivo: en GEN-94 un contract sin threat model se auto-aprobó y el defecto
#     costó una ronda entera de review (SDD/retro.md RT1). El chequeo es de
#     PRESENCIA, no de contenido: un `N/A` declarado cuenta como presente —
#     validar que el N/A sea legítimo es trabajo del reviewer.
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

VERSION="0.12.0"
[ "${1:-}" = "--version" ] && { echo "sdd-lint-contract $VERSION"; exit 0; }

CONTRACT="${1:-}"
ROOT="${2:-.}"
[ -n "$CONTRACT" ] && [ -f "$CONTRACT" ] || { echo "uso: sdd-lint-contract.sh <contract.md> [repo-root]" >&2; exit 3; }

BLOCKERS=0
WARNS=0

# Frases prohibidas (ES + EN), case-insensitive, con boundaries donde importa.
BANNED='if needed|if applicable|if necessary|when available|if present|may be|might be|to be defined|to be decided|tbd|or equivalent|or similar|as appropriate|por definir|a definir|si aplica|si es necesario|de ser necesario|si hace falta|según convenga|cuando esté disponible|podría ser|preferentemente|o equivalente|o similar|se verá|a confirmar'

# --- chequeo 3: acumuladores (la presencia es propiedad del archivo, no de una línea) ---
TAB="$(printf '\t')"
SECTIONS_CONTRACT="Objective
Out of scope
Threat model"
SECTIONS_REQ="Architectural Delta
Acceptance criteria
Checklist del arquetipo"
RECORDS=""
REQ_IDS=""
CUR_REQ="__contract__"
HAS_CONCERNS=0

in_code=0
lineno=0
while IFS= read -r line; do
  lineno=$((lineno+1))
  # La declaración de concerns vive DENTRO de una cerca de código cuando sale de
  # enrich-user-story (`concerns:` YAML), así que se busca antes del filtro de
  # cercas. Pero un contract escrito a mano la declara en prosa —
  # `**Concerns** (standards/concerns.md): security blocking...` es la forma del
  # contract de GEN-94. Las dos son válidas: el chequeo es de PRESENCIA de la
  # declaración, no de su sintaxis. Aceptar sólo la forma YAML ponía en rojo un
  # contract válido, que es el defecto de SDD/debt.md D10/D11 (un checker que se
  # marca solo entrena a ignorar el exit 2).
  trimmed="${line#"${line%%[![:space:]]*}"}"
  _c="$trimmed"
  while :; do
    case "$_c" in
      ' '*|'-'*|'#'*|'*'*|'|'*|'>'*) _c="${_c#?}" ;;
      *) break ;;
    esac
  done
  case "$_c" in
    [Cc]oncerns|[Cc]oncerns:*|[Cc]oncerns'*'*|[Cc]oncerns' '*) HAS_CONCERNS=1 ;;
  esac

  case "$line" in '```'*) in_code=$((1-in_code)); continue ;; esac
  [ "$in_code" = 1 ] && continue

  # Encabezados: sólo FUERA de cercas — si contaran adentro, un contract podría
  # declarar una sección obligatoria dentro de un ejemplo y pasar el chequeo.
  case "$line" in
    '#'*)
      _hashes=""; _rest="$line"
      while [ "${_rest#\#}" != "$_rest" ]; do _hashes="$_hashes#"; _rest="${_rest#\#}"; done
      _text="${_rest#"${_rest%%[![:space:]]*}"}"
      if [ "${#_hashes}" -eq 1 ]; then
        case "$_text" in
          R[0-9]*)
            CUR_REQ="${_text%%[![:alnum:]]*}"
            REQ_IDS="$REQ_IDS $CUR_REQ"
            ;;
        esac
      fi
      RECORDS="$RECORDS
${CUR_REQ}${TAB}${_text}"
      ;;
  esac
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

# --- chequeo 3: veredicto ---
# Ubicado acá por la condición que debe valer al ejecutarse: el archivo entero ya
# fue leído y BLOCKERS todavía no se consultó. No por qué bloque tiene al lado
# (SDD/retro.md RT9).
_seen() { # _seen <scope> <sección>  → 0 si está presente (match por prefijo, case-insensitive)
  printf '%s\n' "$RECORDS" | grep -qi "^$1${TAB}$2"
}
_falta() {
  printf 'BLOCKER\t0\tseccion-ausente\t%s\n' "$1"
  BLOCKERS=$((BLOCKERS+1))
}

OLDIFS="$IFS"
IFS='
'
for sec in $SECTIONS_CONTRACT; do
  _seen '__contract__' "$sec" || _falta "$sec"
done
if [ -z "$REQ_IDS" ]; then
  # Sin bloques `# R<n>`: el documento entero es un requerimiento único.
  for sec in $SECTIONS_REQ; do
    _seen '__contract__' "$sec" || _falta "$sec"
  done
else
  for rid in $(printf '%s' "$REQ_IDS" | tr ' ' '\n' | grep -v '^$'); do
    for sec in $SECTIONS_REQ; do
      _seen "$rid" "$sec" || _falta "$rid: $sec"
    done
  done
fi
IFS="$OLDIFS"

[ "$HAS_CONCERNS" -eq 0 ] && _falta 'concerns:'

[ "$BLOCKERS" -gt 0 ] && exit 2
exit 0
