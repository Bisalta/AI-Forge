-- sqlserver-parte-b.sql
--
-- Aprovisionamiento de solo lectura en `Dev SQL` — PARTE B: user por base
-- y membresía en `db_datareader`, Y NADA MÁS (contract v10, AC42 —
-- decisión de Patrick Ocampo que revierte el punto 4 de v4: `db_datareader`
-- es la ÚNICA garantía en SQL Server, no la primera de dos). `db_datareader`
-- es permiso POR BASE (a diferencia de `pg_read_all_data`, que es de
-- cluster): una base nueva NO queda cubierta hasta que se agregue a la
-- lista de abajo Y este script se corra otra vez (AC10, declarado también
-- en RUNBOOK.md).
--
-- SALE `db_denydatawriter` (contract v10; hasta v9 este script la
-- otorgaba junto con `db_datareader`, con el `DENY` ganándole a cualquier
-- `GRANT` posterior). Se escribe acá lo que se pierde, con las palabras de
-- quien lo decidió (Patrick Ocampo, Slack 21-sep-2026 12:22, textual en
-- `APROBACIONES.md` punto 6): *"sin `db_denydatawriter` no queda un
-- `DENY` explícito, así que un `GRANT` de escritura concedido por error en
-- el futuro no tendría nada que lo anule."* Con esto, el rol
-- (`db_datareader`, y ninguna otra membresía) pasa a ser la única barrera
-- del lado de SQL Server — literalmente, no por omisión. Un `INSERT`
-- falla porque el login no tiene permiso para escribir, no porque algo lo
-- deniegue explícitamente.
--
-- ALCANCE POR PEDIDO NOMBRADO (contract v9, "Cambios v8 → v9", regla de
-- Patrick Ocampo, Slack 21-sep-2026 10:31): el login arranca en CERO y
-- cada base se agrega por su nombre, con fecha y solicitante registrados
-- en APROBACIONES.md. Es el default invertido de lo que este script tenía
-- hasta v8: aquel recorría sys.databases entero concediendo todo salvo
-- exclusiones; éste recorre SÓLO la lista declarada abajo. Con la lista
-- vacía, el bucle no itera nada, no crea ningún user, y el script sale 0
-- — ese es el estado de arranque que la aprobación describe.
--
-- CÓMO AGREGAR UNA BASE NUEVA: agregar un valor al INSERT de
-- @bases_permitidas de abajo (una fila, con su nombre exacto tal como
-- aparece en sys.databases) y volver a correr este script completo. Es
-- la única fricción que la regla de Patrick permite: nombrar la base acá
-- y en APROBACIONES.md, nada más — no exige aprobación adicional.
--
-- CÓMO DAR DE BAJA UNA BASE (contract v10 — el orden cambió: ya NO es
-- "revertir con una copia recortada, después sacar la fila"): sacar la
-- fila de este INSERT (y registrar la baja en APROBACIONES.md), correr
-- `sqlserver-inverso.sql` REAL sin modificar (revoca por ENUMERACIÓN —
-- recorre sys.databases entero, no lee esta lista — así que encuentra y
-- saca a bisalta_lectura de TODAS LAS BASES ONLINE donde exista hoy,
-- incluidas las que siguen en esta lista, y borra el login; una base NO
-- ONLINE con el user no se toca y queda huérfana, ver comentario de
-- cabecera de sqlserver-inverso.sql), y RECIÉN DESPUÉS
-- volver a correr `sqlserver-parte-a.sql` (recrea el login) y este mismo
-- script (por la lista ya actualizada, sin la base dada de baja) para
-- dejar la instancia con exactamente lo que la lista declara ahora.
-- Procedimiento completo en RUNBOOK.md, sección "Inverso" → "Procedimiento
-- de baja". Ya no hace falta ninguna copia de trabajo: el inverso real
-- sirve igual sea cual sea la base que se dé de baja.
--
-- El historial de qué se pidió, cuándo y quién lo solicitó vive en
-- APROBACIONES.md, sección "Bases pedidas" — no se retranscribe acá para
-- no mantener el mismo dato en dos lugares que puedan desincronizarse:
-- el INSERT de abajo es la lista vigente en cada momento, y
-- APROBACIONES.md es el registro histórico de pedidos. Las bases que NO
-- están en la lista quedan intactas: el user no se crea ahí porque no
-- fueron pedidas, no porque haya un filtro de exclusión que las
-- descarte.
--
-- DEFENSA EN PROFUNDIDAD, NO EL CRITERIO: aunque el criterio real de
-- alcance sea "está en la lista", este script sigue rechazando por
-- nombre las cinco bases que nunca deben llevar el user, por si alguien
-- las escribe en la lista por error: `SSISDB`, `master`, `model`, `msdb`
-- y `tempdb`. Si aparecen en @bases_permitidas, el bucle las salta y
-- avisa por qué (bloque @bases_prohibidas, abajo) — nunca las procesa en
-- silencio. `SSISDB` queda fuera además por la razón de contract v6
-- ("Cambios v5 → v6", punto 1, Patrick Ocampo): guarda connection
-- managers y logs de ejecución, cero dato de negocio y sí credenciales,
-- y un servidor MCP cuyo propósito es que ninguna credencial pase por el
-- contexto no puede alcanzar el lugar donde viven las cadenas de
-- conexión.
--
-- SIN SALTOS SILENCIOSOS: si un nombre de la lista no existe en
-- sys.databases, o existe pero no está ONLINE (state <> 0), el script lo
-- dice por PRINT y sigue con el resto de la lista — nunca lo saltea sin
-- avisar. Es la lección explícita de sp_MSforeachdb (ya no se usa desde
-- v5, contract): su exclusión de bases en estados como RESTORING u
-- OFFLINE es un comportamiento interno no documentado, sin condición
-- visible en el llamado ni forma de auditar qué bases quedaron afuera.
-- El filtro de este script, en cambio, es una condición explícita y
-- visible en cada rama del bucle (abajo), y cada rama que no procesa una
-- base imprime por qué.
--
-- Recorre la lista con un CURSOR EXPLÍCITO sobre una variable de tabla
-- (contract v10, AC7/AC42, sección "Garantías por motor (asimetría
-- declarada, no disimulada)", cerrada, no reabrir) — mismo patrón de
-- cursor local que el script ya usaba hasta v8 para sys.databases, ahora
-- apuntado a @bases_permitidas en vez de al catálogo del servidor. Esta
-- lista sigue siendo la fuente de verdad para CONCEDER (`sqlserver-
-- inverso.sql`, en cambio, ya no lee ninguna lista para REVOCAR — ver su
-- propio comentario de cabecera): dos direcciones, dos fuentes de verdad.
--
-- Corre con un login con privilegio de sysadmin en la instancia — nunca
-- con el propio bisalta_lectura que este script crea.
--
-- Idempotente: IF NOT EXISTS antes de CREATE USER y antes de ALTER ROLE
-- ADD MEMBER, así que correrlo dos veces no falla y no duplica membresías.
--
-- GUARDA DE INSTANCIA (contract v13, AC44 — extendida acá por el mismo
-- argumento, ver RUNBOOK.md sección "AC44"): AC44 en sentido estricto sólo
-- exige la guarda en sqlserver-parte-a.sql, porque su motivo es que un
-- LOGIN es objeto de instancia. Este script no crea un login — crea
-- users por base y los mete en db_datareader —, pero corre contra la
-- MISMA instancia, y el mismo hueco aplica: nada acá abajo dice contra
-- qué servidor corre, y correrlo por error contra BD-PRINCIPAL concedería
-- lectura sobre bases de producción reales de forma directa (peor,
-- incluso, que crear un login sin usar: acá el daño es inmediato sobre
-- datos nombrados). Se decide duplicar la guarda como defensa en
-- profundidad, con el mismo criterio que `@bases_prohibidas` más abajo:
-- el criterio real es otro (la lista, o el login existente), pero la
-- guarda de instancia no cuesta nada repetir y cierra la misma clase de
-- hueco. Mismo valor, ya medido (contract v17) — ver el comentario de
-- sqlserver-parte-a.sql.

