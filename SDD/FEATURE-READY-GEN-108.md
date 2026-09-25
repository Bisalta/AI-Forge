# Feature Ready — `bisalta-db` v0.1.0 · consulta de solo lectura sin credencial en contexto

**Branch**: `feat-GEN-108-mcp-bisalta-db` → `prod` · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v26** · **Proxima**: `GEN-108` (`GEN-108.1`, `GEN-108.2`)
**Quién hizo qué**: `AGENT_r1` (infra) y `AGENT_r2` (third-party-integration) hasta v19 · **v20 lo escribió Patrick Ocampo** (casos y función de normalización), Ian los pegó y lo integró el planner · v21 y v22 los hizo el planner a pedido de Ian, porque ningún agente pudo tocar esa parte (ver "Dónde está el riesgo") · v19 a v22 **en review**: ronda 1 `REJECTED` (`E19`), ronda 2 `REJECTED` sólo por documentos, **ronda 3 `APPROVED`**
**Feature Ready: APROBADO por Ian Vargas, 24-sep-2026** sobre v22, con las mutaciones (b) y (c) abiertas y su evidencia pendiente (`D63`–`D65`). **Después de aprobar**: v23 cerró la (b) con seis casos de Patrick y corrió (b), (c) y (d) sobre su árbol (`76f258e`); por ser una corrección posterior a `APPROVED`, v23 volvió a review (§7.5) y quedó `APPROVED` en la ronda 2. Después, el caso 13 pasó a nombrar su tipo (`D67`, `e0a70bb`); su review escaló en la ronda 3 por falta de la escalera sellada sobre ese árbol, y el planner la ratificó corriendo el runner (`E20`). Después se corrió la (a), con adaptador, sobre el árbol de entonces (`D65`). Después, v24 cerró la (c) con cinco casos del planner (`D64`). **Por último, v25 cambia código** a partir de la review de seguridad de gradiel12 en el PR: TLS obligatorio, límite de consulta en SQL Server y más sentencias rechazadas. **Feature Ready: APROBADO de nuevo por Ian Vargas sobre v25, el 25-sep-2026**, después de probarlo a través del plugin instalado. En la misma aprobación pidió sumar ya el bundle de RDS (`D70`): eso es **v26**, donde Postgres pasa a autenticar al servidor.
**Gates**: suite 17/17 · secret-scan exit 0 · shellcheck exit 0 · linter de closure exit 0 · 48 de 48 casos adversariales de Patrick (en v25, el caso 8 pasa de aceptar a rechazar) y los del planner · escalera del árbol actual sellada por el runner en `SDD/verification/feat-GEN-108-mcp-bisalta-db-v26.md`

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

✅ **Las cuatro mutaciones de `AC51` caen.** La (b) —la regla de los literales `E'…'` de Postgres— **cae desde v23**: Patrick explicó que esa regla no está para frenar ataques sino para no rechazar consultas legítimas, y mandó seis de esas; con la regla apagada caen cinco, y el sexto es un control. La (c) —la de los corchetes— es de la misma clase, y **cae desde v24** con cinco casos que escribió el planner: cuatro nombres entre corchetes que llevan una comilla, una comilla doble, un `/*` o un `]]`, y un control (`D64`). Hasta v23 la mataba sólo un caso de Patrick, que también cae con otra mutación. Las cuatro mutaciones, más la independencia de los casos nuevos respecto de la (d), están corridas sobre el árbol de v24, en `SDD/verification/feat-GEN-108-mcp-bisalta-db-v24.md`. Los 48 casos de Patrick y los 5 del planner coinciden.

🟡 **Una parte de la lista blanca no la puede tocar un agente.** El filtro de seguridad cortó tres veces el trabajo de ajustarla contra formas de pasarla, aunque los casos fueran de Patrick. Por eso v20 lo escribió él (`RT54`). Lo que no cortó, de v23 a v25, fueron los casos de consultas legítimas y las reglas de rechazo explícitas por nombre (`RT55`).

