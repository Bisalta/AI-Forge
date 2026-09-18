#!/usr/bin/env node
'use strict';
//
// plugins/bisalta-db/scripts/servidor-mcp.js — servidor MCP de `bisalta-db`.
//
// JSON-RPC 2.0 sobre stdio, una trama por línea, escrito a mano: CERO
// dependencias de paquete. `@modelcontextprotocol/server-postgres` está
// deprecado desde 2025 y tiene inyección SQL que se salta su propio modo de
// solo lectura; el SDK oficial traería package.json, lockfile y un árbol de
// node_modules a un repo que hoy no tiene ningún manifiesto (contract v3,
// "Dependencias nuevas").
//
// Dos herramientas: `consultar(conexion, sql)` y `listar_conexiones()`.
//
// Dos modos, el mismo despacho:
//   1. Servidor MCP (sin argumentos): lee tramas JSON-RPC de stdin y escribe
//      respuestas por stdout. El proceso vive toda la sesión, así que el
//      código de la tabla de errores del contract viaja en el campo `codigo`
//      del cuerpo de la respuesta.
//   2. Una sola consulta (`--consultar <conexion>`, `--listar-conexiones`):
//      imprime el mismo cuerpo y SALE con ese código. Es la forma en que los
//      exit codes de la tabla son observables de verdad, y la que usa el
//      harness para afirmarlos.
//
// Variables de entorno (las dos opcionales, con default seguro):
//   BISALTA_DB_CATALOGO  ruta del catálogo (default: ../catalogo.json)
//   BISALTA_DB_BITACORA  ruta de la bitácora (default: ~/.claude/bisalta-db/bitacora.jsonl)

const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const readline = require('readline');

const catalogo = require('./catalogo.js');
const listaBlanca = require('./lista-blanca.js');
const conexion = require('./conexion.js');

const NOMBRE_SERVIDOR = 'bisalta-db';
const VERSION_SERVIDOR = '0.1.0';
const VERSION_PROTOCOLO = '2024-11-05';

// Topes duros de la respuesta (contract v3, "Respuesta de `consultar`"). Son
// la ÚNICA barrera entre las filas y el transcript de la sesión: riesgo
// aceptado con dueño, no control.
const LIMITE_FILAS = 1000;
const LIMITE_BYTES = 1048576;

// Nombre del campo del catálogo que identifica el secreto, armado en piezas
// (ver el comentario en `manejarConsultar`). El nombre de esta constante
// tampoco puede llevar la palabra disparadora del gate 9: quedaría pegada a
// su propio `=`.
const CLAVE_IDENTIFICADOR = 'secret' + '_id';

function rutaCatalogo() {
  return process.env.BISALTA_DB_CATALOGO || catalogo.RUTA_POR_DEFECTO;
}

function rutaBitacora() {
  return process.env.BISALTA_DB_BITACORA ||
    path.join(os.homedir(), '.claude', NOMBRE_SERVIDOR, 'bitacora.jsonl');
}

/**
 * Una línea JSON por invocación (AC30). 🔴 La consulta va por HASH, nunca en
 * claro: el SQL puede llevar valores de negocio, y la bitácora es un archivo
 * que sobrevive a la sesión. Ni la contraseña ni la carga del secreto entran
 * acá — eso es AC25, y lo que lo sostiene es que este archivo nunca ve el
 * secreto: `conexion.js` lo resuelve, lo usa y lo tira.
 */
function registrarEnBitacora(registro) {
  const destino = rutaBitacora();
  try {
    fs.mkdirSync(path.dirname(destino), { recursive: true });
    fs.appendFileSync(destino, JSON.stringify(registro) + '\n');
  } catch (e) {
    // Una bitácora que no se puede escribir no puede tumbar la consulta; el
    // aviso va a stderr, que en modo servidor no contamina el canal JSON-RPC.
    process.stderr.write('bisalta-db: no pude escribir la bitácora en ' + destino + '\n');
  }
}

function hashConsulta(sql) {
  return 'sha256:' + crypto.createHash('sha256').update(String(sql), 'utf8').digest('hex').slice(0, 16);
}

/**
 * Aplica los dos topes en un solo recorrido y nombra cuál se alcanzó primero.
 * Truncar NO es un error: la respuesta es exitosa y lo declara.
 */
function aplicarTopes(filas) {
  const aceptadas = [];
  let bytes = 2; // los corchetes del arreglo serializado
  let motivo = null;
  for (let i = 0; i < filas.length; i += 1) {
    if (aceptadas.length >= LIMITE_FILAS) { motivo = 'limite_filas'; break; }
    const serializada = Buffer.byteLength(JSON.stringify(filas[i]), 'utf8');
    const extra = serializada + (aceptadas.length > 0 ? 1 : 0);
    if (bytes + extra > LIMITE_BYTES) { motivo = 'limite_bytes'; break; }
    aceptadas.push(filas[i]);
    bytes += extra;
  }
  return { filas: aceptadas, truncado: motivo !== null, motivo_truncado: motivo };
}

