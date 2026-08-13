#!/usr/bin/env bash
# SDD/tests/test_doc_hash.sh — AC29 a AC35 del contract R5
# (SDD/contracts/2026-08-13-sicop-hardening.md): identidad de CONTENIDO del
# doc de gates que sdd-run-gates.sh estampa en el encabezado del reporte, y
# los cuatro artefactos normativos que dependen de esa identidad.
#
# Problema que esto reproduce: el runner (sin el fix de T2.1) estampa
# **Doc**: <ruta> y nada más — una ruta no identifica un contenido, y
# doc_quality_gates.md cambia varias veces por día durante el propio ciclo
# (medición externa: 31 cambios en 8 días, 8 en un solo día). Corrida contra
# el estado SIN el fix (script sin doc_hash(), y sin los cuatro archivos de
# T3.1-T3.4 actualizados): tiene que salir en rojo, porque ningún "sha256:"
# aparece en el encabezado del reporte ni en los cuatro documentos.
#
# AC29: el hash estampado coincide con los primeros 16 hex de
# `shasum -a 256 <doc>` sobre el MISMO archivo.
#
# AC30 (AC de detección de este requerimiento): dos sub-checks que en
# conjunto tienen poder de detección real —
#   (a) estabilidad: dos corridas SIN cambiar el doc dan el MISMO hash
#       (descarta un hash que "siempre difiere", ej. por timestamp o PID);
#   (b) sensibilidad: un byte distinto en el doc entre corridas da hashes
#       DISTINTOS (descarta un hash constante).
# Un hash que sólo pasara (a) o sólo (b) produce salida indistinguible de
# uno correcto si sólo se mira una corrida — texto exacto del AC30 del
# contract ("un hash constante, o uno que se recalcula mal y siempre
# difiere, produce salidas indistinguibles de uno correcto").
#
# AC31: sin shasum NI sha256sum en el PATH, el runner estampa sha256:- y
# sigue saliendo con el código de los gates (nunca aborta) — mismo criterio
# que el sellado de árbol de R1. Se prueba con un PATH mínimo CURADO
# (resuelto con el PATH real ANTES de overridear nada) que tiene todo lo
# que sdd-run-gates.sh necesita para correr de punta a punta salvo esos dos
# binarios: un PATH vacío rompería el script entero por razones ajenas al
# hash y no probaría AC31, probaría un crash. Gate 2 forzado a "false" para
# confirmar que el exit code sigue siendo el de los gates (1), no un valor
# fijo por la degradación del hash.
#
# AC32-AC35 son "verificable con grep" en el contract — mismo tratamiento
# que AC38 (contract R2) en SDD/tests/test_guard_identity.sh: se leen los
# archivos normativos reales (nunca una copia) y se assertea el contenido
# real, no una transcripción.
#
# Repos git temporales en SDD/tests/.tmp/, limpiados con trap ... EXIT.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_GATES="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-run-gates.sh"

TMP_BASE="$SCRIPT_DIR/.tmp/test_doc_hash-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() {
  rm -rf "$TMP_BASE"
  return 0
}
trap cleanup EXIT

if [ ! -f "$RUN_GATES" ]; then
  echo "  FAIL  setup — no existe $RUN_GATES"
  exit 1
fi

if ! command -v shasum >/dev/null 2>&1; then
  echo "  FAIL  setup — shasum no disponible en esta maquina: AC29 exige comparar contra 'shasum -a 256' (contract R5)"
  exit 1
fi

DOC_REL="SDD/docs/doc_quality_gates.md"

