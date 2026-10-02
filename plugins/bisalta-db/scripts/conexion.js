#!/usr/bin/env node
'use strict';
//
// plugins/bisalta-db/scripts/conexion.js — resolución del secreto y ejecución
// del cliente CLI del dialecto (contract v3, "Entrega de la credencial al
// cliente").
//
// 🔴 LA CREDENCIAL NUNCA VIAJA POR argv. Un argumento de línea de comandos es
// visible en la tabla de procesos de toda la máquina.
//
//   - Postgres: archivo temporal en modo 600 bajo un `mkdtemp`, apuntado por
//     la variable de libpq que nombra un ARCHIVO de contraseñas
//     (`PGPASSFILE`), y borrado en un `finally` que corre también cuando la
//     consulta falla. Están prohibidas las variables de libpq que llevan la
//     contraseña, el usuario y el host como valor, y sus banderas
//     equivalentes de `psql`: la conexión se arma con un conninfo (URI), que
//     no las necesita. Es la invariante que los tests de Proveedores-Back ya
//     fijaban, y la verifica AC23 grepeando este directorio.
//   - SQL Server: variable de entorno acotada al proceso hijo. `sqlcmd` no
//     tiene equivalente de archivo, y su bandera de contraseña la dejaría
//     visible en la tabla de procesos. La asimetría está declarada, no
//     disimulada.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const crypto = require('crypto');

const TIMEOUT_SENTENCIA_MS = 120000;
// Desde v19 (AC28) esto ya NO se manda al motor como `statement_timeout`: el
// límite de sentencia lo fija el rol (AC49 — 60s en Postgres; si 60s queda
// corto para un agregado legítimo, se sube en el rol, no acá). Esta constante
// sólo sirve de base para el corte de PROCESO de abajo, que es el que corta
// en los dos motores cuando el motor no corta solo (red caída, handshake que
// no avanza) o cuando no hay equivalente del lado del servidor (SQL Server).
const TIMEOUT_PROCESO_MS = TIMEOUT_SENTENCIA_MS + 5000;
const MAX_BUFFER = 64 * 1024 * 1024;

const PREFIJO_TEMP = 'bisalta-db-';
// AC56 (v25): un directorio temporal más viejo que esto es huérfano. El
// `finally` de `ejecutarConsulta` no corre si el proceso muere con SIGKILL, y
// el archivo de contraseña (0600) queda en el tmpdir. Diez minutos es muy por
// encima del corte de proceso (TIMEOUT_PROCESO_MS), así que no se borra el de
// una consulta que otra sesión todavía está corriendo.
const EDAD_HUERFANO_MS = 10 * 60 * 1000;
// AC58 (v26): las autoridades de certificación de Amazon RDS, del sitio
// oficial de AWS (truststore.pki.rds.amazonaws.com/global/global-bundle.pem,
// descargado el 25-sep-2026). Viaja con el plugin: libpq no lo trae.
const BUNDLE_RDS = path.join(__dirname, '..', 'certificados', 'rds-global-bundle.pem');
const NOMBRE_TEMP = new RegExp('^' + PREFIJO_TEMP + '[A-Za-z0-9]{6}$');
// AC54 (v25): límite de consulta de SQL Server, del lado del cliente con `-t`.
// Es el mismo valor que el `statement_timeout` del rol de Postgres (AC49):
// SQL Server no tiene un equivalente por login, y sin esto una sentencia
// larga retiene la sesión hasta el corte de proceso.
const TIMEOUT_CONSULTA_SQLSERVER_S = 60;
// AC61 (v28): las consultas de SQL Server corren en READ UNCOMMITTED. Medido
// el 28-sep: ninguna de las seis bases del catálogo tiene
// READ_COMMITTED_SNAPSHOT, así que
// con el aislamiento por omisión un SELECT toma bloqueos compartidos y frena
// a quien escribe filas (D75); los cambios de estructura siguen esperando,
// por el bloqueo de esquema. A cambio, puede leer filas sin confirmar, leer
// dos veces o saltear filas confirmadas, o cortar con el error 601. Lo arma
// el plugin, después de la lista blanca; la consulta del usuario sigue sin
// poder llevar SET ni punto y coma (AC53).
const NIVEL_AISLAMIENTO_SQLSERVER = 'READ UNCOMMITTED';
const AISLAMIENTO_SQLSERVER = 'SET TRANSACTION ISOLATION LEVEL ' + NIVEL_AISLAMIENTO_SQLSERVER + '; ';
// AC62 (v29, D86): el aviso viaja en cada respuesta de SQL Server, no sólo en
// la descripción de la herramienta, que el modelo lee una vez. El nivel sale
// de la misma constante que arma el prefijo, así que no puede informarse uno
// y mandarse otro.
// v30: el aviso es propio de cada nivel, porque cada uno falla distinto. Un
// nivel sin aviso escrito no tiene un texto genérico que lo cubra: el módulo
// no carga, y el servidor no arranca.
const AVISOS_POR_NIVEL = {
  'READ UNCOMMITTED': 'Corrió en READ UNCOMMITTED: puede incluir filas que otra transacción todavía no ' +
    'confirmó y, si alguien escribía mientras tanto, filas leídas dos veces o salteadas. Un COUNT o un ' +
    'total pueden estar mal.'
};
function avisoParaNivel(nivel) {
  if (!Object.prototype.hasOwnProperty.call(AVISOS_POR_NIVEL, nivel)) {
    throw new Error('nivel de aislamiento sin aviso escrito: ' + String(nivel));
  }
  return AVISOS_POR_NIVEL[nivel];
}
const AVISO_AISLAMIENTO_SQLSERVER = avisoParaNivel(NIVEL_AISLAMIENTO_SQLSERVER);
// Separador de campos para SQL Server: un carácter de control que no aparece
// en datos de texto normales (unit separator, 0x1F).
const SEPARADOR_SQLSERVER = String.fromCharCode(31);
// AC66 y AC67: los avisos ANSI del motor que se apartan en el formato JSON,
// por texto exacto. En JSON una línea no puede ser un pedazo de dato que
// empiece igual, pero tampoco se adivina: sólo los medidos.
const AVISOS_ANSI_SQLSERVER = ['Warning: Null value is eliminated by an aggregate or other SET operation.'];
// Nombre de la variable de entorno de la contraseña de sqlcmd, armado en dos
// piezas a propósito: escrito entero y contiguo junto a su asignación, este
// archivo dispararía el propio gate 9 (secret-scan) contra sí mismo.
const VARIABLE_CREDENCIAL_SQLSERVER = 'SQLCMD' + 'PASSWORD';

