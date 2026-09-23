# Task brief — v19 parte 2 · normalización en un solo recorrido (AC51) y T-SQL sin separador (AC52)

- **Agente**: `AGENT_r2` · **Modelo**: `opus` (código de seguridad: la lista blanca)
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v19**, ACs **AC51** y **AC52**
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya existe; **NO crear otra, NO commitear a `prod`**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-2.md` (nuevo)

## Problema

Leé la sección **"Cambios v18 → v19"** del contract (punto 4) y los textos de `AC51` y `AC52`.

**La fuente de los casos es `SDD/tests/fixtures/casos-adversariales-lista-blanca.js`**: la revisión adversarial de Patrick Ocampo del 23-sep, tal como él la entregó. Exporta `CASOS`, un arreglo de `[dialecto, consulta, esperado, motivo]`, donde `esperado` es `true` si la consulta tiene que **aceptarse** y `false` si tiene que **rechazarse**.

- **No lo edites**, ni copies sus consultas a otro archivo, ni las pegues en el report, ni en tu respuesta, ni en ningún commit. El test **lo carga** y recorre sus casos; el report cita cada caso **por su índice y su `motivo`**, nunca por la consulta.
- Dos veredictos del archivo parecen errores y no lo son. Patrick los explica, y el comentario del propio archivo también:
  - el caso de comentario de bloque **anidado** está marcado para **aceptarse**: hoy se rechaza por el motivo equivocado, y con el arreglo pasa a coincidir con lo que ejecuta el motor. Que cambie de rechazo a aceptación **es lo esperado**;
  - los de la sección "límite conocido" están marcados para **aceptarse** a propósito: son lo que la lista blanca no puede arreglar (contract v19, "Riesgos"), y no tienen que quedar como tests rojos permanentes.

## Files — lo único que tocás

| Archivo | Para qué |
|---|---|
| `plugins/bisalta-db/scripts/lista-blanca.js` | `AC51`: `normalizar()` pasa a ser **un solo recorrido de izquierda a derecha** que distingue literales de comilla simple (con `''` escapado), identificadores entre comillas dobles (se copian tal cual), comentarios de línea y comentarios de bloque **anidados** — la especificación está en el texto de `AC51`. `AC52`: en `sqlserver`, la lista de palabras que rechaza `AC47` suma `TRUNCATE`, `DROP`, `CREATE` y `ALTER`. **Nada más del archivo cambia**: el orden de los chequeos por sentencia y los motivos existentes se quedan |
| `SDD/tests/test_lista_blanca.sh` | un bloque nuevo que carga el archivo de casos y, **por cada caso**, verifica que el veredicto del validador coincida con `esperado`. Nombre de cada assert: `AC51/AC52 caso <índice> (<dialecto>): <motivo>`. Los asserts existentes se quedan como están |
| `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-2.md` | la evidencia |

**No tocás**: el archivo de casos, el contract, `conexion.js`, `catalogo*`, `aprovisionamiento/*`, ningún ledger, el brief de Feature Ready, el CHANGELOG.

## Pasos

- [ ] **T1** Leer el contract v19, `quality-gates.md` §5, §6 y §10, y el archivo de casos.
- [ ] **T2** **Antes de tocar el código**: correr el bloque nuevo del test contra el `lista-blanca.js` actual, y registrar **qué índices fallan** y cuál es el veredicto actual de cada uno. Es el rojo de partida, y el report lo necesita (por índice, no por consulta).
- [ ] **T3** `AC51` y `AC52` en el código. Suite completa en verde, **con los 21 casos** del archivo coincidiendo.
- [ ] **T4** Commit. Árbol limpio.
- [ ] **T5** Evidencia: el runner (`sdd-run-gates.sh -o <report> --full`) sobre el árbol limpio, y un addendum con:
  - el rojo de partida de T2 (índices y veredictos, por índice);
  - los triples de las dos mutaciones declaradas —(AC51) volver a la `normalizar()` anterior, que sacás de `git show dffb83a:plugins/bisalta-db/scripts/lista-blanca.js` (un hash fijo: `HEAD~1` cambia según en qué commit estés parado); (AC52) quitar las cuatro palabras—, con un script que **verifica que cada mutación se aplicó** (`git diff --quiet` distinto de 0), imprime el **exit code** de las tres corridas y los **índices** de los asserts que caen, restaura con `git checkout` y exige árbol limpio al final;
  - la tabla de binding AC ↔ test.
  Commit y push.

## Reglas innegociables

- **Ninguna conexión a ninguna base.**
- **Ninguna consulta del archivo de casos sale del archivo**: ni en el report, ni en commits, ni en tu respuesta. Se citan por índice y `motivo`.
- Mitigaciones prohibidas (`quality-gates.md` §6). Ninguna dependencia nueva. Bash 3.2.
- No declares una validación que no corriste.
- Si algo del contract es ambiguo, `blocked` con la pregunta. No elijas.

## Retorno

El último bloque es el JSON `sdd.result` (`plugins/sdd-flow/standards/orchestration.md` §2).

## Execution Report

(lo llenás vos)
