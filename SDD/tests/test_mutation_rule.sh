#!/usr/bin/env bash
# SDD/tests/test_mutation_rule.sh — AC19 a AC24 del contract R3
# (SDD/contracts/2026-08-13-sicop-hardening.md): la regla de prueba por
# mutación deja de valer sólo para el arquetipo `bugfix` y pasa a valer para
# todo AC de detección, en cualquier arquetipo.
#
# Los seis ACs son "verificable con grep" en el contract — mismo tratamiento
# que AC38 (contract R2) en test_guard_identity.sh y AC32-AC35 (contract R5)
# en test_doc_hash.sh: se leen los archivos normativos REALES del árbol
# (nunca una copia ni una transcripción) y se assertea su contenido.
#
# Corrida contra el estado SIN el cambio (quality-gates.md con el ítem 5 de
# la DoD limitado a `bugfix`, sin sección 10, y los otros cuatro archivos sin
# referencia): tiene que salir en rojo — ninguno de los literales de abajo
# existe todavía en el árbol.
#
# AC23 es el AC de DETECCIÓN de este requerimiento y por eso lleva su propia
# prueba por mutación (registrada en el verification report): su condición de
# aprobación es una AUSENCIA ("ninguno de los cinco archivos recopia el texto
# normativo del triple"), y un chequeo de ausencia que busca una frase
# inexistente pasa siempre. La mutación declarada es recopiar el texto
# normativo en uno de los cinco archivos y verificar que estos asserts se
# ponen rojos.
#
# Límite conocido de los asserts de AC23: detectan la copia LITERAL del texto
# normativo, no una paráfrasis. Es deliberado — el mismo criterio de §10.1
# aplicado a este test: una copia reescrita es un hallazgo de review con
# criterio (Fase 2 del reviewer), no algo que un grep pueda decidir sin
# convertirse en un control ruidoso.
#
# Sin repos temporales ni fixtures: estos ACs se verifican sobre el árbol de
# este repo, así que no hay nada que limpiar.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

QG="$REPO_ROOT/plugins/sdd-flow/standards/quality-gates.md"
PLAN="$REPO_ROOT/plugins/sdd-flow/skills/sdd-plan/SKILL.md"
IMPL="$REPO_ROOT/plugins/sdd-flow/agents/implementing-agent.md"
REVIEWER="$REPO_ROOT/plugins/sdd-flow/agents/reviewer-agent.md"
PRREPORT="$REPO_ROOT/plugins/sdd-flow/skills/write-pr-report/SKILL.md"

for required in "$QG" "$PLAN" "$IMPL" "$REVIEWER" "$PRREPORT"; do
  if [ ! -f "$required" ]; then
    echo "  FAIL  setup — no existe $required"
    exit 1
  fi
done

qg_text="$(cat "$QG")"
plan_text="$(cat "$PLAN")"
impl_text="$(cat "$IMPL")"
reviewer_text="$(cat "$REVIEWER")"
prreport_text="$(cat "$PRREPORT")"

# Los tres literales que gobiernan este requerimiento.
# SECTION_TITLE: el título por el que los cinco archivos referencian la regla.
# TRIPLE_TEXT:   el texto normativo del triple — vive en UN solo archivo.
# TRIPLE_ARROW:  la forma corta del triple, mismo criterio que TRIPLE_TEXT.
SECTION_TITLE="Prueba por mutación (AC de detección)"
TRIPLE_TEXT="verde con el sistema intacto, rojo con la mutación aplicada, verde otra vez tras revertirla"
TRIPLE_ARROW="verde → rojo → verde"

# has_text <texto> <literal> — imprime "si"/"no" según substring literal.
# lib.sh define assert_contains (presencia) pero no un assert de AUSENCIA, y
# el Reuse statement del contract R0 prohíbe que un test_*.sh defina asserts
# propios: esta función no assertea nada, produce el valor que después compara
# assert_eq — la misma forma que test_doc_hash.sh usa para AC30 y AC35.
has_text() {
  case "$1" in
    *"$2"*) printf 'si\n' ;;
    *) printf 'no\n' ;;
  esac
}

