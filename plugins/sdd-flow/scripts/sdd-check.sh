#!/usr/bin/env bash
# sdd-flow — chequeo mecánico del diff (Fase 1 del review, standards/quality-gates.md §7.1).
#
# Busca en el diff las mitigaciones prohibidas que son detectables sin criterio:
# tests skipeados, supresores de linter/type-checker, `any` nuevo, tests eliminados,
# ablandamiento de configs de test/lint/coverage. Determinístico: ni alucina ni se cansa.
#
# Uso:   sdd-check.sh [base-ref]        (default: merge-base con la rama default del repo)
# Salida: una línea por hallazgo:  SEVERIDAD<TAB>archivo<TAB>regla<TAB>extracto
# Exit:  0 = limpio o solo WARN · 2 = hay BLOCKER · (errores de entorno => 0, fail-open)
#
# Un BLOCKER acá es un candidato: el reviewer confirma contra el contract (un skip
# puede ser legítimo si el contract declara el cambio de comportamiento). Lo que este
# script NO puede juzgar, no lo juzga — solo lo pone sobre la mesa.

set -uo pipefail

VERSION="0.10.0"
[ "${1:-}" = "--version" ] && { echo "sdd-check $VERSION"; exit 0; }

command -v git >/dev/null 2>&1 || { echo "WARN	-	env	git no disponible — chequeo omitido"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "WARN	-	env	no es un repo git — chequeo omitido"; exit 0; }

BASE="${1:-}"
if [ -z "$BASE" ]; then
  DEFAULT_BRANCH="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
  [ -n "$DEFAULT_BRANCH" ] || DEFAULT_BRANCH="$(git rev-parse --verify --quiet main >/dev/null 2>&1 && echo main || echo master)"
  BASE="$(git merge-base HEAD "$DEFAULT_BRANCH" 2>/dev/null || echo "")"
fi
[ -n "$BASE" ] || { echo "WARN	-	env	no pude resolver la base del diff — pasala como argumento"; exit 0; }

# Diff base -> working tree (incluye lo commiteado y lo sucio). -U0: solo líneas cambiadas.
DIFF="$(git diff -U0 "$BASE" -- . 2>/dev/null)" || { echo "WARN	-	env	git diff falló contra '$BASE'"; exit 0; }
[ -n "$DIFF" ] || { exit 0; }

printf '%s\n' "$DIFF" | awk '
  BEGIN { blockers = 0; file = "-" }

  /^\+\+\+ b\// { file = substr($0, 7); next }
  /^\+\+\+ \/dev\/null/ { file = "-"; next }

  function report(sev, rule, line) {
    gsub(/\t/, " ", line)
    if (length(line) > 160) line = substr(line, 1, 157) "..."
    printf "%s\t%s\t%s\t%s\n", sev, file, rule, line
    if (sev == "BLOCKER") blockers++
  }

  function is_test_file()   { return file ~ /(\.spec\.|\.test\.|_test\.|__tests__\/|\/tests?\/)/ }
  function is_config_file() { return file ~ /(jest|vitest|playwright|cypress|eslint|tsconfig|pytest\.ini|setup\.cfg|pyproject\.toml|\.coveragerc|codecov|sonar)/ }

  # ---- líneas AGREGADAS ----
  # Nota: awk POSIX no soporta \b — se usa `padded` (línea con espacios en los
  # bordes) y [^A-Za-z0-9_] como boundary explícito.
  /^\+/ && !/^\+\+\+/ {
    line = substr($0, 2)
    padded = " " line " "

    # tests skipeados / desactivados
    if (padded ~ /(\.skip *\(|[^A-Za-z0-9_](xit|xdescribe|xtest) *\(|(test|it)\.todo *\(|@Disabled|[^A-Za-z0-9_]@Ignore[^A-Za-z0-9_]|#\[ignore\]|pytest\.mark\.skip|unittest\.skip)/)
      report("BLOCKER", "test-skipeado", line)

    # supresores de linter / type-checker
    if (line ~ /(@ts-ignore|@ts-expect-error|eslint-disable|# *type: *ignore|# *noqa|\/\/ *nolint|@SuppressWarnings|# *rubocop:disable)/)
      report("BLOCKER", "supresor", line)

    # any nuevo en TypeScript
    if (file ~ /\.tsx?$/ && line !~ /^[ \t]*(\/\/|\*)/ && padded ~ /(: *any[^A-Za-z0-9_]|[^A-Za-z0-9_]as +any[^A-Za-z0-9_]|<any>|[^A-Za-z0-9_]any\[\])/)
      report("BLOCKER", "any-nuevo", line)

    # bypass de hooks/CI en scripts o config
    if (file !~ /\.md$/ && padded ~ /--no-verify[^A-Za-z0-9_-]/)
      report("BLOCKER", "no-verify", line)

    # ablandamiento de config de tests/lint/coverage
    if (is_config_file() && tolower(line) ~ /(ignore|exclude|threshold|skiplibcheck|omit *=)/)
      report("WARN", "config-ablandada", line)

    # catch silencioso (best-effort, una línea)
    if (line ~ /catch[^{]*\{ *\}/ || padded ~ /except[^:]*: *pass[^A-Za-z0-9_]/)
      report("WARN", "catch-silencioso", line)
  }

  # ---- líneas ELIMINADAS en archivos de test ----
  /^-/ && !/^---/ {
    line = substr($0, 2)
    padded = " " line " "
    if (is_test_file() && padded ~ /[^A-Za-z0-9_.](it|test|describe) *\(/)
      report("WARN", "test-eliminado", line)
    else if (is_test_file() && padded ~ /[^A-Za-z0-9_.](expect|assert)[^A-Za-z0-9_]/)
      report("WARN", "assert-eliminado", line)
  }

  END { exit (blockers > 0 ? 2 : 0) }
'
RC=$?

# --- patrones extra del repo (markers prohibidos del stack) --------------------
# Archivo: SDD/scripts/sdd-check.patterns (o SDD_CHECK_PATTERNS). Una regla por
# línea: SEVERIDAD<TAB>nombre-regla<TAB>ERE — se aplica a las líneas AGREGADAS
# del diff. Así doc_quality_gates.md §"Markers prohibidos" deja de ser prosa.
PATTERNS_FILE="${SDD_CHECK_PATTERNS:-SDD/scripts/sdd-check.patterns}"
if [ -f "$PATTERNS_FILE" ]; then
  while IFS=$'\t' read -r sev rule ere; do
    case "$sev" in BLOCKER|WARN) ;; *) continue ;; esac
    [ -n "$ere" ] || continue
    HITS="$(printf '%s\n' "$DIFF" | awk -F'\t' -v ere="$ere" '
      /^\+\+\+ b\// { file = substr($0, 7); next }
      /^\+/ && !/^\+\+\+/ { line = substr($0, 2); if (line ~ ere) { gsub(/\t/," ",line); if (length(line)>160) line=substr(line,1,157)"..."; printf "%s\t%s\n", file, line } }
    ')"
    if [ -n "$HITS" ]; then
      printf '%s\n' "$HITS" | while IFS=$'\t' read -r f l; do printf '%s\t%s\t%s\t%s\n' "$sev" "$f" "$rule" "$l"; done
      [ "$sev" = "BLOCKER" ] && RC=2
    fi
  done < "$PATTERNS_FILE"
fi

exit "$RC"
