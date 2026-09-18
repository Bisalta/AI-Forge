-- postgres-parte-b.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` — PARTE B.
-- Corre UNA VEZ POR BASE, conectado a esa base: los GRANT de este archivo
-- son por base, a diferencia de los roles de la parte A que son de cluster
-- (contract SDD/contracts/2026-09-18-bisalta-db-mcp.md v2, sección
-- "Garantías por motor (asimetría declarada, no disimulada)").
--
-- Orden de ejecución declarado en RUNBOOK.md: primero proveedores_dev,
-- verificar (AC1), después el resto de las bases del catálogo
-- (proveedores_qa y cualquier base que se agregue más adelante).
--
-- Qué otorga: GRANT CONNECT sobre la base actual a los dos roles. Es lo que
-- pg_read_all_data NO cubre por sí solo: esa membresía resuelve SELECT
-- sobre tablas/vistas/secuencias y USAGE sobre esquemas de forma dinámica
-- en todas las bases del cluster, pero el privilegio de CONNECT sobre una
-- base puntual es independiente y no viene incluido en la membresía.
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