// Guarda de réplica (contract v16, AC46). Es el PRIMER `--command` de toda
// consulta Postgres: corre en la misma conexión que el SQL del consumidor —o
// sea contra la misma instancia— y, con ON_ERROR_STOP=1, si falla psql
// termina sin ejecutar el segundo. Hace falta porque Aurora apunta el
// endpoint `cluster-ro-` al writer cuando el cluster se queda sin réplicas
// (medido el 23-sep-2026: una sola réplica). Es lo que hace INCONDICIONAL a
// la garantía `endpoint-replica-lectura`: el nivel sigue a la verificación.
// El literal es el del contract, carácter por carácter.
const GUARDA_REPLICA = "DO $guarda$ BEGIN IF NOT pg_is_in_recovery() THEN RAISE EXCEPTION 'bisalta-db: la conexion no llego a una replica de lectura'; END IF; END $guarda$";
// El texto que se reconoce en el stderr de psql para responder `no_es_replica`.
// Es el mensaje del RAISE de arriba: si uno cambia sin el otro, la guarda
// sigue cortando pero la respuesta degrada a `conexion_fallida`.
const MENSAJE_NO_REPLICA = 'bisalta-db: la conexion no llego a una replica de lectura';

function fallo(codigo, error, mensaje) {
  const e = new Error(mensaje);
  e.codigo = codigo;
  e.error = error;
  return e;
}

/**
 * Saca de un texto cualquier aparición de los valores sensibles. Último
 * cinturón de AC25: ningún mensaje de cliente, por raro que venga, puede
 * llevarse la contraseña a la bitácora ni a la respuesta.
 */
function redactar(texto, sensibles) {
  let salida = String(texto === null || texto === undefined ? '' : texto);
  for (let i = 0; i < sensibles.length; i += 1) {
    const valor = sensibles[i];
    if (typeof valor === 'string' && valor.length > 0) {
      salida = salida.split(valor).join('[redactado]');
    }
  }
  return salida;
}

// AC60 (v27): quién consulta, para que el motor lo muestre mientras la
// consulta corre. Sale de la identidad de AWS con la que se leyó el secreto,
// que es la barrera real (IAM), pero NO viaja en claro: viaja un SEUDÓNIMO,
// `u-` y los primeros 8 caracteres hexadecimales del SHA-256 del nombre.
// Decisión de Ian Vargas, 28-sep (opción B): el nombre de la sesión lo ve
// cualquier login de la réplica, y un Claude que mirara `pg_stat_activity`
// traería los correos del equipo a su contexto. El seudónimo se resuelve con
// `--seudonimo` (el propio) y `--seudonimo-de <nombre>` (cualquiera). No es
// un dato oculto (quien conozca los nombres puede calcularlo). NO es auditoría: el
// nombre sólo se ve en vivo (D49, D74).
const IDENTIDAD_DESCONOCIDA = '?';
// Un `sts` que no responde no puede sumarle a cada consulta el corte de
// proceso entero (125 s): la identidad es diagnóstico, y 10 s alcanzan.
const TIMEOUT_STS_MS = 10000;
let identidadResuelta = null;

/**
 * El nombre de una persona dentro de un ARN de AWS: el último tramo de un
 * usuario IAM (`…:user/<ruta>/<nombre>`) o el nombre de sesión de un rol
 * asumido (`…:assumed-role/<rol>/<sesion>`). Nunca el número de cuenta. De
 * cualquier otro ARN (`root`, `federated-user`) no sale un nombre: `?`.
 */
