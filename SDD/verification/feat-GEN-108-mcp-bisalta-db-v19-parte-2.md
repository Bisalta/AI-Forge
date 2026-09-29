# Verification Report — AGENT_r2 · v19 parte 2 (normalización en un solo recorrido, T-SQL sin separador)

Evidencia de la escalera de gates (`plugins/sdd-flow/standards/quality-gates.md` §4-§5). Brief: `SDD/briefs/v19-parte-2-normalizacion-y-tsql.md`. Contract: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v19, ACs **AC51** y **AC52**.

- **Branch**: `feat-GEN-108-mcp-bisalta-db`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` v19
- **Commit evaluado**: `e6bdb25d0f520deed149d5f3fe7af4d116ca106e`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` — `sha256:56736c3e5b778ea1` (copiado del encabezado del reporte generado, no recalculado)

**Regla de este report**: ninguna consulta de `SDD/tests/fixtures/casos-adversariales-lista-blanca.js` aparece acá. Cada caso se cita por su **índice en `CASOS` (base 0)** y su `motivo`, que es el cuarto campo del caso. Las salidas que se pegan abajo son las del test, que sólo imprime índice, dialecto, motivo y exit code.

---

## Gates — evidencia GENERADA

```
bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-2-gates.md
```

- **Reporte generado**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-2-gates.md`
- **Resumen** (línea `sdd.gates` del runner, pegada tal cual): `{"type":"sdd.gates","green":4,"red":0,"skipped":7,"report":"SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-2-gates.md"}`
- Encabezado del reporte: commit `e6bdb25`, `Tree: 6650f23f75e39d8f3344d614b0ebf6101517eea5 — LIMPIO`. Exit del runner: `runner exit=0`.
- **Una corrida anterior del runner, borrada, declarada acá**: la primera corrida (mismo comando, mismo árbol) terminó con la misma línea `{"type":"sdd.gates","green":4,"red":0,"skipped":7,...}`. Pero la lancé con un pipe en un shell que no expande `PIPESTATUS`, así que su exit code no quedó registrado. Como el reporte todavía no estaba commiteado y su presencia ensuciaba el árbol, lo borré y volví a correr el runner sin pipe. No era un rojo, pero se borró un reporte, y por eso queda escrito.

---

## Rojo de partida (T2) — el bloque nuevo contra el `lista-blanca.js` anterior

Primero el bloque nuevo del test, con `lista-blanca.js` idéntico a `HEAD` (`c93ca0f`). El control previo imprimió `lista-blanca.js sin cambios vs HEAD: diff exit=0`.

```
bash SDD/tests/test_lista_blanca.sh   →   exit=1
```

Las líneas del bloque nuevo, pegadas tal cual:

```
  ok    AC51/AC52 el archivo de casos adversariales carga
  ok    AC51/AC52 el archivo de casos adversariales trae casos
  FAIL  AC51/AC52 caso 0 (postgres): comentario dentro de un literal: se quitaba ANTES que el literal (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 1 (sqlserver): idem en sqlserver (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 2 (postgres): apertura de bloque dentro de un literal (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 3 (postgres): los bloques ANIDAN en los dos motores: para el motor esto es solo SELECT 1 (exit 0) — esperado [0], obtenido [4]
  FAIL  AC51/AC52 caso 4 (sqlserver): TRUNCATE (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 5 (sqlserver): DROP (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 6 (sqlserver): CREATE (exit 4) — esperado [4], obtenido [0]
  FAIL  AC51/AC52 caso 7 (sqlserver): ALTER (exit 4) — esperado [4], obtenido [0]
  ok    AC51/AC52 caso 8 (sqlserver): el literal se borra al normalizar; el motor si lo ejecuta (exit 0)
  ok    AC51/AC52 caso 9 (postgres): idem via dblink (exit 0)
  ok    AC51/AC52 caso 10 (postgres): escribe (exit 0)
  ok    AC51/AC52 caso 11 (postgres): avanza la secuencia (exit 0)
  ok    AC51/AC52 caso 12 (postgres): no se ve adentro (exit 0)
  ok    AC51/AC52 caso 13 (postgres): lo contiene statement_timeout, no la lista (exit 0)
  ok    AC51/AC52 caso 14 (postgres): AC47 postgres (exit 4)
  ok    AC51/AC52 caso 15 (sqlserver): AC47 sqlserver (exit 4)
  ok    AC51/AC52 caso 16 (postgres): set_config (exit 4)
  ok    AC51/AC52 caso 17 (postgres): palabra dentro de un literal: NO debe rechazarse (exit 0)
  ok    AC51/AC52 caso 18 (postgres): comilla escapada (exit 0)
  ok    AC51/AC52 caso 19 (postgres): comentario de linea real (exit 0)
  ok    AC51/AC52 caso 20 (postgres): rechazo de mas a proposito: falla cerrado (exit 4)
FAIL — 8 assert(s) fallaron
```

Veredicto y motivo del validador por índice, antes y después del arreglo. Salen de un script del scratchpad que llama a `validarSql()` e imprime sólo `aceptado` y `motivo`, nunca la consulta ni el campo `sentencia`:

| Índice | Dialecto | `esperado` | Antes (`c93ca0f`) | Después (`e6bdb25`) |
|---|---|---|---|---|
| 0 | postgres | rechazar | **aceptar** | rechazar · `no_empieza_con_select_ni_with` |
| 1 | sqlserver | rechazar | **aceptar** | rechazar · `escritura_embebida` |
| 2 | postgres | rechazar | **aceptar** | rechazar · `no_empieza_con_select_ni_with` |
| 3 | postgres | aceptar | **rechazar · `escritura_embebida`** | aceptar |
| 4 | sqlserver | rechazar | **aceptar** | rechazar · `escritura_embebida` |
| 5 | sqlserver | rechazar | **aceptar** | rechazar · `escritura_embebida` |
| 6 | sqlserver | rechazar | **aceptar** | rechazar · `escritura_embebida` |
| 7 | sqlserver | rechazar | **aceptar** | rechazar · `escritura_embebida` |
| 8-13 | (ver arriba) | aceptar | aceptar | aceptar |
| 14 | postgres | rechazar | rechazar · `escritura_embebida` | rechazar · `escritura_embebida` |
| 15 | sqlserver | rechazar | rechazar · `escritura_embebida` | rechazar · `escritura_embebida` |
| 16 | postgres | rechazar | rechazar · `funcion_prohibida` | rechazar · `funcion_prohibida` |
| 17-19 | postgres | aceptar | aceptar | aceptar |
| 20 | postgres | rechazar | rechazar · `escritura_embebida` | rechazar · `escritura_embebida` |

El índice 3 pasa de rechazo a aceptación, que es lo esperado según el brief. Antes lo rechazaba `escritura_embebida` porque la normalización cerraba el bloque anidado en el primer cierre. Los controles 14-20 no cambian de veredicto ni de motivo.

---

## Resultado después del arreglo

```
bash SDD/tests/test_lista_blanca.sh   →   exit=0
ok=99 FAIL=0 casos=21
```

(`casos` cuenta las líneas `ok    AC51/AC52 caso `: los 21 del archivo coinciden con `esperado`.)

```
bash SDD/tests/run.sh   →   run.sh exit=0
---
17 passed, 0 failed (17 total)
```

```
shellcheck --severity=warning SDD/tests/test_lista_blanca.sh   →   shellcheck exit=0
```

---

## AC ↔ test binding

| AC | Comportamiento | Test | Tipo | Estado |
|---|---|---|---|---|
| AC51 | La normalización es un solo recorrido que distingue literales (con `''`), identificadores entre comillas dobles, comentarios de línea y comentarios de bloque anidados | `SDD/tests/test_lista_blanca.sh::"AC51/AC52 caso <índice> (<dialecto>): <motivo>"`. Un assert por caso del archivo. Los que la mutación de AC51 pone rojos son los índices **0, 1, 2 y 3** | unit (CLI por stdin, exit code) | [x] pass (ver "Hallazgo" abajo: la propiedad del AC no se cumple para dos construcciones que el AC no enumera) |
| AC52 | En `sqlserver`, la lista de AC47 suma `TRUNCATE`, `DROP`, `CREATE`, `ALTER` | el mismo assert por caso; la mutación de AC52 pone rojos los índices **4, 5, 6 y 7** | unit (CLI por stdin, exit code) | [x] pass |
| (guarda del bloque) | El bloque no puede quedar verde sin recorrer nada | `SDD/tests/test_lista_blanca.sh::"AC51/AC52 el archivo de casos adversariales carga"` y `::"AC51/AC52 el archivo de casos adversariales trae casos"` | unit | [x] pass |

El nombre literal en el archivo es `"AC51/AC52 caso $indice ($dialecto): $motivo"`. `assert_exit` le agrega el sufijo ` (exit N)` al imprimirlo, como en todo el harness.

---

## Prueba por mutación (AC de detección) — AC51 y AC52

Mutaciones declaradas en el contract v19:
- **AC51**: *"volver a la normalización anterior (tres reemplazos en secuencia) pone rojo al menos uno de sus casos"*. La anterior se toma de `git show dffb83a:plugins/bisalta-db/scripts/lista-blanca.js`, que es un hash fijo.
- **AC52**: *"quitar esas cuatro palabras pone rojo sus casos"*.

Script: `/private/tmp/claude-501/-Users-ian-vargas-Documents-GitHub-AI-Forge/369e3696-8032-4820-85a1-c41b707ef169/scratchpad/mutaciones-ac51-ac52.sh`. Está en el scratchpad de la sesión y no se versiona, así que el contenido va completo acá. No contiene ninguna consulta.

```bash
#!/usr/bin/env bash
# Triples de mutación de AC51 y AC52 — contract v19.
#   AC51: "volver a la normalización anterior (tres reemplazos en secuencia)
#          pone rojo al menos uno de sus casos". La anterior se toma de
#          dffb83a (hash fijo), no de HEAD~1.
#   AC52: "quitar esas cuatro palabras pone rojo sus casos".
# Imprime el exit code de cada corrida y los índices de los asserts de casos
# que caen. Nunca imprime una consulta: sólo las líneas FAIL del test, que
# citan índice y motivo.
set -u
cd /Users/ian.vargas/Documents/GitHub/AI-Forge || exit 99
ARCHIVO="plugins/bisalta-db/scripts/lista-blanca.js"
TEST="SDD/tests/test_lista_blanca.sh"
LOGS="$(mktemp -d)"

git diff --quiet && git diff --cached --quiet
echo "arbol limpio al empezar: exit=$? (0 = limpio)"

caidos() {
  # índices de los asserts de casos que cayeron, y cuántos FAIL hubo en total
  local indices
  indices="$(grep '^  FAIL  AC51/AC52 caso ' "$1" | sed 's/^  FAIL  AC51\/AC52 caso \([0-9]*\) .*/\1/' | tr '\n' ' ')"
  echo "indices caidos: [${indices% }] · FAIL totales: $(grep -c '^  FAIL' "$1")"
}

triple() {
  local nombre="$1" mutar="$2"
  echo
  echo "===== $nombre ====="
  bash "$TEST" >"$LOGS/$nombre-1.log" 2>&1; local ec1=$?
  echo "1) intacto            -> bash $TEST : exit=$ec1"

  node -e "$mutar" "$ARCHIVO"; local ecm=$?
  git diff --quiet -- "$ARCHIVO"; local ecd=$?
  echo "   mutación aplicada   -> node exit=$ecm · git diff --quiet exit=$ecd (distinto de 0 = aplicada)"
  if [ "$ecd" -eq 0 ]; then
    echo "   ABORTO: la mutación no cambió el archivo"; git checkout -- "$ARCHIVO"; exit 98
  fi

  bash "$TEST" >"$LOGS/$nombre-2.log" 2>&1; local ec2=$?
  echo "2) con la mutación    -> bash $TEST : exit=$ec2"
  echo "   $(caidos "$LOGS/$nombre-2.log")"

  git checkout -- "$ARCHIVO"
  git diff --quiet -- "$ARCHIVO"; local ecr=$?
  echo "   revertida           -> git checkout · git diff --quiet exit=$ecr (0 = revertida)"

  bash "$TEST" >"$LOGS/$nombre-3.log" 2>&1; local ec3=$?
  echo "3) revertida          -> bash $TEST : exit=$ec3"
  echo "RESUMEN $nombre: verde1=$ec1 aplicada=$ecd rojo=$ec2 revertida=$ecr verde2=$ec3"
}

# AC51: reemplaza la normalizar() actual por la de dffb83a.
ANTERIOR="$(git show dffb83a:"$ARCHIVO")"
export ANTERIOR
MUTAR_AC51='
  var fs = require("fs"), p = process.argv[1];
  function funcion(txt) {
    var ini = txt.indexOf("function normalizar(sql) {");
    var fin = txt.indexOf("\n}\n", ini) + 3;
    if (ini < 0 || fin < 3) { process.exit(3); }
    return [ini, fin];
  }
  var actual = fs.readFileSync(p, "utf8"), vieja = process.env.ANTERIOR + "\n";
  var a = funcion(actual), v = funcion(vieja);
  fs.writeFileSync(p, actual.slice(0, a[0]) + vieja.slice(v[0], v[1]) + actual.slice(a[1]));
'
triple AC51 "$MUTAR_AC51"

# AC52: quita las cuatro palabras de la lista de sqlserver.
MUTAR_AC52='
  var fs = require("fs"), p = process.argv[1];
  var s = fs.readFileSync(p, "utf8"), viejo = "|INTO|TRUNCATE|DROP|CREATE|ALTER)";
  if (s.split(viejo).length !== 2) { process.exit(3); }
  fs.writeFileSync(p, s.replace(viejo, "|INTO)"));
'
triple AC52 "$MUTAR_AC52"

echo
git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]
EC_FINAL=$?
echo "arbol limpio al terminar: exit=$EC_FINAL (0 = limpio)"
rm -rf "$LOGS"
exit "$EC_FINAL"
```

Salida completa de la corrida del 23-sep-2026, sobre el commit `e6bdb25` con árbol limpio, pegada tal cual:

```
arbol limpio al empezar: exit=0 (0 = limpio)

===== AC51 =====
1) intacto            -> bash SDD/tests/test_lista_blanca.sh : exit=0
   mutación aplicada   -> node exit=0 · git diff --quiet exit=1 (distinto de 0 = aplicada)
2) con la mutación    -> bash SDD/tests/test_lista_blanca.sh : exit=1
   indices caidos: [0 1 2 3] · FAIL totales: 4
   revertida           -> git checkout · git diff --quiet exit=0 (0 = revertida)
3) revertida          -> bash SDD/tests/test_lista_blanca.sh : exit=0
RESUMEN AC51: verde1=0 aplicada=1 rojo=1 revertida=0 verde2=0

===== AC52 =====
1) intacto            -> bash SDD/tests/test_lista_blanca.sh : exit=0
   mutación aplicada   -> node exit=0 · git diff --quiet exit=1 (distinto de 0 = aplicada)
