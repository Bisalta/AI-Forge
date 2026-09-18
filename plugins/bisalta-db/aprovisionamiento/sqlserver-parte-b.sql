-- sqlserver-parte-b.sql
--
-- Aprovisionamiento de solo lectura en `Dev SQL` — PARTE B: user por base
-- y membresía en db_datareader. db_datareader es un permiso POR BASE (a
-- diferencia de pg_read_all_data, que es de cluster): una base nueva NO
-- queda cubierta hasta que este script se corra otra vez (AC10, declarado
-- también en RUNBOOK.md).
--
-- Recorre sys.databases con un CURSOR EXPLÍCITO (contract v2, AC7 y
-- sección "Garantías por motor (asimetría declarada, no disimulada)",
-- cerrada, no reabrir). NO usar sp_MSforeachdb: no está soportado desde
-- SQL Server 2016+ y salta bases en algunos estados (ej. RESTORING,
-- OFFLINE) sin avisar.
--
-- Filtro: database_id > 4 (excluye master=1, tempdb=2, model=3, msdb=4,
-- las cuatro bases de sistema) y state = 0 (ONLINE únicamente). ~35 bases
-- de usuario medidas el 18-sep-2026 (AC7).
--
-- Corre con un login con privilegio de sysadmin en la instancia — nunca
-- con el propio bisalta_lectura que este script crea.
--
-- Idempotente: IF NOT EXISTS antes de CREATE USER y antes de ALTER ROLE
-- ADD MEMBER, así que correrlo dos veces no falla y no duplica membresías.

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT name
  FROM sys.databases
  WHERE database_id > 4   -- excluye master, tempdb, model, msdb
    AND state = 0;        -- ONLINE unicamente

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
    END';

  EXEC sp_executesql @sql;

  FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO
