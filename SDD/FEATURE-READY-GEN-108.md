# Feature Ready — `bisalta-db` v0.1.0 · consulta de solo lectura sin credencial en contexto

**Branch**: `feat-GEN-108-mcp-bisalta-db` → `prod` · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v22** · **Proxima**: `GEN-108` (`GEN-108.1`, `GEN-108.2`)
**Quién hizo qué**: `AGENT_r1` (infra) y `AGENT_r2` (third-party-integration) hasta v19 · **v20 lo escribió Patrick Ocampo** (casos y función de normalización), Ian los pegó y lo integró el planner · v21 y v22 los hizo el planner a pedido de Ian, porque ningún agente pudo tocar esa parte (ver "Dónde está el riesgo") · v19 a v22 **en review**: ronda 1 `REJECTED` (`E19`), ronda 2 `REJECTED` sólo por documentos, **ronda 3 `APPROVED`**
**Gates**: suite 17/17 · secret-scan exit 0 · shellcheck exit 0 · linter de closure exit 0 · 42 de 42 casos adversariales de Patrick

---

## Qué es

Un plugin que le da a Claude Code consulta de solo lectura contra las bases de Bisalta **sin que ninguna credencial entre en el contexto de la sesión**. La credencial no desaparece: pasa de un archivo que hoy hay que leerle al modelo —y que queda archivado en el transcript— a un secreto de AWS que el proceso resuelve, usa y tira. **NEO no lo usa**: lee Odoo por XML-RPC, contra la aplicación y no contra la base (contract v13).

## Decisiones que tomé por vos

1. **Cero dependencias npm.** JSON-RPC 2.0 escrito a mano; `psql`, `sqlcmd` y `aws` por CLI. Es tu propio argumento contra `npx -y` aplicado hasta el final, y el repo ya tenía precedente (`usage-monitor` es Node plano probado desde bash).
2. **La lista blanca se portó literal** de `Bisalta/Proveedores-Back`, con sus doce casos. **Resultó insuficiente**, y con ella se portó un defecto de normalización (ver "Dónde está el riesgo"). v16, v19 y v20 la corrigieron.
3. **`AC38(a)` pasa a `N/A`**: te pedí agregar los scripts del plugin al glob de shellcheck y el plugin no trae ningún `.sh` — agregarlo pone el gate en rojo permanente. Medido.
4. **`AC41` es freno, no clasificador.** La guarda por nombre detiene; no decide si un cluster tiene producción.
5. **`portalrh_dev` y `portalrh_qa` fuera del alcance**, porque no sabías si algo se conecta con otro rol y quitar la dependencia es mejor que responder por inferencia.

**Lo que decidiste vos** (23-sep): la réplica se **comprueba en cada consulta** (`AC46`) y las escrituras embebidas se **rechazan** (`AC47`). **Lo que decidió Patrick** (23-sep): el límite de tiempo vive **en el rol** con 60 s y el plugin deja de mandarlo (`AC28`), y la lista blanca se describe como **la capa que da un error temprano, no la que impide el daño** (`D62`).

## Dónde está el riesgo

🔴 **Las filas que el MCP devuelve quedan en el transcript.** Es lo que el plugin hace, así que no hay diseño que lo evite sin negar la función. Elegiste el **tope duro de filas y bytes como única barrera** y descartaste la lista de exclusión de columnas. Está registrado como riesgo aceptado con dueño, no como control.

🔴 **La aprobación de Esteban Fait o Sebastián sigue pendiente.** Patrick aprobó el login de Dev SQL sabiendo que son copias de producción; la política de uso de IA exige además la suya. **Es precondición de habilitar el plugin al equipo, no de mergearlo.**

🟡 **La lista blanca es la capa que da un error temprano, no la barrera.** Patrick intentó romperla el 23-sep y encontró **doce formas de pasarla, ninguna brecha**: todas chocan después con el privilegio, que midió firme en los dos motores, o con la réplica. Se arreglaron las que eran baratas —un defecto de normalización que venía del código original de R2, y sentencias de SQL Server sin separador— y dos regresiones que introdujo el primer arreglo. Dos clases quedan como **límite conocido**, escritas en el contract: el SQL que viaja como texto a una función, y las funciones que escriben sin nombrar una escritura.

🟡 **Dos mutaciones de la lista blanca quedan abiertas, y su evidencia sobre el árbol actual está pendiente.** La (b) —la regla de los literales `E'…'` de Postgres— no cae: apagada, la suite sigue verde; hoy ningún caso la mata, y se le pidió a Patrick el caso que falta. La (c) —la de los corchetes— cae **en parte**: con la regla apagada cae un solo caso, que también cae con otra mutación. La (a) está declarada con adaptador. La evidencia de las mutaciones sobre el árbol de v22 la tiene que rehacer una persona (report de v22, §3; `RT54`). Son huecos de prueba, no de la barrera: las reglas están implementadas y los 42 casos coinciden.