2) con la mutación    -> bash SDD/tests/test_lista_blanca.sh : exit=1
   indices caidos: [4 5 6 7] · FAIL totales: 4
   revertida           -> git checkout · git diff --quiet exit=0 (0 = revertida)
3) revertida          -> bash SDD/tests/test_lista_blanca.sh : exit=0
RESUMEN AC52: verde1=0 aplicada=1 rojo=1 revertida=0 verde2=0

arbol limpio al terminar: exit=0 (0 = limpio)
script exit=0
```

| AC | # | Estado del sistema | Comando | Exit | Asserts de casos que caen |
|---|---|---|---|---|---|
| AC51 | 1 | intacto | `bash SDD/tests/test_lista_blanca.sh` | 0 | — |
| AC51 | 2 | `normalizar()` de `dffb83a` (`git diff --quiet` exit 1) | `bash SDD/tests/test_lista_blanca.sh` | 1 | 0, 1, 2, 3 (4 FAIL en total: ningún assert fuera de los casos) |
| AC51 | 3 | revertida con `git checkout` (`git diff --quiet` exit 0) | `bash SDD/tests/test_lista_blanca.sh` | 0 | — |
| AC52 | 1 | intacto | `bash SDD/tests/test_lista_blanca.sh` | 0 | — |
| AC52 | 2 | sin `TRUNCATE`, `DROP`, `CREATE`, `ALTER` (`git diff --quiet` exit 1) | `bash SDD/tests/test_lista_blanca.sh` | 1 | 4, 5, 6, 7 (4 FAIL en total) |
| AC52 | 3 | revertida con `git checkout` (`git diff --quiet` exit 0) | `bash SDD/tests/test_lista_blanca.sh` | 0 | — |

Los dos rojos no se pisan: la mutación de AC51 no toca ningún caso de AC52, ni al revés. Cada triple es distinguible, y ningún rojo viene de otro assert que se haya roto por el camino.

---

## Hallazgo — la propiedad de AC51 no se cumple para dos construcciones que el AC no enumera

AC51 fija una propiedad (*"de modo que el validador ve las mismas sentencias que ejecuta el motor"*) y enumera cuatro construcciones (literales, identificadores entre comillas dobles, comentarios de línea, comentarios de bloque anidados). Leyendo el código armé cuatro sondas propias. **No son del archivo de Patrick.** Corrieron sólo contra el validador y no contra un motor: el comportamiento del motor que se describe sale de las reglas de su lexer, **sin medir**. Viven en el scratchpad y no se commitean. Acá van descritas por su forma, no como consultas listas para usar.

| Sonda | Dialecto | Forma | Antes (`dffb83a`) | Después (`e6bdb25`) | Qué ejecutaría el motor (no medido) |
|---|---|---|---|---|---|
| A | postgres | literal con prefijo `E` (escape string) con `\'` adentro, seguido de `;`, una escritura y un comentario de línea que termina en comilla simple | rechazar · `no_empieza_con_select_ni_with` | **aceptar** | Para el motor, `\'` escapa la comilla y el literal cierra después. La escritura queda como segunda sentencia. El validador cierra el literal antes, y toma como literal justo el tramo donde está la escritura |
| B | postgres | igual que A, sin el comentario final | rechazar · `no_empieza_con_select_ni_with` | rechazar · `no_empieza_con_select_ni_with` | Igual que A. La salva que un literal sin cerrar deja el resto a la vista (ver abajo) |
| C | sqlserver | identificador entre corchetes con una comilla simple adentro, seguido de una escritura y de un comentario de línea que contiene la comilla y el corchete de cierre | rechazar · `escritura_embebida` | **aceptar** | Para T-SQL la comilla dentro de `[…]` es parte del nombre, así que la escritura es código. El validador abre un literal en esa comilla y lo cierra en la del comentario |
| D | sqlserver | identificador entre corchetes con `--` adentro, seguido de una escritura | aceptar | aceptar | Para T-SQL el `--` dentro de `[…]` es parte del nombre. El validador lo toma como comentario. **Ya pasaba antes del arreglo** |

