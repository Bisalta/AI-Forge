#!/usr/bin/env bash
# SDD/tests/test_analysis_archetype.sh — AC25 a AC28 + AC42 del contract R4
# (SDD/contracts/2026-08-13-sicop-hardening.md v7): décimo arquetipo
# `analysis`, y el guard de `.md` que le faltaba a la regla de supresores de
# `sdd-check.sh`.
#
# AC25-AC28 son "verificable con grep" en el contract — mismo tratamiento que
# AC19-AC24 en test_mutation_rule.sh: se leen los archivos normativos REALES
# del árbol (nunca una copia ni una transcripción) y se assertea su contenido.
#
# AC42 vive en este archivo, y no en uno propio, porque el contract lo agrega
# a la sección R4 en v7 y la tabla de Files del brief declara UN test nuevo.
# Su verificación no es un grep: monta un repo git de usar y tirar y corre el
# `sdd-check.sh` real contra un diff sintético, que es la única forma de
# medir lo que el script hace sin depender del diff de esta branch.
#
# Corrida contra el estado SIN el cambio: tiene que salir en rojo — no existe
# todavía la sección `analysis` en archetypes.md, `enrich-user-story` lista
# nueve arquetipos, y la regla de supresores de sdd-check.sh dispara sobre
# archivos `.md`.
#
# --- Sobre AC28 (AC de DETECCIÓN, forma "sensibilidad" de §10.1) -----------
# AC28 afirma que dos conteos coinciden. Un test que cuenta MAL las dos listas
# de la misma forma equivocada da verde igual, y sigue dando verde el día que
# alguien agrega un arquetipo a un solo lado. Por eso los dos conteos se miden
# con mecanismos INDEPENDIENTES —encabezados `## \`nombre\`` en archetypes.md
# contra los tokens de la lista en línea de la dimensión 7 de
# enrich-user-story— y además de los conteos se comparan los NOMBRES
# ordenados: la igualdad de conjuntos también atrapa un rename en un solo
# lado, que la igualdad de conteos deja pasar. El valor esperado `10` está
# fijo y escrito, así que "las dos mal de la misma forma" tampoco pasa.
# Prueba por mutación registrada en el verification report.
#
# --- Sobre AC42 (AC de DETECCIÓN, forma "rechazo" de §10.1) ---------------
# El guard apaga la regla de supresores sobre archivos `.md`. El riesgo de un
# guard es que apague de más, así que el caso positivo (un supresor en un
# archivo de código SIGUE siendo BLOCKER) se assertea explícitamente: sin él,
# borrar la regla entera daría verde y el "fix" sería un ablandamiento
# disfrazado (T4.3 del brief).
#
# Límite conocido y declarado del guard: un supresor real dentro de un bloque
# de código embebido en un `.md` deja de detectarse. Es el mismo trade-off que
# la regla del flag de bypass de hooks ya toma en ese script desde antes de
# este cambio; el contract R4 lo ratifica para la regla de supresores.
#
# Los literales de supresor se arman EN TIEMPO DE EJECUCIÓN a partir de piezas
# bash separadas (misma convención que `plant_kv` en test_secret_scan.sh): si
# quedaran contiguos en este archivo fuente, `sdd-check.sh` levantaría un
# BLOCKER sobre este propio test — que es un `.sh`, no un `.md`, y por lo
# tanto fuera del guard que AC42 agrega.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ARCH="$REPO_ROOT/plugins/sdd-flow/standards/archetypes.md"
ENRICH="$REPO_ROOT/plugins/sdd-flow/skills/enrich-user-story/SKILL.md"
PLAN="$REPO_ROOT/plugins/sdd-flow/skills/sdd-plan/SKILL.md"
PLUGIN_README="$REPO_ROOT/plugins/sdd-flow/README.md"
SDD_CHECK="$REPO_ROOT/plugins/sdd-flow/scripts/sdd-check.sh"

for required in "$ARCH" "$ENRICH" "$PLAN" "$PLUGIN_README" "$SDD_CHECK"; do
  if [ ! -f "$required" ]; then
    echo "  FAIL  setup — no existe $required"
    exit 1
  fi