🟡 **Esta parte de la lista blanca no la puede tocar un agente.** El filtro de seguridad cortó tres veces el trabajo de ajustarla contra formas de pasarla, aunque los casos fueran de Patrick. Por eso v20 lo escribió él. Cualquier cambio futuro a la lista blanca va a necesitar a una persona para esa parte (`RT54`).

🟡 **El endpoint de réplica depende de que el cluster tenga réplicas, y tiene una sola** — con los nombres de instancia cruzados, huella de un failover anterior. Desde v16 el plugin lo comprueba en cada consulta y **se niega** (`no_es_replica`, código 9) si llegó al writer: una falla cerrada, y un riesgo de disponibilidad, no de seguridad.

🟡 **Los scripts de aprovisionamiento nuevos no los corrió nadie.** v19 metió en los scripts el `ALTER ROLE` y el `REVOKE CREATE ON SCHEMA public` que Patrick aplicó a mano. Lo que está en el motor coincide con lo que los scripts mandan: la configuración del rol, leída del catálogo, y la falta de `CREATE` en `public` en seis de seis bases. Pero la primera corrida real de los scripts va a ser la prueba de que reproducen el estado.

🟡 **En Postgres, `claude_lectura` ve los nombres de las bases del cluster**: `pg_database` es legible por todo rol, y ocultarla rompe clientes. Riesgo aceptado, confirmado por Patrick. En SQL Server el equivalente lo cerró él (`AC48`).

🟡 **La cuenta de producción no está enumerada** (`D43`). Ninguna entrada del catálogo apunta ahí, pero "producción es irrepresentable" descansa en eso, no en un inventario.

✅ **Postgres y SQL Server probados contra las bases reales.** Las seis conexiones de Postgres responden a través del plugin, con `application_name = claude_lectura`; desde v19, con el límite de tiempo del rol (medido con el servidor del repo: `1min`). SQL Server responde desde el plugin, en la instancia correcta, y el login ve sólo su propia base, `master` y `tempdb`.

✅ **`AC34` probado contra una sesión real de Claude Code (22-sep-2026).**

## Qué mirar en 5 minutos

1. **`plugins/bisalta-db/scripts/lista-blanca.js`** — la normalización de v20 es la de Patrick, con sus límites escritos en el comentario de la función.
2. **`SDD/tests/fixtures/`** — los dos archivos de casos de Patrick, que el test recorre sin copiar sus consultas.
3. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-v22.md`** — la escalera sellada sobre el árbol actual, los 42 casos agrupados, el binding y el estado de las mutaciones. El de v20 conserva las tres mutaciones corridas sobre aquel árbol.
4. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md`** — el timeout, el `ALTER ROLE` y el esquema `public`, verificados contra el motor.
5. **`plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`** — quién autorizó qué, y la diferencia entre lo que la aprobación enumera y lo que el acceso alcanza.

## Estado honesto

| | |
|---|---|
| **Hasta v18** | Tres rondas de review sobre todo lo posterior al último `APPROVED`, ratificadas por el planner en v18 |
| **v19** | Parte 1 (timeout, `ALTER ROLE`, esquema `public`) implementada por `AGENT_r1` y verificada contra el motor. Parte 2 (normalización, T-SQL sin separador) implementada por `AGENT_r2`. `APPROVED` (ronda 3) |
| **v20 a v22** | Casos y función de Patrick, integración del planner; v21 y v22 cierran la ronda 1 de review. 42 de 42 casos. Mutaciones: (d) cae; **(b) abierta**; **(c) abierta en parte**; (a) declarada con adaptador. La evidencia de mutaciones sobre el árbol de v22, **pendiente** a cargo de una persona. `APPROVED` (ronda 3), con las mutaciones abiertas registradas como deuda (`D63`–`D65`) |
| **Aprovisionamiento** | Postgres ejecutado por Patrick el 22-sep y SQL Server el 23-sep, verificados desde el plugin. Parte de su evidencia vive en Slack (`D61`) |
| **Alcance de Dev SQL** | Arranca en **cero**. Seis bases pedidas el 21-sep, **iniciales para probar la herramienta**, no definitivas |
| **Deuda, retro y escalaciones del ciclo** | 36 ítems de deuda (27 abiertos), 32 entradas de retro hasta `RT54` y 11 escalaciones hasta `E19` |

**Lo que este PR NO hace**: no crea ningún rol, no toca ninguna base, no carga ningún secreto. Es código y procedimientos. Lo que ya existe en AWS y en las bases lo hizo Patrick a mano.

## Siguiente paso

1. ~~Review de v19 a v22~~ — tres rondas, `APPROVED` en la ronda 3. Quedan tres MINOR y lo abierto registrado como deuda (`D63`–`D67`).
2. **Reinstalar** el plugin y verificar en vivo.
3. **Tu gate de Feature Ready.** Se puede decidir con las mutaciones (b) y (c) abiertas y su evidencia pendiente, todo declarado, o esperar a Patrick.
4. **Merge.** No habilita nada al equipo por sí solo.

Para **habilitarlo al equipo** hace falta además la aprobación de Esteban o Sebastián.
