-- sqlserver-inverso.sql
--
-- Revierte sqlserver-parte-b.sql (quita bisalta_lectura de cada base como
-- user, incluida su membresía en db_denydatawriter — contract v5, AC42)
-- y sqlserver-parte-a.sql (DROP LOGIN). Recorre la MISMA lista explícita
-- que sqlserver-parte-b.sql (contract v9, "Cambios v8 → v9") — nunca
-- sys.databases entero: si la parte B sólo tocó las bases nombradas, el
-- inverso sólo tiene que revisar esas mismas bases para deshacerlo. Si la
-- lista de abajo alguna vez difiere de la de sqlserver-parte-b.sql, ese
-- desvío es exactamente lo que hay que corregir primero — las dos listas
-- se editan juntas.
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
-- SIN SALTOS SILENCIOSOS (mismo criterio que sqlserver-parte-b.sql): si
-- un nombre de la lista no existe en esta instancia, o existe pero no
-- está ONLINE, este script lo dice por PRINT y sigue con el resto — nunca
-- lo saltea sin avisar. `SSISDB`, `master`, `model`, `msdb` y `tempdb`
-- nunca deberían estar en la lista de abajo (la parte B nunca les crea el
-- user), pero si aparecieran por error el bucle las salta igual, con el
-- mismo aviso que la parte B.
--
-- Tolerante a que el user o el login no existan: correrlo sobre una
-- instancia ya revertida, o dos veces seguidas, sale sin error.

DECLARE @bases_permitidas TABLE (nombre SYSNAME PRIMARY KEY);

-- MISMA lista que sqlserver-parte-b.sql (contract v9). Si se edita una,
-- se edita la otra en el mismo cambio.
INSERT INTO @bases_permitidas (nombre) VALUES
  (N'COMPRAS'),
  (N'COMPRAS_STG'),
  (N'Ecommerce'),
  (N'Ecommerce_qa'),
  (N'EXACTUS'),
  (N'BI');

DECLARE @bases_prohibidas TABLE (nombre SYSNAME PRIMARY KEY);

INSERT INTO @bases_prohibidas (nombre) VALUES
  (N'SSISDB'),
  (N'master'),
  (N'model'),
  (N'msdb'),
  (N'tempdb');

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);
DECLARE @estado TINYINT;

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT nombre FROM @bases_permitidas;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF EXISTS (SELECT 1 FROM @bases_prohibidas WHERE nombre = @db_name)
  BEGIN
    PRINT N'RECHAZADA (defensa en profundidad): ' + @db_name
      + N' está en la lista de bases que nunca reciben el user. Nada que revertir ahí.';
  END
  ELSE
  BEGIN
    SET @estado = NULL;
    SELECT @estado = state FROM sys.databases WHERE name = @db_name;

    IF @estado IS NULL
    BEGIN
      PRINT N'AUSENTE: ' + @db_name
        + N' no existe en sys.databases de esta instancia. Nada que revertir ahí en esta corrida.';
    END
    ELSE IF @estado <> 0
    BEGIN
      PRINT N'NO ONLINE: ' + @db_name
        + N' existe pero sys.databases.state = ' + CAST(@estado AS NVARCHAR(10))
        + N' (0 = ONLINE). No se puede USE sobre ella en este estado — reintentar cuando esté ONLINE.';
    END
    ELSE
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
    END
  END

  FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bisalta_lectura')
BEGIN
  DROP LOGIN bisalta_lectura;
END
GO
