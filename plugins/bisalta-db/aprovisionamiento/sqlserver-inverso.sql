-- sqlserver-inverso.sql
--
-- Revierte sqlserver-parte-b.sql (quita bisalta_lectura de cada base como
-- user, incluida su membresía en db_denydatawriter — contract v5, AC42)
-- y sqlserver-parte-a.sql (DROP LOGIN). Mismo recorrido con cursor
-- explícito que la parte B, por la misma razón: no usar sp_MSforeachdb.
--
-- La membresía en db_denydatawriter se quita explícitamente ANTES de
-- DROP USER, en vez de asumir que borrar el user alcanza: este script
-- documenta el estado que revierte con la misma explicitud con la que
-- sqlserver-parte-b.sql documenta el que otorga.
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
    IF EXISTS (
      SELECT 1
      FROM sys.database_role_members drm
      JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
      JOIN sys.database_principals m ON drm.member_principal_id = m.principal_id
      WHERE r.name = ''db_denydatawriter'' AND m.name = ''bisalta_lectura''
    )
    BEGIN
      ALTER ROLE db_denydatawriter DROP MEMBER bisalta_lectura;
    END
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
