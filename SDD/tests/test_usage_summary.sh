#!/usr/bin/env bash
# SDD/tests/test_usage_summary.sh — plugins/usage-monitor/scripts/usage-summary.sh.
#
# Convención propuesta por Esteban en #bisalta-context-sdd (2026-09-07): log local
# de OTel console (`~/.claude/usage-log/`), y lo único que se comparte es el
# resumen de atribución — NUNCA el log crudo (que trae session.id, user.email,
# account_uuid, organization.id — no sólo prompts). Este test prueba que el
# script cumple esa regla mecánicamente, no que alguien recuerde redactar.
#
# Fixture: SDD/tests/fixtures/usage-log-sample.txt, formato real capturado
# corriendo `claude -p ... ` con `OTEL_METRICS_EXPORTER=console` (2026-09-08) —
# object-literal de JS, NO JSON (claves sin comillas, comas finales). Confirma
# que los contadores son ACUMULATIVOS por sesión (el mismo valor se re-emite en
# cada tick hasta que el proceso termina): sumar todas las líneas sobreestimaría
# el costo real ~40x. El fixture tiene 2 sesiones (session-A con 2 ticks del
# mismo grupo de atribución en 0.3 y 0.75, más un grupo de subagente en 1.0;
# session-B con un solo tick en 2.0) para probar max-por-sesión y suma
# entre-sesiones a la vez: total esperado = 0.75 + 1.0 + 2.0 = 3.75.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SUMMARY="$REPO_ROOT/plugins/usage-monitor/scripts/usage-summary.sh"
FIXTURE="$SCRIPT_DIR/fixtures/usage-log-sample.txt"

out="$(bash "$SUMMARY" "$FIXTURE" 2>&1)"; ec=$?

assert_exit 0 "$ec" "corrida limpia sobre el fixture"

assert_contains "$out" "test@example.com" "atribucion: email del header presente"
assert_contains "$out" "2 sesiones" "cuenta de sesiones (2 session.id distintos)"

assert_contains "$out" "\$3.75" "costo total = max-por-sesion + suma entre sesiones (0.75+1.00+2.00)"
assert_contains "$out" "\$2.75" "fuente (principal): session-A main/medium (0.75) + session-B main/low (2.00)"
assert_contains "$out" "\$1.00" "fuente sdd-flow:sdd-plan: solo el grupo subagente de session-A"

assert_contains "$out" "500" "tokens input"
assert_contains "$out" "300" "tokens output"

# --- guarda de no-fuga: los campos sensibles del log crudo NUNCA llegan al resumen ---
for needle in "session-A" "session-B" "fake-uuid-a" "fake-uuid-b" "fake-org-1" "fakehash-a" "fakehash-b" "user_fakeA" "user_fakeB"; do
  case "$out" in
    *"$needle"*)
      printf '  FAIL  no-fuga - "%s" no debería aparecer en el resumen compartible\n' "$needle"
      TEST_FAILURES=$((TEST_FAILURES + 1))
      ;;
    *) printf '  ok    no-fuga - "%s" ausente del resumen\n' "$needle" ;;
  esac
done

test_summary
exit $?
