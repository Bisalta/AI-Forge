-- postgres-parte-0.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` — PARTE 0.
-- Corre ANTES de postgres-parte-a.sql, contra el mismo cluster, y ANTES de
-- crear ningún rol (contract SDD/contracts/2026-09-18-bisalta-db-mcp.md v6,
-- AC41).
--
-- Estado (contract v6, "Cambios v5 → v6", punto 2): Patrick Ocampo provee
-- el aprovisionamiento de Postgres — su Parte 0 ya existe, con la misma
-- condición (`datname ILIKE '%prod%'`, equivalente a `_prod` acá) — pero
-- todavía no la mandó. Este archivo queda como IMPLEMENTACIÓN DE
-- REFERENCIA hasta que llegue el suyo, momento en el que se compara y se
-- reemplaza. Mientras tanto corre el mismo criterio de correctitud que el
-- resto de R1: el hallazgo de la ronda 5 de review (columna que no
-- discrimina, ver PASO 1 abajo) se corrige acá igual, porque vale para
-- los dos scripts, el propio y el que llegue.
--
-- Por qué existe: hallazgo medido por Patrick Ocampo el 18-sep-2026 (ver
-- "Cambios v3 → v4" del contract). `GRANT pg_read_all_data` es una
-- MEMBRESÍA DE CLUSTER, y Postgres concede `CONNECT` a PUBLIC por omisión
-- en toda base — así que un rol creado por postgres-parte-a.sql alcanza
-- TODAS las bases del cluster desde el momento en que existe, sin que
-- nadie tenga que conceder nada más. postgres-parte-b.sql NO es la
-- barrera de acceso: para cuando corre, el acceso ya existe (ver su propio
-- encabezado). Medido: 29 bases en el cluster de dev/qa
-- (plugins/bisalta-db/aprovisionamiento/INVENTARIO.md), no las 2 que
-- declara el catálogo de la aplicación.
--
-- Qué hace este script, en dos pasos, los dos de sólo lectura:
--
--   PASO 1 (informativo) — para cada rol con LOGIN que ya exista en el
--   cluster, imprime dos columnas por base, ninguna alcanza sola (hallazgo
--   de la ronda 5 de review, MAJOR 2 — contract v6):
--
--     - has_database_privilege(..., 'CONNECT'): ve el CONNECT heredado de
--       PUBLIC, que es lo que la columna sí prueba. Pero CONNECT no es
--       leer, y Postgres lo concede a PUBLIC por omisión en TODA base, así
--       que esta columna sale 'true' para cualquier rol en cualquier base,
--       CON o SIN pg_read_all_data. Sola, no discrimina: un GRANT
--       pg_read_all_data omitido pasaría igual de verde.
--     - pg_has_role(rolname, 'pg_read_all_data', 'MEMBER'): membresía DE
--       CLUSTER, la misma en las 29 bases porque no depende de en cuál se
--       consulta — es la forma de ver si el rol de verdad "lee todo",
--       sin que el ACL de la base (pg_database.datacl) tenga que
--       mencionarlo (cuando CONNECT nunca se revocó explícitamente el ACL
--       puede estar vacío/NULL y el CONNECT seguir vigente igual).
--
--   Las dos juntas, no una sola, son lo que permite afirmar "el rol
--   alcanza esta base de verdad": CONNECT sin la membresía no alcanzaría
--   para leer, y la membresía sin CONNECT no podría ni conectar.
--
--   PASO 2 (de control) — aborta con una excepción si el cluster
--   contiene alguna base cuyo nombre TERMINA EN `_prod`. Corrido con
--   `psql -v ON_ERROR_STOP=1` (obligatorio — ver RUNBOOK.md, mismo
--   criterio que los demás `.sql` de este directorio), una excepción acá
--   hace que `psql` salga con exit distinto de 0 y no siga a
--   postgres-parte-a.sql: ningún rol se crea.
--
-- El discriminante es QUÉ CONTIENE EL CLUSTER, nunca el nombre de la base
-- que alguien quiere consultar, y nunca la partícula `stg`. Medido en las
-- dos direcciones (INVENTARIO.md) que ese nombre falla como
-- discriminante: `controlactivos_stg` es un clon que VIVE en el cluster
-- de dev/qa (falso positivo si se rechazara por `stg`), y las cinco
-- `_stg` peligrosas de la empresa son peligrosas por vivir en el cluster
-- de PRODUCCIÓN (`cluster-cr4rbgr7qlr6`, contract, sección "Out of
-- scope"), no por llamarse `_stg` (falso negativo si `_prod` fuera el
-- único chequeo y alguien asumiera que `_stg` ya está cubierto por otro
-- lado). Este script sólo tiene sentido corrido contra el cluster de
-- dev/qa (`sistemas-costruplaza-db.cluster-cfrl3owqzwof`); nunca contra
-- `cluster-cr4rbgr7qlr6`.
--
-- Ratificación pendiente: Patrick Ocampo, dueño de este mecanismo, tiene
-- que ratificar el discriminante `_prod` antes de la primera corrida real
-- contra un cluster real (contract v5, tabla de responsabilidades de
-- "Cambios v4 → v5", punto (e)). Hasta esa ratificación, este script
-- queda `manual-only` como el resto de R1: ningún harness de este repo
-- levanta un cluster Postgres real (AC41).
--
-- No crea ni modifica nada: es SELECT y, si corresponde, RAISE EXCEPTION.
-- Read-only, y por eso también idempotente por definición — correrlo N
-- veces contra el mismo cluster da siempre el mismo resultado.

-- PASO 1 — informativo: a qué bases llega cada rol con LOGIN, de verdad.
-- Las dos columnas juntas son la comprobación (ver comentario de arriba):
-- puede_conectar sola no discrimina pg_read_all_data presente de ausente.
SELECT r.rolname AS rol,
       d.datname AS base,
       has_database_privilege(r.rolname, d.datname, 'CONNECT') AS puede_conectar,
       pg_has_role(r.rolname, 'pg_read_all_data', 'MEMBER') AS lee_todo_el_cluster
FROM pg_roles r
CROSS JOIN pg_database d
WHERE r.rolcanlogin = true
  AND d.datistemplate = false
ORDER BY r.rolname, d.datname;

-- PASO 2 — de control: abortar si el cluster contiene alguna base `_prod`.
DO $$
DECLARE
  v_cantidad int;
  v_bases    text;
BEGIN
  SELECT count(*), string_agg(datname, ', ' ORDER BY datname)
    INTO v_cantidad, v_bases
    FROM pg_database
    WHERE datistemplate = false
      AND datname LIKE '%\_prod' ESCAPE '\';

  IF v_cantidad > 0 THEN
    RAISE EXCEPTION
      'Parte 0: el cluster contiene % base(s) cuyo nombre termina en _prod (%). Este NO es el cluster de dev/qa (sistemas-costruplaza-db.cluster-cfrl3owqzwof). Abortando antes de crear ningún rol.',
      v_cantidad, v_bases;
  END IF;
END
$$;
