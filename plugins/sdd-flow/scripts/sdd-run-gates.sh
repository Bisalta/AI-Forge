#!/usr/bin/env bash
# sdd-flow — runner de la escalera de gates (standards/quality-gates.md §4).
#
# Lee la tabla "Escalera de gates" de SDD/docs/doc_quality_gates.md, corre cada
# comando EN ORDEN y EMITE el reporte de evidencia él mismo: comando, exit code,
# timestamp UTC y las últimas líneas de output por gate. La evidencia deja de
# ser algo que un modelo declara y pasa a ser algo que este script produce.
#
# El reporte sella el HASH DEL ÁRBOL REALMENTE VERIFICADO (working tree +
# índice), no sólo el commit de HEAD: HEAD puede diferir del working tree en
# dos direcciones (cambios sin commitear al correr los gates, o commits
# posteriores a que el reporte se escribiera), y un reporte que sólo nombra
# HEAD se puede presentar como evidencia de un commit que no es el código que
# realmente corrió (contract R1, SDD/contracts/2026-08-13-sicop-hardening.md).
#
# Uso:
#   sdd-run-gates.sh [-d SDD/docs/doc_quality_gates.md] [-o reporte.md] [--keep-going] [--full] [--allow-dirty]
#
#   -d            doc de gates (default: SDD/docs/doc_quality_gates.md)
#   -o            archivo del reporte (default: .sdd/gates-run.md; se sobreescribe)
#   --keep-going  no cortar al primer rojo (default: corta, regla de la escalera)
#   --full        además de la escalera, correr la "Suite completa" declarada
#   --allow-dirty escribir evidencia con árbol sucio aunque -o apunte fuera de
#                 .sdd/ (evidencia que se commitea); el encabezado marca
#                 ARBOL SUCIO y lista los archivos sin commitear
#
# Salida por stdout: el reporte + una última línea JSON parseable:
#   {"type":"sdd.gates","green":N,"red":N,"skipped":N,"report":"<path>"}
# Exit: 0 = todo verde · 1 = hubo rojo · 3 = no pude leer/parsear el doc de
#       gates · 4 = árbol sucio y -o apunta fuera de .sdd/ sin --allow-dirty
#       (esa evidencia se commitea y exige árbol limpio; no se escribe nada)
#
# Env: SDD_GATE_TIMEOUT (segundos por gate, default 1800, requiere `timeout`).
#
# Sellado del árbol (además de Commit, siempre en el encabezado del reporte):
#   - árbol limpio  → Tree: hash de `git rev-parse HEAD^{tree}`.
#   - árbol sucio   → Tree: hash de `git stash create` (objeto que representa
#     working tree + índice, sin tocar la branch ni el stash log). NUNCA
#     `git write-tree` (descartado por el contract: sólo ve el índice, así
#     que un cambio sin `git add` no quedaría representado). Límite conocido
#     heredado de esa misma decisión: `git stash create` sólo ve contenido
#     que alguna vez pasó por `git add` — un archivo sin trackear nunca
#     queda representado en el hash, aunque `DIRTY_FILES` sí lo liste. Si
#     TODO el árbol sucio es sin trackear, no hay nada que stashear y Tree
#     cae a `-` en vez de reusar el hash de HEAD, que mentiría igual que el
#     bug que este sellado arregla.
#   - sin repo git  → Tree: `-`. El sellado NUNCA aborta la corrida por no
#     poder sellar: degrada y la escalera sigue (mismo criterio que el resto
#     del runner).
#
# Qué NO hace: no decide qué gates aplican (eso lo declara el doc — fila sin
# comando o con N/A se reporta [SKIPPED]), no arregla nada, no reintenta.

set -uo pipefail

VERSION="0.11.0"
DOC="SDD/docs/doc_quality_gates.md"
OUT=".sdd/gates-run.md"
KEEP_GOING=0
RUN_FULL=0
ALLOW_DIRTY=0
TIMEOUT_S="${SDD_GATE_TIMEOUT:-1800}"

while [ $# -gt 0 ]; do
  case "$1" in
    -d) DOC="$2"; shift 2 ;;
    -o) OUT="$2"; shift 2 ;;
    --keep-going) KEEP_GOING=1; shift ;;
    --full) RUN_FULL=1; shift ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    --version) echo "sdd-run-gates $VERSION"; exit 0 ;;
    *) echo "arg desconocido: $1" >&2; exit 3 ;;
  esac
