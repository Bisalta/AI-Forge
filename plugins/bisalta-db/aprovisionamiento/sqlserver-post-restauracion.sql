/* ===========================================================================
   sqlserver-post-restauracion.sql — Dev SQL (10.24.40.137)

   CORRER DESPUES DE CADA RESTAURACION de cualquiera de las bases del catalogo.

   POR QUE EXISTE
   Un login de SQL Server vive en la INSTANCIA; el usuario que lo representa
   dentro de una base vive DENTRO de esa base. Una restauracion reemplaza la
   base entera, asi que el usuario se va con ella y el login queda sin puerta
   de entrada. No da error en la restauracion: falla despues, cuando alguien
   consulta, con "Cannot open database ... Using the user default database
   master instead". Nadie se entera hasta ese momento.

   Medido el 5-oct-2026: EXACTUS se restauro el 2-oct 12:11 (msdb.dbo.
   restorehistory, por `sa`) dos horas despues de concederle los permisos, y
   el usuario desaparecio. Las otras cinco los conservaban solo porque sus
   restauraciones fueron ANTES del 23-sep, cuando se creo el login.
   EXACTUS se restaura seguido: 8-jul, 9-sep, 2-oct.

   OJO CON EL SINTOMA: "Cannot open database" se lee como si la base no
   existiera, y no es un error de permisos que se reconozca como tal. Quien lo
   vea por primera vez va a ir a buscar la base, no el usuario. La base esta;
   el que falta es el usuario. (Patrick Ocampo, 5-oct-2026)

   Es idempotente: correrlo de mas no hace nada. Correrlo de menos se nota
   tarde. Ante la duda, correlo.

   AUTORIA: Patrick Ocampo (5-oct-2026), probado contra la instancia.
   Corregido el mismo dia a pedido de Ian Vargas (deuda D102), en la guarda
   final:
     1) Un RAISERROR de severidad 16 no corta el batch: la version anterior
        imprimia el error y DESPUES "GUARDA OK". Ahora las fallas se juntan y
        el batch termina con THROW, que si lo corta. "GUARDA OK" sale solo si
        no hubo ninguna.
     2) Una base esperada que no esta ONLINE cuenta como falla de la guarda.
        Antes se avisaba en la reparacion y la guarda la excluia.
     3) "Puede escribir" mira tambien los permisos concedidos directo al
        usuario (INSERT, UPDATE, DELETE, EXECUTE, ALTER, CONTROL, CREATE ...),
        no solo la pertenencia a roles.

   PROBADO (5-oct-2026, contra la instancia, en transacciones deshechas):
     - camino feliz: Ian Vargas, sqlcmd -b, seis bases 1/1/0/0, exit 0.
     - correccion 1: Patrick, sin VIEW DEFINITION en Ecommerce_qa ->
       "GUARDA FALLIDA" y NO se imprime "GUARDA OK".
     - correccion 3: Patrick, por tres caminos (GRANT INSERT y GRANT EXECUTE
       sobre el esquema, y db_ddladmin) -> los tres dan "puede ESCRIBIR".
     - correccion 2 (base que no esta ONLINE): NO probada. Para hacerlo habia
       que poner una base offline en una instancia compartida; no valia el
       riesgo. Es el unico camino sin correr.

   COMO CORRERLO: con sqlcmd, que respeta los GO. Usar -b para que el exit
   code refleje la guarda, y -N true -C por el certificado de la instancia:
     sqlcmd -S <host> -U <tu usuario> -N true -C -b -i sqlserver-post-restauracion.sql
   SSMS tambien respeta los GO. DBeaver NO sirve (medido el 5-oct-2026):
   seleccionar todo y ejecutar manda los GO al servidor ("Incorrect syntax
   near 'GO'"), y "Execute script" parte en cada ';' y separa cada variable
   de su DECLARE ("Must declare the scalar variable @maquina").
   =========================================================================== */

SET NOCOUNT ON;
GO

/* --- GUARDA DE INSTANCIA -------------------------------------------------
   El login y sus permisos son objetos de instancia. NEO lee otro SQL Server
   (BD-PRINCIPAL), que es produccion.                                        */
DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';

IF @maquina <> @esperada
BEGIN
    RAISERROR(N'ABORTA: este script solo corre en Dev SQL (%s). Estas en %s.',
              16, 1, @esperada, @maquina);
    SET NOEXEC ON;
