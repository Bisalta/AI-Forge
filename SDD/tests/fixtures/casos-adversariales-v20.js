// SDD/tests/fixtures/casos-adversariales-v20.js
// Medidos el 23-sep-2026 contra una implementacion de referencia de v20.
// esperado: false = tiene que RECHAZARSE.  true = tiene que aceptarse.
const CASOS_V20 = [
  // --- Postgres E'...': la barra invertida escapa el caracter siguiente ---
  ['postgres',  "SELECT E'a\\'' ; DELETE FROM res_partner",  false,
   'BYPASS REAL: \\\' escapa la comilla, asi que la siguiente CIERRA. Sin E, el par de comillas se leia como comilla doblada y se tragaba el DELETE'],
  ['postgres',  "SELECT e'a\\'' ; DELETE FROM t",            false,
   'idem en minuscula'],
  ['postgres',  "SELECT E'a\\\\' AS x",                      true,
   'control: barra escapada, el literal SI cierra ahi'],
  ['postgres',  "SELECT E'a''b' AS x",                       true,
   'control: dentro de E, la comilla doblada tambien escapa'],
  ['postgres',  "SELECT E'delete' AS x",                     true,
   'control: palabra dentro de un E-literal'],

  // --- SQL Server [...]: ]] escapa el corchete ---
  ['sqlserver', "SELECT 1 AS [it's] DELETE FROM dbo.t",      false,
   'BYPASS REAL: la comilla dentro del corchete abria un literal que se tragaba el DELETE'],
  ['sqlserver', "SELECT 1 AS [a]]b] AS y",                   true,
   'control: ]] escapado, el identificador es a]b'],
  ['sqlserver', "SELECT * FROM [dbo].[mi tabla]",            true,
   'control: uso normal'],
  ['sqlserver', "SELECT 1 AS [delete]",                      false,
   'rechazo de mas A PROPOSITO, igual que con "delete": el identificador se copia tal cual'],

  // --- SQL Server N'...': NO es un hueco, van como control ---
  ['sqlserver', "SELECT N'a--b' DELETE FROM dbo.t",          false,
   'ya se rechazaba sin el arreglo; el prefijo N no cambia el escapado'],
  ['sqlserver', "SELECT N'delete' AS x",                     true,  'control'],
  ['sqlserver', "SELECT N'a''b' AS x",                       true,  'control'],

  // --- construcciones sin cerrar ---
  ['postgres',  "SELECT 'abc",                               false, 'literal sin cerrar'],
  ['postgres',  "SELECT 'a'' ",                              false,
   'sin cerrar y dificil de ver: la comilla doblada NO cierra'],
  ['postgres',  "SELECT 1 AS \"abc",                         false, 'identificador sin cerrar'],
  ['postgres',  "SELECT 1 /* abc",                           false, 'bloque sin cerrar'],
  ['sqlserver', "SELECT 1 AS [abc",                          false, 'corchete sin cerrar'],
  ['postgres',  "SELECT 'abc' AS x",                         true,  'control'],
  ['postgres',  "SELECT 1 AS \"abc\"",                       true,  'control'],
  ['postgres',  "SELECT 1 /* abc */",                        true,  'control'],
  ['sqlserver', "SELECT 1 AS [abc]",                         true,  'control'],
  // --- v20: la regla de E'...' se mata con consultas LEGITIMAS, no con ataques.
  // Sin la rama de E, las cinco se rechazan como construccion_sin_cerrar_literal.
  ['postgres',  "SELECT E'it\\'s' AS x",                 true,
   'MATA AL MUTANTE: consulta honesta con comilla escapada'],
  ['postgres',  "SELECT E'a\\'b' AS x, 1 AS y",          true,
   'MATA AL MUTANTE: con texto valido despues del literal'],
  ['postgres',  "SELECT E'\\'' AS comilla",              true,
   'MATA AL MUTANTE: el literal es solo una comilla escapada'],
  ['postgres',  "SELECT E'a\\'' AS x, 'b' AS y",         true,
   'MATA AL MUTANTE: E-literal y literal normal en la misma consulta'],
  ['postgres',  "SELECT e'it\\'s' AS y",                 true,
   'MATA AL MUTANTE: cubre que la mutacion apague solo la mayuscula'],
  ['postgres',  "SELECT 'it''s' AS x",                   true,
   'control sano: literal normal con comilla doblada, NO depende de la rama de E'],
];
module.exports = { CASOS_V20 };