done

[ -f "$DOC" ] || { echo "ERROR: no existe $DOC — corré /sdd-init para generarlo (no inventes comandos)" >&2; exit 3; }

# --- sellado: hash del árbol REALMENTE verificado, no sólo HEAD -----------
# HEAD identifica un commit; el working tree puede diferir de él en dos
# direcciones (cambios sin commitear ahora, o commits posteriores a que el
# reporte se escriba). Sellar sólo HEAD deja el reporte listo para mentir
# sobre qué código se corrió — bug medido en SICOP (contract R1). Se calcula
# ACÁ, antes de correr ningún gate, porque la estrictez de abajo puede
# cortar la corrida entera sin gastar tiempo en la escalera.
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo '-')"
TREE="-"
TREE_STATE="sin repo git"
DIRTY=0
DIRTY_FILES=""

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  DIRTY_FILES="$(git status --porcelain 2>/dev/null)"
  if [ -n "$DIRTY_FILES" ]; then
    DIRTY=1
    TREE_STATE="ARBOL SUCIO"
    # git stash create: objeto commit con working tree + índice, SIN tocar
    # la branch ni el stash log (a diferencia de `git stash push`) y sin
    # depender sólo del índice (a diferencia de `git write-tree`, que el
    # contract descarta: un cambio sin `git add` no quedaría representado).
    STASH_OBJ="$(git stash create 2>/dev/null)"
    if [ -n "$STASH_OBJ" ]; then
      TREE="$(git rev-parse "${STASH_OBJ}^{tree}" 2>/dev/null || echo '-')"
    fi
    # Límite conocido de `git stash create` (heredado de la decisión del
    # contract, no algo que este script pueda resolver sin `write-tree`):
    # SÓLO ve contenido trackeado (índice + working tree de archivos que ya
    # pasaron por `git add` alguna vez). Un archivo sin trackear nunca queda
    # representado en el hash de Tree, DIRTY_FILES sí lo lista igual —
    # aunque haya OTROS cambios trackeados que sí entran en el stash. Caso
    # límite: si TODO el árbol sucio es sin trackear, $STASH_OBJ queda vacío
    # (no hay nada trackeado que stashear) y Tree cae a "-" en vez de reusar
    # el hash de HEAD, que mentiría igual que el bug que este sellado
    # arregla.
  else
    TREE_STATE="LIMPIO"
    TREE="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || echo '-')"
  fi
fi

