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
-- base: para cuando este script corre, el rol `claude_lectura` YA lee
-- las 29 bases del cluster de dev/qa (INVENTARIO.md), no sólo las 2 que
-- declara el catálogo de la aplicación. La barrera real, la única que
-- decide si esto corre contra el cluster correcto, es
-- postgres-parte-0.sql — correr ESE antes de éste, siempre.
--
-- Qué hace este `GRANT CONNECT`, entonces, si no es la barrera: es un
-- refuerzo explícito y redundante hoy, documentando la intención sobre
-- las bases catalogadas por la aplicación. Sigue siendo útil como red:
-- si alguna vez alguien revoca `CONNECT` de PUBLIC puntualmente sobre
-- esta base (algo que hoy no está hecho en ninguna base del cluster),
-- este GRANT explícito sigue sosteniendo el acceso del rol acá sin
-- depender del default de PUBLIC. Lo que este GRANT nunca hizo, ni antes
-- ni ahora, es limitar el acceso del rol a sólo las bases donde se lo
-- corre — eso lo decide el cluster entero (parte 0), no esta parte.
--
-- Un solo rol (contract v13, "Cambios v12 → v13" punto 1): `neo_lectura`
-- salió del diseño porque NEO no abre ninguna conexión Postgres. Si algún
-- día se agrega un segundo consumidor real, se agrega su rol acá a la
-- lista del GRANT (y a la parte A) — ver RUNBOOK.md.
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
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO claude_lectura', current_database());
END
$$;

-- AC50 (contract v19, "Cambios v18 → v19" punto 3). El REVOKE CREATE ON
-- SCHEMA public FROM PUBLIC que Patrick aplicó a mano el 22-sep en las seis
-- bases no estaba en ningún script: una base nueva agregada acá volvía a
-- tener el hueco (PG 14 concede CREATE en `public` a PUBLIC por omisión —
-- ver "Cambios v14 → v15" punto 2). EL ORDEN ES LA CONDICIÓN: revocar
-- primero rompería las migraciones de quien ya crea ahí, así que primero se
-- concede CREATE explícito al dueño de la base y a todo rol que YA tenga
-- objetos en `public` — relaciones (pg_class), funciones (pg_proc) y tipos
-- (pg_type), enumerados acá desde el catálogo, nunca
-- escritos a mano, porque son distintos por base (INVENTARIO.md) — y recién
-- después se revoca de PUBLIC. Idempotente: GRANT y REVOKE repetidos no
-- fallan.
DO $$
DECLARE
  duenio_base text := (SELECT pg_catalog.pg_get_userbyid(datdba) FROM pg_database WHERE datname = current_database());
  duenio_objeto text;
BEGIN
  EXECUTE format('GRANT CREATE ON SCHEMA public TO %I', duenio_base);

  FOR duenio_objeto IN
    -- Los tres catálogos de objetos con dueño en un esquema. Con sólo
    -- pg_class, un rol que en `public` tiene funciones o tipos pero ninguna
    -- tabla no recibía el GRANT, y su próxima migración fallaba (review de
    -- v19 y v20, 24-sep-2026).
    -- Se excluyen los superusuarios: no necesitan el GRANT y en RDS el
    -- interno `rdsadmin` es dueño de funciones de extensiones en `public`;
    -- concederle algo no suma nada y arriesga que el bloque aborte. Medido
    -- en proveedores_dev el 24-sep: los dueños son `proveedores` (tablas y
    -- tipos), el usuario maestro (una función y dos tipos, que con sólo
    -- pg_class quedaba afuera) y `rdsadmin` (superusuario).
    SELECT r.rolname
      FROM pg_catalog.pg_roles r
     WHERE NOT r.rolsuper
       AND r.oid IN (
         SELECT c.relowner FROM pg_catalog.pg_class c WHERE c.relnamespace = 'public'::regnamespace
         UNION
         SELECT f.proowner FROM pg_catalog.pg_proc f WHERE f.pronamespace = 'public'::regnamespace
         UNION
         SELECT t.typowner FROM pg_catalog.pg_type t WHERE t.typnamespace = 'public'::regnamespace
       )
  LOOP
    EXECUTE format('GRANT CREATE ON SCHEMA public TO %I', duenio_objeto);
  END LOOP;

  REVOKE CREATE ON SCHEMA public FROM PUBLIC;
END
$$;
