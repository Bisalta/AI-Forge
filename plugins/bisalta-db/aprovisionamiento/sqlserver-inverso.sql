-- sqlserver-inverso.sql
--
-- Revierte sqlserver-parte-b.sql (quita a bisalta_lectura como user de
-- cada base donde exista) y sqlserver-parte-a.sql (DROP LOGIN).
--
-- REVOCA POR ENUMERACIÓN, NO LEE @bases_permitidas (contract v10, decisión
-- de Patrick Ocampo, Slack 21-sep-2026 12:44): rechazó el procedimiento de
-- baja de la ronda anterior —correr este archivo con la lista completa y
-- editarla después— porque "depende de que alguien recuerde el orden". Su
-- regla, textual: "Se concede desde una lista explícita, se revoca por
-- enumeración." Este script recorre `sys.databases` ENTERO, sin ningún
-- filtro por nombre ni por lista, buscando en cada base si
-- `sys.database_principals` tiene a `bisalta_lectura`, y lo saca de donde
-- lo encuentre.
--
-- POR QUÉ DOS MECANISMOS DISTINTOS PARA CONCEDER Y PARA REVOCAR: para
-- CONCEDER (sqlserver-parte-b.sql) hace falta que mande la DECLARACIÓN —
-- una base que nadie pidió no debe entrar, así que el criterio tiene que
-- ser una lista explícita, nunca "todo lo que haya". Para REVOCAR hace
-- falta que mande la REALIDAD — hay que encontrar el user hasta donde
-- nadie lo anotó: lo que quedó de una corrida vieja, de una lista que ya
-- cambió, o de alguien que lo creó a mano, editando la lista de la parte B
-- por su cuenta. Un inverso que sólo leyera @bases_permitidas nunca vería
-- ninguno de esos tres casos. Dos direcciones, dos fuentes de verdad.
--
-- ES UNA REVOCACIÓN TOTAL, A PROPÓSITO: correr este archivo saca a
-- bisalta_lectura de TODAS las bases donde exista hoy —incluidas las que
-- siguen vigentes en la lista de sqlserver-parte-b.sql— y al final borra
-- el login incondicionalmente. Como la enumeración ya barrió el
-- universo entero antes de llegar a esa línea, al terminar el bucle el
-- login no le hace falta a ninguna base: el DROP LOGIN incondicional ya
-- no es una carrera contra "¿queda alguien que todavía lo necesite?",
-- es la consecuencia directa de haber revisado dónde estaba.
--
-- PARA DAR DE BAJA UNA SOLA BASE, MANTENIENDO LAS DEMÁS ACTIVAS: no se usa
-- este archivo solo, ni una copia recortada de él (eso es exactamente lo
-- que Patrick rechazó). El procedimiento (RUNBOOK.md, sección "Inverso" →
-- "Procedimiento de baja") es: (1) sacar esa base del INSERT de
-- sqlserver-parte-b.sql y registrar la baja en APROBACIONES.md; (2) correr
-- ESTE archivo real, sin modificar — revoca todo, login incluido; (3)
-- volver a correr sqlserver-parte-a.sql (recrea el login, con una
-- contraseña nueva que hay que cargar de nuevo en Secrets Manager) y
-- sqlserver-parte-b.sql real (re-concede exactamente lo que la lista, ya
-- actualizada, declara). El mecanismo para conservar las bases que se
-- quedan no es "no tocarlas": es volver a concederlas desde la
-- declaración, que es justamente lo único que sqlserver-parte-b.sql sabe
-- hacer bien.
--
-- SIN SALTOS SILENCIOSOS (mismo criterio que sqlserver-parte-b.sql): si
-- una base no está ONLINE (state <> 0), el script lo dice por PRINT y
-- sigue con el resto — nunca la saltea sin avisar. No hay guarda de
-- "bases prohibidas": a diferencia de conceder, donde SSISDB y las cuatro
-- de sistema nunca deben recibir el user, acá el objetivo es exactamente
-- encontrarlo en cualquier lado si llegó a estar — incluida cualquier base
-- donde nunca debería haber estado.
--
-- Tolerante a que el user o el login no existan: correrlo sobre una
-- instancia ya revertida, o dos veces seguidas, sale sin error.

DECLARE @db_name SYSNAME;
DECLARE @sql NVARCHAR(MAX);
DECLARE @estado TINYINT;

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT name FROM sys.databases;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
  SET @estado = NULL;
  SELECT @estado = state FROM sys.databases WHERE name = @db_name;

  IF @estado <> 0
  BEGIN
    PRINT N'NO ONLINE: ' + @db_name
      + N' existe pero sys.databases.state = ' + CAST(@estado AS NVARCHAR(10))
      + N' (0 = ONLINE). No se puede USE sobre ella en este estado — reintentar cuando esté ONLINE.';
  END
  ELSE
  BEGIN
    SET @sql = N'
      USE ' + QUOTENAME(@db_name) + N';
      IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''bisalta_lectura'')
      BEGIN
        DROP USER bisalta_lectura;
      END';

    EXEC sp_executesql @sql;
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