# =========================================================================
# AC19 — quality-gates.md tiene la sección de prueba por mutación (triple +
# criterio de qué AC lo requiere) y el ítem 5 de la DoD la referencia en vez
# de limitar la regla al arquetipo `bugfix`.
# =========================================================================
assert_contains "$qg_text" "## 10. $SECTION_TITLE" "AC19 quality-gates.md - existe la seccion 10 de prueba por mutacion"
assert_contains "$qg_text" "$TRIPLE_ARROW" "AC19 quality-gates.md - la seccion nombra el triple verde-rojo-verde"
assert_contains "$qg_text" "$TRIPLE_TEXT" "AC19 quality-gates.md - la seccion define las tres corridas del triple"
assert_contains "$qg_text" "criterio de clasificación" "AC19 quality-gates.md - la seccion define el criterio de que AC requiere la prueba por mutacion"

# El ítem 5 de la DoD, leído por su propia línea: la generalización tiene que
# estar EN ese ítem, no en cualquier parte del archivo.
dod5="$(grep -m1 '^5\. ' "$QG")"
assert_contains "$dod5" "$SECTION_TITLE" "AC19 DoD item 5 - referencia la seccion de prueba por mutacion por su titulo"
assert_contains "$dod5" "en cualquier arquetipo" "AC19 DoD item 5 - la regla vale en cualquier arquetipo"
case "$dod5" in
  "5. Si el requerimiento es un "*) dod5_condicionado="si" ;;
  *) dod5_condicionado="no" ;;
esac
assert_eq "$dod5_condicionado" "no" "AC19 DoD item 5 - ya no condiciona la regla al arquetipo bugfix"

# =========================================================================
# AC20 — sdd-plan/SKILL.md exige que cada AC de detección declare su mutación
# en el contract.
# =========================================================================
plan_mut="$(grep -m1 'el contract escribe' "$PLAN")"
assert_contains "$plan_mut" "AC de detección" "AC20 sdd-plan - la regla habla del AC de deteccion"
assert_contains "$plan_mut" "Mutación:" "AC20 sdd-plan - el contract escribe la mutacion debajo del AC de deteccion"
assert_contains "$plan_text" "¿cada AC de detección tiene declarada su mutación" "AC20 sdd-plan - el self-review chequea que cada AC de deteccion tenga su mutacion"

# =========================================================================
# AC21 — reviewer-agent.md: AC de detección sin las tres corridas = BLOCKER;
# cifra reportada sin la salida que la produce = MAJOR. Se assertea la
# SEVERIDAD en la línea de cada regla, no su mera coexistencia en el archivo.
# =========================================================================
rev_triple="$(grep -m1 'un control sin su rojo registrado' "$REVIEWER")"
assert_contains "$rev_triple" "sin las tres corridas" "AC21 reviewer-agent - la regla apunta al AC de deteccion sin las tres corridas"
assert_contains "$rev_triple" "BLOCKER" "AC21 reviewer-agent - AC de deteccion sin las tres corridas es BLOCKER"

rev_cifra="$(grep -m1 'es un recuerdo, no una medición' "$REVIEWER")"
assert_contains "$rev_cifra" "salida del comando" "AC21 reviewer-agent - la regla apunta a la cifra sin la salida que la produce"
assert_contains "$rev_cifra" "MAJOR" "AC21 reviewer-agent - cifra sin su salida es MAJOR"

# =========================================================================
# AC22 — implementing-agent.md y write-pr-report/SKILL.md exigen adjuntar la
# salida del comando de cada cifra reportada.
# =========================================================================
impl_cifra="$(grep -m1 'cifra que reportes' "$IMPL")"
assert_contains "$impl_cifra" "la salida del comando que la produce" "AC22 implementing-agent - toda cifra reportada va con la salida del comando que la produce"
assert_contains "$impl_cifra" "es una cita, no una medición" "AC22 implementing-agent - una cifra copiada de otro documento no cuenta como medicion"

pr_cifra="$(grep -m1 'attach the output of the command' "$PRREPORT")"
assert_contains "$pr_cifra" "figure" "AC22 write-pr-report - toda cifra del PR report va con la salida del comando que la produce"
assert_contains "$prreport_text" "a quote, not a measurement" "AC22 write-pr-report - una cifra copiada de otro documento no cuenta como medicion"

