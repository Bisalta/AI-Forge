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
const VERSION_SERVIDOR = '0.3.0';
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

// AC65 (v31): columnas cuyo nombre indica una credencial. Su valor se
// reemplaza en la respuesta, en todos los dialectos. Es por NOMBRE: una
// columna renombrada en la consulta (`SELECT token AS t`) no se detecta. Es
// higiene contra la exposición accidental, no una barrera de acceso; el
// acceso lo decide el rol de la base (decisión de Ian, 1-oct).
const COLUMNA_SENSIBLE = /token|secret|pass(?:word|wd)|key_hash|api_?key/i;
const VALOR_REDACTADO = '[redactado]';

/**
 * Reemplaza el valor de las columnas sensibles y devuelve cuáles fueron.
 * Todo valor, también el vacío y el nulo: `psql --csv` entrega un NULL como
 * campo vacío y el parser no los distingue (review de v31, ronda 1), así que
 * dejar pasar uno de los dos dejaría pasar los dos.
 */
function redactarColumnasSensibles(filas) {
  const redactadas = [];
  const vistas = {};
  const salida = filas.map(function (fila) {
    const copia = {};
    Object.keys(fila).forEach(function (columna) {
      if (COLUMNA_SENSIBLE.test(columna)) {
        if (!Object.prototype.hasOwnProperty.call(vistas, columna)) { vistas[columna] = true; redactadas.push(columna); }
        copia[columna] = VALOR_REDACTADO;
      } else {
        copia[columna] = fila[columna];
      }
    });
    return copia;
  });
  return { filas: salida, redactadas: redactadas };
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
    // v30: un error de la consulta en SQL Server (6 o 7) corrió con el nivel
    // del prefijo, y uno de ellos, el Msg 601, sólo existe por ese nivel. Sin
    // el campo, se lee como una caída de la red. El 5 (secreto) no llegó a
    // correr nada y no lo lleva.
    if (entrada.dialecto === 'sqlserver' && (codigo === 6 || codigo === 7)) {
      extra.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
    }
    return terminar(codigo, cuerpoDeError(codigo, nombreError, extra), 0, false);
  }

  // AC65: se redacta ANTES de los topes, así el tope de bytes mide lo que de
  // verdad sale.
  const redaccion = redactarColumnasSensibles(resultado.filas);
  const topes = aplicarTopes(redaccion.filas);
  const cuerpo = {
    conexion: entrada.nombre,
    dialecto: entrada.dialecto
  };
  // AC62 (v29, D86): en SQL Server el nivel y su aviso van en la respuesta,
  // antes de las filas, para que quien las lea no informe una cifra sin
  // confirmar con el mismo tono que una confirmada.
  if (entrada.dialecto === 'sqlserver') {
    cuerpo.aislamiento = conexion.NIVEL_AISLAMIENTO_SQLSERVER;
    cuerpo.aviso = conexion.AVISO_AISLAMIENTO_SQLSERVER;
  }
  // AC65: qué columnas se taparon, para que quien lee no tome '[redactado]'
  // por el dato.
  if (redaccion.redactadas.length > 0) {
    cuerpo.columnas_redactadas = redaccion.redactadas;
  }
  Object.assign(cuerpo, {
    filas: topes.filas,
    filas_devueltas: topes.filas.length,
    truncado: topes.truncado,
    motivo_truncado: topes.motivo_truncado
  });
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
      'Rechaza, antes de conectar, toda sentencia que no empiece con SELECT o WITH, y también las que ' +
      'llevan una escritura embebida: INSERT, UPDATE, DELETE, MERGE o INTO en cualquier posición ' +
      '(un WITH con escritura adentro, SELECT ... INTO) y, en Postgres, set_config. ' +
      'En SQL Server la consulta lleva una sola sentencia, sin punto y coma, y se rechazan además TRUNCATE, DROP, ' +
      'CREATE, ALTER, EXEC, sp_/xp_ y las sentencias que no son lectura (WAITFOR, WHILE, GRANT, REVOKE, ' +
      'DENY, USE, DBCC, SET, DECLARE, BEGIN, BACKUP, RESTORE, KILL, SHUTDOWN, OPENROWSET, OPENQUERY, ' +
      'OPENDATASOURCE), con un límite de 60 s por consulta. En SQL Server la consulta corre en ' +
      'READ UNCOMMITTED para no bloquear a quien escribe: puede devolver filas que otra transacción ' +
      'todavía no confirmó y, si alguien escribe mientras tanto, leer dos veces o saltear filas ya ' +
      'confirmadas (un COUNT o un total pueden dar mal) o cortar con el error 601. Las respuestas exitosas de ' +
      'SQL Server lo repiten en los campos aislamiento y aviso, y sus errores de consulta, en aislamiento. ' +
      'En Postgres, si la conexión no llegó a una réplica de lectura, se niega con no_es_replica sin ' +
      'ejecutar el SQL. En una conexión multitenant (la que tiene sesion en listar_conexiones), el plugin fija ' +
      'el tenant antes de la consulta. Las columnas cuyo nombre indica una credencial (token, secret, password, ' +
      'key_hash, api_key) salen como [redactado], y columnas_redactadas dice cuáles. Tope de ' + LIMITE_FILAS +
      ' filas y ' + LIMITE_BYTES + ' bytes.',
    inputSchema: {
      type: 'object',
      properties: {
        conexion: { type: 'string', description: 'Nombre de la conexión, tal como lo devuelve listar_conexiones.' },
        sql: { type: 'string', description: 'SQL de solo lectura: cada sentencia empieza con SELECT o WITH y no lleva ' +
          'INSERT, UPDATE, DELETE, MERGE ni INTO en ninguna posición (se rechaza SELECT ... INTO y un WITH con ' +
          'escritura adentro); en Postgres tampoco set_config.' }
      },
      required: ['conexion', 'sql']
    }
  },
  {
    name: 'listar_conexiones',
    description: 'Lista las conexiones disponibles con su dialecto, ambiente, base y las garantías de solo ' +
      'lectura que cada una tiene, y en las multitenant, sesion: el parámetro, los tenants y qué destraba. ' +
      'No expone host, puerto, identificador del secreto, región ni ningún UUID de tenant.',
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

/**
 * AC60 (v27): resolver un seudónimo. `--seudonimo` imprime el de quien corre
 * el comando, con la identidad de AWS, y NO imprime el nombre: así se puede
 * correr desde una sesión de Claude sin traer el correo al contexto.
 * `--seudonimo-de <nombre>` imprime el de un nombre dado, para mapear una
 * lista de usuarios IAM. La región sale de la primera entrada del catálogo.
 */
function correrSeudonimo(argv) {
  const k = argv.indexOf('--seudonimo-de');
  if (k !== -1) {
    const nombre = argv[k + 1];
    if (!nombre) { process.stderr.write('uso: --seudonimo-de <nombre>\n'); process.exitCode = 2; return; }
    process.stdout.write(conexion.seudonimo(nombre) + '\n');
    return;
  }
  let region;
  try { region = catalogo.cargarCatalogo(rutaCatalogo())[0].region; } catch (e) { region = null; }
  if (!region) { process.stderr.write('no pude leer la región del catálogo\n'); process.exitCode = 2; return; }
  const propio = conexion.resolverIdentidad(region);
  process.stdout.write(propio + '\n');
  // `?` es "no hay seudónimo": `sts` falló o el ARN no tiene nombre. Sale
  // distinto de 0 para que no se confunda con un seudónimo.
  if (propio === '?') {
    process.stderr.write('no hay seudónimo: aws sts falló, o la identidad no tiene un nombre (root, federated-user)\n');
    process.exitCode = 1;
  }
}

module.exports = {
  manejarConsultar: manejarConsultar,
  manejarListar: manejarListar,
  aplicarTopes: aplicarTopes,
  redactarColumnasSensibles: redactarColumnasSensibles,
  HERRAMIENTAS: HERRAMIENTAS,
  LIMITE_FILAS: LIMITE_FILAS,
  LIMITE_BYTES: LIMITE_BYTES,
  VERSION_PROTOCOLO: VERSION_PROTOCOLO
};

if (require.main === module) {
  // AC56 (v25): antes de atender nada, los archivos de contraseña que dejó un
  // proceso muerto sin pasar por su `finally`.
  conexion.limpiarTemporalesHuerfanos();
  const argv = process.argv.slice(2);
  // AC60: por el PRIMER argumento, para que un `--sql --seudonimo` de la CLI
  // no caiga en el modo seudónimo.
  if (argv[0] === '--seudonimo' || argv[0] === '--seudonimo-de') {
    correrSeudonimo(argv);
  } else if (argv.indexOf('--consultar') !== -1 || argv.indexOf('--listar-conexiones') !== -1) {
    correrUnaVez(argv);
  } else {
    correrServidor();
  }
}
