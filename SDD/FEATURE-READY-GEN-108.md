# Feature Ready — `bisalta-db` v0.1.0 · consulta de solo lectura sin credencial en contexto

**Branch**: `feat-GEN-108-mcp-bisalta-db` → `prod` · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v16** · **Proxima**: `GEN-108` (`GEN-108.1`, `GEN-108.2`)
**Agentes**: `AGENT_r1` (infra) · `AGENT_r2` (third-party-integration, reabierto para v16) · todo lo posterior al último `APPROVED` está **en review** (ver "Estado honesto")
**Gates**: suite 17/17 · secret-scan exit 0 · shellcheck exit 0 · linter de closure exit 0

---

## Qué es

Un plugin que le da a Claude Code consulta de solo lectura contra las bases de Bisalta **sin que ninguna credencial entre en el contexto de la sesión**. La credencial no desaparece: pasa de un archivo que hoy hay que leerle al modelo —y que queda archivado en el transcript— a un secreto de AWS que el proceso resuelve, usa y tira. **NEO no lo usa**: lee Odoo por XML-RPC, contra la aplicación y no contra la base (contract v13).

## Decisiones que tomé por vos

1. **Cero dependencias npm.** JSON-RPC 2.0 escrito a mano; `psql`, `sqlcmd` y `aws` por CLI. Es tu propio argumento contra `npx -y` aplicado hasta el final, y el repo ya tenía precedente (`usage-monitor` es Node plano probado desde bash).
2. **La lista blanca se portó literal** de `Bisalta/Proveedores-Back`, con sus doce casos — incluido el que la mató (`DELETE … WHERE id IN (SELECT …)`). **Y resultó insuficiente**: con ella se portó su punto ciego (ver "Dónde está el riesgo"). v16 le agrega el rechazo de escrituras embebidas.
3. **`AC38(a)` pasa a `N/A`**: te pedí agregar los scripts del plugin al glob de shellcheck y el plugin no trae ningún `.sh` — agregarlo pone el gate en rojo permanente. Medido.
4. **`AC41` es freno, no clasificador.** La guarda por nombre detiene; no decide si un cluster tiene producción.
5. **`portalrh_dev` y `portalrh_qa` fuera del alcance**, porque no sabías si algo se conecta con otro rol y quitar la dependencia es mejor que responder por inferencia.

Y dos que decidiste vos el 23-sep: la réplica **se comprueba en cada consulta** (`AC46`) en vez de declararse, y las escrituras embebidas **se rechazan en la lista blanca** (`AC47`) en vez de aceptarse como riesgo.

## Dónde está el riesgo

🔴 **Las filas que el MCP devuelve quedan en el transcript.** Es lo que el plugin hace, así que no hay diseño que lo evite sin negar la función. Elegiste el **tope duro de filas y bytes como única barrera** y descartaste la lista de exclusión de columnas. Está registrado como riesgo aceptado con dueño, no como control.

🔴 **La aprobación de Esteban Fait o Sebastián sigue pendiente.** Patrick aprobó el login de Dev SQL sabiendo que son copias de producción; la política de uso de IA exige además la suya. **Es precondición de habilitar el plugin al equipo, no de mergearlo.**

🟡 **La lista blanca dejaba pasar escrituras, y nada del ciclo lo vio hasta el 23-sep** (`RT50`). Aceptaba `WITH x AS (DELETE …) SELECT …` en los dos dialectos, `SELECT … INTO` —que crea una tabla— y `set_config` para apagar la sesión de solo lectura. Sobrevivió a 17 triples de mutación y a tres reviews: los tests verificaban bien lo que enumeraban, y nadie enumeró esto. **No hubo exposición**: en Postgres lo frenaban tres barreras detrás, medidas con cinco sondas sin efecto posible; en SQL Server, donde el rol es la única barrera, se encontró **antes** de que existiera el login. Cerrado en v16 (`AC47`), pendiente de la review.

🟡 **El endpoint de réplica depende de que el cluster tenga réplicas, y tiene una sola** — con los nombres de instancia cruzados, huella de un failover anterior. Aurora apunta `cluster-ro-` al writer si se queda sin réplicas. Desde v16 **el plugin lo comprueba en cada consulta y se niega** (`no_es_replica`, código 9): si el cluster pierde su réplica, el plugin deja de responder en Postgres en vez de quedar en condiciones de escribir. Es una falla cerrada, y un riesgo de disponibilidad, ya no de seguridad.

🟡 **En SQL Server el rol es la única barrera detrás de la lista blanca**, y es condicional: sin `db_denydatawriter` no hay `DENY` que anule un `GRANT` de escritura concedido por error (`D48`, aceptado por Patrick).

🟡 **Lo que Patrick configuró en el rol de Postgres no está en el repo** (`D59`): un `ALTER ROLE` con `default_transaction_read_only`, `statement_timeout`, `idle_in_transaction_session_timeout` y `lock_timeout`, que fue una de las barreras que frenó las sondas. Recrear el rol lo pierde. Y el `statement_timeout` de 60 s que puso él **no rige**: los 120 s del plugin le ganan (`D58`, decisión suya).