done

# has_text <texto> <literal> — imprime "si"/"no" según substring literal.
# lib.sh define assert_contains (presencia) pero no un assert de AUSENCIA, y
# el Reuse statement del contract R0 prohíbe que un test_*.sh defina asserts
# propios: esta función no assertea nada, produce el valor que después compara
# assert_eq — la misma forma que test_mutation_rule.sh y test_doc_hash.sh.
has_text() {
  case "$1" in
    *"$2"*) printf 'si\n' ;;
    *) printf 'no\n' ;;
  esac
}

# section_of <archivo> <nombre-arquetipo> — imprime SOLO la sección
# `## \`<nombre>\`` de archetypes.md, desde su encabezado hasta el siguiente
# `## ` o el `---` que cierra el bloque de arquetipos.
#
# Por qué no alcanza con grepear el archivo entero: los otros nueve
# arquetipos ya contienen "NFR obligatorias", "Tests exigidos" y
# "Checklist → ACs", así que un assert sobre todo el archivo daría verde SIN
# la sección nueva. Los asserts de AC25/AC26 corren sobre este recorte.
section_of() {
  awk -v name="$2" '
    BEGIN { hdr = "^## `" name "`" }
    /^## / { if (f) exit; if ($0 ~ hdr) f = 1 }
    f && /^---$/ { exit }
    f { print }
  ' "$1"
}

# checklist_of <texto-de-seccion> — imprime los ítems del bloque
# "- **Checklist → ACs**:" de una sección, sin el resto de las viñetas.
checklist_of() {
  printf '%s\n' "$1" | awk '
    /^- \*\*Checklist/ { f = 1; next }
    f && /^- \*\*/ { exit }
    f { print }
  '
}

# line_of <archivo> <patron-ere> — número de línea de la primera coincidencia,
# o 0 si no hay ninguna. Sirve para assertear POSICIÓN, no sólo presencia.
line_of() {
  n="$(grep -nE -m1 "$2" "$1" | cut -d: -f1)"
  [ -n "$n" ] || n=0
  printf '%s\n' "$n"
}

analysis_section="$(section_of "$ARCH" "analysis")"
analysis_checklist="$(checklist_of "$analysis_section")"

# =========================================================================
# AC25 — archetypes.md contiene la sección `analysis` con las tres partes que
# tienen los otros nueve: NFR obligatorias, tests exigidos y checklist→ACs.
# Los tres asserts corren sobre el RECORTE de la sección, no sobre el archivo.
# =========================================================================
assert_contains "$analysis_section" '## `analysis`' "AC25 archetypes.md - existe la seccion del arquetipo analysis"
assert_contains "$analysis_section" "- **NFR obligatorias**:" "AC25 archetypes.md - la seccion analysis declara sus NFR obligatorias"
assert_contains "$analysis_section" "- **Tests exigidos**:" "AC25 archetypes.md - la seccion analysis declara los tests exigidos"
assert_contains "$analysis_section" "- **Checklist → ACs**:" "AC25 archetypes.md - la seccion analysis tiene el checklist que entra como ACs"

# Las dos NFR obligatorias que el contract fija para este arquetipo.
nfr_line="$(printf '%s\n' "$analysis_section" | grep -m1 -- '- \*\*NFR obligatorias\*\*:')"
assert_contains "$nfr_line" '`observability`' "AC25 archetypes.md - observability es NFR obligatoria del arquetipo analysis"
assert_contains "$nfr_line" '`data-privacy`' "AC25 archetypes.md - data-privacy es NFR obligatoria cuando el dataset tiene PII"

