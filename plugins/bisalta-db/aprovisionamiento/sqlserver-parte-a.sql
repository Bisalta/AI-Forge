-- sqlserver-parte-a.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` en `Dev SQL`
-- (10.24.40.137) — PARTE A: login de servidor.
--
-- Login único `bisalta_lectura` — un solo consumidor real hoy (Ian
-- Vargas), igual que Postgres desde v13 quedó con un solo rol
-- (`claude_lectura`; ver postgres-parte-a.sql y contract v13, "Cambios
-- v12 → v13" punto 1: `neo_lectura` salió porque NEO no abre ninguna
-- conexión Postgres, y nunca tuvo un login propio acá tampoco). La
-- asimetría real entre motores no es la cantidad de identidades — es la
-- que la tabla "Garantías por motor" del contract documenta, no compensa
-- (contract v10): SQL Server no tiene equivalente de
-- default_transaction_read_only ni de réplica de lectura. Desde v10, la
-- membresía `db_datareader` que otorga sqlserver-parte-b.sql es la ÚNICA
-- barrera del lado del rol — ya no hay una segunda red de `DENY`
-- (`db_denydatawriter` se quitó en v10, decisión de Patrick Ocampo: sin
-- ella no queda un `DENY` explícito que le gane a un `GRANT` de escritura
-- concedido por error, y eso se acepta a sabiendas). No hay tampoco
-- barrera del lado del motor: ninguna base de Dev SQL está en solo
-- lectura (INVENTARIO.md).
--
-- Contraseña: NO vive en este archivo. Sustituir el placeholder
-- <PASSWORD_LECTURA_SQL> por la contraseña real al ejecutar — ver
-- RUNBOOK.md, sección "Forma del secreto". El orden no está fijado: si el
-- secreto de Secrets Manager ya existe, la contraseña se RECUPERA DE AHÍ
-- en vez de generarse; si no existe, se genera acá y ese mismo valor se
-- guarda después en su campo `password`. Dos valores distintos dan un
-- fallo de autenticación que no se distingue del de un login inexistente.
--
-- Idempotente: no falla si el login ya existe (chequeo contra
-- sys.server_principals antes del CREATE LOGIN).
--
-- GUARDA DE INSTANCIA (contract v13, AC44): equivalente en SQL Server de lo
-- que postgres-parte-0.sql hace para Postgres. `CREATE LOGIN` es un objeto
-- DE INSTANCIA, y nada en este script decía contra qué servidor corría —
-- lo único que lo mantenía en Dev SQL era quién escribía la cadena de
-- conexión. Importa porque hay otro SQL Server en juego: NEO lee
-- `BD-PRINCIPAL`, que es producción, y sin esta guarda el script no sabe
-- distinguirla de Dev SQL. Aborta con `RAISERROR` severidad 16 y
-- `SET NOEXEC ON` — nada corre después, ni siquiera el CREATE LOGIN de
-- abajo.
--
-- VALOR SIN CONFIRMAR: `EC2AMAZ-2RGHL0C` sale de un registro de SSM, no de
-- una medición contra la instancia. Patrick Ocampo pidió explícitamente
-- confirmarlo corriendo `SELECT SERVERPROPERTY('MachineName')` conectado a
-- Dev SQL antes de fijarlo — textual: "si no coincide, el valor manda
-- sobre el mío". No se pudo medir en esta ronda porque el login todavía no
-- existe en esa instancia (dependencia circular: hace falta el login para
-- conectar, y el login es justamente lo que este script crea). RUNBOOK.md,
-- sección "Prerequisitos", manda medirlo como PRIMER PASO, antes de correr
-- este script contra Dev SQL — si la medición no coincide con el valor de
-- abajo, el valor medido manda y hay que actualizar esta línea antes de
-- ejecutar.

SET NOCOUNT ON;

DECLARE @maquina  sysname = CAST(SERVERPROPERTY('MachineName') AS sysname);
DECLARE @esperada sysname = N'EC2AMAZ-2RGHL0C';   -- Dev SQL, 10.24.40.137 — SIN CONFIRMAR, ver comentario de arriba

IF @maquina <> @esperada
BEGIN
    RAISERROR(N'ABORTA: este script solo corre en Dev SQL (%s). Estas en %s.',
              16, 1, @esperada, @maquina);
    SET NOEXEC ON;
END

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bisalta_lectura')
BEGIN
  CREATE LOGIN bisalta_lectura WITH PASSWORD = '<PASSWORD_LECTURA_SQL>', CHECK_POLICY = ON;
END
GO
