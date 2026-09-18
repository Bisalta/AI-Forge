-- sqlserver-parte-b.sql
--
-- Aprovisionamiento de solo lectura en `Dev SQL` — PARTE B: user por base
-- y membresía en LAS DOS: db_datareader y db_denydatawriter (contract v5,
-- AC42 — v4 agregó la segunda; cerrada, no reabrir). Un `GRANT` nunca le
-- gana a un `DENY` en SQL Server, así que db_denydatawriter es la segunda
-- red: aunque alguien conceda INSERT/UPDATE/DELETE explícito al user más
-- adelante, el DENY de rol sigue ganando. Las dos son permisos POR BASE (a
-- diferencia de pg_read_all_data, que es de cluster): una base nueva NO
-- queda cubierta hasta que este script se corra otra vez (AC10, declarado
-- también en RUNBOOK.md).
--
-- Recorre sys.databases con un CURSOR EXPLÍCITO (contract v5, AC7/AC42 y
-- sección "Garantías por motor (asimetría declarada, no disimulada)",
-- cerrada, no reabrir). NO usar sp_MSforeachdb: no está soportado desde
-- SQL Server 2016+, y su exclusión de bases en estados como RESTORING u
-- OFFLINE es un comportamiento interno no documentado, sin condición
-- visible en el llamado ni forma de auditar qué bases quedaron afuera.
-- El filtro de este script, en cambio, es una condición explícita en el
-- WHERE del cursor (abajo): visible, versionada en este archivo, y
-- reproducible corriendo la misma consulta a mano contra sys.databases.
--
-- Filtro: database_id > 4 (excluye master=1, tempdb=2, model=3, msdb=4,
-- las cuatro bases de sistema), name <> 'SSISDB' (ver más abajo) y
-- state = 0 (ONLINE únicamente) — control explícito del filtro, no un
-- salto implícito del proveedor. 32 bases de usuario medidas el
-- 18-sep-2026, las 32 ONLINE
-- (plugins/bisalta-db/aprovisionamiento/INVENTARIO.md; el contract citaba
-- "~35" antes de esta medición); de esas 32, este script cubre **31**
-- (`SSISDB` queda afuera a propósito). Una base OFFLINE o RESTORING al
-- momento de esta corrida queda fuera de `state = 0` igual que quedaría
-- fuera de sp_MSforeachdb, y por el mismo motivo que una base nueva
-- (AC10, "Acción operativa" en RUNBOOK.md): re-correr este script cubre
-- ambos huecos.
--
-- SSISDB (database_id = 36, 5.77 GB, INVENTARIO.md) queda FUERA del loop,
-- por nombre (contract v6, "Cambios v5 → v6", punto 1 — decisión de
-- Patrick Ocampo, Slack 2026-09-18 15:52 CST). database_id > 4 sólo saca
-- las cuatro bases de sistema y no la agarra a ella, así que la exclusión
-- va explícita en el WHERE de abajo, no implícita en ese filtro. Razón,
-- textual: "guarda los proyectos desplegados con sus parámetros y
-- connection managers, o sea que es un lugar donde viven cadenas de
-- conexión, más los logs de ejecución. Cero dato de negocio y sí
-- credenciales." Un servidor MCP cuyo propósito es que ninguna credencial
-- pase por el contexto no puede alcanzar el lugar donde viven las cadenas
-- de conexión. Ya no es una decisión pendiente (era el punto (d) de
-- "Cambios v4 → v5"): quedó cerrada en v6.
--
-- Corre con un login con privilegio de sysadmin en la instancia — nunca
-- con el propio bisalta_lectura que este script crea.
--
-- Idempotente: IF NOT EXISTS antes de CREATE USER y antes de cada ALTER
-- ROLE ADD MEMBER, así que correrlo dos veces no falla y no duplica
-- membresías.

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT name
  FROM sys.databases
  WHERE database_id > 4     -- excluye master, tempdb, model, msdb
    AND name <> 'SSISDB'    -- fuera del loop, decision cerrada (contract v6)
    AND state = 0;          -- ONLINE unicamente

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'
    USE ' + QUOTENAME(@db_name) + N';
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''bisalta_lectura'')
    BEGIN
      CREATE USER bisalta_lectura FOR LOGIN bisalta_lectura;
    END
    IF NOT EXISTS (
      SELECT 1
      FROM sys.database_role_members drm
      JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
      JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
      WHERE r.name = ''db_datareader'' AND m.name = ''bisalta_lectura''
    )
    BEGIN
      ALTER ROLE db_datareader ADD MEMBER bisalta_lectura;
    END
    IF NOT EXISTS (
      SELECT 1
      FROM sys.database_role_members drm
      JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
      JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
      WHERE r.name = ''db_denydatawriter'' AND m.name = ''bisalta_lectura''
    )
    BEGIN
      ALTER ROLE db_denydatawriter ADD MEMBER bisalta_lectura;
    END';

  EXEC sp_executesql @sql;

  FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO
