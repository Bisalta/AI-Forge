#!/usr/bin/env bash
# sdd-flow — runner de la escalera de gates (standards/quality-gates.md §4).
#
# Lee la tabla "Escalera de gates" de SDD/docs/doc_quality_gates.md, corre cada
# comando EN ORDEN y EMITE el reporte de evidencia él mismo: comando, exit code,
# timestamp UTC y las últimas líneas de output por gate. La evidencia deja de
# ser algo que un modelo declara y pasa a ser algo que este script produce.
#
# Uso:
#   sdd-run-gates.sh [-d SDD/docs/doc_quality_gates.md] [-o reporte.md] [--keep-going] [--full]
#
#   -d            doc de gates (default: SDD/docs/doc_quality_gates.md)
#   -o            archivo del reporte (default: .sdd/gates-run.md; se sobreescribe)
#   --keep-going  no cortar al primer rojo (default: corta, regla de la escalera)
#   --full        además de la escalera, correr la "Suite completa" declarada
#
# Salida por stdout: el reporte + una última línea JSON parseable:
#   {"type":"sdd.gates","green":N,"red":N,"skipped":N,"report":"<path>"}
# Exit: 0 = todo verde · 1 = hubo rojo · 3 = no pude leer/parsear el doc de gates
#
# Env: SDD_GATE_TIMEOUT (segundos por gate, default 1800, requiere `timeout`).
#
# Qué NO hace: no decide qué gates aplican (eso lo declara el doc — fila sin
# comando o con N/A se reporta [SKIPPED]), no arregla nada, no reintenta.

set -uo pipefail

VERSION="0.10.0"
DOC="SDD/docs/doc_quality_gates.md"
OUT=".sdd/gates-run.md"
KEEP_GOING=0
RUN_FULL=0
TIMEOUT_S="${SDD_GATE_TIMEOUT:-1800}"

while [ $# -gt 0 ]; do
  case "$1" in
    -d) DOC="$2"; shift 2 ;;
    -o) OUT="$2"; shift 2 ;;
    --keep-going) KEEP_GOING=1; shift ;;
    --full) RUN_FULL=1; shift ;;
    --version) echo "sdd-run-gates $VERSION"; exit 0 ;;
    *) echo "arg desconocido: $1" >&2; exit 3 ;;
  esac
done

[ -f "$DOC" ] || { echo "ERROR: no existe $DOC — corré /sdd-init para generarlo (no inventes comandos)" >&2; exit 3; }

# --- parsear la tabla: | # | Gate | Comando | Obligatorio | Notas | -----------
# Filas de datos: empiezan con "| <num> |". Comando = 3ra celda, entre backticks.
GATES_TSV="$(awk -F'|' '
  /^\| *[0-9]+ *\|/ {
    num=$2; gate=$3; cmd=$4
    gsub(/^ +| +$/, "", num); gsub(/^ +| +$/, "", gate); gsub(/^ +| +$/, "", cmd)
    # extraer contenido entre backticks si los hay
    if (match(cmd, /`[^`]+`/)) cmd = substr(cmd, RSTART+1, RLENGTH-2)
    printf "%s\t%s\t%s\n", num, gate, cmd
  }' "$DOC")"

[ -n "$GATES_TSV" ] || { echo "ERROR: no encontré filas de gates en $DOC (formato: | N | gate | \`cmd\` | ...)" >&2; exit 3; }

FULL_CMD=""
if [ "$RUN_FULL" = 1 ]; then
  FULL_CMD="$(grep -m1 -i 'suite completa' "$DOC" | grep -oE '`[^`]+`' | head -1 | tr -d '\`')"
fi

mkdir -p "$(dirname "$OUT")" 2>/dev/null || true

now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
run_cmd() { # respeta timeout si existe
  if command -v timeout >/dev/null 2>&1; then timeout "$TIMEOUT_S" bash -c "$1"; else bash -c "$1"; fi
}

GREEN=0; RED=0; SKIPPED=0; STOPPED=""
ROWS=""; DETAILS=""

run_gate() { # $1=num $2=nombre $3=cmd
  local num="$1" gate="$2" cmd="$3" ts ec tail_out tmp
  # sin comando corrible → SKIPPED con razón (el doc manda)
  if [ -z "$cmd" ] || printf '%s' "$cmd" | grep -qiE '^(n/?a|—|-|\[PLACEHOLDER\])' || printf '%s' "$cmd" | grep -q 'PLACEHOLDER'; then
    ROWS="${ROWS}| ${num} | ${gate} | — | — | $(now) | [SKIPPED] sin comando en el doc (${cmd:-vacío}) |\n"
    SKIPPED=$((SKIPPED+1)); return 0
  fi
  ts="$(now)"
  tmp="$(mktemp)"
  run_cmd "$cmd" >"$tmp" 2>&1; ec=$?
  tail_out="$(tail -n 15 "$tmp")"; rm -f "$tmp"
  if [ "$ec" -eq 0 ]; then
    ROWS="${ROWS}| ${num} | ${gate} | \`${cmd}\` | 0 | ${ts} | verde |\n"; GREEN=$((GREEN+1))
  else
    ROWS="${ROWS}| ${num} | ${gate} | \`${cmd}\` | ${ec} | ${ts} | **rojo** |\n"; RED=$((RED+1))
  fi
  DETAILS="${DETAILS}### Gate ${num} — ${gate} (exit ${ec})\n\n\`\`\`\n${tail_out}\n\`\`\`\n\n"
  return "$ec"
}

while IFS=$'\t' read -r num gate cmd; do
  if ! run_gate "$num" "$gate" "$cmd"; then
    if [ "$KEEP_GOING" = 0 ]; then STOPPED="escalera cortada en el gate ${num} (${gate}) — regla: se arregla y se reinicia desde ese escalón"; break; fi
  fi
done <<< "$GATES_TSV"

if [ -n "$FULL_CMD" ] && [ "$RED" -eq 0 ]; then
  run_gate "—" "suite completa" "$FULL_CMD" || true
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"

{
  printf '# Gates run — generado por sdd-run-gates.sh v%s\n\n' "$VERSION"
  printf -- '- **Branch**: `%s` · **Commit**: `%s` · **Doc**: `%s` · **Fecha**: %s\n' "$BRANCH" "$COMMIT" "$DOC" "$(now)"
  printf -- '- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.\n\n'
  printf '| # | Gate | Comando | Exit | Timestamp UTC | Resultado |\n|---|---|---|---|---|---|\n'
  printf '%b' "$ROWS"
  [ -n "$STOPPED" ] && printf '\n> ⛔ %s\n' "$STOPPED"
  printf '\n## Output por gate (últimas 15 líneas)\n\n'
  printf '%b' "$DETAILS"
} > "$OUT"

cat "$OUT"
printf '\n{"type":"sdd.gates","green":%d,"red":%d,"skipped":%d,"report":"%s"}\n' "$GREEN" "$RED" "$SKIPPED" "$OUT"
[ "$RED" -eq 0 ] && exit 0 || exit 1
