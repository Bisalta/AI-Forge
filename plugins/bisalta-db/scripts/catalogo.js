#!/usr/bin/env node
'use strict';
//
// plugins/bisalta-db/scripts/catalogo.js — lectura y validación de
// plugins/bisalta-db/catalogo.json (contract v2, "Contrato de datos").
//
// 🔴 PRODUCCIÓN ES IRREPRESENTABLE, NO RECHAZADA POR NOMBRE. `ambiente`
// admite `dev` y `qa` y nada más: no hay valor que nombre producción. Una
// lista de nombres prohibidos es red; esto es barrera. La comprobación de
// host de producción (AC12) es el cinturón encima del tirante, para el caso
// de una entrada de dev/qa que apunte al cluster equivocado.
//
// El catálogo NO tiene campo de usuario ni de contraseña: los dos salen del
// secreto de AWS, en la forma estándar de RDS.
//
// Uso como CLI:  node catalogo.js [ruta]   (default: ../catalogo.json)
// Exit: 0 = catálogo válido · 1 = inválido (los problemas van a stderr,
//       cada uno nombrando la entrada) · 2 = no se pudo leer o parsear.

const fs = require('fs');
const path = require('path');

const RUTA_POR_DEFECTO = path.join(__dirname, '..', 'catalogo.json');

// Los únicos campos que una entrada puede tener. Cualquier otro hace que el
// catálogo entero se rechace: un campo desconocido es una suposición de
// alguien que no leyó el contrato de datos, y callarla es peor que fallar.
const CAMPOS = ['nombre', 'dialecto', 'ambiente', 'host', 'puerto', 'base', 'secret_id', 'region', 'garantias'];

const DIALECTOS = ['postgres', 'sqlserver'];
const AMBIENTES = ['dev', 'qa'];
const GARANTIAS = ['rol-solo-lectura', 'sesion-read-only', 'endpoint-replica-lectura'];

// Cluster y host de la cuenta AWS de PRODUCCIÓN (contract v2, "Out of
// scope"). Ninguna entrada puede apuntar ahí.
const HOSTS_PROHIBIDOS = ['cluster-cr4rbgr7qlr6', '192.168.252.22'];

const NOMBRE_VALIDO = /^[a-z0-9-]+$/;

function esCadenaNoVacia(v) {
  return typeof v === 'string' && v.replace(/^\s+|\s+$/g, '') !== '';
}

/**
 * Valida el arreglo de entradas.
 * @returns {string[]} problemas; vacío = catálogo válido. Cada problema
 *   nombra la entrada (por `nombre` si lo tiene, si no por su índice).
 */
