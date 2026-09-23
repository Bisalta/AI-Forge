# Task brief — R1 reabierto (v17) · SQL Server aprovisionado: AC44 medido y AC48

- **Agente**: `AGENT_r1` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v17**, ACs **AC44** (precondición cerrada) y **AC48** (nuevo)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya existe; **NO crear otra, NO commitear a `prod`**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1-v17.md` (archivo nuevo; no toques los de R1, R2, v15 ni v16)

## Problema

Leé entera la sección **"Cambios v16 → v17"** del contract, y los textos de `AC44` y `AC48`. En corto: Patrick Ocampo aprovisionó SQL Server, midió el `MachineName`, y encontró que el login podía listar los nombres de todas las bases del servidor. Lo cerró a mano con un `DENY` que hoy no está en ningún script del repo.

## Lo que Patrick reportó (Slack, 23-sep-2026 13:04 y 13:05) — textual, para que lo cites

Vos no podés leer Slack: estas cifras vienen del planner, y en el report se citan como **reportadas por Patrick**, nunca como medidas por vos.

- `SERVERPROPERTY('MachineName')`, medido vía SSM contra la instancia: `EC2AMAZ-2RGHL0C`.
- Login `bisalta_lectura` con `db_datareader` en `COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`, `EXACTUS`, `BI`: en cada una `lee=1 escribe=0`.
- Verificado como el login: lee `COMPRAS` (84 tablas); `CREATE TABLE` → `Msg 262: CREATE TABLE permission denied in database 'COMPRAS'.`; `SSISDB` no la puede abrir; `CONSTRUPLAZA_EFLOW` (267 GB) no la puede abrir.
- Antes del `DENY`: el login listaba **36** nombres de base. Después de `DENY VIEW ANY DATABASE TO [bisalta_lectura];`: ve `master` y `tempdb`, y sigue leyendo las seis.
- Las cuatro tablas de usuario de `master` son `spt_fallback_*` y `spt_monitor`, de fábrica.

## Files — lo único que tocás

| Archivo | Para qué |
|---|---|
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-a.sql` | `AC48`: `DENY VIEW ANY DATABASE TO [bisalta_lectura];` **después** del bloque que crea el login y **fuera** de él, para que cada corrida lo re-aplique. Y `AC44`: el comentario y la línea de `@esperada` dejan de decir "sin confirmar" — dicen que se midió el 23-sep y cómo |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-parte-b.sql` | `AC44`: las dos menciones de "sin confirmar" (hoy ~116 y ~122), mismo criterio |
| `plugins/bisalta-db/aprovisionamiento/sqlserver-inverso.sql` | **leelo, y tocalo sólo si hace falta**: confirmá si el `DROP LOGIN` se alcanza en todos los caminos. Si se alcanza, el `DENY` se va con el login y no hay nada que revertir; si hay un camino que no lo alcanza, un `DENY` que queda restringe y nunca abre, así que tampoco hay que revertirlo. Escribí en un comentario cuál de los dos casos es, con la línea |
| `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | `AC44`: las dos menciones de "sin confirmar" (~172 y ~1021) y el paso 6 del "Orden de ejecución", que pide medir un valor que ya está medido. `AC48`: sección de verificación nueva, con los pasos **como el login**. Y una nota en las verificaciones de `AC7`, `AC42` y `AC43`: miden membresía (`sys.database_principals`), no visibilidad — lo que ve el login lo verifica `AC48` |
| `plugins/bisalta-db/catalogo.json` | la `condicion` de `rol-solo-lectura` en las **seis** entradas de SQL Server: que el rechazo es por privilegio (`Msg 262`, reportado por Patrick el 23-sep) y el consumidor no lo puede apagar, **además** de lo que ya dice sobre `db_denydatawriter`. **Nada más del catálogo cambia**: el `nivel` sigue `condicional` (contract v17, punto 4) |
| `plugins/bisalta-db/README.md` | la tabla "Garantías por motor": la fila nueva de enumeración de bases (copiala del contract), y la fila del rol en SQL Server con lo del privilegio |
| `SDD/verification/feat-GEN-108-mcp-bisalta-db-R1-v17.md` | la evidencia |

**No tocás**: el contract, `SDD/retro.md`, `SDD/debt.md`, `SDD/escalations.md`, `SDD/FEATURE-READY-GEN-108.md`, `CHANGELOG.md`, nada fuera de `plugins/bisalta-db/` salvo el report, y **ningún test** (ninguno lee `aprovisionamiento/`, y v17 no pide uno).

## Pasos

- [ ] **T1** Leer el contract v17 y `quality-gates.md` §5 y §6.
- [ ] **T2** Los cambios de la tabla de arriba.
- [ ] **T3** Barrido por concepto: `grep -rn -i "sin confirmar\|MachineName"` en `plugins/bisalta-db/` y revisar cada aparición contra v17. Ninguna aparición puede seguir diciendo que el valor falta medirse.
- [ ] **T4** Suite y secret-scan en verde. Commit (`[FIX] [GEN-108] [bisalta-db] …`, cerrando con `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`). Árbol limpio.
- [ ] **T5** Evidencia: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh -o SDD/verification/feat-GEN-108-mcp-bisalta-db-R1-v17.md --full` sobre el árbol limpio, y un addendum con: el diff de los `.sql` y del runbook, el resultado del barrido de T3, lo que encontraste en el inverso, y las cifras de Patrick de arriba **citadas como reportadas por él**. La verificación de `AC48` desde el plugin la agrega el planner. Commit y push.

## Reglas innegociables

- **Ninguna conexión a ninguna base.** Este alcance no la necesita.
- Mitigaciones prohibidas (`quality-gates.md` §6). Ninguna dependencia nueva. Un literal con forma de credencial se arma en piezas.
- No declares una validación que no corriste.
- Si algo del contract es ambiguo, `blocked` con la pregunta. No elijas.

## Retorno

El último bloque es el JSON `sdd.result` (`plugins/sdd-flow/standards/orchestration.md` §2).

## Execution Report

(lo llenás vos)