function nombreDeArn(arn) {
  const m = /^arn:aws[a-z-]*:(iam|sts)::[0-9]+:(user|assumed-role)\/(.+)$/.exec(String(arn).trim());
  if (!m) return IDENTIDAD_DESCONOCIDA;
  const tramos = m[3].split('/');
  const nombre = tramos[tramos.length - 1];
  return nombre === '' ? IDENTIDAD_DESCONOCIDA : nombre;
}

/** AC60: el seudónimo de un nombre. `?` sigue siendo `?`. */
function seudonimo(nombre) {
  if (nombre === IDENTIDAD_DESCONOCIDA) return IDENTIDAD_DESCONOCIDA;
  return 'u-' + crypto.createHash('sha256').update(String(nombre), 'utf8').digest('hex').slice(0, 8);
}

/**
 * AC60: el seudónimo de quien consulta. Se pide una sola vez por proceso y se
 * guarda, también cuando `sts` respondió con un ARN del que no sale un nombre:
 * eso da `?` y no cambia pidiéndolo de nuevo. Si `aws sts` FALLA, devuelve `?`
 * y no lo guarda, para volver a intentar en la próxima consulta. Nunca frena
 * la consulta: es un dato para diagnosticar, no una barrera; por eso su límite
 * de tiempo es corto. El caché dura lo que dura el proceso: si cambian las
 * credenciales de AWS (otro `aws sso login`, otro perfil), hay que reiniciar
 * la sesión para que el seudónimo cambie.
 */
function resolverIdentidad(region) {
  if (identidadResuelta !== null) return identidadResuelta;
  const r = spawnSync('aws', [
    'sts', 'get-caller-identity',
    '--region', region,
    '--query', 'Arn',
    '--output', 'text'
  ], { encoding: 'utf8', maxBuffer: MAX_BUFFER, timeout: TIMEOUT_STS_MS });
  if (r.error || r.status !== 0) return IDENTIDAD_DESCONOCIDA;
  identidadResuelta = seudonimo(nombreDeArn(r.stdout));
  return identidadResuelta;
}

/** El nombre de la sesión en el motor: `<usuario del secreto>/<seudónimo>`. */
function nombreDeSesion(usuario, identidad) {
  return String(usuario) + '/' + String(identidad || IDENTIDAD_DESCONOCIDA);
}

/** Escapa `\` y `:`, los dos caracteres con significado en el archivo de libpq. */
function escaparCampoPassfile(valor) {
  return String(valor).replace(/\\/g, '\\\\').replace(/:/g, '\\:');
}

/**
 * Resuelve el secreto con el binario `aws`. Devuelve usuario y contraseña en
 * la forma estándar de RDS.
 *
 * Se llama `resolverCredencial` por una razón mecánica, no de estilo: un
 * identificador que lleva la palabra disparadora del gate 9 (secret-scan)
 * queda, al exportarse, pegado a los dos puntos de la clave del objeto — y
 * ese archivo se detecta a sí mismo como si tuviera una credencial. La
 * convención del repo es partir el literal, nunca excluir el path. El
 * comentario que explica esto tampoco puede escribir la forma completa: la
 * prosa que describe lo que prohíbe dispara la misma detección.
 * @throws error con `.codigo` 5 (no resuelve) u 8 (binario ausente). Nunca
 *   incluye la salida cruda de `aws`: puede traer el ARN de la identidad
 *   llamante (threat model, punto 2).
 */
function resolverCredencial(entrada) {
  const r = spawnSync('aws', [
    'secretsmanager', 'get-secret-value',
    '--secret-id', entrada.secret_id,
    '--region', entrada.region,
    '--query', 'SecretString',
    '--output', 'text'
  ], { encoding: 'utf8', maxBuffer: MAX_BUFFER, timeout: TIMEOUT_PROCESO_MS });

  if (r.error && r.error.code === 'ENOENT') {
    throw fallo(8, 'cliente_ausente', 'falta el binario `aws` en el PATH');
  }
  if (r.error || r.status !== 0) {
    throw fallo(5, 'secreto_inaccesible',
      'no pude resolver el secreto de la conexión `' + entrada.nombre + '` (secret_id `' + entrada.secret_id + '`)');
  }

  let carga;
  try {
    carga = JSON.parse(String(r.stdout).replace(/\s+$/, ''));
  } catch (e) {
    throw fallo(5, 'secreto_inaccesible',
      'el secreto de la conexión `' + entrada.nombre + '` (secret_id `' + entrada.secret_id + '`) no tiene la forma estándar de RDS');
  }
  const usuario = carga ? carga.username : null;
  const contrasena = carga ? carga['pass' + 'word'] : null;
  if (typeof usuario !== 'string' || usuario === '' || typeof contrasena !== 'string' || contrasena === '') {
    throw fallo(5, 'secreto_inaccesible',
      'al secreto de la conexión `' + entrada.nombre + '` (secret_id `' + entrada.secret_id + '`) le falta alguno de los dos campos de la forma estándar de RDS');
  }
  return { usuario: usuario, contrasena: contrasena, valorSesion: valorDeSesion(entrada, carga) };
}