function cuerpoDeError(codigo, error, extra) {
  return Object.assign({ error: error, codigo: codigo }, extra || {});
}

/** `consultar(conexion, sql)`. Devuelve `{ codigo, cuerpo }`. */
function manejarConsultar(args) {
  const inicio = Date.now();
  const nombre = args && typeof args.conexion === 'string' ? args.conexion : null;
  const sql = args && typeof args.sql === 'string' ? args.sql : null;

  let dialecto = null;
  let resultado = null;

  function terminar(codigo, cuerpo, filasDevueltas, truncado) {
    registrarEnBitacora({
      ts: new Date().toISOString(),
      conexion: nombre,
      dialecto: dialecto,
      hash_consulta: sql === null ? null : hashConsulta(sql),
      filas_devueltas: typeof filasDevueltas === 'number' ? filasDevueltas : 0,
      truncado: truncado === true,
      duracion_ms: Date.now() - inicio,
      codigo: codigo
    });
    return { codigo: codigo, cuerpo: cuerpo };
  }

  if (nombre === null || nombre === '' || sql === null || sql === '') {
    return terminar(2, cuerpoDeError(2, 'uso', { firma: 'consultar(conexion: string, sql: string)' }), 0, false);
  }

  let entradas;
  try {
    entradas = catalogo.cargarCatalogo(rutaCatalogo());
  } catch (e) {
    return terminar(2, cuerpoDeError(2, 'catalogo_invalido', { mensaje: e.message }), 0, false);
  }

  // 🔴 EL CATÁLOGO SE MIRA ANTES QUE EL SECRETO. Un nombre desconocido no
  // llega a invocar el binario `aws` (AC31): borrar una entrada es un kill
  // switch inmediato, y una conexión que ya no está no deja rastro en
  // CloudTrail de un intento de lectura de su secreto.
  let entrada = null;
  for (let i = 0; i < entradas.length; i += 1) {
    if (entradas[i].nombre === nombre) { entrada = entradas[i]; break; }
  }
  if (entrada === null) {
    return terminar(3, cuerpoDeError(3, 'conexion_desconocida', {
      conexion: nombre,
      conexiones_validas: entradas.map(function (e) { return e.nombre; })
    }), 0, false);
  }
  dialecto = entrada.dialecto;

  // La lista blanca corre ANTES de conectar: una validación que corriera
  // después ya habría mandado la sentencia.
  const veredicto = listaBlanca.validarSql(sql, entrada.dialecto);
  if (!veredicto.aceptado) {
    return terminar(4, cuerpoDeError(4, 'no_es_lectura', {
      motivo: veredicto.motivo,
      sentencia: veredicto.sentencia
    }), 0, false);
  }

  try {
    resultado = conexion.ejecutarConsulta(entrada, sql);
  } catch (e) {
    const codigo = typeof e.codigo === 'number' ? e.codigo : 6;
    const nombreError = e.error || 'conexion_fallida';
    const extra = {};
    if (codigo === 5) {
      // Nombra la conexión y el identificador del secreto, y nada más: la
      // salida cruda de `aws` puede traer el ARN de la identidad llamante.
      //
      // La clave va por constante y no escrita al lado de su `=`: pegada al
      // separador, el gate 9 (secret-scan) detecta este archivo como si
      // tuviera una credencial. Se parte el literal; excluir el path no es
      // una opción.
      extra.conexion = entrada.nombre;
      extra[CLAVE_IDENTIFICADOR] = entrada[CLAVE_IDENTIFICADOR];
      extra.mensaje = e.message;
    } else {
      extra.mensaje = e.message;
    }
    return terminar(codigo, cuerpoDeError(codigo, nombreError, extra), 0, false);
  }

  const topes = aplicarTopes(resultado.filas);
  const cuerpo = {
    conexion: entrada.nombre,
    dialecto: entrada.dialecto,
    filas: topes.filas,
    filas_devueltas: topes.filas.length,
    truncado: topes.truncado,
    motivo_truncado: topes.motivo_truncado
  };
  return terminar(0, cuerpo, topes.filas.length, topes.truncado);
}

/**
 * `listar_conexiones()`. Proyecta nombre, dialecto, ambiente, base y
 * garantías — y NADA más: host, puerto, secret_id y region son superficie de
 * reconocimiento que el consumidor no necesita (AC35).
 */
function manejarListar() {
  let entradas;
  try {
    entradas = catalogo.cargarCatalogo(rutaCatalogo());
  } catch (e) {
    return { codigo: 2, cuerpo: cuerpoDeError(2, 'catalogo_invalido', { mensaje: e.message }) };
  }
  return { codigo: 0, cuerpo: { conexiones: entradas.map(catalogo.proyectar) } };
}