🟡 **La cuenta de producción no está enumerada** (`D43`). Ninguna entrada del catálogo apunta ahí, pero "producción es irrepresentable" descansa en eso, no en un inventario.

✅ **Postgres probado de punta a punta contra la base real (23-sep-2026).** Las seis conexiones de Postgres responden a través del plugin instalado, las seis con `application_name = claude_lectura`. La sesión en solo lectura y la conexión contra la réplica se verificaron en `proveedores-dev`. La guarda de `AC46` se verificó con el servidor del repo: contra el endpoint de escritura se niega con código 9, y contra la réplica devuelve filas.

✅ **La prueba en vivo encontró un defecto que la suite no veía.** `AC29` estaba verde en los tests y la sesión real se llamaba `psql`: el test miraba cómo se armaba el comando, no qué efecto tenía (`RT48`). Corregido en v15.

✅ **`AC34` probado contra una sesión real de Claude Code (22-sep-2026).** Claude Code negoció `2024-11-05`, descubrió las dos herramientas y las invocó sin ajustes.

## Qué mirar en 5 minutos

1. **`plugins/bisalta-db/scripts/lista-blanca.js`** — la guarda que decide qué SQL corre. Es la que tenía el hueco; mirá los dos chequeos nuevos al final del recorrido por sentencia.
2. **`plugins/bisalta-db/catalogo.json`** — doce entradas (seis de Postgres, seis de SQL Server), ninguna con usuario ni contraseña, sólo `secret_id`. Cada garantía declara su nivel y la condición de la que depende.
3. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-v16.md`** — la escalera sellada por el runner, los trece triples de v16 con el exit code de cada corrida, el binding AC ↔ test, y la verificación contra el motor.
4. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md` §2** — los diecisiete triples originales de R2, más un decimoctavo de la ronda 2.
5. **`plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`** — quién autorizó qué, y la diferencia entre lo que la aprobación enumera y lo que el acceso alcanza.

## Estado honesto

| | |
|---|---|
| **R2 — el plugin** | `APPROVED` por el reviewer sobre su alcance original: 30 ACs, 17 triples re-corridos por él. **Reabierto para v16** (`AC45a`–`AC47`), implementado por `AGENT_r2`: trece triples, en review |
| **R1 — el aprovisionamiento** | `APPROVED` por el reviewer por última vez sobre el contract **v14** (`2529071`, 22-sep). Antes hubo dos `ESCALATE`, los dos por el cap de tres rondas. `E9` era un defecto del contract: un cambio de diseño que no reconcilió los ACs que lo verifican. `E10` era de medición: el barrido de clase buscó con los patrones de las citas ya corregidas y no por el concepto, y se le escapó un `PRINT` que habría revocado bases recién concedidas. El planner resolvió los dos, y la review sobre v14 los cubrió después |
| **Todo lo posterior a `2529071`** | **En review** (`quality-gates.md` §7.5: una corrección de algo ya aprobado vuelve al loop). Se escribe como rango y no como lista porque una lista de commits dentro de un documento que se commitea después queda vieja en el mismo acto. La ronda 1 devolvió `ESCALATE` (`E12`): tres decisiones que el contract no tenía, cerradas en v16 |
| **Aprovisionamiento de Postgres** | **Ejecutado por Patrick el 22-sep.** Su verificación —431 objetos legibles, cero escribibles, `CREATE TABLE` rechazado— está en Slack, **no en un artefacto del repo** (`D61`) |
| **Aprovisionamiento de SQL Server** | **Pendiente de Patrick**: el login de Dev SQL, su secreto, correr los scripts, y medir `SERVERPROPERTY('MachineName')` para cerrar `AC44`. **Conviene que no cree el login antes de que v16 esté mergeado**: `AC47` es lo que cierra el hueco de la lista blanca en ese motor |
| **Alcance de Dev SQL** | Arranca en **cero**. Seis bases pedidas el 21-sep (`COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`, `EXACTUS`, `BI`), **iniciales para probar la herramienta**, no definitivas |
| **Deuda, retro y escalaciones del ciclo** | 30 ítems de deuda (`D32`–`D61`), 28 entradas de retro (`RT23`–`RT50`) y 4 escalaciones (`E9`–`E12`). Dos ítems de deuda son del propio `sdd-flow` (`D34`/`D35`: el verification report queda fuera del gate que valida el árbol) |

**Lo que este PR NO hace**: no crea ningún rol, no toca ninguna base, no carga ningún secreto. Es código y procedimientos. Lo que ya existe en AWS y en las bases lo hizo Patrick a mano, siguiendo el runbook.

## Siguiente paso

1. **Review de todo lo posterior a `2529071`** (§7.5), ronda 2, hasta `APPROVED`.
2. **Tu gate de Feature Ready**, sobre este brief.
3. **Merge.** No habilita nada al equipo por sí solo.

Para **habilitarlo al equipo** hace falta además SQL Server completo (Patrick) y la aprobación de Esteban o Sebastián.