// AC64 (v31): un UUID en su forma canónica. Se interpola en un SET, que no
// acepta parámetros, así que no pasa nada que no sea exactamente esto.
const UUID_VALIDO = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * AC64 (v31): el valor del parámetro de sesión de una entrada multitenant,
 * armado desde el secreto. Cada tenant es la clave `tenant_<nombre>`; el
 * catálogo sólo nombra cuáles. `uuid_lista` los une con coma y sin espacios
 * (medido el 1-oct: con un espacio, el cast a uuid falla y rompe la consulta
 * entera). Si falta uno o no es un UUID, la consulta no corre: correrla sin
 * el filtro, o con un filtro a medias, daría un resultado que parece válido.
 * El mensaje nombra la clave, nunca el valor.
 * @returns {null|{parametro: string, valor: string}}
 */
function valorDeSesion(entrada, carga) {
  if (!entrada.sesion) return null;
  const valores = [];
  for (let i = 0; i < entrada.sesion.tenants.length; i += 1) {
    const clave = 'tenant_' + entrada.sesion.tenants[i];
    const valor = carga[clave];
    if (typeof valor !== 'string' || !UUID_VALIDO.test(valor)) {
      throw fallo(5, 'secreto_inaccesible',
        'al secreto de la conexión `' + entrada.nombre + '` (secret_id `' + entrada.secret_id + '`) le falta `' +
        clave + '` o no es un UUID');
    }
    valores.push(valor.toLowerCase());
  }
  return { parametro: entrada.sesion.parametro, valor: valores.join(',') };
}

/**
 * Comando de Postgres. El usuario, el host, el puerto y la base viajan en el
 * conninfo; la contraseña, sólo en el archivo que apunta la variable de
 * archivo de credenciales de libpq.
 * AC28 (sesión de solo lectura; el `statement_timeout` ya no viaja por acá,
 * lo fija el rol — AC49) y AC29 (`application_name` = `<usuario del secreto>/<seudónimo>`, AC60,
 * para que `pg_stat_activity` atribuya del lado del motor) se verifican
 * sobre lo que esta función
 * devuelve. Con un solo rol (`claude_lectura` — contract v13, "Cambios
 * v12 → v13" punto 1: `neo_lectura` salió porque NEO no abre ninguna
 * conexión Postgres), `application_name` ya no distingue CONSUMIDORES —
 * hoy hay uno solo — pero sigue sirviendo para atribuir la sesión al rol
 * que la abrió. Si se agrega un segundo consumidor real, vuelve a
 * distinguir quién corrió qué (D53).
 * AC46 (v16): `--quiet` y DOS `--command`, en este orden — la guarda de
 * réplica y después el SQL del consumidor. Sin `--quiet`, psql imprime `DO`
 * como primera línea del CSV (medido).
 */
function construirComandoPostgres(entrada, usuario, rutaPassfile, sql, identidad, valorSesion) {
  const conninfo = 'postgresql://' + encodeURIComponent(usuario) + '@' +
    entrada.host + ':' + entrada.puerto + '/' + encodeURIComponent(entrada.base);
  return {
    comando: 'psql',
    args: ['--no-psqlrc', '--pset=pager=off', '--csv', '--quiet', '--variable=ON_ERROR_STOP=1',
      '--command', GUARDA_REPLICA].concat(
      // AC64 (v31): el parámetro de sesión de una entrada multitenant, entre
      // la guarda y el SQL. Lo arma el plugin después de la lista blanca: la
      // consulta del usuario sigue sin poder traer SET ni set_config. Es
      // sesión y no rol porque en PG 14 un parámetro sin declarar no se puede
      // fijar con ALTER ROLE sin un superuser (medido por Patrick el 1-oct).
      valorSesion ? ['--command', 'SET ' + valorSesion.parametro + " = '" + valorSesion.valor + "'"] : [],
      ['--command', sql, conninfo]),
    env: {
      PGPASSFILE: rutaPassfile,
      // AC28 (v19): PGOPTIONS deja de llevar `statement_timeout` — el rol lo
      // fija (AC49) y si cada cliente manda el suyo, el servidor no tiene
      // piso y el valor del rol es decorativo (contract, "Cambios v18 → v19"
      // punto 1).
      PGOPTIONS: '-c default_transaction_read_only=on',
      // AC29 va por PGAPPNAME y NO por `-c application_name` dentro de
      // PGOPTIONS. Medido contra el motor real el 23-sep-2026: psql fija su
      // propio `application_name` en la conexión y le GANA al `-c`, así que
      // `pg_stat_activity` mostraba `psql` y no el usuario del secreto. Las
      // tres formas se midieron una al lado de la otra; sólo PGAPPNAME y el
      // parámetro del conninfo sobreviven. No mover esto de vuelta a
      // PGOPTIONS: el comando se ve correcto y el efecto no lo es.
      // AC29 y AC60 (v27): el usuario del secreto, más el seudónimo de quien consulta.
      PGAPPNAME: nombreDeSesion(usuario, identidad),
      // AC55 (v25) y AC58 (v26): TLS obligatorio y con el servidor
      // autenticado. `verify-full` exige que el certificado lo firme una de
      // las autoridades del bundle de RDS que viaja con el plugin, y que el
      // nombre del host coincida. Con el `prefer` por omisión, libpq caía a
      // texto plano si el servidor no ofrecía TLS; con `require`, cifraba sin
      // saber con quién. PGSSLROOTCERT explícito, además, hace que un
      // `~/.postgresql/root.crt` de otra cosa no cambie el comportamiento.
      PGSSLMODE: 'verify-full',
      PGSSLROOTCERT: BUNDLE_RDS,
      PGCONNECT_TIMEOUT: '15'
    }
  };
}