- **A y C son regresiones de este cambio**: el código anterior las rechazaba, pero por accidente, porque el orden de los reemplazos dejaba la escritura a la vista.
- **D es preexistente.**
- Por qué no las arreglo: el AC enumera *"identificadores entre comillas dobles"*, no corchetes, y *"literales"* sin mencionar el prefijo `E`. El brief especifica *"literales de comilla simple (con `''` escapado)"*. Sumar las dos construcciones cierra una decisión que el contract no tomó, y el contract ya clasificó cada hallazgo de Patrick en "se arregla" o "límite conocido". Esa clasificación la tiene que hacer el planner, no yo.
- Detrás siguen en pie las mismas barreras que el contract v19 punto 4 describe (en Postgres la sesión de solo lectura, la réplica comprobada por AC46 y el rol; en SQL Server el privilegio). La lista blanca es la primera capa, no la que impide el daño.

### Decisión que tomé y que el planner tiene que ratificar: construcción sin cerrar

Un literal de comilla simple o un comentario de bloque **sin cerrar** deja el resto del texto a la vista, sin normalizar. No lo extendí hasta el final del texto, que es lo que haría un lexer. Mis razones: así se comportaban los reemplazos anteriores (sin cierre, la regex no encontraba nada), el header del archivo declara "falla cerrado", y el motor rechaza por sintaxis una construcción sin cerrar, así que ocultarla no le sirve a ninguna consulta legítima. Con la otra opción la sonda B pasaba a aceptarse. Ningún caso del archivo de Patrick ejercita esta rama, así que **no tiene test**: queda como pregunta al planner en el `sdd.result`.