# Los tests exigidos: el test que falsaría la conclusión + la re-derivación.
tests_line="$(printf '%s\n' "$analysis_section" | grep -m1 -- '- \*\*Tests exigidos\*\*:')"
# El literal lleva el énfasis que el contract le pone a la palabra: el texto
# normativo es `que **falsaría** la conclusión`, no `que falsaría la
# conclusión`. Se corrige el assert al texto real del contract, no al revés.
assert_contains "$tests_line" 'que **falsaría** la conclusión' "AC25 archetypes.md - los tests exigidos incluyen el test que falsaria la conclusion"
assert_contains "$tests_line" "re-derivación de cada cifra citada" "AC25 archetypes.md - los tests exigidos incluyen la re-derivacion de cada cifra citada"

# Posición declarada en el Architectural Delta: entre `infra` y "Cómo lo usa
# el pipeline". Se assertea con números de línea, no a ojo.
ln_infra="$(line_of "$ARCH" '^## `infra`')"
ln_analysis="$(line_of "$ARCH" '^## `analysis`')"
ln_pipeline="$(line_of "$ARCH" '^## Cómo lo usa el pipeline')"
if [ "$ln_analysis" -gt "$ln_infra" ] && [ "$ln_analysis" -lt "$ln_pipeline" ] && [ "$ln_infra" -gt 0 ]; then
  pos="ok"
else
  pos="fuera-de-lugar (infra=$ln_infra analysis=$ln_analysis pipeline=$ln_pipeline)"
fi
assert_eq "$pos" "ok" "AC25 archetypes.md - la seccion analysis va entre infra y Como lo usa el pipeline"

# =========================================================================
# AC26 — la sección incluye los SIETE ítems del contenido normativo, y
# exactamente siete: un ítem de más o de menos rompe el conteo.
# Cada ítem se assertea por su texto, dentro del bloque de checklist.
# =========================================================================
checklist_count="$(printf '%s\n' "$analysis_checklist" | grep -c '^  - ')"
assert_eq "$checklist_count" "7" "AC26 archetypes.md - el checklist del arquetipo analysis tiene exactamente siete items"

assert_contains "$analysis_checklist" "Hipótesis nula declarada antes de mirar el resultado" "AC26 item 1 - hipotesis nula declarada antes de mirar el resultado"
assert_contains "$analysis_checklist" "El test que falsaría la conclusión, nombrado y corrido" "AC26 item 2 - el test que falsaria la conclusion nombrado y corrido"
assert_contains "$analysis_checklist" "su resultado se reporta gane o pierda" "AC26 item 2 - el resultado se reporta gane o pierda"
assert_contains "$analysis_checklist" "Toda cifra re-derivada desde la fuente, con la salida de la consulta adjunta" "AC26 item 3 - toda cifra re-derivada desde la fuente con la salida adjunta"
assert_contains "$analysis_checklist" "Sensibilidad declarada: qué pasa con la conclusión al excluir las filas defectuosas" "AC26 item 4 - sensibilidad al excluir las filas defectuosas"
assert_contains "$analysis_checklist" "si las exclusiones se concentran en pocas unidades" "AC26 item 4 - si las exclusiones se concentran en pocas unidades"
# Ítems 5 y 6 — redacción de v8. La de v1-v7 era autosatisfacible por el error
# que el ítem previene (ronda 1 de R4), así que además del texto nuevo se
# assertea la AUSENCIA del viejo: una reescritura que deja las dos redacciones
# conviviendo deja el ítem tan ambiguo como antes.
#
# Los dos asserts de ausencia NO son tautológicos, y está medido: las dos
# frases viejas existían en el árbol hasta la ronda 2, así que estos asserts
# salen rojos contra el estado anterior. Queda en el verification report.
assert_contains "$analysis_checklist" "Unidad de análisis y unidad de agrupamiento declaradas, con el número de grupos" "AC26 item 5 - unidad de analisis Y unidad de agrupamiento declaradas con el numero de grupos"
assert_contains "$analysis_checklist" "la inferencia se hace a nivel del grupo" "AC26 item 5 - cuando las observaciones se agrupan la inferencia va a nivel del grupo"
assert_contains "$analysis_checklist" "el reporte nombra la técnica usada" "AC26 item 5 - el reporte nombra la tecnica usada"
assert_eq "$(has_text "$analysis_checklist" "Unidad de análisis declarada, y el test a esa unidad")" "no" "AC26 item 5 - la redaccion vieja autosatisfacible ya no esta"