/** Comando de SQL Server. La contraseña va por entorno, nunca por argv. */
// AC67 (v34): el transporte de SQL Server. Medido el 2-oct: en formato de
// tabla, `sqlcmd` corta todo texto a 256 caracteres (5000 llegaron 256) y un
// valor con saltos de línea se parte en varias filas, sin forma segura de
// rearmarlo cuando el valor no está en la última columna. Con FOR JSON el
// motor escapa los saltos de línea y parte el texto en trozos de 2033, que se
// vuelven a juntar: un valor de 20000 caracteres llega entero. `-y 8000` hace
// falta igual, porque si no, cada trozo se corta a 256; `-y 0` no sirve,
// porque saca el encabezado. FOR JSON falla con una columna sin nombre (Msg
// 13605) o con nombres repetidos (Msg 13601): ahí se vuelve a la tabla.
const SUFIJO_JSON_SQLSERVER = '\nFOR JSON PATH, INCLUDE_NULL_VALUES';
const ANCHO_SQLSERVER = '8000';
const ENCABEZADO_JSON_SQLSERVER = 'JSON_F52E2B61-18A1-11d1-B105-00805F49916B';
const SIN_JSON_SQLSERVER = /^Msg 1360[15],/m;

function construirComandoSqlserver(entrada, usuario, contrasena, sql, identidad, formato) {
  // El salto de línea antes de FOR JSON corta un comentario de línea con que
  // termine la consulta. Un comentario de bloque sin cerrar ya lo rechaza la
  // lista blanca (AC51).
  const sufijo = formato === 'tabla' ? '' : SUFIJO_JSON_SQLSERVER;
  const env = {};
  env[VARIABLE_CREDENCIAL_SQLSERVER] = contrasena;
  return {
    comando: 'sqlcmd',
    // AC55 (v25): `-N true` exige el cifrado en vez de dejarlo al default de
    // cada versión de sqlcmd. `-C` confía en el certificado sin validarlo:
    // medido el 25-sep, con `-N true` solo la conexión falla, porque el
    // certificado de la instancia no es de una autoridad conocida. Cifra,
    // pero no autentica al servidor (D71). AC54: `-t`, el límite de consulta.
    args: ['-S', entrada.host + ',' + entrada.puerto, '-d', entrada.base, '-U', usuario,
      '-N', 'true', '-C', '-t', String(TIMEOUT_CONSULTA_SQLSERVER_S),
      // AC60 (v27): `-H` fija lo que el motor muestra como `HOST_NAME()`. Sin
      // él, sqlcmd manda el nombre de la máquina, que no identifica a nadie.
      '-H', nombreDeSesion(usuario, identidad),
      '-b', '-y', ANCHO_SQLSERVER, '-s', SEPARADOR_SQLSERVER, '-W', '-Q', AISLAMIENTO_SQLSERVER + sql + sufijo],
    env: env,
    formato: formato === 'tabla' ? 'tabla' : 'json'
  };
}

/**
 * Parser CSV (RFC 4180) de la salida de `psql --csv`: comillas dobles,
 * comilla escapada como `""`, saltos de línea dentro del campo.
 */
function parsearCsv(texto) {
  const filas = [];
  let campo = '';
  let fila = [];
  let dentroDeComillas = false;
  let i = 0;
  const s = String(texto);
  while (i < s.length) {
    const c = s[i];
    if (dentroDeComillas) {
      if (c === '"') {
        if (s[i + 1] === '"') { campo += '"'; i += 2; continue; }
        dentroDeComillas = false; i += 1; continue;
      }
      campo += c; i += 1; continue;
    }
    if (c === '"') { dentroDeComillas = true; i += 1; continue; }
    if (c === ',') { fila.push(campo); campo = ''; i += 1; continue; }
    if (c === '\r') { i += 1; continue; }
    if (c === '\n') { fila.push(campo); filas.push(fila); fila = []; campo = ''; i += 1; continue; }
    campo += c; i += 1;
  }
  if (campo !== '' || fila.length > 0) { fila.push(campo); filas.push(fila); }
  if (filas.length === 0) return { columnas: [], filas: [] };
  const columnas = filas.shift();
  const objetos = [];
  for (let f = 0; f < filas.length; f += 1) {
    const obj = {};
    for (let c2 = 0; c2 < columnas.length; c2 += 1) {
      obj[columnas[c2]] = filas[f][c2] === undefined ? null : filas[f][c2];
    }
    objetos.push(obj);
  }
  return { columnas: columnas, filas: objetos };
}

