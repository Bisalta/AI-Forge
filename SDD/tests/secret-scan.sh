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
# Uso: bash SDD/tests/secret-scan.sh
# Exit: 0 = limpio · 1 = encontró posibles secretos (lista arriba) ·
#       2 = error de entorno (sin git / no es repo git) — fail-CLOSED: sin
#       poder listar los archivos versionados no hay forma de garantizar
#       nada, así que se reporta como fallo, nunca como verde falso.

set -uo pipefail

command -v git >/dev/null 2>&1 || { echo "ERROR: git no disponible — no puedo listar archivos versionados" >&2; exit 2; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ERROR: no es un repo git" >&2; exit 2; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
SELF_ABS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# Patrones de standards/security.md §3, con una precisión sobre el original:
# el de clave privada exige el cierre real "-----" del header PEM
# (`-----BEGIN [...] PRIVATE KEY-----`), no sólo "PRIVATE KEY" suelto. Sin
# el cierre, el propio texto que documenta este patrón en standards/security.md
# (y en este mismo script) matchearía contra sí mismo — falso positivo
# conocido de cualquier secret-scanner que documenta su propio patrón como
# texto. Con el cierre exigido, el patrón sigue detectando cualquier clave
# PEM real (el formato SIEMPRE cierra el header con guiones) y dejar de
# matchear la prosa que sólo lo menciona no reduce la detección real.
PATTERN="AKIA[0-9A-Z]{16}|-----BEGIN [A-Za-z ]*PRIVATE KEY-----|(password|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'][^\"'[:space:]]{4,}[\"']"

FOUND=0
while IFS= read -r f; do
  [ -f "$REPO_ROOT/$f" ] || continue
  # Se excluye a sí mismo: el patrón de arriba queda escrito literalmente en
  # este archivo, así que grepearlo contra sí mismo es el mismo falso
  # positivo autorreferencial que motivó el cierre "-----" de arriba.
  [ "$REPO_ROOT/$f" = "$SELF_ABS" ] && continue
  hits="$(grep -InE "$PATTERN" "$REPO_ROOT/$f" 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    printf '%s\n' "$hits" | while IFS= read -r line; do
      printf '%s:%s\n' "$f" "$line"
    done
    FOUND=1
  fi
done < <(git -C "$REPO_ROOT" ls-files)

if [ "$FOUND" -eq 1 ]; then
  echo "secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo" >&2
  exit 1
fi

total="$(git -C "$REPO_ROOT" ls-files | wc -l | tr -d ' ')"
echo "secret-scan: sin hallazgos sobre $total archivos versionados"
exit 0
