-- postgres-parte-a.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` — PARTE A.
-- Corre UNA VEZ POR CLUSTER, DESPUÉS de postgres-parte-0.sql (control: el
-- cluster no puede contener ninguna base `_prod`; ver ese archivo y AC41,
-- contract SDD/contracts/2026-09-18-bisalta-db-mcp.md v5) y ANTES de
-- postgres-parte-b.sql: los roles son objetos de cluster en Postgres, no
-- de base (contract v5, sección "Garantías por motor (asimetría
-- declarada, no disimulada)").
--
-- Cluster objetivo: identificador de cluster sistemas-costruplaza-db.cluster-cfrl3owqzwof
-- (dev/qa) — esto es el identificador de cluster, no el endpoint completo;
-- el endpoint completo para conectar es
-- sistemas-costruplaza-db.cluster-cfrl3owqzwof.us-east-1.rds.amazonaws.com
-- (RUNBOOK.md, sección "Prerequisitos").
-- NUNCA correr esto contra el cluster cuyo identificador es cluster-cr4rbgr7qlr6
-- (cuenta AWS de producción, donde viven los cinco pares _prod/_stg): un rol
-- de login creado ahí queda al lado de producción (contract v3, sección
-- "Out of scope").
--
-- Roles creados: claude_lectura, neo_lectura — dos, no uno, para que
-- pg_stat_activity distinga quién corrió qué y se pueda revocar a uno sin
-- el otro (contract v3, AC1).
--
-- IMPORTANTE — GRANT pg_read_all_data, y SIN NOINHERIT (contract v3, AC1,
-- cerrada, no reabrir): pg_read_all_data es una MEMBRESÍA
-- (predefined role de Postgres), no un privilegio directo. Las membresías
-- no se aplican sin SET ROLE cuando el rol miembro tiene NOINHERIT. El
-- default de CREATE ROLE ya es INHERIT — este script no agrega NOINHERIT
-- en ningún lado. Si alguna vez alguien lo agrega, el rol queda sin ver una
-- sola tabla y AC1 falla.
--
-- Contraseña: NO vive en este archivo. Sustituir los dos placeholders de
-- abajo (<PASSWORD_CLAUDE_LECTURA>, <PASSWORD_NEO_LECTURA>) por la
-- contraseña real al ejecutar — ver RUNBOOK.md, sección "Forma del
-- secreto". Ninguno de los dos placeholders es una credencial real.
--
-- Idempotente (AC3): correr esto dos veces seguidas sale 0 las dos veces y
-- deja el mismo conjunto de roles. CREATE ROLE no es idempotente por sí
-- solo en Postgres, así que se envuelve en un chequeo de existencia contra
-- pg_roles. GRANT sí es naturalmente idempotente (otorgar una membresía ya
-- otorgada no falla).

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'claude_lectura') THEN
    CREATE ROLE claude_lectura WITH LOGIN PASSWORD '<PASSWORD_CLAUDE_LECTURA>';
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'neo_lectura') THEN
    CREATE ROLE neo_lectura WITH LOGIN PASSWORD '<PASSWORD_NEO_LECTURA>';
  END IF;
END
$$;

GRANT pg_read_all_data TO claude_lectura;
GRANT pg_read_all_data TO neo_lectura;