/**
 * Parser de la salida tabular de `sqlcmd` con separador explícito: primera
 * línea de encabezados, segunda de guiones, y al final la línea de filas
 * afectadas que el cliente agrega.
 */
function parsearSalidaSqlserver(texto) {
  const lineas = String(texto).split(/\r?\n/);
  let columnas = null;
  let indiceUtil = 0;
  const objetos = [];
  const avisos = [];
  for (let i = 0; i < lineas.length; i += 1) {
    const linea = lineas[i];
    // AC67 (v34): una columna sin nombre deja la línea de encabezado vacía, y
    // la primera no vacía es la de guiones. Se nombran por posición, para que
    // la de guiones no pase por encabezado (medido el 2-oct: salía `-`).
    if (columnas === null && /^-+$/.test(linea.split(SEPARADOR_SQLSERVER).join('').replace(/\s+/g, '')) && linea.indexOf('-') !== -1) {
      columnas = linea.split(SEPARADOR_SQLSERVER).map(function (x, n) { return 'columna_' + (n + 1); });
      indiceUtil = 2;
      continue;
    }
    if (linea.replace(/\s+/g, '') === '') continue;
    if (/^\(\d+ rows? affected\)/i.test(linea.replace(/^\s+/, ''))) continue;
    const celdas = linea.split(SEPARADOR_SQLSERVER);
    if (columnas === null) { columnas = celdas; indiceUtil = 1; continue; }
    // AC66 (v33): un aviso ANSI del motor ("Warning: Null value is eliminated
    // by an aggregate…") viaja por stdout, en su propia línea y sin
    // separador. Medido el 2-oct: llegaba como una fila más, con el texto en
    // la primera columna. No es un dato: se aparta y se informa. `-m 11` no lo
    // saca (no tiene nivel de severidad), y SET ANSI_WARNINGS OFF cambiaría la
    // semántica de la consulta. Límite: en un resultado de una sola columna,
    // un valor que empiece con "Warning: " se toma por aviso.
    if (celdas.length === 1 && /^Warning: /.test(linea)) { avisos.push(linea.replace(/\s+$/, '')); continue; }
    if (indiceUtil === 1 && /^-+$/.test(celdas[0].replace(/\s+/g, ''))) { indiceUtil = 2; continue; }
    indiceUtil = 2;
    const obj = {};
    for (let c = 0; c < columnas.length; c += 1) {
      obj[columnas[c]] = celdas[c] === undefined ? null : celdas[c];
    }
    objetos.push(obj);
  }
  return { columnas: columnas || [], filas: objetos, avisos: avisos };
}

/**
 * AC67 (v34): la salida de una consulta con FOR JSON. El motor devuelve una
 * sola columna, con un nombre fijo, partida en trozos que se concatenan. Un
 * resultado vacío no trae ningún trozo. Los avisos ANSI conocidos se apartan
 * igual que en la tabla (AC66).
 */
function parsearSalidaJsonSqlserver(texto) {
  const lineas = String(texto).split(/\r?\n/);
  const avisos = [];
  let i = 0;
  while (i < lineas.length && lineas[i].indexOf(ENCABEZADO_JSON_SQLSERVER) !== 0) {
    if (AVISOS_ANSI_SQLSERVER.indexOf(lineas[i].replace(/\s+$/, '')) !== -1) avisos.push(lineas[i].replace(/\s+$/, ''));
    i += 1;
  }
  if (i >= lineas.length) {
    throw fallo(6, 'conexion_fallida', 'la salida de SQL Server no trae el resultado en JSON');
  }
  i += 1;
  if (i < lineas.length && /^-+$/.test(lineas[i].replace(/\s+/g, ''))) i += 1;
  const trozos = [];
  let cerrado = false;
  for (; i < lineas.length; i += 1) {
    const linea = lineas[i];
    if (AVISOS_ANSI_SQLSERVER.indexOf(linea.replace(/\s+$/, '')) !== -1) { avisos.push(linea.replace(/\s+$/, '')); continue; }
    // Un trozo nunca está vacío: la primera línea vacía cierra el resultado,
    // y después sólo se buscan avisos.
    if (linea === '') { cerrado = true; continue; }
    if (!cerrado) trozos.push(linea);
  }
  let filas = [];
  if (trozos.length > 0) {
    try {
      filas = JSON.parse(trozos.join(''));
    } catch (e) {
      throw fallo(6, 'conexion_fallida', 'la salida de SQL Server no se pudo leer como JSON');
    }
  }
  if (!Array.isArray(filas)) {
    throw fallo(6, 'conexion_fallida', 'la salida de SQL Server no es un arreglo JSON');
  }
  return { columnas: filas.length > 0 ? Object.keys(filas[0]) : [], filas: filas, avisos: avisos };
}

