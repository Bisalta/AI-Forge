#!/usr/bin/env bash
# SDD/tests/test_run_gates_tree.sh — AC7 a AC12 del contract R1
# (SDD/contracts/2026-08-13-sicop-hardening.md): el runner sella el árbol
# REALMENTE verificado (working tree + índice), no sólo el commit de HEAD.
#
# Bug que esto reproduce: plugins/sdd-flow/scripts/sdd-run-gates.sh (v0.10.0)
# sólo estampa `**Commit**: <short-sha-de-HEAD>` en el encabezado del
# reporte. HEAD puede diferir del working tree que realmente corrió los
# gates (cambios sin commitear, o commits posteriores a que el reporte se
# escribiera) — medido tres veces en este mismo ciclo: los reportes de gates
# de R0 sellan el commit ANTERIOR al trabajo real (ver R1-runner-tree-seal.md).
#
# Corrida contra el script SIN el fix (T1.2 del brief): tiene que salir en
# rojo porque el encabezado no tiene "Tree:", no hay exit 4 con árbol sucio
# fuera de .sdd/, ni --allow-dirty, ni --version 0.11.0.
#
# Repos git temporales en SDD/tests/.tmp/ (AC7-AC11 necesitan un repo git de
# verdad: HEAD, índice y working tree reales). AC12 es la excepción: necesita
# un directorio que NO sea repo git, y SDD/tests/.tmp/ está DENTRO del repo
# ai-forge — cualquier subdirectorio ahí sigue siendo "inside work tree" para
# git (camina hacia arriba hasta encontrar el .git de ai-forge). Por eso el
# fixture de AC12 vive en un directorio de `mktemp -d` (fuera de cualquier
# repo), limpiado por el mismo trap.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_GATES="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-run-gates.sh"

TMP_BASE="$SCRIPT_DIR/.tmp/test_run_gates_tree-$$"
NONGIT_DIR=""

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() {
  rm -rf "$TMP_BASE"
  [ -n "$NONGIT_DIR" ] && rm -rf "$NONGIT_DIR"
  return 0
}
trap cleanup EXIT

if [ ! -f "$RUN_GATES" ]; then
  echo "  FAIL  setup — no existe $RUN_GATES"
  exit 1
fi