# fixture_gates_doc <dir> [gate2_cmd] — misma forma que test_run_gates_tree.sh
# (escalera minima de dos gates), para no depender de la tabla real del repo.
fixture_gates_doc() {
  dir="$1"
  gate2="${2:-true}"
  mkdir -p "$dir/SDD/docs"
  cat > "$dir/$DOC_REL" <<EOF
# Escalera de gates — fixture de test_doc_hash.sh (repo temporal, nunca versionado)

| # | Gate | Comando | Obligatorio | Notas |
|---|---|---|---|---|
| 1 | unit tests | \`true\` | sí | fixture: siempre sale 0 |
| 2 | security | \`$gate2\` | sí | fixture |
EOF
}

# new_repo <dir> [gate2_cmd] — repo git aislado con identidad local (nunca
# depende del git config del desarrollador) y un primer commit limpio.
new_repo() {
  dir="$1"
  gate2="${2:-true}"
  mkdir -p "$dir"
  git init -q "$dir"
  ( cd "$dir" && git config user.email "test@example.com" && git config user.name "test" && git config commit.gpgsign false )
  fixture_gates_doc "$dir" "$gate2"
  printf 'linea inicial\n' > "$dir/tracked.txt"
  ( cd "$dir" && git add -A && git commit -qm "init" )
}

# doc_hash_ref <archivo> — la MISMA fuente de verdad que exige AC29 (los
# primeros 16 hex de `shasum -a 256`), calculada por FUERA del runner: si
# reusara la función doc_hash() de sdd-run-gates.sh, un bug en esa función
# se auto-confirmaría contra sí misma en vez de contra el comando real que
# el AC exige.
doc_hash_ref() {
  shasum -a 256 "$1" | awk '{print $1}' | cut -c1-16
}

# extract_hash <salida-del-runner> — el primer "sha256:..." (16 hex o "-")
# que aparece en el encabezado del reporte.
extract_hash() {
  printf '%s\n' "$1" | grep -oE 'sha256:[0-9a-f-]+' | head -1
}

# =========================================================================
# AC29 — el encabezado estampa el doc con RUTA y HASH, y el hash coincide
# con los primeros 16 hex de `shasum -a 256 <doc>` sobre el mismo archivo.
# =========================================================================
AC29_DIR="$TMP_BASE/ac29"
new_repo "$AC29_DIR" "true"
EXPECTED_HASH_AC29="sha256:$(doc_hash_ref "$AC29_DIR/$DOC_REL")"

out29="$(cd "$AC29_DIR" && bash "$RUN_GATES" -d "$DOC_REL" -o .sdd/gates-run.md 2>&1)"
ec29=$?
assert_exit 0 "$ec29" "AC29 arbol limpio - el runner sale 0"
assert_contains "$out29" "$DOC_REL" "AC29 el encabezado estampa la ruta del doc"
assert_contains "$out29" "$EXPECTED_HASH_AC29" "AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo"

# =========================================================================
# AC30 (AC de detección) — estabilidad + sensibilidad, ver header.
# =========================================================================
AC30_DIR="$TMP_BASE/ac30"
new_repo "$AC30_DIR" "true"

out30_run1="$(cd "$AC30_DIR" && bash "$RUN_GATES" -d "$DOC_REL" -o .sdd/gates-run.md 2>&1)"
hash30_run1="$(extract_hash "$out30_run1")"

out30_run2="$(cd "$AC30_DIR" && bash "$RUN_GATES" -d "$DOC_REL" -o .sdd/gates-run.md 2>&1)"
hash30_run2="$(extract_hash "$out30_run2")"

assert_eq "$hash30_run2" "$hash30_run1" "AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash"

# un byte distinto (append, sin newline final): sha256 es sensible a cada
# byte, y la línea nueva sin "|" al principio no altera el parseo de la
# tabla (no matchea la regex de fila del awk).
printf 'x' >> "$AC30_DIR/$DOC_REL"
out30_run3="$(cd "$AC30_DIR" && bash "$RUN_GATES" -d "$DOC_REL" -o .sdd/gates-run.md 2>&1)"
hash30_run3="$(extract_hash "$out30_run3")"

if [ "$hash30_run3" = "$hash30_run1" ]; then ac30_differs="no"; else ac30_differs="si"; fi
assert_eq "$ac30_differs" "si" "AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas"

# =========================================================================
# AC31 — sin shasum NI sha256sum en el PATH: estampa sha256:- y sale con el
# código de los gates (no aborta). PATH mínimo curado, gate 2 forzado a
# "false" para probar que el exit code sigue siendo el de los gates (1) y
# no un valor fijo por la degradación del hash.
# =========================================================================
# minbin_without_hash_tools <dest> — symlinks EXACTAMENTE los binarios que
# sdd-run-gates.sh necesita para correr de punta a punta (resueltos con el
# PATH real ANTES de overridear nada — nunca `true`/`false`, que son
# builtins de bash y no dependen de PATH), salvo shasum/sha256sum: un PATH
# vacío rompería el script entero por razones ajenas al hash y probaría un
# crash, no AC31.
minbin_without_hash_tools() {
  local dest="$1" name p
  mkdir -p "$dest"
  for name in bash git awk grep mkdir dirname date mktemp tail rm cat; do
    p="$(command -v "$name" 2>/dev/null)" || { echo "  FAIL  setup — no encontre '$name' en el PATH real, no puedo armar el PATH minimo de AC31"; exit 1; }
    ln -sf "$p" "$dest/$name"
  done
}

AC31_DIR="$TMP_BASE/ac31"
new_repo "$AC31_DIR" "false"

MINBIN="$TMP_BASE/minbin-ac31"
minbin_without_hash_tools "$MINBIN"

out31="$(cd "$AC31_DIR" && PATH="$MINBIN" bash "$RUN_GATES" -d "$DOC_REL" -o .sdd/gates-run.md 2>&1)"
ec31=$?
assert_exit 1 "$ec31" "AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta"
assert_contains "$out31" "sha256:-" "AC31 sin shasum ni sha256sum en el PATH - estampa sha256:-"

# =========================================================================
# AC32 — plugins/sdd-flow/templates/verification-report.md registra el doc
# de gates con hash, no sólo con ruta.
# =========================================================================
VERIF_TEMPLATE="$REPO_ROOT/plugins/sdd-flow/templates/verification-report.md"
verif_text="$(cat "$VERIF_TEMPLATE")"
assert_contains "$verif_text" "con hash, no sólo con ruta" "AC32 verification-report.md - registra el doc de gates con hash, no solo con ruta"
assert_contains "$verif_text" "sha256:" "AC32 verification-report.md - menciona el formato sha256: del hash estampado"

# =========================================================================
# AC33 — plugins/sdd-flow/skills/sdd-init/SKILL.md exige escribir
# SDD/docs/doc-manifest.md con el hash de cada doc generado, y exige
# comparar antes de sobrescribir, mostrando el diff cuando el hash difiere.
# =========================================================================
SDD_INIT_SKILL="$REPO_ROOT/plugins/sdd-flow/skills/sdd-init/SKILL.md"
sdd_init_text="$(cat "$SDD_INIT_SKILL")"
assert_contains "$sdd_init_text" "doc-manifest.md" "AC33 sdd-init/SKILL.md - menciona SDD/docs/doc-manifest.md"
assert_contains "$sdd_init_text" "No lo sobreescribas en silencio" "AC33 sdd-init/SKILL.md - exige no sobreescribir en silencio cuando el hash difiere"
assert_contains "$sdd_init_text" "mostrale el diff" "AC33 sdd-init/SKILL.md - exige mostrar el diff antes de sobreescribir"

# =========================================================================
# AC34 — plugins/sdd-flow/agents/reviewer-agent.md distingue los dos casos
# con mensajes distintos: hashes iguales + evidencia que no reproduce =
# BLOCKER de evidencia podrida; hashes distintos = hallazgo propio de que
# los gates cambiaron durante el ciclo.
# =========================================================================
REVIEWER_AGENT="$REPO_ROOT/plugins/sdd-flow/agents/reviewer-agent.md"
reviewer_text="$(cat "$REVIEWER_AGENT")"
assert_contains "$reviewer_text" "evidencia podrida" "AC34 reviewer-agent.md - hashes iguales con evidencia que no reproduce es evidencia podrida"
assert_contains "$reviewer_text" "hallazgo propio" "AC34 reviewer-agent.md - hashes distintos es un hallazgo propio, no evidencia podrida"
assert_contains "$reviewer_text" "cambiaron durante el ciclo" "AC34 reviewer-agent.md - el hallazgo de hashes distintos dice que los gates cambiaron durante el ciclo"

# =========================================================================
# AC35 — plugins/sdd-flow/templates/doc-manifest.md existe con una fila por
# cada uno de los tres docs de SDD/docs/.
# =========================================================================
MANIFEST_TEMPLATE="$REPO_ROOT/plugins/sdd-flow/templates/doc-manifest.md"
[ -f "$MANIFEST_TEMPLATE" ] && manifest_exists="si" || manifest_exists="no"
assert_eq "$manifest_exists" "si" "AC35 templates/doc-manifest.md existe"
if [ -f "$MANIFEST_TEMPLATE" ]; then
  manifest_text="$(cat "$MANIFEST_TEMPLATE")"
else
  manifest_text=""
fi
assert_contains "$manifest_text" "doc_architecture.md" "AC35 doc-manifest.md - tiene fila para doc_architecture.md"
assert_contains "$manifest_text" "doc_verification_guide.md" "AC35 doc-manifest.md - tiene fila para doc_verification_guide.md"
assert_contains "$manifest_text" "doc_quality_gates.md" "AC35 doc-manifest.md - tiene fila para doc_quality_gates.md"

test_summary
exit $?