# La estrictez se deriva del destino del reporte, no de una bandera que hay
# que acordarse de pasar: -o dentro de .sdd/ es uso ad-hoc (nunca se
# commitea); -o fuera de .sdd/ es evidencia que sí se commitea y por eso
# exige árbol limpio, salvo escape hatch explícito (--allow-dirty).
UNDER_SDD_DIR=0
case "$OUT" in
  .sdd|.sdd/*|*/.sdd|*/.sdd/*) UNDER_SDD_DIR=1 ;;
esac

if [ "$DIRTY" = 1 ] && [ "$UNDER_SDD_DIR" = 0 ] && [ "$ALLOW_DIRTY" = 0 ]; then
  {
    printf 'ERROR: arbol sucio y -o "%s" queda fuera de .sdd/ — es evidencia que se commitea y exige arbol limpio.\n' "$OUT"
    printf 'Commiteá los cambios, o corré de nuevo con --allow-dirty. Archivos sin commitear:\n'
    printf '%s\n' "$DIRTY_FILES"
  } >&2
  exit 4
fi

# --- parsear la tabla: | # | Gate | Comando | Obligatorio | Notas | -----------
# Filas de datos: empiezan con "| <num> |". El comando vive entre backticks en la
# 3ra celda. Cuidado con dos trampas reales:
#  - un comando CON pipes (`cmd | grep x`) parte la celda al splitear por "|":
#    se recupera tomando el primer span `...` de la línea completa (el comando es
#    la primera celda backtickeada del template);
#  - una celda sin backticks (N/A, —, PLACEHOLDER) NO debe robar backticks de la
#    columna Notas: se pasa cruda y run_gate la trata como SKIPPED.
GATES_TSV="$(awk -F'|' '
  /^\| *[0-9]+ *\|/ {
    num=$2; gate=$3; cell=$4
    gsub(/^ +| +$/, "", num); gsub(/^ +| +$/, "", gate); gsub(/^ +| +$/, "", cell)
    cmd = cell
    if (cell ~ /^`.*`$/ && cell !~ /`.*`.*`/) {
      cmd = substr(cell, 2, length(cell) - 2)          # celda backtickeada completa
    } else if (cell ~ /^`/) {                          # cortada por un pipe interno
      if (match($0, /`[^`]+`/)) cmd = substr($0, RSTART+1, RLENGTH-2)
    }
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
NL=$'\n'

# Nota: nada de printf %b sobre contenido de comandos — un comando con backslashes
# (grep '\d', awk '\t') se manglaría en el reporte. Newlines reales, printf %s.
run_gate() { # $1=num $2=nombre $3=cmd
  local num="$1" gate="$2" cmd="$3" ts ec tail_out tmp
  # sin comando corrible → SKIPPED con razón (el doc manda)
  if [ -z "$cmd" ] || printf '%s' "$cmd" | grep -qiE '^(n/?a|—|-|\[PLACEHOLDER\])' || printf '%s' "$cmd" | grep -q 'PLACEHOLDER'; then
    ROWS="${ROWS}| ${num} | ${gate} | — | — | $(now) | [SKIPPED] sin comando en el doc (${cmd:-vacío}) |${NL}"
    SKIPPED=$((SKIPPED+1)); return 0
  fi
  ts="$(now)"
  tmp="$(mktemp)"
  run_cmd "$cmd" >"$tmp" 2>&1; ec=$?
  tail_out="$(tail -n 15 "$tmp")"; rm -f "$tmp"
  if [ "$ec" -eq 0 ]; then
    ROWS="${ROWS}| ${num} | ${gate} | \`${cmd}\` | 0 | ${ts} | verde |${NL}"; GREEN=$((GREEN+1))
  else
    ROWS="${ROWS}| ${num} | ${gate} | \`${cmd}\` | ${ec} | ${ts} | **rojo** |${NL}"; RED=$((RED+1))
  fi
  DETAILS="${DETAILS}### Gate ${num} — ${gate} (exit ${ec})${NL}${NL}\`\`\`${NL}${tail_out}${NL}\`\`\`${NL}${NL}"
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

{
  printf '# Gates run — generado por sdd-run-gates.sh v%s\n\n' "$VERSION"
  printf -- '- **Branch**: `%s` · **Commit**: `%s` · **Doc**: `%s` · **Fecha**: %s\n' "$BRANCH" "$COMMIT" "$DOC" "$(now)"
  if [ "$DIRTY" = 1 ]; then
    # shellcheck disable=SC2016  # backtick literal para markdown (mismo patron que Branch/Commit/Doc arriba), no es expansion querida
    printf -- '- Tree: `%s` — %s. Archivos sin commitear:\n' "$TREE" "$TREE_STATE"
    while IFS= read -r dirty_line; do
      # shellcheck disable=SC2016  # backtick literal para markdown, no es expansion querida
      printf '  - `%s`\n' "$dirty_line"
    done <<< "$DIRTY_FILES"
  else
    # shellcheck disable=SC2016  # backtick literal para markdown, no es expansion querida
    printf -- '- Tree: `%s` — %s\n' "$TREE" "$TREE_STATE"
  fi
  printf -- '- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.\n\n'
  printf '| # | Gate | Comando | Exit | Timestamp UTC | Resultado |\n|---|---|---|---|---|---|\n'
  printf '%s' "$ROWS"
  [ -n "$STOPPED" ] && printf '\n> ⛔ %s\n' "$STOPPED"
  printf '\n## Output por gate (últimas 15 líneas)\n\n'
  printf '%s' "$DETAILS"
} > "$OUT"

cat "$OUT"
printf '\n{"type":"sdd.gates","green":%d,"red":%d,"skipped":%d,"report":"%s"}\n' "$GREEN" "$RED" "$SKIPPED" "$OUT"
[ "$RED" -eq 0 ] && exit 0 || exit 1