END
ELSE
    PRINT 'Guarda OK: instancia ' + @maquina;
GO

/* --- EL LOGIN TIENE QUE EXISTIR ------------------------------------------
   Una restauracion no lo toca. Si falta, el problema es otro y hay que
   mirarlo antes de seguir: lo crea sqlserver-parte-a.sql.                   */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'bisalta_lectura')
BEGIN
    RAISERROR(N'ABORTA: el login bisalta_lectura no existe en la instancia. Esto no lo causa una restauracion: correr sqlserver-parte-a.sql.', 16, 1);
    SET NOEXEC ON;
END
GO

/* --- REPARAR CADA BASE DEL ALCANCE ---------------------------------------
   La lista es la misma de sqlserver-parte-b.sql. Agregar una base al catalogo
   = agregarla tambien aca (y en la guarda final), o se va a romper en la
   primera restauracion.                                                     */
DECLARE @bases TABLE (nombre sysname);
INSERT INTO @bases (nombre) VALUES
    (N'COMPRAS'), (N'COMPRAS_STG'), (N'Ecommerce'),
    (N'Ecommerce_qa'), (N'EXACTUS'), (N'BI');

DECLARE @b sysname, @sql nvarchar(max);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT nombre FROM @bases;
OPEN cur;
FETCH NEXT FROM cur INTO @b;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @b AND state_desc = 'ONLINE')
        /* Avisa, no saltea en silencio: una base fuera de linea durante la
           reparacion es justo la que va a quedar rota. La guarda final la
           cuenta como falla. */
        RAISERROR(N'La base %s no existe o no esta ONLINE. Volver a correr cuando lo este.', 16, 1, @b);
    ELSE
    BEGIN
        SET @sql = N'USE ' + QUOTENAME(@b) + N';

            /* Tres estados posibles despues de una restauracion:
               1) el usuario no esta         -> se crea
               2) esta pero HUERFANO: vino en el respaldo del servidor de
                  origen y su SID no es el de NUESTRO login. Existe, asi que
                  CREATE USER falla, y sin embargo el login no entra. Se
                  reengancha con ALTER USER ... WITH LOGIN.
               3) esta y enganchado          -> no se toca                    */
            IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''bisalta_lectura'')
            BEGIN
                CREATE USER [bisalta_lectura] FOR LOGIN [bisalta_lectura];
                PRINT ''  usuario creado'';
            END
            ELSE IF EXISTS (
                SELECT 1 FROM sys.database_principals dp
                 WHERE dp.name = N''bisalta_lectura''
                   AND dp.type IN (''S'',''U'')
                   AND dp.sid <> (SELECT sid FROM sys.server_principals WHERE name = N''bisalta_lectura''))
            BEGIN
                ALTER USER [bisalta_lectura] WITH LOGIN = [bisalta_lectura];
                PRINT ''  usuario HUERFANO reenganchado'';
            END

            ALTER ROLE db_datareader ADD MEMBER [bisalta_lectura];
            GRANT VIEW DEFINITION TO [bisalta_lectura];';

        PRINT @b;
        EXEC sp_executesql @sql;
    END
    FETCH NEXT FROM cur INTO @b;
END
CLOSE cur;
DEALLOCATE cur;
GO

/* --- GUARDA FINAL --------------------------------------------------------
   Mide en vez de confiar, y FALLA. Un script de reparacion que imprime
   "listo" cuando algo quedo mal es peor que no tenerlo. Por eso las fallas
   se juntan y el batch termina con THROW: RAISERROR de severidad 16 no
   corta el batch, y el PRINT de abajo salia igual.                          */
DECLARE @esperadas TABLE (nombre sysname);
INSERT INTO @esperadas (nombre) VALUES
    (N'COMPRAS'), (N'COMPRAS_STG'), (N'Ecommerce'),
    (N'Ecommerce_qa'), (N'EXACTUS'), (N'BI');

DECLARE @h TABLE (base sysname, lee bit, ve_definicion bit, escribe bit, huerfano bit);
DECLARE @b sysname, @sql nvarchar(max);

DECLARE cur2 CURSOR LOCAL FAST_FORWARD FOR
    SELECT e.nombre FROM @esperadas e
     WHERE EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = e.nombre AND d.state_desc = 'ONLINE');
