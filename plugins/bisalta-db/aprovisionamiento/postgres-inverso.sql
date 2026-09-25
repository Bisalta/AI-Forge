-- postgres-inverso.sql
--
-- Revierte postgres-parte-a.sql y postgres-parte-b.sql: revoca CONNECT en
-- la base actual, revoca la membresía pg_read_all_data y borra el rol
-- (AC4: tras correrlo, claude_lectura no puede conectar al cluster).
-- Un solo rol (contract v13): `neo_lectura` salió del diseño porque NEO
-- no abre ninguna conexión Postgres. Si se agrega un segundo consumidor
-- real más adelante, se agrega su bloque acá siguiendo el mismo patrón.
--
-- CÓMO CORRERLO (importante, ver RUNBOOK.md): conectado a CADA base donde
-- se corrió la parte B (proveedores_dev, proveedores_qa, y cualquier otra
-- que se haya agregado), en ese orden, una por una. DROP ROLE en Postgres
-- falla mientras el rol conserve cualquier privilegio en CUALQUIER base del
-- cluster (dependencia compartida vía pg_shdepend, catálogo cluster-wide) —
-- no sólo en la base actual. Por eso el DROP está envuelto en un manejo de
-- excepción: si todavía quedan privilegios en otra base, este script avisa
-- con RAISE NOTICE y NO falla; el DROP recién tiene efecto real la última
-- vez que se corre, contra la última base pendiente.
--
-- Tolerante a que los roles no existan (correrlo sobre un cluster ya
-- revertido, o dos veces seguidas, sale 0 las dos veces).

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'claude_lectura') THEN
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM claude_lectura', current_database());
    REVOKE pg_read_all_data FROM claude_lectura;
    BEGIN
      DROP ROLE claude_lectura;
    EXCEPTION WHEN dependent_objects_still_exist THEN
      RAISE NOTICE 'claude_lectura todavia tiene privilegios en otra base del cluster; correr este script tambien ahi antes de que el DROP tenga efecto';
    END;
  END IF;
END
$$;
