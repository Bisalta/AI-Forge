#!/usr/bin/env bash
# SDD/tests/secret-scan.sh — gate 9 (security) de SDD/docs/doc_quality_gates.md.
#
# Reuse: implementa el "grep mínimo" de plugins/sdd-flow/standards/security.md
# §3 (sin gitleaks/trufflehog instalados en la máquina de referencia — no se
# agrega una dependencia nueva de contrabando, standards/security.md §4).
# Semántica invertida a propósito respecto de un test normal: EXIT 0 = no
# encontró secretos, EXIT 1 = encontró al menos uno.
#
# Alcance: sólo los archivos VERSIONADOS (`git ls-files`) — no escanea
# SDD/tests/.tmp/ (gitignoreado) ni node_modules ni nada por el estilo.
#
# AC6bis (contract v2): el patrón cubre clave sin comillas, `SCREAMING_SNAKE`,
# y separador `:` además de `=` — la ronda 1 sólo detectaba clave en minúscula
# con valor entre comillas, y dejaba pasar cuatro de las cinco formas reales.
#
# Threat model (contract v2, punto 3): la salida nombra archivo y línea SIN
# imprimir el valor detectado — nunca se arma un `file:line:contenido` con la
# línea completa, así ningún artefacto de evidencia puede llegar a contener
# el secreto encontrado.
#
# Uso: bash SDD/tests/secret-scan.sh
# Exit: 0 = limpio · 1 = encontró posibles secretos (lista arriba, sin valor) ·
#       2 = error de entorno (sin git / no es repo git) — fail-CLOSED: sin
#       poder listar los archivos versionados no hay forma de garantizar
#       nada, así que se reporta como fallo, nunca como verde falso.

set -uo pipefail

command -v git >/dev/null 2>&1 || { echo "ERROR: git no disponible — no puedo listar archivos versionados" >&2; exit 2; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ERROR: no es un repo git" >&2; exit 2; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
SELF_ABS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# Patrones de standards/security.md §3, con dos precisiones sobre el original:
#
# 1. El de clave privada exige el cierre real "-----" del header PEM
#    (`-----BEGIN [...] PRIVATE KEY-----`), no sólo "PRIVATE KEY" suelto. Sin
#    el cierre, el propio texto que documenta este patrón en
#    standards/security.md (y en este mismo script) matchearía contra sí
#    mismo — falso positivo autorreferencial conocido de cualquier
#    secret-scanner que documenta su propio patrón como texto. Con el cierre
#    exigido, el patrón sigue detectando cualquier clave PEM real (el formato
#    SIEMPRE cierra el header con guiones) y dejar de matchear la prosa que
#    sólo lo menciona no reduce la detección real.
#
# 2. El de password/secret/token/api_key admite prefijo y sufijo de
#    identificador (`[A-Za-z0-9_]*` a cada lado de la palabra disparadora) y
#    valor CON o SIN comillas (`["']?`), case-insensitive (`-i` en el grep de
#    abajo). Ratificación v2 / AC6bis: la ronda 1 exigía comillas alrededor
#    del valor y sólo matcheaba la palabra exacta en minúscula, así que dejaba
#    pasar `api_key=sk_live_...` (sin comillas), `PASSWORD="..."` y
#    `AWS_SECRET_ACCESS_KEY=...`/`GITHUB_TOKEN: ...` (SCREAMING_SNAKE, la
#    palabra disparadora en el medio del identificador) — cuatro de las cinco
#    formas reales medidas en la ronda 1. El separador es `:` o `=`, con
#    espacio opcional a cada lado (cubre `GITHUB_TOKEN: valor`).
#
#    El valor sólo admite el charset real de un token/credencial
#    (`[A-Za-z0-9_./+=-]`, con o sin comillas) — NO backtick, NO `<`/`>`, NO
#    espacios. Medido en el propio repo: con una clase de valor "cualquier
#    cosa menos comilla/espacio" (más laxa), `plugins/sdd-flow/commands/
#    sdd-agents.md:12` ("Primer token: `<task-slug>`", un placeholder de
#    documentación entre backticks) matcheaba como si fuera un secreto real.
#    Un valor real de credencial nunca lleva backtick ni `<`/`>` adentro.
PATTERN="AKIA[0-9A-Z]{16}|-----BEGIN [A-Za-z ]*PRIVATE KEY-----|[A-Za-z0-9_]*(password|secret|token|api[_-]?key)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9_./+=-]{4,}[\"']?"

# Exclusiones por PATH, con razón (no un "ignorar para pasar" — ninguna es
# código productivo ni un secreto real, y las dos vienen del mismo problema
# autorreferencial que ya motivó la auto-exclusión del script de abajo):
#
# - SDD/contracts/: por diseño de este mismo contract (AC6bis es el ejemplo:
#   un AC de detección declara EN EL CONTRACT el valor literal que hay que
#   plantar para probarlo), un contract que describe un AC de detección de
#   secretos necesariamente cita las cinco formas completas como texto. Es
#   prosa que ESPECIFICA qué detectar, no un secreto embebido en config. No
#   se excluye SDD/briefs/ ni SDD/verification/: esos los escribe este mismo
#   agente, que puede (y debe) describir las formas sin re-citarlas literales.
EXCLUDE_PATH_PREFIXES="SDD/contracts/"

is_excluded_path() {
  local path="$1" prefix
  local old_ifs="$IFS"
  IFS=' '
  for prefix in $EXCLUDE_PATH_PREFIXES; do
    case "$path" in
      "$prefix"*) IFS="$old_ifs"; return 0 ;;
    esac
  done
  IFS="$old_ifs"
  return 1
}

FOUND=0
SCANNED=0
EXCLUDED=0
while IFS= read -r f; do
  [ -f "$REPO_ROOT/$f" ] || continue
  # Se excluye a sí mismo: el patrón de arriba queda escrito literalmente en
  # este archivo, así que grepearlo contra sí mismo es el mismo falso
  # positivo autorreferencial que motivó el cierre "-----" de arriba.
  if [ "$REPO_ROOT/$f" = "$SELF_ABS" ] || is_excluded_path "$f"; then
    EXCLUDED=$((EXCLUDED + 1))
    continue
  fi
  SCANNED=$((SCANNED + 1))
  # -i: case-insensitive (cubre SCREAMING_SNAKE, AC6bis). -o: sólo el span
  # matcheado (nunca la línea completa) -> a la salida sólo le llega el
  # número de línea (campo 1); el valor detectado (campo 2+) se descarta acá
  # mismo y nunca se imprime — threat model contract v2 punto 3.
  line_numbers="$(grep -iInEo "$PATTERN" "$REPO_ROOT/$f" 2>/dev/null | cut -d: -f1)"
  if [ -n "$line_numbers" ]; then
    printf '%s\n' "$line_numbers" | while IFS= read -r ln; do
      printf '%s:%s: posible secreto (standards/security.md §3) — valor no impreso\n' "$f" "$ln"
    done
    FOUND=1
  fi
done < <(git -C "$REPO_ROOT" ls-files)

if [ "$FOUND" -eq 1 ]; then
  echo "secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo" >&2
  exit 1
fi

echo "secret-scan: sin hallazgos sobre $SCANNED archivos versionados ($EXCLUDED excluidos: self + SDD/contracts/)"
exit 0