OPEN cur2;
FETCH NEXT FROM cur2 INTO @b;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'USE ' + QUOTENAME(@b) + N';
        SELECT ' + QUOTENAME(@b, '''') + N',
               CONVERT(bit, IS_ROLEMEMBER(''db_datareader'', ''bisalta_lectura'')),
               CONVERT(bit, CASE WHEN EXISTS (
                   SELECT 1 FROM sys.database_permissions p
                     JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
                    WHERE dp.name = N''bisalta_lectura'' AND p.permission_name = ''VIEW DEFINITION''
                      AND p.state_desc = ''GRANT'' AND p.class = 0) THEN 1 ELSE 0 END),
               CONVERT(bit, CASE WHEN IS_ROLEMEMBER(''db_datawriter'',''bisalta_lectura'') = 1
                                   OR IS_ROLEMEMBER(''db_owner'',''bisalta_lectura'') = 1
                                   OR IS_ROLEMEMBER(''db_ddladmin'',''bisalta_lectura'') = 1
                                   OR IS_ROLEMEMBER(''db_securityadmin'',''bisalta_lectura'') = 1
                                   OR EXISTS (
                                       SELECT 1 FROM sys.database_permissions p
                                         JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
                                        WHERE dp.name = N''bisalta_lectura''
                                          AND p.state_desc IN (''GRANT'', ''GRANT_WITH_GRANT_OPTION'')
                                          AND (p.permission_name IN (''INSERT'', ''UPDATE'', ''DELETE'', ''EXECUTE'',
                                                                     ''ALTER'', ''CONTROL'', ''TAKE OWNERSHIP'',
                                                                     ''ALTER ANY SCHEMA'', ''ALTER ANY USER'',
                                                                     ''ALTER ANY ROLE'')
                                               OR p.permission_name LIKE ''CREATE %''))
                                  THEN 1 ELSE 0 END),
               CONVERT(bit, CASE WHEN EXISTS (
                   SELECT 1 FROM sys.database_principals dp
                    WHERE dp.name = N''bisalta_lectura'' AND dp.type IN (''S'',''U'')
                      AND dp.sid <> (SELECT sid FROM sys.server_principals WHERE name = N''bisalta_lectura''))
                                  THEN 1 ELSE 0 END);';
    INSERT INTO @h (base, lee, ve_definicion, escribe, huerfano) EXEC sp_executesql @sql;
    FETCH NEXT FROM cur2 INTO @b;
END
CLOSE cur2;
DEALLOCATE cur2;

SELECT base, lee, ve_definicion, escribe AS puede_escribir, huerfano FROM @h ORDER BY base;

DECLARE @fallas nvarchar(2000) = N'';

IF EXISTS (SELECT 1 FROM @esperadas e
            WHERE NOT EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = e.nombre AND d.state_desc = 'ONLINE'))
    SET @fallas += N' Alguna base esperada no existe o no esta ONLINE: no se reparo ni se midio.';

IF EXISTS (SELECT 1 FROM @esperadas e
            WHERE EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = e.nombre AND d.state_desc = 'ONLINE')
              AND NOT EXISTS (SELECT 1 FROM @h h WHERE h.base = e.nombre AND h.lee = 1 AND h.ve_definicion = 1))
    SET @fallas += N' Alguna base quedo sin lectura o sin VIEW DEFINITION.';

IF EXISTS (SELECT 1 FROM @h WHERE escribe = 1)
    SET @fallas += N' bisalta_lectura puede ESCRIBIR en alguna base: asi no sirve.';

IF EXISTS (SELECT 1 FROM @h WHERE huerfano = 1)
    SET @fallas += N' Quedo un usuario huerfano: el reenganche no funciono.';

IF @fallas <> N''
BEGIN
    SET @fallas = N'GUARDA FALLIDA:' + @fallas + N' Ver la tabla de arriba.';
    THROW 50000, @fallas, 1;
END

PRINT 'GUARDA OK: bisalta_lectura lee y ve definiciones en las seis bases, y no escribe en ninguna.';
GO

/* --- NO HACE FALTA REPETIR ACA -------------------------------------------
   El DENY VIEW ANY DATABASE es permiso de INSTANCIA, no de base: una
   restauracion no lo toca. Si alguna vez se recrea el LOGIN, eso si hay que
   volver a ponerlo — vive en sqlserver-parte-a.sql.                         */