assert_contains "$analysis_checklist" "Tamaño de muestra (filas y grupos) y tamaño de efecto mínimo detectable declarados" "AC26 item 6 - tamano de muestra en filas y grupos y efecto minimo detectable"
assert_contains "$analysis_checklist" "contra qué efecto, a qué α y a qué potencia" "AC26 item 6 - el numero se declara contra un efecto, un alfa y una potencia"
assert_contains "$analysis_checklist" "La potencia calculada con el efecto observado no cuenta" "AC26 item 6 - la potencia observada no cuenta"
assert_eq "$(has_text "$analysis_checklist" "Tamaño de muestra y potencia declarados, con el número")" "no" "AC26 item 6 - la redaccion vieja sin tamano de efecto ya no esta"
assert_contains "$analysis_checklist" "La conclusión se escribe con su incertidumbre, no como afirmación categórica" "AC26 item 7 - la conclusion se escribe con su incertidumbre"

# =========================================================================
# AC27 — enrich-user-story/SKILL.md incluye `analysis` en la lista de
# arquetipos de su dimensión 7. Se lee la LÍNEA de la dimensión, no el
# archivo entero: la palabra "analysis" puede aparecer en cualquier prosa.
# =========================================================================
dim7_line="$(grep -m1 'Exactamente uno:' "$ENRICH")"
assert_contains "$dim7_line" "analysis" "AC27 enrich-user-story - la dimension 7 lista el arquetipo analysis"

# La rama de preguntas NFR que el arquetipo dispara (T2.2 del brief).
assert_contains "$(cat "$ENRICH")" "reproducible por otro" "AC27 enrich-user-story - observability del arquetipo analysis es que la corrida sea reproducible por otro"

# =========================================================================
# AC28 (AC de DETECCIÓN — forma "sensibilidad") — el total declarado en
# archetypes.md y en enrich-user-story coincide: diez en ambos.
#
# Dos mecanismos independientes de conteo + comparación de nombres. Ver la
# nota del encabezado.
# =========================================================================
arch_count="$(grep -c '^## `' "$ARCH")"
arch_names="$(grep '^## `' "$ARCH" | sed 's/^## `\([^`]*\)`.*/\1/' | sort | tr '\n' ' ')"

dim7_list="$(printf '%s\n' "$dim7_line" | sed 's/.*Exactamente uno: `\([^`]*\)`.*/\1/')"
enrich_count="$(printf '%s\n' "$dim7_list" | awk -F' · ' '{print NF}')"
enrich_names="$(printf '%s\n' "$dim7_list" | awk -F' · ' '{for (i = 1; i <= NF; i++) print $i}' | sort | tr '\n' ' ')"

assert_eq "$arch_count" "10" "AC28 archetypes.md - declara diez arquetipos"
assert_eq "$enrich_count" "10" "AC28 enrich-user-story - la dimension 7 lista diez arquetipos"
assert_eq "$arch_count" "$enrich_count" "AC28 - el total de arquetipos coincide entre archetypes.md y enrich-user-story"
assert_eq "$arch_names" "$enrich_names" "AC28 - las dos listas nombran exactamente los mismos diez arquetipos"

# Impact set (fuera de AC28, que nombra dos archivos): el README del plugin
# es la TERCERA declaración de la lista y trae el total escrito con letra.
readme_line="$(grep -m1 'arquetipos (' "$PLUGIN_README")"
assert_contains "$readme_line" "10 arquetipos" "IMPACT plugin README - el total de arquetipos declarado es diez"
assert_contains "$readme_line" "analysis" "IMPACT plugin README - la lista de arquetipos incluye analysis"

