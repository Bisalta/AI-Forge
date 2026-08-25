# shellcheck shell=bash
# SDD/tests/test_lint_contract_sections.sh
#
# AC1-AC9 del contract SDD/contracts/2026-08-25-consumption-optimization.md (R4):
# el chequeo 3 de sdd-lint-contract.sh — secciones obligatorias ausentes.
#
# Bash 3.2 puro. Los assert_* salen de lib.sh; este archivo no define ninguno.
#
# MUTACIÓN (quality-gates.md §10): la mutación declarada por el contract es
# «vaciar la lista de secciones obligatorias de ámbito contract y de ámbito
# requerimiento». Se aplica sobre una COPIA del linter en el tmpdir, no sobre el
# archivo del repo: el sistema bajo prueba es el script, y una copia mutada ES el
# script mutado. Evita dejar el repo sucio si el test muere a mitad, que es un
# modo de falla real del arnés (SDD/retro.md RT11).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LINTER="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-lint-contract.sh"
TMP="$(mktemp -d)"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------- helpers locales (no son asserts) ----------

# count_ausentes <salida> → cuántas líneas seccion-ausente trae
count_ausentes() {
  printf '%s\n' "$1" | grep -c 'seccion-ausente' 2>/dev/null || true
}

# mutante → escribe en $TMP/mutante.sh el linter con AMBAS listas vacías
mutante() {
  awk '
    /^SECTIONS_CONTRACT="Objective$/      { print "SECTIONS_CONTRACT=\"\""; skip=1; next }
    /^SECTIONS_REQ="Architectural Delta$/ { print "SECTIONS_REQ=\"\"";      skip=1; next }
    skip && /"$/ { skip=0; next }
    skip         { next }
                 { print }
  ' "$LINTER" > "$TMP/mutante.sh"
}

# ---------- fixtures ----------

fixture() { # fixture <nombre> <contenido-por-stdin>
  cat > "$TMP/$1.md"
}

# A — completo salvo Threat model
fixture completo_sin_threat <<'EOF'
# HLTC — fixture
## Objective
Cerrar algo.
## Out of scope
Nada más.
```
concerns:
  security: n/a
```
# R0 — lo primero
## Architectural Delta
Toca un archivo.
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
EOF

# B — le faltan las cuatro de ámbito contract; el requerimiento está completo
fixture sin_ninguna_de_contract <<'EOF'
# HLTC — fixture
# R0 — lo primero
## Architectural Delta
Toca un archivo.
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
EOF

# C — R0 completo, R1 sin Acceptance criteria
fixture r1_sin_acceptance <<'EOF'
# HLTC — fixture
## Objective
Cerrar algo.
## Out of scope
Nada más.
## Threat model
N/A — no cambia superficie invocable.
**Concerns**: security n/a.
# R0 — lo primero
## Architectural Delta
Toca un archivo.
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
# R1 — lo segundo
## Architectural Delta
Toca otro archivo.
## Checklist del arquetipo `refactor`
| Ítem | Estado |
EOF

# D — sin bloques # R<n>: el documento entero es un requerimiento único
fixture sin_bloques_r <<'EOF'
# HLTC — fixture
## Objective
Cerrar algo.
## Out of scope
Nada más.
## Threat model
N/A.
```
concerns:
  security: n/a
```
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
EOF

# E — encabezado anotado con sufijo
fixture threat_anotado <<'EOF'
# HLTC — fixture
## Objective
Cerrar algo.
## Out of scope
Nada más.
## Threat model (standards/security.md §6)
N/A.
```
concerns:
  security: n/a
```
# R0 — lo primero
## Architectural Delta
Toca un archivo.
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
EOF

# F — frase abierta Y sección ausente a la vez
fixture abierta_y_ausente <<'EOF'
# HLTC — fixture
## Objective
El endpoint valida el payload if needed.
## Out of scope
Nada más.
```
concerns:
  security: n/a
```
# R0 — lo primero
## Architectural Delta
Toca un archivo.
## Acceptance criteria
| # | Criterio |
## Checklist del arquetipo `infra`
| Ítem | Estado |
EOF

# ---------- AC1 ----------
printf '\n-- test_falta_threat_model (AC1)\n'
out="$(bash "$LINTER" "$TMP/completo_sin_threat.md" "$TMP" 2>&1)"; rc=$?
assert_exit 2 "$rc" "test_falta_threat_model"
assert_contains "$out" "$(printf 'BLOCKER\t0\tseccion-ausente\tThreat model')" \
  "test_falta_threat_model — línea exacta"
assert_eq "$(count_ausentes "$out")" "1" "test_falta_threat_model — exactamente una"

# triple de mutación (AC1)
mutante
out_m="$(bash "$TMP/mutante.sh" "$TMP/completo_sin_threat.md" "$TMP" 2>&1)"; rc_m=$?
assert_exit 0 "$rc_m" "test_falta_threat_model — MUTANTE no detecta (rojo esperado)"
assert_eq "$(count_ausentes "$out_m")" "0" "test_falta_threat_model — MUTANTE cero hallazgos"
out_r="$(bash "$LINTER" "$TMP/completo_sin_threat.md" "$TMP" 2>&1)"; rc_r=$?
assert_exit 2 "$rc_r" "test_falta_threat_model — revertido vuelve a detectar"
# El triple se distingue: 2 / 0 / 2 y 1 / 0 / 1 (SDD/retro.md RT11)
assert_eq "$rc-$rc_m-$rc_r" "2-0-2" "test_falta_threat_model — las tres corridas se distinguen"

