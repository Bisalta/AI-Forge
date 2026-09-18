# Aprobaciones de acceso — plugin `bisalta-db`

Quién autorizó qué, cuándo, y sabiendo qué. Este archivo existe porque una aprobación
que vive sólo en un DM no la encuentra nadie dentro de seis meses, y porque lo que se
autoriza acá es lectura sobre copias de datos de producción.

**Regla**: una conexión del catálogo que toque copias de producción no se habilita al
equipo sin una entrada en este archivo. La entrada nombra a la persona, la fecha, y el
alcance **medido** — no el alcance supuesto.

---

## Dev SQL (`10.24.40.137:1433`) — login de solo lectura

- **Quién aprueba**: Patrick Ocampo
- **Cuándo**: 18-sep-2026
- **Dónde consta**: DM de Slack con Ian Vargas, 2026-09-18 12:46 CST
- **Estado**: aprobado

Texto literal de la aprobación, como Patrick pidió que quedara escrito:

> *Patrick Ocampo aprueba un login de solo lectura sobre las bases de Dev SQL
> (10.24.40.137), sabiendo que son copias de producción — EXACTUS 395 GB, BI 177,
> COMPRAS 107 — y en conocimiento de que la política las pone bajo aprobación de Esteban
> o Sebastián.*

Y la instrucción con la que lo acompañó:

> *No lo dejés solo en este DM: ponelo en el expediente del repo, que es donde alguien lo
> va a ir a buscar dentro de seis meses.*

### Alcance real, medido después de la aprobación

La aprobación nombra tres bases. El inventario corrido el mismo día
([`INVENTARIO.md`](./INVENTARIO.md)) midió **32 bases y 1383 GB en total**, e incluye una
que no está en el texto aprobado:

| | |
|---|---|
| `EXACTUS` | 396.10 GB — la aprobación dice 395 |
| `BI` | 177.06 GB |
| `COMPRAS` | 107.09 GB |
| **`CONSTRUPLAZA_EFLOW`** | **266.92 GB — no nombrada en la aprobación; segunda más grande del servidor** |
| otras 28 | el resto hasta 1383 GB |

Esto **no invalida la aprobación**: `db_datareader` sobre el servidor alcanza 31 de las 32
con o sin esa enumeración (`SSISDB` queda fuera del loop por decisión de Patrick, contract
v6, "Cambios v5 → v6" punto 1 — no guarda dato de negocio y sí credenciales), y el texto
dice "las bases de Dev SQL", no una lista cerrada. Se deja escrito porque la diferencia
entre lo enumerado y lo medido es exactamente el tipo de cosa que después nadie puede
reconstruir. Comunicado a Patrick el mismo día.

### Lo que esta aprobación NO cubre

- La política de uso de IA de la empresa pone los datos de producción bajo aprobación de
  **Esteban Fait o Sebastián**. Patrick aprobó el login sabiéndolo y dejándolo dicho;
  esa segunda aprobación **sigue pendiente** y es precondición de habilitar el plugin al
  equipo, no de construirlo.
- `Prod SQL` (`192.168.252.22`). Fuera de alcance, otra cuenta de AWS.

---

## Postgres — cluster de dev/qa (`cfrl3owqzwof`)

- **Quién aprueba**: Patrick Ocampo (crea él los roles y las claves)
- **Cuándo**: 18-sep-2026
- **Dónde consta**: mismo DM
- **Estado**: aprobado, con dos condiciones que él fijó

1. **IAM auth queda para después.** Va clave en Secrets Manager. Su razón textual:
   habilitarlo *"es modificar un cluster compartido y no lo quiero meter en la misma
   semana que esto"*. Anotado como la mejora que sigue.
2. **El cluster de producción (`cluster-cr4rbgr7qlr6`) queda fuera**, y con él las cinco
   `_stg` que viven ahí. No por política sino porque no hay forma de dar una sin dar las
   `_prod` hermanas: `pg_read_all_data` es membresía de cluster y Postgres concede
   `CONNECT` a PUBLIC por omisión.

### Alcance real, medido

`pg_read_all_data` alcanza **las 29 bases del cluster** desde que el rol existe, no las
dos que el catálogo declara. Cinco de esas 29 no declaran ambiente en el nombre
(`babelfish_db`, `bisalta`, `construplaza`, `qa`, `rrhh`). Detalle en
[`INVENTARIO.md`](./INVENTARIO.md).

Las bases `_stg` que viven en **este** cluster (`controlactivos_stg`) son clones de dev y
entran al alcance: Ian Vargas, 18-sep-2026. No se confunden con las `_stg` del cluster de
producción, que siguen fuera.
