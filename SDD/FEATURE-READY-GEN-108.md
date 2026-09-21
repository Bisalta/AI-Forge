# Feature Ready — `bisalta-db` v0.1.0 · consulta de solo lectura sin credencial en contexto

**Branch**: `feat-GEN-108-mcp-bisalta-db` → `prod` · **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v9** · **Proxima**: `GEN-108` (`GEN-108.1`, `GEN-108.2`)
**Agentes**: `AGENT_r1` (infra, 8 rondas en tres alcances) · `AGENT_r2` (third-party-integration, 2 rondas)
**Gates**: suite 17/17 · secret-scan exit 0 · shellcheck exit 0 · linter de closure exit 0

---

## Qué es

Un plugin que le da a Claude Code y a NEO consulta de solo lectura contra las bases de Bisalta **sin que ninguna credencial entre en el contexto de la sesión**. La credencial no desaparece: pasa de un archivo que hoy hay que leerle al modelo —y que queda archivado en el transcript— a un secreto de AWS que el proceso resuelve, usa y tira.

## Decisiones que tomé por vos

1. **Cero dependencias npm.** JSON-RPC 2.0 escrito a mano; `psql`, `sqlcmd` y `aws` por CLI. Es tu propio argumento contra `npx -y` aplicado hasta el final, y el repo ya tenía precedente (`usage-monitor` es Node plano probado desde bash).
2. **La lista blanca se porta literal** de `Bisalta/Proveedores-Back`, con sus doce casos — incluido el que la mató (`DELETE … WHERE id IN (SELECT …)`).
3. **`AC38(a)` pasa a `N/A`**: te pedí agregar los scripts del plugin al glob de shellcheck y el plugin no trae ningún `.sh` — agregarlo pone el gate en rojo permanente. Medido.
4. **`AC41` es freno, no clasificador.** La guarda por nombre detiene; no decide si un cluster tiene producción.
5. **`portalrh_dev` y `portalrh_qa` fuera del alcance**, porque no sabías si algo se conecta con otro rol y quitar la dependencia es mejor que responder por inferencia.

## Dónde está el riesgo

🔴 **Las filas que el MCP devuelve quedan en el transcript.** Es lo que el plugin hace, así que no hay diseño que lo evite sin negar la función. Elegiste el **tope duro de filas y bytes como única barrera** y descartaste la lista de exclusión de columnas. Está registrado como riesgo aceptado con dueño, no como control.

🔴 **La aprobación de Esteban Fait o Sebastián sigue pendiente.** Patrick aprobó el login de Dev SQL sabiendo que son copias de producción; la política de uso de IA exige además la suya. **Es precondición de habilitar el plugin al equipo, no de mergearlo.**

🟡 **`AC34` no se probó contra una sesión real de Claude Code.** El handshake corre contra el harness; el `protocolVersion` declarado (`2024-11-05`) no se negoció con el cliente real. Es lo primero que hay que probar al instalar.

🟡 **La cuenta de producción no está enumerada** (`D43`). Ninguna entrada del catálogo apunta ahí, pero "producción es irrepresentable" descansa en eso, no en un inventario.

## Qué mirar en 5 minutos

1. **`plugins/bisalta-db/catalogo.json`** — tres entradas, ninguna con usuario ni contraseña, sólo `secret_id`. Es el contrato de datos entero en 35 líneas.
2. **`plugins/bisalta-db/scripts/lista-blanca.js`** — la guarda que decide qué SQL corre. Si algo va a fallar feo, falla acá.
3. **`SDD/verification/feat-GEN-108-mcp-bisalta-db-R2.md` §2** — los 17 triples de mutación con el patch literal de cada uno. Es la evidencia de que las barreras se pueden poner rojas.
4. **`plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`** — quién autorizó qué, y la diferencia entre lo que la aprobación enumera y lo que el acceso alcanza.

## Estado honesto

| | |
|---|---|
| **R2 — el plugin** | `APPROVED` por el reviewer. 30 ACs, 17 triples `verde → rojo → verde` re-corridos por él |
| **R1 — el aprovisionamiento** | `APPROVED` por el reviewer sobre el alcance de **v9** (la lista explícita), tras auditarle el barrido de clase receta por receta. Antes hubo un `ESCALATE` sobre el alcance de v7, resuelto por ratificación del planner: el defecto que quedaba era del contract, no del implementador |
| **10 de los 12 ACs de R1** | `manual-only` con razón escrita, en estado **`pendiente-de-ejecución`**. Ningún harness de este repo puede crear un rol de Postgres |
| **Alcance de Dev SQL** | Arranca en **cero**. Seis bases pedidas el 21-sep (`COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`, `EXACTUS`, `BI` — 861 GB de 1383), **iniciales para probar la herramienta**, no definitivas |
| **Ejecución del aprovisionamiento** | **Frenada por Patrick** hasta que defina alcance |
| **Deuda** | `D32`–`D44`. Dos son del propio `sdd-flow` (`D34`/`D35`: el verification report queda fuera del gate que valida el árbol) |

**Lo que este PR NO hace**: no crea ningún rol, no toca ninguna base, no carga ningún secreto. Es código y procedimientos.

## Siguiente paso

Mergear no habilita nada por sí solo. Para que el plugin funcione hacen falta, en este orden: que Patrick cierre alcance (`qa`, los dos clusters sin medir, SQL Server), que corra los scripts y cargue las claves él mismo en Secrets Manager, que escriba la política IAM, y la aprobación de Esteban o Sebastián para habilitarlo al equipo.
