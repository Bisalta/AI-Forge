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
// dirección (contract v2, decisión 3).
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

/**
 * Quita comentarios de bloque, comentarios de línea y literales de texto.
 * Mismo orden que el `perl -0777` del script original: un `-- UPDATE ...` no
 * puede disparar un rechazo falso, y una palabra dentro de una cadena
 * tampoco. Los literales se reemplazan por `''` (comilla vacía) para no
 * romper la forma de la sentencia.
 */
function normalizar(sql) {
  return String(sql)
    .replace(/\/\*[\s\S]*?\*\//g, ' ')
    .replace(/--[^\n]*/g, '')
    .replace(/'(?:[^']|'')*'/g, "''");
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

  const normalizado = normalizar(sql);

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
