#!/usr/bin/env bash
# usage-summary.sh — resumen de atribución desde un log local de OTel console.
#
# Convención propuesta por Esteban en #bisalta-context-sdd (2026-09-07),
# opción B (descentralizada) confirmada por Patrick el mismo día: cada
# persona guarda su propio log local y comparte un resumen cuando hace falta
# — NUNCA el log crudo (trae session.id, user.email, account_uuid,
# organization.id). Ubicación del archivo y detalle de env vars en
# plugins/usage-monitor/README.md.
#
# Uso: usage-summary.sh [archivo]
#   sin argumento: usa $CLAUDE_USAGE_LOG, o ~/.claude/usage-log/console.log
# Exit: 0 = ok · 2 = no encontré node o el archivo

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE="${1:-${CLAUDE_USAGE_LOG:-$HOME/.claude/usage-log/console.log}}"

command -v node >/dev/null 2>&1 || { echo "ERROR: node no disponible — hace falta para parsear el log" >&2; exit 2; }
[ -f "$FILE" ] || { echo "ERROR: no existe $FILE — ¿ya prendiste OTEL_METRICS_EXPORTER=console? (ver README.md)" >&2; exit 2; }

exec node "$SCRIPT_DIR/parse-usage-log.js" "$FILE"
