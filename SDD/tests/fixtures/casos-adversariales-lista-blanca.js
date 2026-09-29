// Casos adversariales contra plugins/bisalta-db/scripts/lista-blanca.js
// Medidos el 23-sep-2026 contra feat-GEN-108-mcp-bisalta-db.
// esperado: false = tiene que RECHAZARSE.  true = tiene que aceptarse.
const CASOS = [
  // --- AC51: la normalizacion truncaba y validaba el sobrante ---
  ['postgres',  "SELECT 'a--b' ; DELETE FROM res_partner",            false,
   'comentario dentro de un literal: se quitaba ANTES que el literal'],
  ['sqlserver', "SELECT 'a--b' DELETE FROM dbo.t",                    false,
   'idem en sqlserver'],
  ['postgres',  "SELECT 'a/*x' ; DELETE FROM t /*'*/",                false,
   'apertura de bloque dentro de un literal'],
  ['postgres',  "SELECT 1 /* /* anidado */ DELETE FROM t */",         true,
   'los bloques ANIDAN en los dos motores: para el motor esto es solo SELECT 1'],

  // --- AC52: T-SQL no exige punto y coma ---
  ['sqlserver', "SELECT 1 TRUNCATE TABLE dbo.t",                      false, 'TRUNCATE'],
  ['sqlserver', "SELECT 1 DROP TABLE dbo.t",                          false, 'DROP'],
  ['sqlserver', "SELECT 1 CREATE TABLE dbo.z(x int)",                 false, 'CREATE'],
  ['sqlserver', "SELECT 1 ALTER TABLE dbo.t ADD z int",               false, 'ALTER'],

  // --- limite conocido, NO pendiente: escritura dentro de un literal ---
  ['sqlserver', "SELECT * FROM OPENQUERY(srv, 'DELETE FROM t')",      false,
   'el literal se borra al normalizar; el motor si lo ejecuta (v25: ya no es limite conocido, se rechaza por OPENQUERY, AC53)'],
  ['postgres',  "SELECT dblink_exec('dbname=x', 'DELETE FROM t')",    true, 'idem via dblink'],

  // --- limite conocido: funciones que escriben sin nombrar la escritura ---
  ['postgres',  "SELECT setval('mi_seq', 1)",                         true, 'escribe'],
  ['postgres',  "SELECT nextval('mi_seq')",                           true, 'avanza la secuencia'],
  ['postgres',  "SELECT mi_funcion_que_escribe()",                    true, 'no se ve adentro'],
  ['postgres',  "SELECT pg_sleep(3600)",                              true,
   'lo contiene statement_timeout, no la lista'],

  // --- controles: no deben cambiar de veredicto con el arreglo ---
  ['postgres',  "WITH x AS (DELETE FROM t RETURNING *) SELECT * FROM x", false, 'AC47 postgres'],
  ['sqlserver', "WITH c AS (SELECT 1 AS i) DELETE FROM c",              false, 'AC47 sqlserver'],
  ['postgres',  "SELECT set_config('default_transaction_read_only','off',false)", false, 'set_config'],
  ['postgres',  "SELECT 'delete' AS x",                                 true,
   'palabra dentro de un literal: NO debe rechazarse'],
  ['postgres',  "SELECT 'no toca'' esto' AS x",                         true, 'comilla escapada'],
  ['postgres',  "SELECT 1 -- DELETE FROM t",                            true, 'comentario de linea real'],
  ['postgres',  "SELECT * FROM t FOR UPDATE",                           false,
   'rechazo de mas a proposito: falla cerrado'],
];
module.exports = { CASOS };