SET NOCOUNT ON;

DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — MEDIDO, ver sqlserver-parte-a.sql

IF @maquina <> @esperada
BEGIN
    RAISERROR(N'ABORTA: este script solo corre en Dev SQL (%s). Estas en %s.',
              16, 1, @esperada, @maquina);
    SET NOEXEC ON;
END

DECLARE @bases_permitidas TABLE (nombre SYSNAME PRIMARY KEY);

-- Lista explícita de bases con acceso concedido. ÚNICO lugar del script
-- que se edita para agregar o quitar una base — ver comentario de
-- cabecera "CÓMO AGREGAR UNA BASE NUEVA" y, para el caso de baja, "CÓMO
-- DAR DE BAJA UNA BASE" (desde v10: se saca la fila primero, DESPUÉS
-- corre el inverso — el inverso ya no necesita la lista para encontrar
-- lo que hay que revocar).
INSERT INTO @bases_permitidas (nombre) VALUES
  (N'COMPRAS'),
  (N'COMPRAS_STG'),
  (N'Ecommerce'),
  (N'Ecommerce_qa'),
  (N'EXACTUS'),
  (N'BI');

DECLARE @bases_prohibidas TABLE (nombre SYSNAME PRIMARY KEY);

-- Defensa en profundidad: nunca se procesan aunque aparezcan arriba por
-- error. `SSISDB` por la razón de contract v6 citada en la cabecera; las
-- cuatro de sistema porque nunca son destino de un login de aplicación.
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
      + N' está en la lista de bases que nunca reciben el user. No se crea nada ahí. Sacala de @bases_permitidas.';
  END
  ELSE
  BEGIN
    SET @estado = NULL;
    SELECT @estado = state FROM sys.databases WHERE name = @db_name;

    IF @estado IS NULL
    BEGIN
      PRINT N'AUSENTE: ' + @db_name
        + N' no existe en sys.databases de esta instancia. Revisar el nombre en @bases_permitidas — no se crea nada para ella en esta corrida.';
    END
    ELSE IF @estado <> 0
    BEGIN
      PRINT N'NO ONLINE: ' + @db_name
        + N' existe pero sys.databases.state = ' + CAST(@estado AS NVARCHAR(10))
        + N' (0 = ONLINE). No se crea el user hasta que esté ONLINE — volver a correr este script cuando lo esté.';
    END
    ELSE
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
    END
  END

  FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO
