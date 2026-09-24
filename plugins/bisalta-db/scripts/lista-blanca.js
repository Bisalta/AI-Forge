#!/usr/bin/env node
'use strict';
//
// plugins/bisalta-db/scripts/lista-blanca.js — qué SQL es aceptable, por dialecto.
//
// Port de `scripts/consulta-lectura.sh` de Bisalta/Proveedores-Back, rama
// feat-PROV-131-api-comprassync (otro repo). Los doce casos de
// `tests/consultaLecturaWrapper.test.mjs` viven acá como AC15-AC22 en
// SDD/tests/test_lista_blanca.sh.
//
// 🔴 LISTA BLANCA, NO LISTA NEGRA, Y ANCLADA AL PRINCIPIO DE LA SENTENCIA.
// Un bloque `DO` puede hacer cualquier cosa y una lista negra de
// INSERT/UPDATE/DELETE lo deja pasar entero. Y la palabra tiene que estar al
// PRINCIPIO: la versión laxa (buscar SELECT/WITH en cualquier posición)
// pasaba once de los doce tests originales, y el caso que la mató fue
// `DELETE ... WHERE id IN (SELECT ...)`.
//
// Una lista blanca por dialecto: un mismo patrón estaría mal en alguna
// dirección (contract v3, decisión 3).
//
// 🔴 EMPEZAR CON SELECT O WITH NO ALCANZA (contract v16, AC47). Un `WITH`
// puede llevar una escritura adentro (`WITH x AS (DELETE ... RETURNING *)
// SELECT ...` en Postgres; `WITH c AS (SELECT ...) DELETE FROM c` en SQL
// Server), `SELECT ... INTO nueva` crea una tabla, y `set_config` apaga la
// sesión de solo lectura desde un SELECT. Medido el 23-sep-2026: las tres
// formas se ACEPTABAN. Por eso, además del ancla, cada sentencia ya
// normalizada se rechaza si nombra una palabra de escritura. Rechaza de más a
// sabiendas —`SELECT ... FOR UPDATE`, y un identificador entre comillas
// dobles con uno de esos nombres, porque la normalización no quita comillas
// dobles—: falla cerrado.
//
// Uso como CLI (el SQL entra por stdin, nunca por argv):
//   printf '%s' "SELECT 1" | node lista-blanca.js postgres
// Exit: 0 = aceptado · 4 = rechazado (tabla de errores del contract) ·
//       2 = uso incorrecto (dialecto ausente o desconocido).

const DIALECTOS = ['postgres', 'sqlserver'];

// Cada sentencia tiene que empezar con SELECT o WITH seguido de espacio o
// paréntesis. El ancla `^` es la regla; sin ella esto es una lista negra.
const ANCLA_LECTURA = /^(SELECT|WITH)[\s(]/i;

// Apertura de comilla de dólar de Postgres: `$$` o `$etiqueta$`. Un cuerpo
// entre comillas de dólar no se normaliza (no es un literal de comilla
// simple) y puede esconder cualquier cosa, incluido un `;`.
const COMILLA_DOLAR = /\$([A-Za-z_][A-Za-z_0-9]*)?\$/;

// Reglas propias de SQL Server.
const EJECUCION_SQLSERVER = /(^|[^A-Za-z0-9_])(EXEC|EXECUTE)([^A-Za-z0-9_]|$)/i;
const PROCEDIMIENTO_SQLSERVER = /(^|[^A-Za-z0-9_])(sp_|xp_)/i;

// Reglas de los dos dialectos (contract v16, AC47): una palabra de escritura
// en cualquier posición de la sentencia normalizada, y —sólo en postgres— la
// función que cambia un parámetro de la sesión desde dentro de un SELECT.
const ESCRITURA_EMBEBIDA = /(^|[^A-Za-z0-9_])(INSERT|UPDATE|DELETE|MERGE|INTO)([^A-Za-z0-9_]|$)/i;
const FUNCION_PROHIBIDA_POSTGRES = /(^|[^A-Za-z0-9_])set_config([^A-Za-z0-9_]|$)/i;

// Reglas propias de SQL Server (contract v19, AC52): T-SQL no exige separador
// entre sentencias, así que una sentencia que empieza con SELECT puede seguir
// con cualquier otra sin `;`. Es la lista de AC47 más TRUNCATE, DROP, CREATE y
// ALTER; si una palabra se suma a ESCRITURA_EMBEBIDA, se suma también acá.
const ESCRITURA_EMBEBIDA_SQLSERVER = /(^|[^A-Za-z0-9_])(INSERT|UPDATE|DELETE|MERGE|INTO|TRUNCATE|DROP|CREATE|ALTER)([^A-Za-z0-9_]|$)/i;

/**
 * Quita comentarios de línea, comentarios de bloque y literales de texto, en
 * UN SOLO RECORRIDO de izquierda a derecha (contract v19, AC51).
 *
 * 🔴 TRES REEMPLAZOS EN SECUENCIA NO VEN LO MISMO QUE EL MOTOR. Cada pasada
 * ignora lo que las otras ya saben: un `--` o un `/*` dentro de un literal se
 * quitaba como comentario ANTES de reconocer el literal, y se llevaba puesto
 * el resto de la línea —o del texto—, incluida una escritura que el motor sí
 * ejecuta. Y un bloque anidado se cerraba en el primer `*\/`, dejando a la
 * vista como código lo que para el motor sigue siendo comentario. El
 * recorrido decide en cada posición qué construcción está abierta, igual que
 * el lexer del motor:
 *   - literal de comilla simple, con `''` como comilla escapada → `''`;
 *   - identificador entre comillas dobles → se copia tal cual, y adentro un
 *     `--`, un `/*` o una comilla simple no abren nada;
 *   - comentario de línea → se quita hasta el salto de línea, que se queda;
 *   - comentario de bloque, ANIDADO en los dos motores → un espacio.
 * Reglas propias de cada dialecto (contract v20, `AC51`):
 *   - postgres: literal de escape con prefijo `E`/`e` pegado a la comilla,
 *     donde la barra invertida escapa el carácter siguiente;
 *   - sqlserver: identificador entre corchetes, con `]]` como escape adentro
 *     → se copia tal cual.
 * Una construcción SIN CERRAR —literal, identificador o comentario de
 * bloque abierto al final del texto— no se normaliza a medias: la función
 * devuelve cuál quedó abierta en `sinCerrar`, y `validarSql()` rechaza antes
 * de partir en sentencias, con el tipo en el motivo. Ese texto no es SQL
 * válido para ningún motor, así que el rechazo no pierde ninguna consulta
 * legítima.
 *
 * Implementación de referencia de Patrick Ocampo (Slack, 23-sep-2026), que
 * él mismo revisó antes de entregarla. Límites que dejó escritos: el literal
 * común asume `standard_conforming_strings = on` (el valor por omisión; si
 * estuviera en `off`, el validador vería más texto, no menos: falla
 * cerrado); el contenido de un identificador se copia tal cual, así que uno
 * que se llame como una palabra de escritura se rechaza de más, a propósito.
 *
 * @returns {{texto: string, sinCerrar: (null|'literal'|'identificador'|'comentario')}}
 */
function normalizar(sql, dialecto) {
  const s = String(sql); const n = s.length;
  let out = '', i = 0, sinCerrar = null;

  const literal = (escapaConBarra) => {        // i apunta a la comilla de apertura
    i += 1;
    let cerrado = false;
    while (i < n) {
      const ch = s[i];
      if (escapaConBarra && ch === '\\') { i += 2; continue; }
      if (ch === "'") {
        if (s[i + 1] === "'") { i += 2; continue; }
        i += 1; cerrado = true; break;
      }
      i += 1;
    }
    if (!cerrado) sinCerrar = sinCerrar || 'literal';
    out += "''";
  };

  while (i < n) {
    const c = s[i], c2 = s[i + 1];

    // Postgres: E'...' -> la barra invertida escapa el caracter siguiente
    if (dialecto === 'postgres' && (c === 'E' || c === 'e') && c2 === "'"
        && (i === 0 || !/[A-Za-z0-9_$]/.test(s[i - 1]))) {
      out += c; i += 1; literal(true); continue;
    }
    if (c === "'") { literal(false); continue; }

    // SQL Server: identificador entre corchetes, con ]] como escape
    if (dialecto === 'sqlserver' && c === '[') {
      out += c; i += 1;
      let cerrado = false;
      while (i < n) {
        out += s[i];
        if (s[i] === ']') {
          if (s[i + 1] === ']') { out += s[i + 1]; i += 2; continue; }
          i += 1; cerrado = true; break;
        }
        i += 1;
      }
      if (!cerrado) sinCerrar = sinCerrar || 'identificador';
      continue;
    }
    if (c === '"') {
      out += c; i += 1;
      let cerrado = false;
      while (i < n) {
        out += s[i];
        if (s[i] === '"') {
          if (s[i + 1] === '"') { out += s[i + 1]; i += 2; continue; }
          i += 1; cerrado = true; break;
        }
        i += 1;
      }
      if (!cerrado) sinCerrar = sinCerrar || 'identificador';
      continue;
    }
    if (c === '-' && c2 === '-') { while (i < n && s[i] !== '\n') i += 1; continue; }
    if (c === '/' && c2 === '*') {
      let p = 1; i += 2;
      while (i < n && p > 0) {
        if (s[i] === '/' && s[i + 1] === '*') { p += 1; i += 2; continue; }
        if (s[i] === '*' && s[i + 1] === '/') { p -= 1; i += 2; continue; }
        i += 1;
      }
      if (p > 0) sinCerrar = sinCerrar || 'comentario';
      out += ' '; continue;
    }
    out += c; i += 1;
  }
  return { texto: out, sinCerrar: sinCerrar };
}

/**
 * Parte el texto normalizado por `;`. Conserva los saltos de línea dentro de
 * cada sentencia y recién ahí los colapsa: partir por línea fue el bug que
 * los doce tests originales no vieron porque todos usaban SQL de una sola
 * línea. La última sentencia se revisa aunque no termine en `;` — si el
 * splitter la perdiera, una escritura al final del archivo pasaría sin
 * mirarse.
 */
function partirEnSentencias(textoNormalizado) {
  const partes = String(textoNormalizado).split(';');
  const sentencias = [];
  for (let i = 0; i < partes.length; i += 1) {
    const limpia = partes[i].replace(/[\r\n]+/g, ' ').replace(/^\s+|\s+$/g, '');
    if (limpia !== '') sentencias.push(limpia);
  }
  return sentencias;
}

function rechazo(motivo, sentencia) {
  // Los primeros 90 caracteres de la sentencia ofensora — nunca el archivo
  // completo, nunca un stack trace (threat model del contract, punto 3).
  return { aceptado: false, motivo: motivo, sentencia: String(sentencia).slice(0, 90) };
}

/**
 * Veredicto de la lista blanca.
 * @param {string} sql
 * @param {string} dialecto  'postgres' | 'sqlserver'
 * @returns {{aceptado: boolean, motivo: string|null, sentencia: string|null}}
 */
function validarSql(sql, dialecto) {
  if (DIALECTOS.indexOf(dialecto) === -1) {
    return rechazo('dialecto_desconocido', String(dialecto));
  }

  const normalizada = normalizar(sql, dialecto);
  // AC51 v20: una construcción sin cerrar se rechaza ANTES de partir en
  // sentencias. El tipo va en el motivo para que quien lo lea no busque un
  // problema de permisos que no existe (pedido de Patrick Ocampo).
  if (normalizada.sinCerrar) {
    return rechazo('construccion_sin_cerrar_' + normalizada.sinCerrar, String(sql).replace(/[\r\n]+/g, ' '));
  }
  const normalizado = normalizada.texto;

  // SQL Server: cualquier `;` que quede tras quitar comentarios y literales.
  // Un batch de T-SQL con varias sentencias no tiene equivalente de sesión de
  // solo lectura que lo contenga, así que acá se manda una sola sentencia.
  if (dialecto === 'sqlserver' && normalizado.indexOf(';') !== -1) {
    return rechazo('punto_y_coma_no_permitido', normalizado.replace(/[\r\n]+/g, ' ').replace(/^\s+/, ''));
  }

  const sentencias = partirEnSentencias(normalizado);
  if (sentencias.length === 0) return rechazo('sin_sentencias', '');

  for (let i = 0; i < sentencias.length; i += 1) {
    const sentencia = sentencias[i];

    if (!ANCLA_LECTURA.test(sentencia)) {
      return rechazo('no_empieza_con_select_ni_with', sentencia);
    }

    if (dialecto === 'postgres' && COMILLA_DOLAR.test(sentencia)) {
      return rechazo('comilla_de_dolar', sentencia);
    }

    if (dialecto === 'sqlserver') {
      if (EJECUCION_SQLSERVER.test(sentencia)) {
        return rechazo('ejecucion_de_procedimiento', sentencia);
      }
      if (PROCEDIMIENTO_SQLSERVER.test(sentencia)) {
        return rechazo('procedimiento_de_sistema', sentencia);
      }
    }

    // 🔴 ESTOS DOS VAN AL FINAL, DESPUÉS DE TODOS LOS DEMÁS (AC47): así
    // ningún rechazo que ya existía cambia de motivo. Y miran `sentencia`,
    // que ya está normalizada — sobre el SQL crudo, `SELECT 'delete' AS x`
    // se rechazaría por una palabra que vive dentro de un literal. En
    // sqlserver la lista suma las cuatro de AC52, con el mismo motivo.
    const escritura = dialecto === 'sqlserver' ? ESCRITURA_EMBEBIDA_SQLSERVER : ESCRITURA_EMBEBIDA;
    if (escritura.test(sentencia)) {
      return rechazo('escritura_embebida', sentencia);
    }
    if (dialecto === 'postgres' && FUNCION_PROHIBIDA_POSTGRES.test(sentencia)) {
      return rechazo('funcion_prohibida', sentencia);
    }
  }

  return { aceptado: true, motivo: null, sentencia: null };
}

module.exports = { validarSql: validarSql, normalizar: normalizar, partirEnSentencias: partirEnSentencias, DIALECTOS: DIALECTOS };

// --- CLI -------------------------------------------------------------------
// 🔴 `process.exitCode` Y NO `process.exit()`: `process.stdout` hacia un pipe
// es asíncrono, y salir en el acto corta lo que todavía está en el buffer. Se
// fija el código y el proceso termina cuando no queda nada pendiente. Misma
// regla en los tres CLI de este plugin y en el servidor.
function correrCli() {
  const dialecto = process.argv[2];
  if (!dialecto) {
    process.stderr.write('uso: printf "%s" "<sql>" | node lista-blanca.js <postgres|sqlserver>\n');
    process.exitCode = 2;
    return;
  }
  if (DIALECTOS.indexOf(dialecto) === -1) {
    process.stderr.write('dialecto desconocido: ' + dialecto + ' (esperaba ' + DIALECTOS.join(' o ') + ')\n');
    process.exitCode = 2;
    return;
  }
  let sql = '';
  try {
    sql = require('fs').readFileSync(0, 'utf8');
  } catch (e) {
    sql = '';
  }
  const veredicto = validarSql(sql, dialecto);
  process.stdout.write(JSON.stringify(veredicto) + '\n');
  process.exitCode = veredicto.aceptado ? 0 : 4;
}

if (require.main === module) {
  correrCli();
}