# =========================================================================
# T2.3 — sdd-plan/SKILL.md: el binding AC↔test admite la forma de evidencia
# del arquetipo `analysis` (salida de la consulta que re-deriva la cifra y
# corrida del test estadístico), no sólo un test unitario.
# =========================================================================
plan_text="$(cat "$PLAN")"
plan_evid="$(grep -m1 'arquetipo `analysis`' "$PLAN")"
assert_contains "$plan_evid" "binding" "T2.3 sdd-plan - la regla habla del binding AC-test del arquetipo analysis"
assert_contains "$plan_text" "la salida de la consulta que re-deriva la cifra" "T2.3 sdd-plan - la evidencia admite la salida de la consulta que re-deriva la cifra"
assert_contains "$plan_text" "la corrida del test estadístico que falsaría la conclusión" "T2.3 sdd-plan - la evidencia admite la corrida del test estadistico"

# =========================================================================
# AC42 (AC de DETECCIÓN — forma "rechazo") — sdd-check.sh no levanta BLOCKER
# de supresor sobre un archivo `.md`, y SIGUE levantándolo sobre código.
#
# Repo git de usar y tirar bajo SDD/tests/.tmp/ (gitignoreado), con un commit
# base contra el que sdd-check.sh diffea. Nunca este repo.
# =========================================================================
TMP_DIR="$SCRIPT_DIR/.tmp/test_analysis_archetype-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$TMP_DIR"
git init -q "$TMP_DIR"
printf 'fixture de test_analysis_archetype.sh\n' > "$TMP_DIR/doc.md"
printf 'export const x = 1;\n' > "$TMP_DIR/code.ts"
(
  cd "$TMP_DIR" &&
    git add -A &&
    git -c user.name=sdd-test -c user.email=sdd-test@example.invalid \
      commit -q -m "base del fixture"
)
BASE_SHA="$(cd "$TMP_DIR" && git rev-parse HEAD)"

TAB="$(printf '\t')"

# Literales de supresor armados en runtime — ver la nota del encabezado.
SUP_TS="$(printf '%s%s' '@ts-' 'ignore')"
SUP_ESLINT="$(printf '%s%s' 'eslint-' 'disable')"

run_check() { ( cd "$TMP_DIR" && bash "$SDD_CHECK" "$BASE_SHA" 2>&1 ); }

# reset_fixture — devuelve doc.md y code.ts al commit base, para que cada caso
# tenga su propio diff y ninguno herede el hallazgo del anterior. Sin esto, el
# exit code de un caso lo decide el hallazgo del caso previo y los
# `assert_exit` dejan de medir lo que dicen medir.
reset_fixture() { ( cd "$TMP_DIR" && git checkout -q -- . ); }

# --- caso 1: el supresor aparece SOLO en un archivo `.md` -----------------
# Es el caso que el reviewer midió sobre el repo real: `sdd-check.sh` salía 2
# por el `@ts-`+`ignore` que enumera las mitigaciones PROHIBIDAS en
# commands/sdd-fixes.md, sobre un texto que existía desde antes del diff.
reset_fixture
printf 'Mitigaciones prohibidas: %s y %s no se usan para pasar un gate.\n' "$SUP_TS" "$SUP_ESLINT" >> "$TMP_DIR/doc.md"

out_md="$(run_check)"; ec_md=$?
assert_eq "$(has_text "$out_md" "${TAB}doc.md${TAB}supresor${TAB}")" "no" "AC42 sdd-check.sh - no reporta supresor sobre un archivo .md"
assert_exit 0 "$ec_md" "AC42 sdd-check.sh - sale 0 cuando el unico supresor del diff esta en un .md"

# --- caso 2: el mismo supresor en un archivo de código sigue siendo BLOCKER
# T4.3 del brief: sin este caso, borrar la regla entera daría verde y el fix
# sería un ablandamiento disfrazado de guard.
reset_fixture
printf '// %s\nexport const y = 2;\n' "$SUP_TS" >> "$TMP_DIR/code.ts"

out_code="$(run_check)"; ec_code=$?
assert_contains "$out_code" "BLOCKER${TAB}code.ts${TAB}supresor${TAB}" "AC42 sdd-check.sh - un supresor en un archivo de codigo sigue siendo BLOCKER"
assert_exit 2 "$ec_code" "AC42 sdd-check.sh - sale 2 cuando hay un supresor en un archivo de codigo"

