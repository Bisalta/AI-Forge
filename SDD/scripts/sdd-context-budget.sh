#!/usr/bin/env bash
# sdd-context-budget.sh — cuánto contexto ESTÁTICO carga cada rol del ciclo SDD.
#
# Contesta una sola pregunta: qué archivos del plugin entran en el contexto de un
# rol y cuánto pesan. Es el insumo de la palanca B del diseño de consumo
# (docs/specs/2026-08-25-consumption-optimization-design.md).
#
# Uso:   sdd-context-budget.sh <planner|implementing|reviewer> [repo-root]
# Exit:  0 = ok · 2 = rol desconocido · 3 = no encuentro el plugin
#
# LO QUE MIDE Y LO QUE NO — leerlo antes de citar una cifra de acá:
#  · Mide el contexto ESTÁTICO: los archivos que el rol carga por su definición.
#  · NO mide el contexto acumulado (contract, briefs, diffs, evidencia, retornos
#    de agente), que en un ciclo real es la mayor parte.
#  · NO mide TURNOS. El costo es Σ(contexto × turnos) y este script sólo da el
#    primer factor. Una cifra de acá NO se convierte en dólares sin el segundo.
#  · Los tokens son APROXIMADOS: bytes / 3.6. No hay tokenizador en este repo y
#    agregarlo sería una dependencia nueva (security.md §4). La aproximación
#    sirve para COMPARAR archivos entre sí, no para facturar.
#
# La lista de archivos por rol no es inventada: sale de grepear las referencias a
# `standards/` en los artefactos de cada rol (commands/, skills/, agents/).

set -uo pipefail

VERSION="0.1.0"
[ "${1:-}" = "--version" ] && { echo "sdd-context-budget $VERSION"; exit 0; }

DIVISOR="3.6"
ROLES="planner implementing reviewer"

ROLE="${1:-}"
ROOT="${2:-.}"
PLUGIN="$ROOT/plugins/sdd-flow"

usage() {
  printf 'uso: sdd-context-budget.sh <rol> [repo-root]\n' >&2
  printf 'roles válidos: %s\n' "$ROLES" >&2
}

case " $ROLES " in
  *" ${ROLE:-__vacio__} "*) : ;;
  *)
    printf 'ERROR: rol desconocido: %s\n' "${ROLE:-<vacío>}" >&2
    usage
    exit 2
    ;;
esac

[ -d "$PLUGIN" ] || { printf 'ERROR: no encuentro %s\n' "$PLUGIN" >&2; exit 3; }

# --- qué carga cada rol (derivado de las referencias reales del plugin) ---
case "$ROLE" in
  planner)
    FILES="commands/sdd.md
skills/sdd-plan/SKILL.md
skills/enrich-user-story/SKILL.md
standards/quality-gates.md
standards/archetypes.md
standards/concerns.md
standards/security.md
standards/orchestration.md
standards/base-standards.md"
    ;;
  implementing)
    FILES="agents/implementing-agent.md
standards/quality-gates.md
standards/base-standards.md
standards/security.md
standards/orchestration.md"
    ;;
  reviewer)
    FILES="agents/reviewer-agent.md
standards/quality-gates.md
standards/security.md
standards/concerns.md
standards/orchestration.md"
    ;;
esac

printf '# sdd-context-budget %s — contexto ESTÁTICO del rol `%s`\n' "$VERSION" "$ROLE"
printf '#\n'
printf '# Los tokens son APROXIMADOS: bytes / %s. No hay tokenizador en este repo;\n' "$DIVISOR"
printf '# la cifra sirve para comparar archivos entre sí, no para facturar.\n'
printf '# Mide contexto estático. NO mide contexto acumulado ni turnos, y el costo\n'
printf '# real es la suma del contexto por los turnos que vive.\n'
printf '#\n'
printf '# %10s  %8s  %s\n' "BYTES" "~TOKENS" "ARCHIVO"

TOTAL_BYTES=0
MISSING=0
OLDIFS="$IFS"; IFS='
'
for f in $FILES; do
  path="$PLUGIN/$f"
  if [ -f "$path" ]; then
    b="$(wc -c < "$path" | tr -d ' ')"
  else
    b=0
    MISSING=$((MISSING+1))
  fi
  t="$(awk -v b="$b" -v d="$DIVISOR" 'BEGIN{printf "%d", b/d}')"
  if [ "$b" -eq 0 ]; then
    printf '  %10s  %8s  %s   [AUSENTE]\n' "$b" "$t" "$f"
  else
    printf '  %10s  %8s  %s\n' "$b" "$t" "$f"
  fi
  TOTAL_BYTES=$((TOTAL_BYTES + b))
done
IFS="$OLDIFS"

TOTAL_TOK="$(awk -v b="$TOTAL_BYTES" -v d="$DIVISOR" 'BEGIN{printf "%d", b/d}')"
printf 'TOTAL %10s  %8s  %s archivo(s)\n' "$TOTAL_BYTES" "$TOTAL_TOK" "$(printf '%s\n' "$FILES" | grep -c .)"
[ "$MISSING" -gt 0 ] && printf '# AVISO: %s archivo(s) del rol no existen y cuentan 0 — la cifra está incompleta.\n' "$MISSING"

exit 0