🟠 **Review de seguridad de gradiel12 (PR #14, 24-sep).** No bloquea el merge; pide sus puntos 1 y 2 antes de habilitar al equipo. v25 aplica lo que no dependía de nadie más, y todo tiene su mutación verificada:
- **TLS obligatorio** en los dos motores (`AC55`). **Desde v26, Postgres autentica al servidor** con el bundle de RDS (`AC58`, `D70` pagada). **SQL Server cifra pero no autentica al servidor**, y eso queda como **riesgo aceptado** (`D71`, 25-sep): a Dev SQL sólo se llega por la VPN, según confirmaste vos, y Patrick lo aceptó.
- **`sqlcmd -t 60`** (`AC54`): SQL Server no tenía límite de consulta.
- **Diecisiete sentencias de SQL Server que no son lectura, rechazadas** (`AC53`). El caso 8 de Patrick usaba `OPENQUERY` y deja de ser límite conocido: se cambió sólo su veredicto esperado.
- **Temporales huérfanos** borrados al arrancar (`AC56`).
- **Un defecto que la review no vio** (`AC57`): `sqlcmd` escribe sus errores en stdout, y el plugin sólo leía stderr. Todo error de SQL Server llegaba sin mensaje.
- **Antes de habilitar al equipo**, además: el tope de conexiones del rol (`D73`), saber qué persona corrió cada consulta (`D74`), los bloqueos y el techo de recursos en Dev SQL (`D75`), y qué es `COMPRAS_STG` (`D72`).

🟡 **El endpoint de réplica depende de que el cluster tenga réplicas, y tiene una sola** — con los nombres de instancia cruzados, huella de un failover anterior. Desde v16 el plugin lo comprueba en cada consulta y **se niega** (`no_es_replica`, código 9) si llegó al writer: una falla cerrada, y un riesgo de disponibilidad, no de seguridad.

🟡 **Los scripts de aprovisionamiento nuevos no los corrió nadie.** v19 metió en los scripts el `ALTER ROLE` y el `REVOKE CREATE ON SCHEMA public` que Patrick aplicó a mano. Lo que está en el motor coincide con lo que los scripts mandan: la configuración del rol, leída del catálogo, y la falta de `CREATE` en `public` en seis de seis bases. Pero la primera corrida real de los scripts va a ser la prueba de que reproducen el estado.

🟡 **En Postgres, `claude_lectura` ve los nombres de las bases del cluster**: `pg_database` es legible por todo rol, y ocultarla rompe clientes. Riesgo aceptado, confirmado por Patrick. En SQL Server el equivalente lo cerró él (`AC48`).

🟡 **La cuenta de producción no está enumerada** (`D43`). Ninguna entrada del catálogo apunta ahí, pero "producción es irrepresentable" descansa en eso, no en un inventario.

✅ **Postgres y SQL Server probados contra las bases reales.** Las seis conexiones de Postgres responden a través del plugin, con `application_name = claude_lectura`; desde v19, con el límite de tiempo del rol: `1min`, medido el 24-sep **a través del plugin instalado con v22**. SQL Server responde desde el plugin, en la instancia correcta, y el login ve sólo su propia base, `master` y `tempdb`.

✅ **`AC34` probado contra una sesión real de Claude Code (22-sep-2026).**

## Qué mirar en 5 minutos

1. **`plugins/bisalta-db/scripts/lista-blanca.js`** — la normalización de v20 es la de Patrick, con sus límites escritos en el comentario de la función.
2. **`SDD/tests/fixtures/`** — los dos archivos de casos de Patrick, que el test recorre sin copiar sus consultas.
3. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-v26.md`** — la escalera sellada sobre el árbol actual, las 45 mutaciones de `AC53` a `AC59` y la verificación en vivo de `verify-full`, con su control negativo. **`…-v25.md`** trae las mediciones que decidieron el diseño de v25 y la prueba a través del plugin instalado. **`…-v24.md`** trae las cuatro mutaciones de `AC51`. **`…-v23-D67.md`** trae los controles de aislamiento de la (a), y **`…-v23.md`**, los 48 casos agrupados y el binding. El de v22 trae la verificación en vivo con el plugin instalado.
4. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md`** — el timeout, el `ALTER ROLE` y el esquema `public`, verificados contra el motor.
5. **`plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`** — quién autorizó qué, y la diferencia entre lo que la aprobación enumera y lo que el acceso alcanza.

## Estado honesto

| | |
|---|---|
| **Hasta v18** | Tres rondas de review sobre todo lo posterior al último `APPROVED`, ratificadas por el planner en v18 |
| **v19** | Parte 1 (timeout, `ALTER ROLE`, esquema `public`) implementada por `AGENT_r1` y verificada contra el motor. Parte 2 (normalización, T-SQL sin separador) implementada por `AGENT_r2`. `APPROVED` (ronda 3) |
| **v20 a v22** | Casos y función de Patrick, integración del planner; v21 y v22 cierran la ronda 1 de review. 42 de 42 casos. Mutaciones: (d) cae; **(b) abierta**; **(c) abierta en parte**; (a) declarada con adaptador. La evidencia de mutaciones sobre el árbol de v22, **pendiente** a cargo de una persona. `APPROVED` (ronda 3), con las mutaciones abiertas registradas como deuda (`D63`–`D65`) |
| **v23** | Seis casos más de Patrick para la mutación (b), que ahora cae. 48 de 48 casos. Review §7.5: `APPROVED` en la ronda 2. El caso 13 nombra su tipo (`D67`): `ESCALATE` en la ronda 3 por evidencia faltante, ratificado por el planner con la escalera sellada (`E20`). Después, la (a) sobre el árbol actual (`D65`), con review `APPROVED` en la ronda 3 |
| **v24** | Cinco casos del planner para la mutación (c), que ahora cae (`D64`). Las cuatro mutaciones de `AC51` caen sobre el árbol actual. Review §7.5: `APPROVED` en la ronda 3 |
| **v25** | Review de seguridad de gradiel12: `AC53` a `AC57`, 34 mutaciones que caen, cifrado verificado en vivo. Review §7.5: `APPROVED` en la ronda 3. **Probado a través del plugin instalado** el 25-sep (report de v25, §5) |
| **v26** | Postgres autentica al servidor con el bundle de RDS (`AC58`). Las seis conexiones conectan con `verify-full`, y con una autoridad ajena falla. **Un gate de seguridad cambió qué mira** (`AC59`): el secret-scan ya no escanea el base64 de un certificado público dentro de un bloque cerrado. La primera versión de la regla tenía tres huecos que la review encontró y que ya están cerrados. Review §7.5: `APPROVED` en la ronda 3 |
| **Aprovisionamiento** | Postgres ejecutado por Patrick el 22-sep y SQL Server el 23-sep, verificados desde el plugin. Parte de su evidencia vive en Slack (`D61`) |
| **Alcance de Dev SQL** | Arranca en **cero**. Seis bases pedidas el 21-sep, **iniciales para probar la herramienta**, no definitivas |
| **Deuda, retro y escalaciones del ciclo** | 49 ítems de deuda (33 abiertos), 34 entradas de retro hasta `RT56` y 12 escalaciones hasta `E20` |

**Lo que este PR NO hace**: no crea ningún rol, no toca ninguna base, no carga ningún secreto. Es código y procedimientos. Lo que ya existe en AWS y en las bases lo hizo Patrick a mano.

## Siguiente paso

1. ~~Review de v19 a v22~~ — tres rondas, `APPROVED` en la ronda 3. Quedan tres MINOR y lo abierto registrado como deuda (`D63`–`D67`).
2. ~~Reinstalar el plugin y verificar en vivo~~ — hecho el 24-sep sobre v22.
3. ~~Tu gate de Feature Ready~~ — **aprobado el 24-sep sobre v22**. **No se reconfirma sobre v23**: v23 sólo agrega casos al fixture y cierra una deuda que la aprobación ya aceptaba abierta (`D63`); no cambia código, alcance ni riesgos. Si querés reconfirmarlo igual, es tu decisión. Lo que se aprobó abierto quedó cerrado después: **(b) en v23, la evidencia de (a) sobre el árbol actual, y (c) en v24** (`D63`–`D65`). v24 tampoco cambia código, alcance ni riesgos: agrega casos al test.
4. ~~Review §7.5 de v23~~ — ronda 1 `REJECTED`, sólo por documentos; **ronda 2 `APPROVED`**, sin hallazgos. Después, el caso 13 de Patrick pasó a nombrar su tipo (`D67`, `e0a70bb`): sólo la descripción, con su triple en el report de v23, §4. Por ser posterior a `APPROVED`, volvió a review: `ESCALATE` en la ronda 3, porque la escalera sellada no cubría el fixture nuevo. El planner lo ratificó corriendo el runner sobre ese árbol (`E20`). La (a) sobre el árbol actual: tres rondas, `APPROVED` en la tercera.
5. ~~Review §7.5 de v24~~ — ronda 1 `REJECTED`, sólo por documentos; ronda 2 `APPROVED` con un MINOR, corregido; **ronda 3 `APPROVED`**, sin hallazgos.
6. ~~Review §7.5 de v25~~ — ronda 1 `REJECTED` (dos MAJOR de documentación); ronda 2 `APPROVED` con cuatro MINOR, corregidos; **ronda 3 `APPROVED`**, sin hallazgos.
7. ~~Tu gate de Feature Ready, otra vez, sobre v25~~ — **aprobado el 25-sep**, después de la prueba a través del plugin instalado.
7b. ~~v26, el bundle de RDS~~ (pedido en la misma aprobación): review §7.5 en tres rondas. Ronda 1 `REJECTED`, porque la primera regla del secret-scan tenía dos huecos. Ronda 2 `APPROVED` con un tercer hueco, corregido. **Ronda 3 `APPROVED`**, con dos MINOR de prosa a deuda (`D79`, `D80`).
7c. ~~Probar v26 a través del plugin instalado~~ — hecho el 25-sep a las 14:04: las seis conexiones de Postgres conectan con `verify-full`, y SQL Server responde igual (report de v26, §5).
7d. ~~Confirmar Feature Ready sobre v26~~ — **APROBADO por Ian Vargas el 25-sep-2026**, después de la prueba a través del plugin instalado. v26 cambia qué mira un gate de seguridad (`AC59`).
8. **Merge.** Requiere la review de un code owner (`@Bisalta/construplaza-admin`). No habilita nada al equipo por sí solo.

Para **habilitarlo al equipo** hace falta además la aprobación de Esteban o Sebastián.