# =========================================================================
# AC23 (AC de detección de este requerimiento) — los cinco archivos
# referencian la sección por su TÍTULO, y ninguno de los otros cuatro recopia
# el texto normativo del triple.
# Lado positivo primero: el texto normativo existe en quality-gates.md. Sin
# este assert, borrar la sección entera dejaría los cuatro asserts de ausencia
# en verde — que es exactamente el control tautológico que R3 prohíbe.
# =========================================================================
assert_contains "$qg_text" "$SECTION_TITLE" "AC23 quality-gates.md - contiene la seccion referenciada por su titulo"
assert_contains "$plan_text" "$SECTION_TITLE" "AC23 sdd-plan - referencia la seccion por su titulo"
assert_contains "$impl_text" "$SECTION_TITLE" "AC23 implementing-agent - referencia la seccion por su titulo"
assert_contains "$reviewer_text" "$SECTION_TITLE" "AC23 reviewer-agent - referencia la seccion por su titulo"
assert_contains "$prreport_text" "$SECTION_TITLE" "AC23 write-pr-report - referencia la seccion por su titulo"

assert_contains "$qg_text" "$TRIPLE_TEXT" "AC23 quality-gates.md - el texto normativo del triple vive aca"

assert_eq "$(has_text "$plan_text" "$TRIPLE_TEXT")" "no" "AC23 sdd-plan - no recopia el texto normativo del triple"
assert_eq "$(has_text "$plan_text" "$TRIPLE_ARROW")" "no" "AC23 sdd-plan - no recopia la forma corta del triple"
assert_eq "$(has_text "$impl_text" "$TRIPLE_TEXT")" "no" "AC23 implementing-agent - no recopia el texto normativo del triple"
assert_eq "$(has_text "$impl_text" "$TRIPLE_ARROW")" "no" "AC23 implementing-agent - no recopia la forma corta del triple"
assert_eq "$(has_text "$reviewer_text" "$TRIPLE_TEXT")" "no" "AC23 reviewer-agent - no recopia el texto normativo del triple"
assert_eq "$(has_text "$reviewer_text" "$TRIPLE_ARROW")" "no" "AC23 reviewer-agent - no recopia la forma corta del triple"
assert_eq "$(has_text "$prreport_text" "$TRIPLE_TEXT")" "no" "AC23 write-pr-report - no recopia el texto normativo del triple"
assert_eq "$(has_text "$prreport_text" "$TRIPLE_ARROW")" "no" "AC23 write-pr-report - no recopia la forma corta del triple"

# =========================================================================
# AC24 — quality-gates.md declara que un diff que corrige un artefacto ya
# aprobado vuelve al loop de review.
# =========================================================================
assert_contains "$qg_text" "Correcciones posteriores a" "AC24 quality-gates.md - existe la regla de correcciones posteriores a APPROVED"
qg_post="$(grep -m1 'vuelve al loop' "$QG")"
assert_contains "$qg_post" "ya aprobado" "AC24 quality-gates.md - la regla apunta al artefacto ya aprobado"
assert_contains "$qg_post" "se revisa como el cambio original" "AC24 quality-gates.md - la correccion se revisa como el cambio original"

# =========================================================================
# Severidades en la tabla de §7.2 — fuente de verdad de las dos severidades
# nuevas de AC21, más la del hallazgo de hash distinto que el review de R5
# dejó sin nombrar (MINOR heredado, T3.2 del brief).
# =========================================================================
qg_blocker="$(grep -m1 '| `BLOCKER` |' "$QG")"
assert_contains "$qg_blocker" "sin las tres corridas" "AC21 quality-gates 7.2 - AC de deteccion sin las tres corridas es BLOCKER"
qg_major="$(grep -m1 '| `MAJOR` |' "$QG")"
assert_contains "$qg_major" "cifra reportada sin la salida" "AC21 quality-gates 7.2 - cifra reportada sin su salida es MAJOR"
assert_contains "$qg_major" "hash del doc de gates distinto" "T3.2 quality-gates 7.2 - hash del doc de gates distinto que toca una fila que corrio es MAJOR"
qg_minor="$(grep -m1 '| `MINOR` |' "$QG")"
assert_contains "$qg_minor" "ninguna fila que corrió" "T3.2 quality-gates 7.2 - hash del doc de gates distinto que no toca filas que corrieron es MINOR"

rev_hash="$(grep -m1 'Hashes distintos' "$REVIEWER")"
assert_contains "$rev_hash" "MAJOR" "T3.2 reviewer-agent - la rama de hashes distintos nombra MAJOR"
assert_contains "$rev_hash" "MINOR" "T3.2 reviewer-agent - la rama de hashes distintos nombra MINOR"

test_summary
exit $?