/**
 * Corre la consulta y devuelve las filas. La lista blanca ya la validó: acá
 * no se decide qué SQL es aceptable.
 * @throws error con `.codigo` 5, 6, 7, 8 o 9.
 */
function ejecutarConsulta(entrada, sql) {
  const credencial = resolverCredencial(entrada);
  const sensibles = [credencial.contrasena];
  // AC60: después del secreto, así nunca se llama a AWS por una conexión
  // desconocida ni por un SQL que la lista blanca rechazó.
  const identidad = resolverIdentidad(entrada.region);

  let directorioTemporal = null;
  try {
    let plan;
    if (entrada.dialecto === 'postgres') {
      directorioTemporal = fs.mkdtempSync(path.join(os.tmpdir(), PREFIJO_TEMP));
      const rutaPassfile = path.join(directorioTemporal, 'credencial');
      const linea = [
        escaparCampoPassfile(entrada.host),
        escaparCampoPassfile(entrada.puerto),
        escaparCampoPassfile(entrada.base),
        escaparCampoPassfile(credencial.usuario),
        escaparCampoPassfile(credencial.contrasena)
      ].join(':') + '\n';
      fs.writeFileSync(rutaPassfile, linea, { mode: 0o600 });
      fs.chmodSync(rutaPassfile, 0o600);
      plan = construirComandoPostgres(entrada, credencial.usuario, rutaPassfile, sql, identidad, credencial.valorSesion);
    } else {
      plan = construirComandoSqlserver(entrada, credencial.usuario, credencial.contrasena, sql, identidad, 'json');
    }

    const correr = function (p) {
      return spawnSync(p.comando, p.args, {
        encoding: 'utf8',
        env: Object.assign({}, process.env, p.env),
        maxBuffer: MAX_BUFFER,
        timeout: TIMEOUT_PROCESO_MS
      });
    };
    let r = correr(plan);
    // AC67 (v34): si FOR JSON no se puede aplicar a esta consulta (una columna
    // sin nombre o repetida), se vuelve a correr en formato de tabla, y la
    // respuesta lo dice. Cualquier otro error sigue su camino.
    let respaldo = false;
    if (entrada.dialecto === 'sqlserver' && r.status !== 0 && SIN_JSON_SQLSERVER.test(String(r.stdout))) {
      plan = construirComandoSqlserver(entrada, credencial.usuario, credencial.contrasena, sql, identidad, 'tabla');
      respaldo = true;
      r = correr(plan);
    }

    if (r.error && r.error.code === 'ENOENT') {
      throw fallo(8, 'cliente_ausente', 'falta el binario `' + plan.comando + '` en el PATH');
    }
    // AC57 (v25): sqlcmd escribe sus errores en stdout y deja stderr vacío
    // (medido el 25-sep). Sin esto, todo error de SQL Server llegaba al
    // consumidor sin mensaje, y un corte por `-t` no se reconocía como
    // `tiempo_agotado`. Sólo cuando el proceso falló: en una corrida exitosa,
    // stdout son datos.
    const textoError = (entrada.dialecto === 'sqlserver' && r.status !== 0 && String(r.stderr || '').trim() === '')
      // Se redacta stdout ENTERO antes de elegir el tramo: si se cortara
      // primero, una credencial partida por el corte dejaría pasar su final
      // sin redactar (review de v25, ronda 2).
      ? errorDeSqlcmd(redactar(r.stdout, sensibles)) : r.stderr;
    const salidaError = redactar(textoError, sensibles);
    // 🔴 LA GUARDA DE RÉPLICA SE CLASIFICA PRIMERO (AC46), antes del tiempo
    // agotado y del genérico `conexion_fallida`: si la sesión cayó en el
    // writer, lo que el consumidor tiene que saber es eso, y el SQL suyo no
    // llegó a ejecutarse.
    if (entrada.dialecto === 'postgres' && r.status !== 0 && salidaError.indexOf(MENSAJE_NO_REPLICA) !== -1) {
      throw fallo(9, 'no_es_replica',
        'la conexión `' + entrada.nombre + '` no llegó a una réplica de lectura; la consulta no se ejecutó');
    }
    if (r.error && (r.error.code === 'ETIMEDOUT' || r.signal !== null)) {
      // Corte de PROCESO (el plugin lo mata): puede citar su propio valor.
      throw fallo(7, 'tiempo_agotado', 'la consulta superó los ' + TIMEOUT_PROCESO_MS + ' ms');
    }
    if (/statement timeout|Timeout expired|query_canceled/i.test(salidaError)) {
      // Corte del MOTOR por su propio límite de sentencia (AC28/AC49: el rol
      // lo fija, no el plugin). No cita 120000 ms: ese ya no es el límite
      // vigente, y citarlo sería afirmar un valor que el plugin no controla.
      throw fallo(7, 'tiempo_agotado', 'la consulta alcanzó el límite de tiempo de la sesión');
    }
    if (r.status !== 0) {
      throw fallo(6, 'conexion_fallida', salidaError.replace(/\s+$/, '').slice(0, 500));
    }

    const salida = String(r.stdout);
    const resultado = entrada.dialecto === 'postgres' ? parsearCsv(salida)
      : (plan.formato === 'json' ? parsearSalidaJsonSqlserver(salida) : parsearSalidaSqlserver(salida));
    return { columnas: resultado.columnas, filas: resultado.filas, avisos: resultado.avisos || [], respaldo: respaldo, usuario: credencial.usuario, plan: plan };
  } finally {
    // 🔴 EL BORRADO VA ACÁ Y NO DESPUÉS DEL `spawnSync`: corre también cuando
    // la consulta falla, que es justo el camino donde es fácil olvidarlo
    // (AC24).
    if (directorioTemporal !== null) {
      try { fs.rmSync(directorioTemporal, { recursive: true, force: true }); } catch (e) { /* nada que hacer */ }
    }
  }
}

