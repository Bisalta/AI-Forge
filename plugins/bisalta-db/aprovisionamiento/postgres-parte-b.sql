-- postgres-parte-b.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` — PARTE B.
-- Corre UNA VEZ POR BASE, conectado a esa base: el GRANT de este archivo
-- es por base, a diferencia de los roles de la parte A que son de cluster
-- (contract SDD/contracts/2026-09-18-bisalta-db-mcp.md v5, sección
-- "Garantías por motor (asimetría declarada, no disimulada)").
--
-- ESTE SCRIPT NO ES LA BARRERA DE ACCESO (corregido en v5 — no lo era
-- desde v4, pero el comentario original todavía lo presentaba así).
-- `pg_read_all_data`, que la parte A ya otorgó, es una membresía DE
-- CLUSTER, y Postgres concede `CONNECT` a PUBLIC por omisión en toda
-- base: para cuando este script corre, los roles `claude_lectura` y
-- `neo_lectura` YA leen las 29 bases del cluster de dev/qa
-- (INVENTARIO.md), no sólo las 2 que declara el catálogo de la
-- aplicación. La barrera real, la única que decide si esto corre contra
-- el cluster correcto, es postgres-parte-0.sql — correr ESE antes de
-- éste, siempre.
--
-- Qué hace este `GRANT CONNECT`, entonces, si no es la barrera: es un
-- refuerzo explícito y redundante hoy, documentando la intención sobre
-- las bases catalogadas por la aplicación. Sigue siendo útil como red:
-- si alguna vez alguien revoca `CONNECT` de PUBLIC puntualmente sobre
-- esta base (algo que hoy no está hecho en ninguna base del cluster),
-- este GRANT explícito sigue sosteniendo el acceso de los dos roles acá
-- sin depender del default de PUBLIC. Lo que este GRANT nunca hizo, ni
-- antes ni ahora, es limitar el acceso de los roles a sólo las bases
-- donde se lo corre — eso lo decide el cluster entero (parte 0), no esta
-- parte.
--
-- Orden de ejecución declarado en RUNBOOK.md: primero postgres-parte-0.sql
-- (control) y postgres-parte-a.sql (roles), después este archivo contra
-- proveedores_dev, verificar (AC1), después el resto de las bases del
-- catálogo (proveedores_qa y cualquier base que se agregue más adelante).
--
-- current_database() dentro de EXECUTE format(...) es justamente lo que
-- hace que este script sea "por base": el nombre de la base grantada es el
-- de la conexión activa al momento de correrlo, nunca un literal fijo.
--
-- Idempotente: GRANT CONNECT otorgado dos veces no falla.

DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO claude_lectura, neo_lectura', current_database());
END
$$;
