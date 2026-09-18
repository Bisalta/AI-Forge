# shellcheck shell=bash
# SDD/tests/test_escalation_ledger.sh
#
# AC21-AC25 del contract SDD/contracts/2026-08-25-consumption-optimization.md (R6):
# ledger de clasificación de ESCALATE/REJECTED y su tally.
#
# Bash 3.2 puro. MUTACIÓN sobre copias en tmpdir — nunca sobre SDD/escalations.md
# real: mutar el ledger versionado dejaría el árbol sucio si el proceso muere.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LEDGER="$REPO_ROOT/SDD/escalations.md"
TALLY="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-escalation-tally.sh"
TMP="$(mktemp -d)"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ---------- AC21 ----------
printf '\n-- test_backfill_gen94_completo (AC21)\n'
# v7: el backfill original (v6, "exactamente 3") sólo grepeaba ESCALATE|REJECTED
# literal sobre el historial de versiones — no veía E4/E5 (llegaron por "review
# APPROVED con gaps" y "re-review", nunca con esas palabras) ni E6 (BLOCKED).
# Re-derivado a 6 en v7. v8: el propio ciclo GEN-101 no había registrado sus
# dos REJECTED (ronda 1 y ronda 2 del reviewer) — hallazgo de la ronda 2 sobre
# el propio mecanismo, MAJOR M5. Van E7/E8.
#
# GEN-108: este bloque afirmaba "exactamente 8" y "TOTAL 8" contra un ledger
# cuyo propósito es CRECER — cada escalación legítima nueva lo ponía rojo, y
# pasó: la fila E9 de GEN-108 rompió seis asserts sin que nada estuviera mal.
# Una cifra congelada contra un artefacto que crece no es una aserción, es una
# fecha de vencimiento. Se cambia por la INVARIANTE, que es más fuerte: los
# eventos del backfill siguen presentes, y TODA fila lleva una Clase del enum
# cerrado. El conteo se deriva del propio ledger.
n_eventos="$(grep -cE '^\| E[0-9]+ \|' "$LEDGER")"
n_plan="$(grep -cE '^\| E[0-9]+ \|.*\| plan \|' "$LEDGER")"
n_clasificadas="$(grep -cE '^\| E[0-9]+ \|.*\| (plan|ejecución|herramienta|decisión) \|' "$LEDGER")"
[ "$n_eventos" -ge 8 ] && ge8="si" || ge8="no"
assert_eq "$ge8" "si" "test_backfill_gen94_completo — el backfill de GEN-94 + GEN-101 (8 eventos) sigue presente"
assert_eq "$n_clasificadas" "$n_eventos" "test_backfill_gen94_completo — TODA fila de evento lleva una Clase del enum cerrado"
for _e in E1 E2 E3 E4 E5 E6 E7 E8; do
  assert_eq "$(grep -cE "^\| $_e \|.*\| plan \|" "$LEDGER")" "1" "test_backfill_gen94_completo — $_e presente y Clase plan"
done
assert_contains "$(cat "$LEDGER")" "sicop-hardening" "test_backfill_gen94_completo — ciclo GEN-94 nombrado"
assert_contains "$(cat "$LEDGER")" "consumo GEN-101" "test_backfill_gen94_completo — el propio ciclo también está registrado (no sólo el ajeno)"
assert_contains "$(cat "$LEDGER")" "orchestration.md" "test_backfill_gen94_completo — referencia la definición cerrada de §6.1"

# ---------- AC22 ----------
printf '\n-- test_version (AC22)\n'
out="$(bash "$TALLY" --version 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_version"
assert_eq "$out" "sdd-escalation-tally 0.1.0" "test_version — cadena exacta"

