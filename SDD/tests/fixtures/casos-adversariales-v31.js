// SDD/tests/fixtures/casos-adversariales-v31.js
// Casos de Patrick Ocampo (Slack, 1-oct-2026), para la regla identificador_unicode.
// esperado: false = tiene que RECHAZARSE.  true = tiene que aceptarse.
const CASOS_V31 = [
  // --- deben RECHAZARSE ---
  [
    "postgres",
    "SELECT U&\"set_c\\006Fnfig\"('app.tenant_ids','otro',false)",
    false,
    "el hueco: set_config escrito con escape Unicode",
  ],
  [
    "postgres",
    "SELECT u&\"set_c\\006Fnfig\"('app.tenant_ids','otro',false)",
    false,
    "minuscula: U& no distingue mayusculas",
  ],
  [
    "postgres",
    "SELECT U&\"set_c!006Fnfig\"('a','b',false) UESCAPE '!'",
    false,
    "con caracter de escape propio via UESCAPE",
  ],
  [
    "postgres",
    "WITH x AS (SELECT U&\"set_c\\006Fnfig\"('a','b',false)) SELECT * FROM x",
    false,
    "escondido dentro de un CTE",
  ],
  [
    "postgres",
    'SELECT U&"data" FROM t',
    false,
    "inocente, pero se rechaza igual: no decodificamos, rechazamos la forma",
  ],

  // --- deben ACEPTARSE ---
  [
    "postgres",
    "SELECT U&'\\0441\\043B\\043E\\0432\\043E' AS x",
    true,
    "literal Unicode: el contenido se blanquea al normalizar, no puede esconder un nombre",
  ],
  [
    "postgres",
    'SELECT col_u&"mask" FROM t',
    true,
    "borde: col_u es un identificador y & es el operador; no es U&",
  ],
  [
    "postgres",
    'SELECT "mi columna" FROM t',
    true,
    "identificador normal entre comillas",
  ],
  ["postgres", "SELECT 1 AS u FROM t", true, "una u suelta no activa nada"],

  // --- controles: no deben cambiar de motivo ---
  [
    "postgres",
    "SELECT set_config('a','b',false)",
    false,
    "sigue dando funcion_prohibida",
  ],
  ["postgres", "SELECT $$x$$", false, "sigue dando comilla_de_dolar"],
];
module.exports = { CASOS_V31 };