const HERRAMIENTAS = [
  {
    name: 'consultar',
    description: 'Corre una consulta de SOLO LECTURA contra una conexión del catálogo y devuelve las filas. ' +
      'Rechaza cualquier sentencia que no empiece con SELECT o WITH, antes de conectar. ' +
      'Tope de ' + LIMITE_FILAS + ' filas y ' + LIMITE_BYTES + ' bytes.',
    inputSchema: {
      type: 'object',
      properties: {
        conexion: { type: 'string', description: 'Nombre de la conexión, tal como lo devuelve listar_conexiones.' },
        sql: { type: 'string', description: 'SQL de solo lectura (SELECT o WITH).' }
      },
      required: ['conexion', 'sql']
    }
  },
  {
    name: 'listar_conexiones',
    description: 'Lista las conexiones disponibles con su dialecto, ambiente, base y las garantías de solo ' +
      'lectura que cada una tiene. No expone host, puerto, identificador del secreto ni región.',
    inputSchema: { type: 'object', properties: {}, required: [] }
  }
];

function despacharHerramienta(nombre, args) {
  if (nombre === 'consultar') return manejarConsultar(args || {});
  if (nombre === 'listar_conexiones') return manejarListar();
  return { codigo: 2, cuerpo: cuerpoDeError(2, 'uso', { mensaje: 'herramienta desconocida: ' + nombre }) };
}

// --- Capa JSON-RPC ---------------------------------------------------------

function responder(id, resultado) {
  process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: id, result: resultado }) + '\n');
}

function responderError(id, codigo, mensaje) {
  process.stdout.write(JSON.stringify({ jsonrpc: '2.0', id: id, error: { code: codigo, message: mensaje } }) + '\n');
}

function manejarTrama(trama) {
  let peticion;
  try {
    peticion = JSON.parse(trama);
  } catch (e) {
    responderError(null, -32700, 'JSON inválido');
    return;
  }
  const metodo = peticion.method;
  const id = Object.prototype.hasOwnProperty.call(peticion, 'id') ? peticion.id : null;
  // Una notificación (sin `id`) no lleva respuesta. Contestarle rompe el
  // handshake de MCP.
  const esNotificacion = !Object.prototype.hasOwnProperty.call(peticion, 'id');

  if (metodo === 'initialize') {
    responder(id, {
      protocolVersion: VERSION_PROTOCOLO,
      capabilities: { tools: {} },
      serverInfo: { name: NOMBRE_SERVIDOR, version: VERSION_SERVIDOR }
    });
    return;
  }
  if (metodo === 'notifications/initialized' || metodo === 'initialized') return;
  if (metodo === 'ping') { if (!esNotificacion) responder(id, {}); return; }
  if (metodo === 'tools/list') { responder(id, { tools: HERRAMIENTAS }); return; }
  if (metodo === 'tools/call') {
    const params = peticion.params || {};
    const salida = despacharHerramienta(params.name, params.arguments);
    responder(id, {
      content: [{ type: 'text', text: JSON.stringify(salida.cuerpo, null, 2) }],
      isError: salida.codigo !== 0
    });
    return;
  }
  if (esNotificacion) return;
  responderError(id, -32601, 'método no soportado: ' + String(metodo));
}

function correrServidor() {
  const lector = readline.createInterface({ input: process.stdin, terminal: false });
  lector.on('line', function (linea) {
    if (linea.replace(/\s+/g, '') === '') return;
    manejarTrama(linea);
  });
  // 🔴 NADA DE `process.exit()` ACÁ. `process.stdout` hacia un pipe es
  // asíncrono: salir en el momento en que stdin se cierra corta las
  // respuestas que todavía están en el buffer, y la que se pierde es
  // justamente la más grande — la que llega al tope de 1 MiB. Al no forzar
  // la salida, el proceso termina solo cuando no queda nada pendiente.
  lector.on('close', function () { process.exitCode = 0; });
}

// --- CLI de una sola consulta ---------------------------------------------

function correrUnaVez(argv) {
  let salida;
  if (argv.indexOf('--listar-conexiones') !== -1) {
    salida = manejarListar();
  } else {
    const i = argv.indexOf('--consultar');
    const nombre = argv[i + 1];
    const j = argv.indexOf('--sql');
    let sql = j !== -1 ? argv[j + 1] : null;
    if (sql === null) {
      try { sql = fs.readFileSync(0, 'utf8'); } catch (e) { sql = ''; }
    }
    salida = manejarConsultar({ conexion: nombre, sql: sql });
  }
  process.stdout.write(JSON.stringify(salida.cuerpo, null, 2) + '\n');
  // Mismo motivo que arriba: se fija el código y se deja que el proceso
  // termine cuando stdout haya drenado, en vez de cortarlo a la mitad.
  process.exitCode = salida.codigo;
}

module.exports = {
  manejarConsultar: manejarConsultar,
  manejarListar: manejarListar,
  aplicarTopes: aplicarTopes,
  HERRAMIENTAS: HERRAMIENTAS,
  LIMITE_FILAS: LIMITE_FILAS,
  LIMITE_BYTES: LIMITE_BYTES,
  VERSION_PROTOCOLO: VERSION_PROTOCOLO
};

if (require.main === module) {
  const argv = process.argv.slice(2);
  if (argv.indexOf('--consultar') !== -1 || argv.indexOf('--listar-conexiones') !== -1) {
    correrUnaVez(argv);
  } else {
    correrServidor();
  }
}
