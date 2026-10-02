#!/usr/bin/env node
'use strict';
//
// plugins/bisalta-db/scripts/catalogo.js — lectura y validación de
// plugins/bisalta-db/catalogo.json (contract v3, "Contrato de datos").
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
// AC64 (v31): el único campo opcional. Una base multitenant filtra por un
// parámetro de sesión (RLS), y sin él el rol ve 0 filas. La entrada declara
// el parámetro, su formato y los NOMBRES de los tenants; los UUID viven en el
// secreto (`tenant_<nombre>`), nunca acá: este archivo es público.
const CAMPOS_OPCIONALES = ['sesion'];
const CAMPOS_SESION = ['parametro', 'formato', 'tenants', 'alcance'];
// Hay dos convenciones medidas el 1-oct: SmartCheck usa `app.tenant_ids`, una
// lista separada por coma; SmartFleet, `app.tenant_id`, un solo UUID.
const FORMATOS_SESION = ['uuid', 'uuid_lista'];
// Un parámetro de configuración propio: `<prefijo>.<nombre>`. Se interpola en
// un SET, que no acepta parámetros: sólo pasa lo que cabe en este patrón.
const PARAMETRO_SESION_VALIDO = /^[a-z_][a-z0-9_]*\.[a-z_][a-z0-9_]*$/;
const TENANT_VALIDO = /^[a-z0-9_]+$/;

const DIALECTOS = ['postgres', 'sqlserver'];
const AMBIENTES = ['dev', 'qa'];
// 'deny-escritura' (contract v5, "Contrato de datos" y "Cambios v3 → v4"
// punto 4): db_denydatawriter en SQL Server. El enum de este archivo es
// el único lugar del código que lo declara — las entradas `sqlserver` de
// catalogo.json la suma en el mismo cambio (contract v5, "AGENT_r2 no se
// reabre... salvo el enum de garantías del catálogo, que se trata como
// parte del scope reabierto de R1").
const GARANTIAS = ['rol-solo-lectura', 'sesion-read-only', 'endpoint-replica-lectura', 'deny-escritura'];

// Nivel de cada garantía (contract v15; criterio cerrado en v16, "Cambios
// v15 → v16" punto 1). Las tres garantías de Postgres no son igual de fuertes
// y declararlas al mismo nivel era una afirmación que no se sostiene.
//   incondicional -> el plugin la comprueba en cada consulta, en la misma
//                    sesión y antes de ejecutar el SQL del consumidor, y se
//                    niega a ejecutarlo si no se cumple.
//   condicional   -> cualquier otra; declara en `condicion` de qué depende.
// Con ese criterio la única incondicional es `endpoint-replica-lectura`,
// PORQUE la guarda de AC46 (conexion.js) la comprueba: Aurora apunta el
// endpoint `cluster-ro-` al writer cuando el cluster se queda sin réplicas, y
// sin la guarda el endpoint solo no alcanzaría. Si la guarda se quita, la
// garantía deja de ser incondicional: el nivel sigue a la verificación, no a
// la intuición sobre el mecanismo.
const NIVELES = ['incondicional', 'condicional'];
const CAMPOS_GARANTIA = ['nombre', 'nivel', 'condicion'];

// Cluster y host de la cuenta AWS de PRODUCCIÓN (contract v3, "Out of
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
      if (CAMPOS.indexOf(claves[k]) === -1 && CAMPOS_OPCIONALES.indexOf(claves[k]) === -1) {
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
        const garantia = entrada.garantias[g];
        const donde = etiqueta + ': garantias[' + g + ']';
        if (garantia === null || typeof garantia !== 'object' || Array.isArray(garantia)) {
          problemas.push(donde + ': tiene que ser un objeto con `nombre` y `nivel`');
          continue;
        }
        const claves = Object.keys(garantia);
        for (let k = 0; k < claves.length; k += 1) {
          if (CAMPOS_GARANTIA.indexOf(claves[k]) === -1) {
            problemas.push(donde + ': campo desconocido: ' + claves[k]);
          }
        }
        if (GARANTIAS.indexOf(garantia.nombre) === -1) {
          problemas.push(donde + ': garantía desconocida: ' + garantia.nombre);
        }
        if (NIVELES.indexOf(garantia.nivel) === -1) {
          problemas.push(donde + ': `nivel` tiene que ser uno de ' + NIVELES.join(', '));
          continue;
        }
        // Una garantía condicional SIN decir de qué depende vuelve a ser la
        // afirmación plana que este cambio vino a eliminar: el catálogo no
        // puede declarar una condición que no nombra.
        if (garantia.nivel === 'condicional' && !esCadenaNoVacia(garantia.condicion)) {
          problemas.push(donde + ': una garantía `condicional` tiene que declarar `condicion`');
        }
        // Y una incondicional con `condicion` se estaría contradiciendo.
        if (garantia.nivel === 'incondicional' && garantia.condicion !== undefined) {
          problemas.push(donde + ': una garantía `incondicional` no lleva `condicion`');
        }
      }
    }

    if (entrada.sesion !== undefined) {
      validarSesion(entrada, etiqueta, problemas);
    }
  }

  return problemas;
}

