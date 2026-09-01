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

VERSION="0.11.0"
[ "${1:-}" = "--version" ] && { echo "sdd-check $VERSION"; exit 0; }

command -v git >/dev/null 2>&1 || { echo "WARN	-	env	git no disponible — chequeo omitido"; exit 0; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "WARN	-	env	no es un repo git — chequeo omitido"; exit 0; }

# --- auto-exclusión (SDD/debt.md D11): a sí mismo, nada más ----------------
# Las reglas de abajo deben nombrar los literales que buscan (@ts-ignore,
# eslint-disable, --no-verify, @Disabled...), así que este mismo archivo los
# contiene. Sin exclusión, cualquier repo que reciba sdd-check.sh recién
# copiado (`/sdd-init`) arranca con el primer commit en rojo permanente
# contra sí mismo. Precedente aceptado del repo: SDD/tests/secret-scan.sh
# excluye únicamente su propio path absoluto, nunca un directorio o
# categoría de archivo (excluir de más ciega el chequeo — SDD/debt.md D6).
SELF_REL=""
SELF_ABS="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"
REPO_TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
if [ -n "$REPO_TOPLEVEL" ]; then
  case "$SELF_ABS" in
    "$REPO_TOPLEVEL"/*) SELF_REL="${SELF_ABS#"$REPO_TOPLEVEL"/}" ;;
  esac
fi

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

printf '%s\n' "$DIFF" | awk -v self="$SELF_REL" '
  BEGIN { blockers = 0; file = "-" }

  /^\+\+\+ b\// { file = substr($0, 7); next }
  /^\+\+\+ \/dev\/null/ { file = "-"; next }

  function is_self() { return self != "" && file == self }

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
    if (is_self()) next
    line = substr($0, 2)
    padded = " " line " "

    # tests skipeados / desactivados
    # Mismo guard de `.md` que la regla de supresores y la del flag de bypass
    # (contract R4/AC42, ampliado en v8): la prosa normativa que ENUMERA lo
    # prohibido no skipea ningún test. Medido: 2 falsos positivos sobre
    # standards/quality-gates.md §6.1 y templates/doc_quality_gates.md.
    if (file !~ /\.md$/ && padded ~ /(\.skip *\(|[^A-Za-z0-9_](xit|xdescribe|xtest) *\(|(test|it)\.todo *\(|@Disabled|[^A-Za-z0-9_]@Ignore[^A-Za-z0-9_]|#\[ignore\]|pytest\.mark\.skip|unittest\.skip)/)
      report("BLOCKER", "test-skipeado", line)

    # supresores de linter / type-checker
    # El guard de `.md` es el mismo que la regla de abajo ya tenía (contract
    # R4/AC42): la prosa normativa que ENUMERA los supresores prohibidos no es
    # un supresor. Sin él, este script levanta un BLOCKER sobre los documentos
    # del propio plugin y entrena al equipo a ignorarlo.
    if (file !~ /\.md$/ && line ~ /(@ts-ignore|@ts-expect-error|eslint-disable|# *type: *ignore|# *noqa|\/\/ *nolint|@SuppressWarnings|# *rubocop:disable)/)
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
    if (is_self()) next
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
#
# Mismo guard `.md` que las tres reglas built-in de arriba, y misma
# auto-exclusión: sin esto, un reporte de evidencia commiteado (quality-gates.md
# §5) que CITA el literal de un patrón custom como parte de lo que encontró
# se vuelve una violación nueva para la próxima corrida — y como los reportes
# se acumulan (R1, R2, R3...) sin sobreescribirse, el falso positivo sólo
# crece. Medido en Bisalta/WMS-Back, ciclo WMS-34.
#
# Segunda auto-exclusión, misma clase que D11 un nivel más abajo: el propio
# PATTERNS_FILE declara el ERE como texto plano, así que por construcción
# contiene el literal que busca — freante agregado (nueva regla, repo nuevo),
# se marca a sí mismo igual que sdd-check.sh se marcaba antes de este fix.
PATTERNS_FILE="${SDD_CHECK_PATTERNS:-SDD/scripts/sdd-check.patterns}"
PATTERNS_REL="$PATTERNS_FILE"
case "$PATTERNS_FILE" in
  /*) [ -n "$REPO_TOPLEVEL" ] && case "$PATTERNS_FILE" in
        "$REPO_TOPLEVEL"/*) PATTERNS_REL="${PATTERNS_FILE#"$REPO_TOPLEVEL"/}" ;;
      esac ;;
esac
if [ -f "$PATTERNS_FILE" ]; then
  while IFS=$'\t' read -r sev rule ere; do
    case "$sev" in BLOCKER|WARN) ;; *) continue ;; esac
    [ -n "$ere" ] || continue
    HITS="$(printf '%s\n' "$DIFF" | awk -F'\t' -v ere="$ere" -v self="$SELF_REL" -v pself="$PATTERNS_REL" '
      /^\+\+\+ b\// { file = substr($0, 7); next }
      /^\+/ && !/^\+\+\+/ {
        if (file ~ /\.md$/) next
        if (self != "" && file == self) next
        if (pself != "" && file == pself) next
        line = substr($0, 2); if (line ~ ere) { gsub(/\t/," ",line); if (length(line)>160) line=substr(line,1,157)"..."; printf "%s\t%s\n", file, line }
      }
    ')"
    if [ -n "$HITS" ]; then
      printf '%s\n' "$HITS" | while IFS=$'\t' read -r f l; do printf '%s\t%s\t%s\t%s\n' "$sev" "$f" "$rule" "$l"; done
      [ "$sev" = "BLOCKER" ] && RC=2
    fi
  done < "$PATTERNS_FILE"
fi

exit "$RC"
