-- sqlserver-parte-a.sql
--
-- Aprovisionamiento de solo lectura para el plugin `bisalta-db` en `Dev SQL`
-- (10.24.40.137) — PARTE A: login de servidor.
--
-- Login único `bisalta_lectura` (no dos, a diferencia de Postgres): el
-- contract v2 cierra "dos roles de Postgres" (AC1) pero no extiende esa
-- distinción a SQL Server. La asimetría entre motores se documenta, no se
-- compensa (contract v2, sección "Garantías por motor (asimetría
-- declarada, no disimulada)"): SQL Server no tiene equivalente de
-- default_transaction_read_only ni de réplica de lectura, así que el rol
-- del login es la única barrera, y ese único login
-- lo comparten las dos identidades consumidoras. No se inventa un segundo
-- login para imitar la separación de Postgres — eso sería una decisión
-- nueva que el contract no cerró.
--
-- Contraseña: NO vive en este archivo. Sustituir el placeholder
-- <PASSWORD_LECTURA_SQL> por la contraseña real al ejecutar — ver
-- RUNBOOK.md, sección "Forma del secreto".
--
-- Idempotente: no falla si el login ya existe (chequeo contra
-- sys.server_principals antes del CREATE LOGIN).

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'bisalta_lectura')
BEGIN
  CREATE LOGIN bisalta_lectura WITH PASSWORD = '<PASSWORD_LECTURA_SQL>', CHECK_POLICY = ON;
END
GO