# fixture_gates_doc <dir> [gate2_cmd] — escalera mínima de dos gates en
# <dir>/SDD/docs/doc_quality_gates.md. gate2_cmd default "true" (verde);
# "false" fuerza un rojo (lo usa AC12 para probar que el exit code sigue
# reflejando el resultado de los gates, no el sellado).
fixture_gates_doc() {
  dir="$1"
  gate2="${2:-true}"
  mkdir -p "$dir/SDD/docs"
  cat > "$dir/SDD/docs/doc_quality_gates.md" <<EOF
# Escalera de gates — fixture de test_run_gates_tree.sh (repo temporal, nunca versionado)

| # | Gate | Comando | Obligatorio | Notas |
|---|---|---|---|---|
| 1 | unit tests | \`true\` | sí | fixture: siempre sale 0 |
| 2 | security | \`$gate2\` | sí | fixture |
EOF
}

# new_repo <dir> — repo git aislado con identidad local (nunca depende del
# git config del desarrollador) y un primer commit: doc_quality_gates.md +
# tracked.txt. Base para AC7/AC8/AC9/AC10.
new_repo() {
  dir="$1"
  mkdir -p "$dir"
  git init -q "$dir"
  ( cd "$dir" && git config user.email "test@example.com" && git config user.name "test" && git config commit.gpgsign false )
  fixture_gates_doc "$dir" "true"
  printf 'linea inicial\n' > "$dir/tracked.txt"
  ( cd "$dir" && git add -A && git commit -qm "init" )
}

# make_dirty <dir> — modifica tracked.txt SIN `git add` (unstaged): alcanza
# para que `git status --porcelain` lo marque sucio y `git stash create`
# pueda representarlo en un tree distinto al de HEAD (decisión del contract
# R1 — ver nota en plugins/sdd-flow/scripts/sdd-run-gates.sh).
make_dirty() {
  dir="$1"
  printf 'linea agregada sin commitear\n' >> "$dir/tracked.txt"
}

# =========================================================================
# AC7 — árbol limpio: Tree: <hash de HEAD^{tree}>, exit 0
# =========================================================================
AC7_DIR="$TMP_BASE/ac7"
new_repo "$AC7_DIR"
EXPECTED_TREE_AC7="$(cd "$AC7_DIR" && git rev-parse 'HEAD^{tree}')"

out7="$(cd "$AC7_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o .sdd/gates-run.md 2>&1)"
ec7=$?
assert_exit 0 "$ec7" "AC7 arbol limpio - sale 0"
assert_contains "$out7" "Tree:" "AC7 arbol limpio - encabezado tiene Tree:"
assert_contains "$out7" "$EXPECTED_TREE_AC7" "AC7 arbol limpio - Tree coincide con el hash de HEAD^{tree}"
[ -f "$AC7_DIR/.sdd/gates-run.md" ] && ac7_file="si" || ac7_file="no"
assert_eq "$ac7_file" "si" "AC7 arbol limpio - el reporte se escribe"

# =========================================================================
# AC8 — árbol sucio, -o DENTRO de .sdd/: se escribe, marca sucio, Tree
# difiere de HEAD^{tree}, sale 0
# =========================================================================
AC8_DIR="$TMP_BASE/ac8"
new_repo "$AC8_DIR"
CLEAN_TREE_AC8="$(cd "$AC8_DIR" && git rev-parse 'HEAD^{tree}')"
make_dirty "$AC8_DIR"
# `git stash create` no muta nada (ni branch ni stash log): correrlo desde
# el test para predecir el hash exacto que el runner va a derivar por su
# cuenta es seguro y determinístico (el tree sólo depende del contenido).
EXPECTED_DIRTY_TREE_AC8="$(cd "$AC8_DIR" && git rev-parse "$(git stash create)^{tree}")"

out8="$(cd "$AC8_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o .sdd/gates-run.md 2>&1)"
ec8=$?
assert_exit 0 "$ec8" "AC8 arbol sucio con -o dentro de .sdd - sale 0"
[ -f "$AC8_DIR/.sdd/gates-run.md" ] && ac8_file="si" || ac8_file="no"
assert_eq "$ac8_file" "si" "AC8 arbol sucio con -o dentro de .sdd - el reporte se escribe"
assert_contains "$out8" "ARBOL SUCIO" "AC8 arbol sucio con -o dentro de .sdd - encabezado marca el arbol sucio"
assert_contains "$out8" "$EXPECTED_DIRTY_TREE_AC8" "AC8 arbol sucio - Tree usa el hash de git stash create"
if [ "$EXPECTED_DIRTY_TREE_AC8" = "$CLEAN_TREE_AC8" ]; then ac8_trees_differ="no"; else ac8_trees_differ="si"; fi
assert_eq "$ac8_trees_differ" "si" "AC8 arbol sucio - Tree difiere del hash de HEAD^{tree} limpio"

# =========================================================================
# AC9 — árbol sucio, -o FUERA de .sdd/ (evidencia que se commitea), SIN
# --allow-dirty: no crea el archivo, sale 4. AC de detección — la corrida
# por mutación (verde->rojo->verde) queda registrada a mano en el
# verification report (mutar el runner, no este archivo de test).
# =========================================================================
AC9_DIR="$TMP_BASE/ac9"
new_repo "$AC9_DIR"
make_dirty "$AC9_DIR"

(cd "$AC9_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o SDD/verification/x-gates.md) >/dev/null 2>&1
ec9=$?
assert_exit 4 "$ec9" "AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - sale 4"
[ -f "$AC9_DIR/SDD/verification/x-gates.md" ] && ac9_file="si" || ac9_file="no"
assert_eq "$ac9_file" "no" "AC9 arbol sucio con -o fuera de .sdd sin allow-dirty - no crea el archivo"

# =========================================================================
# AC10 — árbol sucio, -o FUERA de .sdd/, CON --allow-dirty: crea el
# archivo, encabezado con ARBOL SUCIO, sale 0
# =========================================================================
AC10_DIR="$TMP_BASE/ac10"
new_repo "$AC10_DIR"
make_dirty "$AC10_DIR"

out10="$(cd "$AC10_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o SDD/verification/x-gates.md --allow-dirty 2>&1)"
ec10=$?
assert_exit 0 "$ec10" "AC10 arbol sucio con --allow-dirty - sale 0"
[ -f "$AC10_DIR/SDD/verification/x-gates.md" ] && ac10_file="si" || ac10_file="no"
assert_eq "$ac10_file" "si" "AC10 arbol sucio con --allow-dirty - crea el archivo"
assert_contains "$out10" "ARBOL SUCIO" "AC10 arbol sucio con --allow-dirty - encabezado marca ARBOL SUCIO"

# =========================================================================
# AC11 — --version imprime 0.11.0
# =========================================================================
out11="$(bash "$RUN_GATES" --version 2>&1)"
ec11=$?
assert_exit 0 "$ec11" "AC11 --version sale 0"
assert_contains "$out11" "0.11.0" "AC11 --version imprime 0.11.0"

# =========================================================================
# AC12 — directorio que NO es repo git: Tree: en "-", sale con el exit code
# de los gates (no con 4 ni con un abort del sellado). Gate 2 se fuerza en
# rojo a propósito para probar que el exit code sigue siendo el de los
# gates (1), no un valor fijo por el sellado degradado.
# =========================================================================
NONGIT_DIR="$(mktemp -d)"
if git -C "$NONGIT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "  FAIL  setup — $NONGIT_DIR quedo dentro de un repo git, no puedo probar AC12"
  exit 1
fi
fixture_gates_doc "$NONGIT_DIR" "false"

out12="$(cd "$NONGIT_DIR" && bash "$RUN_GATES" -d SDD/docs/doc_quality_gates.md -o out/gates.md 2>&1)"
ec12=$?
assert_exit 1 "$ec12" "AC12 sin repo git - sale con el exit code de los gates (hay un rojo)"
# shellcheck disable=SC2016  # backtick literal para matchear el Tree: del reporte, no es expansion querida
assert_contains "$out12" 'Tree: `-`' "AC12 sin repo git - Tree en guion"
[ -f "$NONGIT_DIR/out/gates.md" ] && ac12_file="si" || ac12_file="no"
assert_eq "$ac12_file" "si" "AC12 sin repo git - el reporte se escribe igual, sin abortar por el sellado"

test_summary
exit $?
