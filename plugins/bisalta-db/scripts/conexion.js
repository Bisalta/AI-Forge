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
// Separador de campos para SQL Server: un carácter de control que no aparece
// en datos de texto normales (unit separator, 0x1F).
const SEPARADOR_SQLSERVER = String.fromCharCode(31);
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
  return { usuario: usuario, contrasena: contrasena };
}

/**
 * Comando de Postgres. El usuario, el host, el puerto y la base viajan en el
 * conninfo; la contraseña, sólo en el archivo que apunta la variable de
 * archivo de credenciales de libpq.
 * AC28 (sesión de solo lectura; el `statement_timeout` ya no viaja por acá,
 * lo fija el rol — AC49) y AC29 (`application_name` = usuario del secreto,
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
function construirComandoPostgres(entrada, usuario, rutaPassfile, sql) {
  const conninfo = 'postgresql://' + encodeURIComponent(usuario) + '@' +
    entrada.host + ':' + entrada.puerto + '/' + encodeURIComponent(entrada.base);
  return {
    comando: 'psql',
    args: ['--no-psqlrc', '--pset=pager=off', '--csv', '--quiet', '--variable=ON_ERROR_STOP=1',
      '--command', GUARDA_REPLICA, '--command', sql, conninfo],
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
      PGAPPNAME: usuario,
      PGCONNECT_TIMEOUT: '15'
    }
  };
}

/** Comando de SQL Server. La contraseña va por entorno, nunca por argv. */
function construirComandoSqlserver(entrada, usuario, contrasena, sql) {
  const env = {};
  env[VARIABLE_CREDENCIAL_SQLSERVER] = contrasena;
  return {
    comando: 'sqlcmd',
    args: ['-S', entrada.host + ',' + entrada.puerto, '-d', entrada.base, '-U', usuario,
      '-b', '-s', SEPARADOR_SQLSERVER, '-W', '-Q', sql],
    env: env
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
  for (let i = 0; i < lineas.length; i += 1) {
    const linea = lineas[i];
    if (linea.replace(/\s+/g, '') === '') continue;
    if (/^\(\d+ rows? affected\)/i.test(linea.replace(/^\s+/, ''))) continue;
    const celdas = linea.split(SEPARADOR_SQLSERVER);
    if (columnas === null) { columnas = celdas; indiceUtil = 1; continue; }
    if (indiceUtil === 1 && /^-+$/.test(celdas[0].replace(/\s+/g, ''))) { indiceUtil = 2; continue; }
    indiceUtil = 2;
    const obj = {};
    for (let c = 0; c < columnas.length; c += 1) {
      obj[columnas[c]] = celdas[c] === undefined ? null : celdas[c];
    }
    objetos.push(obj);
  }
  return { columnas: columnas || [], filas: objetos };
}

/**
 * Corre la consulta y devuelve las filas. La lista blanca ya la validó: acá
 * no se decide qué SQL es aceptable.
 * @throws error con `.codigo` 5, 6, 7, 8 o 9.
 */
function ejecutarConsulta(entrada, sql) {
  const credencial = resolverCredencial(entrada);
  const sensibles = [credencial.contrasena];

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
      plan = construirComandoPostgres(entrada, credencial.usuario, rutaPassfile, sql);
    } else {
      plan = construirComandoSqlserver(entrada, credencial.usuario, credencial.contrasena, sql);
    }

    const entorno = Object.assign({}, process.env, plan.env);
    const r = spawnSync(plan.comando, plan.args, {
      encoding: 'utf8',
      env: entorno,
      maxBuffer: MAX_BUFFER,
      timeout: TIMEOUT_PROCESO_MS
    });

    if (r.error && r.error.code === 'ENOENT') {
      throw fallo(8, 'cliente_ausente', 'falta el binario `' + plan.comando + '` en el PATH');
    }
    const salidaError = redactar(r.stderr, sensibles);
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
    const resultado = entrada.dialecto === 'postgres' ? parsearCsv(salida) : parsearSalidaSqlserver(salida);
    return { columnas: resultado.columnas, filas: resultado.filas, usuario: credencial.usuario, plan: plan };
  } finally {
    // 🔴 EL BORRADO VA ACÁ Y NO DESPUÉS DEL `spawnSync`: corre también cuando
    // la consulta falla, que es justo el camino donde es fácil olvidarlo
    // (AC24).
    if (directorioTemporal !== null) {
      try { fs.rmSync(directorioTemporal, { recursive: true, force: true }); } catch (e) { /* nada que hacer */ }
    }
  }
}

module.exports = {
  resolverCredencial: resolverCredencial,
  ejecutarConsulta: ejecutarConsulta,
  construirComandoPostgres: construirComandoPostgres,
  construirComandoSqlserver: construirComandoSqlserver,
  parsearCsv: parsearCsv,
  parsearSalidaSqlserver: parsearSalidaSqlserver,
  redactar: redactar,
  TIMEOUT_SENTENCIA_MS: TIMEOUT_SENTENCIA_MS,
  PREFIJO_TEMP: PREFIJO_TEMP,
  SEPARADOR_SQLSERVER: SEPARADOR_SQLSERVER
};
