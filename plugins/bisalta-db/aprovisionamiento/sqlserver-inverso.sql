-- sqlserver-inverso.sql
--
-- Revierte sqlserver-parte-b.sql (quita bisalta_lectura de cada base como
-- user) y sqlserver-parte-a.sql (DROP LOGIN). Mismo recorrido con cursor
-- explícito que la parte B, por la misma razón: no usar sp_MSforeachdb.
--
-- Tolerante a que el user o el login no existan: correrlo sobre una
-- instancia ya revertida, o dos veces seguidas, sale sin error.

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT name
  FROM sys.databases
  WHERE database_id > 4
    AND state = 0;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @sql = N'
    USE ' + QUOTENAME(@db_name) + N';
    IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''bisalta_lectura'')
    BEGIN
      DROP USER bisalta_lectura;
    END';

  EXEC sp_executesql @sql;

  FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bisalta_lectura')
BEGIN
  DROP LOGIN bisalta_lectura;
END
GO
