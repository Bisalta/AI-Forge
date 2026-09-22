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
-- Rol creado: claude_lectura — uno solo (contract v13, "Cambios v12 → v13"
-- punto 1). `neo_lectura` salió del diseño: NEO no abre ninguna conexión
-- Postgres, ni hoy ni en su diseño futuro — lee Odoo por XML-RPC, contra
-- la aplicación y no contra la base, y corre en la cuenta de producción,
-- no en la de dev. Un rol sin consumidor era una clave que rotar, una
-- cuenta que olvidar y una pista falsa de que los dos mundos estaban
-- conectados.
--
-- Lo que se resigna con un solo rol (D53, aceptado por Patrick Ocampo):
-- `pg_stat_activity` no va a distinguir consumidores el día que haya más
-- de uno. Hoy el único es Ian Vargas, así que no distingue nada que
-- exista. Cuando haga falta un segundo consumidor real, se agrega su rol
-- a este script (siguiendo el mismo patrón de `claude_lectura` de abajo) y
-- se vuelve a correr — es idempotente. Ver RUNBOOK.md, sección
-- "Aprovisionamiento — Parte A".
--
-- IMPORTANTE — GRANT pg_read_all_data, y SIN NOINHERIT (contract v3, AC1,
-- cerrada, no reabrir): pg_read_all_data es una MEMBRESÍA
-- (predefined role de Postgres), no un privilegio directo. Las membresías
-- no se aplican sin SET ROLE cuando el rol miembro tiene NOINHERIT. El
-- default de CREATE ROLE ya es INHERIT — este script no agrega NOINHERIT
-- en ningún lado. Si alguna vez alguien lo agrega, el rol queda sin ver una
-- sola tabla y AC1 falla.
--
-- Contraseña: NO vive en este archivo. Sustituir el placeholder de abajo
-- (<PASSWORD_CLAUDE_LECTURA>) por la contraseña real al ejecutar — ver
-- RUNBOOK.md, sección "Forma del secreto". El placeholder no es una
-- credencial real.
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

GRANT pg_read_all_data TO claude_lectura;