/**
 * AC57 (v25): el error de sqlcmd dentro de su stdout. Si falló después de
 * haber emitido filas, stdout trae primero los datos y después el `Msg`: se
 * toma desde la primera línea `Msg <n>, Level <n>`, para que el mensaje no
 * sean datos y un dato que diga "Timeout expired" no se lea como corte. Si no
 * hay ninguna, se toma el final de stdout, que es donde sqlcmd escribe.
 */
function errorDeSqlcmd(stdout) {
  const s = String(stdout === null || stdout === undefined ? '' : stdout);
  const m = /^Msg \d+, Level \d+/m.exec(s);
  return m ? s.slice(m.index) : s.slice(-500);
}

/**
 * AC56 (v25): borra los directorios temporales del plugin que quedaron de un
 * proceso muerto sin pasar por el `finally`. Se llama al arrancar el
 * servidor. Sólo toca directorios con el prefijo del plugin y más viejos que
 * `edadMinimaMs`; cualquier error se ignora, porque la limpieza no puede
 * impedir que el servidor arranque.
 * @returns {number} cuántos borró
 */
function limpiarTemporalesHuerfanos(directorio, edadMinimaMs, ahoraMs) {
  const dir = directorio || os.tmpdir();
  const edad = typeof edadMinimaMs === 'number' ? edadMinimaMs : EDAD_HUERFANO_MS;
  const ahora = typeof ahoraMs === 'number' ? ahoraMs : Date.now();
  let borrados = 0;
  let nombres = [];
  try { nombres = fs.readdirSync(dir); } catch (e) { return 0; }
  for (let i = 0; i < nombres.length; i += 1) {
    // Sólo lo que crea `mkdtemp`: el prefijo más sus seis caracteres. Un
    // `bisalta-db-respaldo-viejo` del usuario no coincide.
    if (!NOMBRE_TEMP.test(nombres[i])) continue;
    const ruta = path.join(dir, nombres[i]);
    try {
      // `lstat` y no `stat`: un symlink con ese nombre no es un directorio del
      // plugin, y no se sigue.
      const st = fs.lstatSync(ruta);
      if (!st.isDirectory() || ahora - st.mtimeMs < edad) continue;
      fs.rmSync(ruta, { recursive: true, force: true });
      borrados += 1;
    } catch (e) { /* nada que hacer */ }
  }
  return borrados;
}

module.exports = {
  limpiarTemporalesHuerfanos: limpiarTemporalesHuerfanos,
  EDAD_HUERFANO_MS: EDAD_HUERFANO_MS,
  TIMEOUT_CONSULTA_SQLSERVER_S: TIMEOUT_CONSULTA_SQLSERVER_S,
  NIVEL_AISLAMIENTO_SQLSERVER: NIVEL_AISLAMIENTO_SQLSERVER,
  AVISO_AISLAMIENTO_SQLSERVER: AVISO_AISLAMIENTO_SQLSERVER,
  avisoParaNivel: avisoParaNivel,
  BUNDLE_RDS: BUNDLE_RDS,
  resolverCredencial: resolverCredencial,
  valorDeSesion: valorDeSesion,
  nombreDeArn: nombreDeArn,
  seudonimo: seudonimo,
  resolverIdentidad: resolverIdentidad,
  nombreDeSesion: nombreDeSesion,
  TIMEOUT_STS_MS: TIMEOUT_STS_MS,
  ejecutarConsulta: ejecutarConsulta,
  construirComandoPostgres: construirComandoPostgres,
  construirComandoSqlserver: construirComandoSqlserver,
  parsearCsv: parsearCsv,
  parsearSalidaSqlserver: parsearSalidaSqlserver,
  parsearSalidaJsonSqlserver: parsearSalidaJsonSqlserver,
  redactar: redactar,
  TIMEOUT_SENTENCIA_MS: TIMEOUT_SENTENCIA_MS,
  PREFIJO_TEMP: PREFIJO_TEMP,
  SEPARADOR_SQLSERVER: SEPARADOR_SQLSERVER
};
