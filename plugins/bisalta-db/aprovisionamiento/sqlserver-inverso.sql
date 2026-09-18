-- sqlserver-inverso.sql
--
-- Revierte sqlserver-parte-b.sql (quita bisalta_lectura de cada base como
-- user, incluida su membresía en db_denydatawriter — contract v5, AC42)
-- y sqlserver-parte-a.sql (DROP LOGIN). Mismo recorrido con cursor
-- explícito que la parte B, por la misma razón: no usar sp_MSforeachdb.
--
-- La membresía en db_denydatawriter se quita explícitamente (ALTER ROLE
-- ... DROP MEMBER) ANTES de DROP USER, en vez de asumir que borrar el
-- user alcanza para esa red en particular — el DENY es lo que más importa
-- dejar registrado como revertido a propósito, no como efecto colateral.
-- db_datareader, en cambio, no lleva su propio DROP MEMBER: desaparece
-- implícitamente cuando DROP USER borra el principal, que es suficiente
-- para esa membresía (no hay un DENY ahí cuyo estado haga falta narrar
-- aparte). No es la misma explicitud para las dos — sólo la del DENY
-- necesita decirse.
--
-- SSISDB queda excluida del WHERE por el mismo nombre que la parte B
-- (contract v6, "Cambios v5 → v6", punto 1): sqlserver-parte-b.sql nunca
-- le crea el user ahí, así que el `IF EXISTS` de abajo ya la habría
-- saltado sola sin esta línea — se deja explícita igual, por la misma
-- razón que el filtro de la parte B es una condición visible en el WHERE
-- y no un salto implícito: quien lea este cursor ve la misma exclusión
-- en los dos scripts, sin tener que inferirla de la tolerancia del
-- `IF EXISTS`.
--
-- Tolerante a que el user o el login no existan: correrlo sobre una
-- instancia ya revertida, o dos veces seguidas, sale sin error.

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT name
  FROM sys.databases
  WHERE database_id > 4
    AND name <> 'SSISDB'
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
