# Pendiente para una persona — hallazgos de la review de v19 y v20 sobre `AC51`

Estos hallazgos de la review §7.5 de v19 y v20 (ronda 1, `REJECTED`, 24-sep-2026) tocan la lista blanca, y **ningún agente de este ciclo los puede hacer**: el filtro de seguridad corta ese trabajo (`SDD/retro.md` `RT54`). Lo demás de esa review ya está cerrado en el contract **v21** (`d63a83b`).

Cuando estén hechos, se sube el contract a **v22**, porque cambian condiciones de aprobación de `AC51` (regla de v18), y se pide una ronda 2 de review. El planner puede hacer ese bump y lanzar la review, que ya no requiere tocar la lista blanca.

## 1. Contract — `SDD/contracts/2026-09-18-bisalta-db-mcp.md`, texto de `AC51`

- **Autoría de los casos.** La frase *"más los que `AGENT_r2` escribe para las reglas de v20 y para la construcción sin cerrar"* es falsa: `AGENT_r2` no escribió ninguno. Reemplazarla por *"más los 21 de Patrick Ocampo en `SDD/tests/fixtures/casos-adversariales-v20.js`"*.
- **Mutación (a).** Tal como está escrita no aplica, porque `normalizar()` cambió de firma y ahora devuelve un objeto. Declarar que se aplica con un adaptador que envuelve la versión vieja: `{ texto: normalizarVieja(sql), sinCerrar: null }`. La review la corrió así, y cae.
- **Mutación (c), abierta en parte.** La review midió que, con la regla de los corchetes apagada, cae un solo caso, y es el mismo que cae con la (d). Declararla **abierta en parte**, igual que la (b), o pedirle a Patrick que confirme que ese caso es el que tiene que matarla.
- **Corrección del fixture.** Declarar que en `0358e73` se corrigió el texto descriptivo (`motivo`) del caso 0 de `casos-adversariales-v20.js`: tenía comillas simples sin escapar y el archivo no cargaba. La consulta de ese caso no se tocó.

## 2. Test — `SDD/tests/test_lista_blanca.sh`

- **Assert del tipo en el motivo.** Hoy el recorrido de los archivos de casos sólo mira el exit code, así que ningún test verifica que el motivo sea `construccion_sin_cerrar_literal`, `…_identificador` o `…_comentario`, que es lo que pide `AC51`. Para los casos de construcción sin cerrar de `CASOS_V20` (según la review, los índices 12 a 16), assertar el **tipo exacto** leyendo **sólo el campo `motivo`** de la salida JSON del validador, nunca el campo `sentencia`. Conviene derivar el tipo esperado de la descripción del caso en el archivo, en vez de fijar índices a mano: el archivo es de Patrick y puede crecer.

## 3. Evidencia — un report nuevo, `SDD/verification/feat-GEN-108-mcp-bisalta-db-v22.md`

Sobre el árbol ya corregido, en un report nuevo, sin editar el de v20:

- el runner (`sdd-run-gates.sh -o <report> --full`);
- la **salida literal** del conteo de los 42 casos, no sólo la cifra;
- la **tabla de binding** de los asserts `AC51 v20 caso <n>`, que hoy no tiene (el binding de v19 cubre sólo la primera tanda);
- el script de mutaciones del report de v20 con dos arreglos: **sumar la (a)**, con el adaptador, y contar los asserts con `grep -c '^  FAIL'` en vez de `grep -c 'FAIL'`, porque este último también cuenta la línea de resumen y da uno de más;
- la última línea del script, **tal cual la imprime**: si el report está sin commitear va a decir `SUCIO`, y eso se explica abajo, no se reemplaza.

## 4. README — `plugins/bisalta-db/README.md`

- **Líneas ~159-161.** La frase *"la barrera es el texto"* sobre SQL Server presenta la lista blanca como barrera. Contradice el punto 5 de v19 y la línea ~167 del propio README, donde el rol es "la única barrera". Reescribirla: la lista blanca es la primera capa, la que rechaza temprano; en SQL Server la barrera es el rol.
- **Líneas ~103-106 y ~150-157.** La tabla por dialecto no refleja que en SQL Server se rechazan también `TRUNCATE`, `DROP`, `CREATE` y `ALTER` (`AC52`), ni el rechazo de v20 por construcción sin cerrar. Agregar las dos cosas.

## Mientras tanto

**Cerrado en v23 (24-sep)**: Patrick mandó seis casos, Ian los pegó en `casos-adversariales-v20.js` (`76f258e`) y la mutación (b) cae (report de v23, §2). **Cerrado en v24 (24-sep)**: la mutación (c) del punto 1 cae con cinco casos que escribió el planner (`a282e3a`, report de v24). Lo que sigue es el texto de antes de esos cierres.

La mutación (b) sigue esperando el caso que Patrick va a mandar. Cuando llegue, entra en el mismo `casos-adversariales-v20.js` o en un archivo aparte de él, y se suma a la evidencia del punto 3.