# --- caso 3 (v8): el MISMO hueco en la regla `test-skipeado` -------------
# Dirección 1 — la prosa normativa que enumera lo prohibido no es un test
# skipeado. Medido en la ronda 1 sobre este repo: 2 hits, en
# standards/quality-gates.md §6.1 y templates/doc_quality_gates.md.
SKIP_LITERAL="$(printf '%s%s' 'it.' 'skip(')"
reset_fixture
printf 'Prohibido en §6.1: %s"caso") y sus variantes.\n' "$SKIP_LITERAL" >> "$TMP_DIR/doc.md"

out_skip_md="$(run_check)"; ec_skip_md=$?
assert_eq "$(has_text "$out_skip_md" "${TAB}doc.md${TAB}test-skipeado${TAB}")" "no" "AC42 sdd-check.sh - no reporta test-skipeado sobre un archivo .md"
assert_exit 0 "$ec_skip_md" "AC42 sdd-check.sh - sale 0 cuando el unico test skipeado del diff esta en un .md"

# Dirección 2 — un test REALMENTE skipeado en un archivo de código sigue
# siendo BLOCKER. Sin esta mitad, el guard es un ablandamiento disfrazado:
# apagar la regla entera daría verde en la dirección 1.
reset_fixture
printf '%s"no corre", () => {});\n' "$SKIP_LITERAL" >> "$TMP_DIR/code.ts"

out_skip_code="$(run_check)"; ec_skip_code=$?
assert_contains "$out_skip_code" "BLOCKER${TAB}code.ts${TAB}test-skipeado${TAB}" "AC42 sdd-check.sh - un test skipeado en un archivo de codigo sigue siendo BLOCKER"
assert_exit 2 "$ec_skip_code" "AC42 sdd-check.sh - sale 2 cuando hay un test skipeado en un archivo de codigo"

# --- caso 4: el guard es de DOS REGLAS, no del archivo `.md` entero ------
# La forma barata de "arreglar" AC42 es saltear los archivos `.md` antes de
# evaluar ninguna regla. Con eso, todos los asserts de arriba pasan igual y el
# checker se vuelve ciego a la prosa. Este caso lo distingue: un `catch`
# silencioso agregado en un `.md` SIGUE reportándose (WARN, sin cambiar el
# exit code), que es la prueba de que las líneas del `.md` se siguen leyendo.
CATCH_LITERAL="$(printf '%s%s' 'catch (e) {' '}')"
reset_fixture
printf 'Ejemplo de lo que no se hace: try { f() } %s\n' "$CATCH_LITERAL" >> "$TMP_DIR/doc.md"

out_warn="$(run_check)"; ec_warn=$?
assert_contains "$out_warn" "WARN${TAB}doc.md${TAB}catch-silencioso${TAB}" "AC42 sdd-check.sh - el guard no saltea el archivo .md entero, solo las dos reglas"
assert_exit 0 "$ec_warn" "AC42 sdd-check.sh - un WARN sobre .md no cambia el exit code"

# --- caso 5: los dos literales prohibidos juntos en prosa normativa ------
# Es la forma exacta en que aparece en el repo real: un documento que enumera
# supresores Y tests skipeados en la misma lista de mitigaciones prohibidas.
reset_fixture
printf 'Mitigaciones prohibidas: %s, %s, %s"caso").\n' "$SUP_TS" "$SUP_ESLINT" "$SKIP_LITERAL" >> "$TMP_DIR/doc.md"

out_both="$(run_check)"; ec_both=$?
assert_eq "$(has_text "$out_both" "BLOCKER${TAB}doc.md")" "no" "AC42 sdd-check.sh - la prosa que enumera las mitigaciones prohibidas no levanta ningun BLOCKER"
assert_exit 0 "$ec_both" "AC42 sdd-check.sh - sale 0 sobre un .md que enumera supresores y tests skipeados"

test_summary
exit $?
