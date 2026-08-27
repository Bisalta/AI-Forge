# shellcheck shell=bash
# SDD/tests/test_model_tier_policy.sh
#
# AC10-AC15 del contract SDD/contracts/2026-08-25-consumption-optimization.md
# (R2: el plugin declara tier, nunca versión · R3: haiku donde el contexto es chico).
# AC16 se eliminó en v7 — duplicaba AC12 y le aplicaba mutación indebida
# (§10.1 la reserva para ACs de detección, no para aserciones de contenido
# estático). Ver la nota en el lugar donde vivía.
#
# Bash 3.2 puro. Los assert_* salen de lib.sh.
#
# MUTACIÓN (quality-gates.md §10): AC10 es AC de detección. Su mutación se
# aplica sobre una COPIA del árbol en el tmpdir — nunca sobre el repo. Mutar
# archivos versionados en un test deja el árbol sucio si el proceso muere, y un
# árbol sucio hace que sdd-run-gates.sh se niegue a sellar evidencia (exit 4).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP="$(mktemp -d)"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------- helpers locales ----------

# ac10_hits <root> → violaciones REALES de la regla de tier bajo <root>.
# Excluye las líneas que CITAN la regla: la sección Modelos de base-standards.md y
# la convención de CLAUDE.md nombran los IDs prohibidos para prohibirlos. Es la
# misma técnica que sdd-lint-contract.sh usa con 'prohibido|closure|banned', y la
# misma clase de problema que SDD/debt.md D10/D11. La exclusión es por LÍNEA que
# lleva lenguaje de prohibición, no por archivo: excluir archivos enteros ciega el
# chequeo (lección de D6). El triple de abajo prueba que no lo ciega.
ac10_hits() {
  ( cd "$1" 2>/dev/null && \
    grep -rniE 'opus 4\.8|sonnet 4\.6|claude-opus-4-8|claude-sonnet-4-6' plugins/ CLAUDE.md 2>/dev/null \
    | grep -viE 'defecto|prohibi|nunca versión|envejece' \
    | grep -c . ) 2>/dev/null || true
}

# frontmatter_model <archivo> → valor de `model:` DENTRO del frontmatter, o vacío.
# No es un grep suelto: verifica que la línea 1 sea `---` y corta en el `---` de
# cierre, así una mención de `model:` en el cuerpo no cuenta como frontmatter.
frontmatter_model() {
  awk '
    NR==1 && $0 != "---" { exit }
    NR>1  && $0 == "---" { exit }
    /^model:[ \t]*/      { sub(/^model:[ \t]*/, ""); print; exit }
  ' "$1"
}

# arbol_copia → copia plugins/ + CLAUDE.md al tmpdir y ecoa la raíz
arbol_copia() {
  rm -rf "$TMP/tree"; mkdir -p "$TMP/tree"
  cp -R "$REPO_ROOT/plugins" "$TMP/tree/"
  cp "$REPO_ROOT/CLAUDE.md" "$TMP/tree/"
  printf '%s' "$TMP/tree"
}

# ---------- AC10 ----------
printf '\n-- test_sin_versiones_pinneadas (AC10)\n'
hits="$(ac10_hits "$REPO_ROOT")"
assert_eq "$hits" "0" "test_sin_versiones_pinneadas — cero versiones pinneadas en plugins/ y CLAUDE.md"

# Triple de mutación (AC10): reintroducir el literal en README.md línea 5.
T="$(arbol_copia)"
hits_verde="$(ac10_hits "$T")"
printf 'El planner corre preferentemente en Opus 4.8.\n' >> "$T/plugins/sdd-flow/README.md"
hits_rojo="$(ac10_hits "$T")"
sed -i.bak '$d' "$T/plugins/sdd-flow/README.md" && rm -f "$T/plugins/sdd-flow/README.md.bak"
hits_revert="$(ac10_hits "$T")"
assert_eq "$hits_rojo" "1" "test_sin_versiones_pinneadas — MUTANTE detectado (rojo esperado)"
assert_eq "$hits_verde-$hits_rojo-$hits_revert" "0-1-0" \
  "test_sin_versiones_pinneadas — las tres corridas se distinguen"

# La exclusión no ciega el chequeo: una violación en la MISMA línea que lenguaje de
# prohibición sí se pierde — límite conocido y declarado, no un descuido.
assert_eq "$(ac10_hits "$REPO_ROOT")" "0" "test_sin_versiones_pinneadas — repo sigue limpio tras el triple"