---

## Impact set

| Símbolo cambiado | Callers (`grep -rn -e normalizar -e validarSql -e lista-blanca -e ESCRITURA_EMBEBIDA plugins SDD/tests SDD/scripts`, sin `.md`) | Cobertura |
|---|---|---|
| `normalizar()` (exportada) | sólo `validarSql()`, en el mismo archivo. Ningún otro archivo la importa | `test_lista_blanca.sh` completo (AC15-AC22, AC47, AC51/AC52), exit 0 |
| `validarSql()`: firma y forma de retorno sin cambios | `plugins/bisalta-db/scripts/servidor-mcp.js:162` | `SDD/tests/test_servidor_mcp.sh` (la lista blanca corre en el servidor antes de conectar, líneas 546-554), dentro de `bash SDD/tests/run.sh` → `17 passed, 0 failed (17 total)` |
| `ESCRITURA_EMBEBIDA_SQLSERVER` (nueva, no exportada) | sólo `validarSql()` | casos 4-7 y 15, más AC47 sqlserver |

`ESCRITURA_EMBEBIDA` (AC47) no cambió. En `sqlserver` la reemplaza la lista extendida, que contiene sus cinco palabras.

## Rojos preexistentes de la base

En `test_lista_blanca.sh`, ninguno. En la corrida T2 sobre la base, los ocho FAIL fueron todos asserts del bloque nuevo (índices 0-7, pegados arriba: `FAIL — 8 assert(s) fallaron`), y todos los asserts preexistentes del archivo dieron `ok`. **La suite completa no la corrí sobre la base antes del cambio**, así que para los otros 16 archivos no afirmo nada sobre la base. Sobre `e6bdb25` está verde (`17 passed, 0 failed`).

## Smoke manual

N/A: AC51 y AC52 no son `manual-only`. **Ninguna conexión a ninguna base** en esta tarea.