# ---------- AC23 ----------
printf '\n-- test_tally_cuenta_correcto (AC23)\n'
out="$(bash "$TALLY" "$LEDGER" 2>&1)"; rc=$?
assert_exit 0 "$rc" "test_tally_cuenta_correcto"
# Derivado del ledger, no congelado (ver nota de GEN-108 arriba).
assert_contains "$out" "TOTAL $n_eventos" "test_tally_cuenta_correcto — el TOTAL del tally coincide con las filas del ledger"
assert_contains "$out" "plan       $n_plan" "test_tally_cuenta_correcto — el conteo de Clase plan coincide"

# Triple de mutación (AC23): agregar una fila más con Clase decisión a una
# copia. ID "E999" — cualquier ID bajo no sirve: el ledger real crece y en
# GEN-108 alcanzó E9, que era justamente el ID que esta fixture usaba.
cp "$LEDGER" "$TMP/ledger_mas_una.md"
printf '| E999 | 2026-08-27 | fixture-test | evento de prueba | decisión | ninguna |\n' >> "$TMP/ledger_mas_una.md"
out_m="$(bash "$TALLY" "$TMP/ledger_mas_una.md" 2>&1)"
assert_contains "$out_m" "TOTAL $((n_eventos + 1))" "test_tally_cuenta_correcto — MUTANTE ve la fila nueva (rojo esperado)"
assert_contains "$out_m" "decisión   1" "test_tally_cuenta_correcto — MUTANTE clasifica la fila nueva"
out_r="$(bash "$TALLY" "$LEDGER" 2>&1)"
assert_contains "$out_r" "TOTAL $n_eventos" "test_tally_cuenta_correcto — revertido (el ledger real nunca se tocó)"

# ---------- AC24 ----------
printf '\n-- test_tally_detecta_clase_ausente (AC24)\n'
# Copia del ledger con la Clase de E2 vaciada. Sustitución literal sobre el
# sufijo EXACTO de esa fila (conocido, lo escribió este mismo brief) en vez de
# reconstrucción por campos: partir por '|' con contenido UTF-8 multi-byte y
# reensamblar a mano es frágil — la primera versión de este test lo probó y
# produjo una fila que ni siquiera matcheaba el patrón del tally (0 filas
# inválidas detectadas, no por falta de bug sino por fixture rota).
sed 's/| plan | RT3, RT4 |$/|  | RT3, RT4 |/' "$LEDGER" > "$TMP/ledger_sin_clase.md"
assert_eq "$(grep -c '^| E2 |.*|  | RT3, RT4 |$' "$TMP/ledger_sin_clase.md")" "1" \
  "test_tally_detecta_clase_ausente — el fixture quedó vacío donde debía (sanity de la fixture, no del sistema bajo prueba)"

out_bad="$(bash "$TALLY" "$TMP/ledger_sin_clase.md" 2>&1)"; rc_bad=$?
assert_exit 3 "$rc_bad" "test_tally_detecta_clase_ausente"
assert_contains "$out_bad" "INVALIDA" "test_tally_detecta_clase_ausente — reporta la palabra"
assert_contains "$out_bad" "E2" "test_tally_detecta_clase_ausente — nombra la fila"

# Triple: el ledger real (limpio) no dispara esto.
bash "$TALLY" "$LEDGER" >/dev/null 2>&1; rc_clean=$?
assert_eq "$rc_clean-$rc_bad" "0-3" \
  "test_tally_detecta_clase_ausente — las dos corridas se distinguen (limpio vs con hueco)"

# ---------- AC25 ----------
printf '\n-- test_regla_retro_ampliada (AC25)\n'
SDD_CMD="$REPO_ROOT/plugins/sdd-flow/commands/sdd.md"
linea_retro="$(grep -n '\*\*Retro\*\*' "$SDD_CMD" | cut -d: -f2-)"
assert_contains "$linea_retro" "escalations.md" "test_regla_retro_ampliada — referencia el ledger"
assert_contains "$linea_retro" "sdd-escalation-tally.sh" "test_regla_retro_ampliada — referencia el tally"
assert_contains "$linea_retro" "mismo acto" "test_regla_retro_ampliada — exige clasificar en el momento, no después"

printf '\n'
test_summary; exit $?