/** AC64 (v31): el bloque `sesion` de una entrada multitenant. */
function validarSesion(entrada, etiqueta, problemas) {
  const sesion = entrada.sesion;
  const donde = etiqueta + ': sesion';
  if (sesion === null || typeof sesion !== 'object' || Array.isArray(sesion)) {
    problemas.push(donde + ': tiene que ser un objeto con ' + CAMPOS_SESION.join(', '));
    return;
  }
  const claves = Object.keys(sesion);
  for (let k = 0; k < claves.length; k += 1) {
    if (CAMPOS_SESION.indexOf(claves[k]) === -1) problemas.push(donde + ': campo desconocido: ' + claves[k]);
  }
  for (let c = 0; c < CAMPOS_SESION.length; c += 1) {
    if (claves.indexOf(CAMPOS_SESION[c]) === -1) problemas.push(donde + ': falta el campo requerido: ' + CAMPOS_SESION[c]);
  }
  // Sólo Postgres: el RLS por parámetro de sesión es de Postgres, y en SQL
  // Server el prefijo de -Q ya es otra cosa (AC61).
  if (entrada.dialecto !== 'postgres') {
    problemas.push(donde + ': sólo se admite en dialecto postgres');
  }
  if (typeof sesion.parametro !== 'string' || !PARAMETRO_SESION_VALIDO.test(sesion.parametro)) {
    problemas.push(donde + ': `parametro` tiene que ser <prefijo>.<nombre>, en minúsculas, dígitos y guiones bajos');
  }
  if (FORMATOS_SESION.indexOf(sesion.formato) === -1) {
    problemas.push(donde + ': `formato` tiene que ser ' + FORMATOS_SESION.join(' o '));
  }
  if (!Array.isArray(sesion.tenants) || sesion.tenants.length === 0) {
    problemas.push(donde + ': `tenants` tiene que ser un arreglo de al menos un nombre');
  } else {
    const vistos = {};
    for (let t = 0; t < sesion.tenants.length; t += 1) {
      const tenant = sesion.tenants[t];
      if (typeof tenant !== 'string' || !TENANT_VALIDO.test(tenant)) {
        problemas.push(donde + ': tenants[' + t + '] admite minúsculas, dígitos y guiones bajos');
      } else if (Object.prototype.hasOwnProperty.call(vistos, tenant)) {
        problemas.push(donde + ': tenants[' + t + '] repetido');
      } else {
        vistos[tenant] = true;
      }
    }
    // Un parámetro de un solo UUID no puede llevar dos: se rechaza el
    // catálogo, en vez de mandar sólo el primero y ocultar el segundo.
    if (sesion.formato === 'uuid' && sesion.tenants.length !== 1) {
      problemas.push(donde + ': el formato `uuid` admite exactamente un tenant');
    }
  }
  // Lo que el parámetro destraba, escrito: el RLS de una base suele cubrir
  // muchas más tablas que las que motivaron la entrada (1-oct: 43 en
  // SmartCheck, no 3).
  if (!esCadenaNoVacia(sesion.alcance)) {
    problemas.push(donde + ': `alcance` tiene que decir qué destraba el parámetro');
  }
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
    garantias: entrada.garantias,
    // AC64: los nombres de los tenants y el alcance, nunca los UUID.
    sesion: entrada.sesion === undefined ? null : {
      parametro: entrada.sesion.parametro,
      tenants: entrada.sesion.tenants,
      alcance: entrada.sesion.alcance
    }
  };
}

module.exports = {
  cargarCatalogo: cargarCatalogo,
  validarEntradas: validarEntradas,
  proyectar: proyectar,
  RUTA_POR_DEFECTO: RUTA_POR_DEFECTO,
  CAMPOS: CAMPOS,
  CAMPOS_OPCIONALES: CAMPOS_OPCIONALES,
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