function validarEntradas(entradas) {
  const problemas = [];

  if (!Array.isArray(entradas)) {
    problemas.push('el catálogo tiene que ser un arreglo de objetos');
    return problemas;
  }
  if (entradas.length === 0) {
    problemas.push('el catálogo no tiene ninguna entrada');
    return problemas;
  }

  const vistos = {};

  for (let i = 0; i < entradas.length; i += 1) {
    const entrada = entradas[i];
    const etiqueta = (entrada && esCadenaNoVacia(entrada.nombre)) ? entrada.nombre : ('entrada #' + i);

    if (entrada === null || typeof entrada !== 'object' || Array.isArray(entrada)) {
      problemas.push(etiqueta + ': no es un objeto');
      continue;
    }

    const claves = Object.keys(entrada);
    for (let k = 0; k < claves.length; k += 1) {
      if (CAMPOS.indexOf(claves[k]) === -1) {
        problemas.push(etiqueta + ': campo no declarado en el contrato de datos: ' + claves[k]);
      }
    }
    for (let c = 0; c < CAMPOS.length; c += 1) {
      if (claves.indexOf(CAMPOS[c]) === -1) {
        problemas.push(etiqueta + ': falta el campo requerido: ' + CAMPOS[c]);
      }
    }

    if (!esCadenaNoVacia(entrada.nombre) || !NOMBRE_VALIDO.test(entrada.nombre)) {
      problemas.push(etiqueta + ': `nombre` admite minúsculas, dígitos y guiones');
    } else if (Object.prototype.hasOwnProperty.call(vistos, entrada.nombre)) {
      problemas.push(etiqueta + ': `nombre` repetido en el catálogo');
    } else {
      vistos[entrada.nombre] = true;
    }

    if (DIALECTOS.indexOf(entrada.dialecto) === -1) {
      problemas.push(etiqueta + ': `dialecto` tiene que ser ' + DIALECTOS.join(' o '));
    }

    if (AMBIENTES.indexOf(entrada.ambiente) === -1) {
      problemas.push(etiqueta + ': `ambiente` tiene que ser ' + AMBIENTES.join(' o ') +
        ' — producción es irrepresentable en este catálogo');
    }

    if (!esCadenaNoVacia(entrada.host)) {
      problemas.push(etiqueta + ': `host` tiene que ser una cadena no vacía');
    } else {
      for (let h = 0; h < HOSTS_PROHIBIDOS.length; h += 1) {
        if (entrada.host.indexOf(HOSTS_PROHIBIDOS[h]) !== -1) {
          problemas.push(etiqueta + ': `host` apunta a la cuenta de producción (' + HOSTS_PROHIBIDOS[h] + ')');
        }
      }
    }

    if (typeof entrada.puerto !== 'number' || !isFinite(entrada.puerto) ||
        Math.floor(entrada.puerto) !== entrada.puerto || entrada.puerto < 1 || entrada.puerto > 65535) {
      problemas.push(etiqueta + ': `puerto` tiene que ser un entero entre 1 y 65535');
    }

    if (!esCadenaNoVacia(entrada.base)) {
      problemas.push(etiqueta + ': `base` tiene que ser una cadena no vacía');
    }
    if (!esCadenaNoVacia(entrada.secret_id)) {
      problemas.push(etiqueta + ': `secret_id` tiene que ser una cadena no vacía');
    }
    if (!esCadenaNoVacia(entrada.region)) {
      problemas.push(etiqueta + ': `region` tiene que ser una cadena no vacía');
    }

    if (!Array.isArray(entrada.garantias) || entrada.garantias.length === 0) {
      problemas.push(etiqueta + ': `garantias` tiene que ser un arreglo de al menos un elemento');
    } else {
      for (let g = 0; g < entrada.garantias.length; g += 1) {
        if (GARANTIAS.indexOf(entrada.garantias[g]) === -1) {
          problemas.push(etiqueta + ': garantía desconocida: ' + entrada.garantias[g]);
        }
      }
    }
  }

  return problemas;
}

/**
 * Lee y valida el catálogo. Se llama por invocación, no una vez al arrancar:
 * es lo que hace que borrar una entrada sea un kill switch inmediato (AC37).
 * @throws {Error} con `.codigo` 2 si no se puede leer/parsear, 1 si es inválido.
 */
function cargarCatalogo(ruta) {
  const destino = ruta || RUTA_POR_DEFECTO;
  let crudo;
  try {
    crudo = fs.readFileSync(destino, 'utf8');
  } catch (e) {
    const err = new Error('no pude leer el catálogo en ' + destino);
    err.codigo = 2;
    throw err;
  }
  let entradas;
  try {
    entradas = JSON.parse(crudo);
  } catch (e) {
    const err = new Error('el catálogo ' + destino + ' no es JSON válido');
    err.codigo = 2;
    throw err;
  }
  const problemas = validarEntradas(entradas);
  if (problemas.length > 0) {
    const err = new Error('catálogo inválido:\n  - ' + problemas.join('\n  - '));
    err.codigo = 1;
    err.problemas = problemas;
    throw err;
  }
  return entradas;
}

/** Proyección pública de `listar_conexiones` (AC35). */
function proyectar(entrada) {
  return {
    nombre: entrada.nombre,
    dialecto: entrada.dialecto,
    ambiente: entrada.ambiente,
    base: entrada.base,
    garantias: entrada.garantias
  };
}

module.exports = {
  cargarCatalogo: cargarCatalogo,
  validarEntradas: validarEntradas,
  proyectar: proyectar,
  RUTA_POR_DEFECTO: RUTA_POR_DEFECTO,
  CAMPOS: CAMPOS,
  GARANTIAS: GARANTIAS
};

// --- CLI -------------------------------------------------------------------
// `process.exitCode` y no `process.exit()`: ver el comentario del CLI de
// lista-blanca.js — salir en el acto corta lo que stdout todavía tiene en el
// buffer cuando la salida va a un pipe.
if (require.main === module) {
  const ruta = process.argv[2] || RUTA_POR_DEFECTO;
  try {
    const entradas = cargarCatalogo(ruta);
    process.stdout.write('catálogo válido: ' + entradas.length + ' conexión(es) — ' +
      entradas.map(function (e) { return e.nombre; }).join(', ') + '\n');
    process.exitCode = 0;
  } catch (e) {
    process.stderr.write(e.message + '\n');
    process.exitCode = typeof e.codigo === 'number' ? e.codigo : 1;
  }
}