# ---------- AC11 ----------
printf '\n-- test_regla_documentada (AC11)\n'
BS="$REPO_ROOT/plugins/sdd-flow/standards/base-standards.md"
assert_contains "$(grep -c '^## Modelos' "$BS")" "1" "test_regla_documentada — sección propia"
assert_contains "$(cat "$BS")" "tier, nunca versión" "test_regla_documentada — enuncia la regla"
assert_contains "$(cat "$BS")" "Co-Authored-By" "test_regla_documentada — declara la excepción de atribución"
assert_contains "$(cat "$BS")" "El reviewer no baja de" "test_regla_documentada — fija el piso del reviewer"

# ---------- AC12 ----------
printf '\n-- test_alias_de_tier_intactos (AC12)\n'
AG="$REPO_ROOT/plugins/sdd-flow/agents"
assert_eq "$(frontmatter_model "$AG/implementing-agent.md")" "sonnet" \
  "test_alias_de_tier_intactos — implementing-agent sigue en sonnet"
assert_eq "$(frontmatter_model "$AG/reviewer-agent.md")" "opus" \
  "test_alias_de_tier_intactos — reviewer-agent sigue en opus"

# ---------- AC13 ----------
printf '\n-- test_skills_mecanicos_en_haiku (AC13)\n'
assert_eq "$(frontmatter_model "$REPO_ROOT/plugins/sdd-flow/skills/write-pr-report/SKILL.md")" "haiku" \
  "test_skills_mecanicos_en_haiku — write-pr-report"
assert_eq "$(frontmatter_model "$REPO_ROOT/plugins/sdd-flow/commands/sdd-status.md")" "haiku" \
  "test_skills_mecanicos_en_haiku — sdd-status"
# sdd-fixes NO baja de tier: su triage declara mutaciones (contract v4)
assert_eq "$(frontmatter_model "$REPO_ROOT/plugins/sdd-flow/commands/sdd-fixes.md")" "" \
  "test_skills_mecanicos_en_haiku — sdd-fixes queda en el default (declara mutaciones)"
# v7: write-pr-report es un skill invocado tanto directo como desde /sdd-pr.
# Nada en este ciclo verifica que el harness honre `model:` en el frontmatter
# de un SKILL de la misma forma que en un agent o un command (hallazgo de
# revisión externa, MAJOR 11) — fix defensivo: declarar el mismo model:haiku
# también en el COMMAND que lo invoca, donde el campo sí es superficie
# soportada sin ambigüedad.
assert_eq "$(frontmatter_model "$REPO_ROOT/plugins/sdd-flow/commands/sdd-pr.md")" "haiku" \
  "test_skills_mecanicos_en_haiku — sdd-pr.md declara haiku directamente (defensivo, no asume composición skill→command)"

# ---------- AC14 ----------
printf '\n-- test_criterio_trivial_enumerado (AC14)\n'
ARCH="$REPO_ROOT/plugins/sdd-flow/standards/archetypes.md"
arch_txt="$(cat "$ARCH")"
assert_contains "$arch_txt" "Criterio de brief trivial" "test_criterio_trivial_enumerado — sección presente"
for cond in "≤2 archivos" "No agrega dependencias" "ACs es de detección"; do
  assert_contains "$arch_txt" "$cond" "test_criterio_trivial_enumerado — condición: $cond"
done
assert_contains "$arch_txt" "las cuatro" "test_criterio_trivial_enumerado — exige las cuatro, no un subconjunto"

# ---------- AC15 ----------
printf '\n-- test_sdd_plan_referencia_criterio (AC15)\n'
PLAN="$REPO_ROOT/plugins/sdd-flow/skills/sdd-plan/SKILL.md"
linea="$(grep -n 'Modelo asignado' "$PLAN" | head -1 | cut -d: -f2-)"
assert_contains "$linea" "archetypes.md" "test_sdd_plan_referencia_criterio — apunta al criterio"
assert_contains "$linea" "cuatro condiciones" "test_sdd_plan_referencia_criterio — nombra las cuatro condiciones"
assert_eq "$(printf '%s' "$linea" | grep -c 'si trivial')" "0" \
  "test_sdd_plan_referencia_criterio — ya no dice «si trivial» sin definición"

# AC16 se borró en v7 (hallazgo de revisión externa, MINOR 18): duplicaba la
# aserción de AC12 palabra por palabra, y encima le pegaba una mutación —
# quality-gates.md §10.1 reserva la mutación para ACs de DETECCIÓN (guardas,
# validaciones), no para "este archivo sigue diciendo X", que es exactamente
# lo que AC12 ya cubre sin mutación (mismo motivo por el que AC21/AC22/AC25
# tampoco la llevan). El "triple" de AC16 mutaba una copia y la releía: eso
# prueba que `sed` funciona, no que un control detecta algo.

printf '\n'
test_summary; exit $?