# ---------- AC2 ----------
printf '\n-- test_faltan_las_cuatro_de_contract (AC2)\n'
out="$(bash "$LINTER" "$TMP/sin_ninguna_de_contract.md" "$TMP" 2>&1)"; rc=$?
assert_exit 2 "$rc" "test_faltan_las_cuatro_de_contract"
assert_eq "$(count_ausentes "$out")" "4" "test_faltan_las_cuatro_de_contract — cuatro líneas"
for sec in "Objective" "Out of scope" "Threat model" "concerns:"; do
  assert_contains "$out" "$sec" "test_faltan_las_cuatro_de_contract — nombra $sec"
done
mutante
out_m="$(bash "$TMP/mutante.sh" "$TMP/sin_ninguna_de_contract.md" "$TMP" 2>&1)"
assert_eq "$(count_ausentes "$out_m")" "1" \
  "test_faltan_las_cuatro_de_contract — MUTANTE sólo deja concerns (la lista no lo gobierna)"

# ---------- AC3 ----------
printf '\n-- test_requerimiento_sin_acceptance_criteria (AC3)\n'
out="$(bash "$LINTER" "$TMP/r1_sin_acceptance.md" "$TMP" 2>&1)"; rc=$?
assert_exit 2 "$rc" "test_requerimiento_sin_acceptance_criteria"
assert_contains "$out" "R1: Acceptance criteria" \
  "test_requerimiento_sin_acceptance_criteria — nombra el requerimiento"
assert_eq "$(count_ausentes "$out")" "1" \
  "test_requerimiento_sin_acceptance_criteria — R0 completo no aporta hallazgos"

# ---------- AC4 ----------
printf '\n-- test_sin_bloques_R_documento_entero (AC4)\n'
out="$(bash "$LINTER" "$TMP/sin_bloques_r.md" "$TMP" 2>&1)"; rc=$?
assert_exit 2 "$rc" "test_sin_bloques_R_documento_entero"
assert_contains "$out" "Architectural Delta" \
  "test_sin_bloques_R_documento_entero — exige la sección de requerimiento"
assert_eq "$(count_ausentes "$out")" "1" "test_sin_bloques_R_documento_entero — sólo la faltante"

# ---------- AC5 ----------
printf '\n-- test_este_contract_sale_limpio (AC5)\n'
out="$(bash "$LINTER" "$REPO_ROOT/SDD/contracts/2026-08-25-consumption-optimization.md" "$REPO_ROOT" 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_este_contract_sale_limpio"
assert_eq "$(count_ausentes "$out")" "0" "test_este_contract_sale_limpio — cero seccion-ausente"

# ---------- AC6 ----------
printf '\n-- test_regresion_contract_gen94 (AC6)\n'
GEN94="$REPO_ROOT/SDD/contracts/2026-08-13-sicop-hardening.md"
out="$(bash "$LINTER" "$GEN94" "$REPO_ROOT" 2>&1)"
assert_eq "$(count_ausentes "$out")" "0" \
  "test_regresion_contract_gen94 — un contract real y completo no se marca"

# triple de mutación (AC6): la mutación DECLARADA es ampliar la lista con una
# sección inventada; el rojo prueba que el chequeo mira de verdad ese archivo.
sed 's/^SECTIONS_CONTRACT="Objective$/SECTIONS_CONTRACT="Seccion Que No Existe\nObjective/' \
  "$LINTER" > "$TMP/mutante_amplia.sh"
out_m="$(bash "$TMP/mutante_amplia.sh" "$GEN94" "$REPO_ROOT" 2>&1)"
assert_eq "$(count_ausentes "$out_m")" "1" \
  "test_regresion_contract_gen94 — MUTANTE con sección inventada sí marca (rojo esperado)"
out_r="$(bash "$LINTER" "$GEN94" "$REPO_ROOT" 2>&1)"
assert_eq "$(count_ausentes "$out_r")" "0" \
  "test_regresion_contract_gen94 — revertido vuelve a cero"
assert_eq "$(count_ausentes "$out")-$(count_ausentes "$out_m")-$(count_ausentes "$out_r")" "0-1-0" \
  "test_regresion_contract_gen94 — las tres corridas se distinguen"

# ---------- AC7 ----------
printf '\n-- test_encabezado_anotado_no_falsea (AC7)\n'
out="$(bash "$LINTER" "$TMP/threat_anotado.md" "$TMP" 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_encabezado_anotado_no_falsea"
assert_eq "$(count_ausentes "$out")" "0" \
  "test_encabezado_anotado_no_falsea — el sufijo anotado no produce falso BLOCKER"

# ---------- AC8 ----------
printf '\n-- test_version_bump_y_argv (AC8)\n'
out="$(bash "$LINTER" --version 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_version_bump_y_argv"
assert_eq "$out" "sdd-lint-contract 0.11.0" "test_version_bump_y_argv — versión bumpeada"
out="$(bash "$LINTER" 2>&1)"; rc=$?
assert_exit 3 "$rc" "test_version_bump_y_argv — sin argumentos sigue saliendo 3"

# ---------- AC9 ----------
printf '\n-- test_frase_abierta_y_seccion_ausente (AC9)\n'
out="$(bash "$LINTER" "$TMP/abierta_y_ausente.md" "$TMP" 2>&1)"; rc=$?
assert_exit 2 "$rc" "test_frase_abierta_y_seccion_ausente"
assert_contains "$out" "frase-abierta" "test_frase_abierta_y_seccion_ausente — reporta la frase"
assert_contains "$out" "seccion-ausente" "test_frase_abierta_y_seccion_ausente — reporta la sección"

printf '\n'
test_summary; exit $?
