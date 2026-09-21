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
- **Cuándo**: **21-sep-2026**
- **Dónde consta**: DM de Slack con Ian Vargas, 2026-09-21 10:31 CST
- **Estado**: aprobado, con alcance **por base y a pedido nombrado**

> 🔴 **Este texto reemplaza en su totalidad al del 18-sep-2026, que queda anulado.** El anterior
> omitía `CONSTRUPLAZA_EFLOW` en su enumeración y, tras la regla del 21-sep, además declaraba un
> alcance **más amplio del que va a existir**. Patrick pidió explícitamente que se reemplazara
> entero y no se le agregara una línea al pie.

Texto literal de la aprobación vigente:

```
Patrick Ocampo, 21-sep-2026.
Reemplaza en su totalidad el texto del 18-sep-2026, que queda anulado.

Apruebo un login de solo lectura en Dev SQL (10.24.40.137), para uso
exclusivo del servidor MCP, con alcance POR BASE Y A PEDIDO NOMBRADO.

1. El login arranca sin acceso a ninguna base de negocio.

2. Cada base se agrega cuando alguien la pide por su nombre. Se concede
   el mismo dia, sin aprobacion adicional, y queda registrada abajo con
   fecha y solicitante. Una base nueva no queda cubierta por omision.

3. Hechos conocidos al firmar: las bases de Dev SQL son COPIAS DE
   PRODUCCION, no datos de desarrollo. Medido el 18-sep-2026: 32 bases,
   1.35 TB, ninguna en solo lectura. COMPRAS_STG pesa exactamente lo
   mismo que COMPRAS (107.09 GB) y se creo el 7-sep-2026. Las mayores:
   EXACTUS 395 GB, CONSTRUPLAZA_EFLOW 266.92 GB, BI 177 GB,
   COMPRAS 107.09 GB.

4. La politica de uso de IA pone los datos de produccion bajo aprobacion
   de Esteban o Sebastian. Esta aprobacion la firmo yo por encima de esa
   via, a sabiendas, y no la sustituye para otros casos.

5. Permanentemente fuera de alcance: SSISDB (catalogo de Integration
   Services, contiene connection managers), master, model, msdb, tempdb.

6. Cada base concedida lleva db_datareader y nada mas. El login no
   recibe ningun rol ni permiso de escritura. Nota: sin
   db_denydatawriter no queda un DENY explicito, asi que un GRANT de
   escritura concedido por error en el futuro no tendria nada que lo
   anule. La lectura sigue siendo la unica capacidad del login.

7. La credencial se genera y se carga directamente en Secrets Manager,
   con politica IAM por consumidor. No pasa por ninguna persona fuera de
   quien firma.

BASES CONCEDIDAS
fecha        base           solicitante
2026-09-21   COMPRAS        Ian Vargas
2026-09-21   COMPRAS_STG    Ian Vargas
2026-09-21   Ecommerce      Ian Vargas
2026-09-21   Ecommerce_qa   Ian Vargas
2026-09-21   EXACTUS        Ian Vargas
2026-09-21   BI             Ian Vargas

Revision: al cierre del corte Exactus->Odoo (17-oct-2026).
```

### Bases pedidas — registro vivo

Patrick pidió la lista el 21-sep-2026 (*"decime hoy qué bases ocupás para arrancar y quedan
concedidas hoy"*). Ian Vargas pidió estas seis y **Patrick las concedió el mismo día** (*"las seis
van… concedidas hoy"*), que es lo que el punto 2 de la aprobación establece. Ian Vargas aclaró que
son las **iniciales para probar la herramienta**, no el alcance definitivo. La ejecución del loop
sigue pendiente; la concesión, no.

| Fecha del pedido | Base | Tamaño | Solicitante | Concedida |
|---|---|---|---|---|
| 2026-09-21 | `COMPRAS` | 107.09 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |
| 2026-09-21 | `COMPRAS_STG` | 107.09 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |
| 2026-09-21 | `Ecommerce` | 16.89 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |
| 2026-09-21 | `Ecommerce_qa` | 56.89 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |
| 2026-09-21 | `EXACTUS` | 396.10 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |
| 2026-09-21 | `BI` | 177.06 GB | Ian Vargas | **concedida** (Patrick, 21-sep 12:22) |

**861.12 GB de los 1383.16 del servidor — el 62%.** Las 26 bases restantes quedan sin conceder, y
una base nueva no queda cubierta por omisión.

### Lo que esta aprobación NO cubre

- La política de uso de IA pone los datos de producción bajo aprobación de **Esteban Fait o
  Sebastián**. Patrick firma por encima de esa vía **a sabiendas**, lo dice en el punto 4, y deja
  escrito que **no la sustituye para otros casos**. Esa segunda aprobación sigue siendo precondición
  de habilitar el plugin al equipo.
- `Prod SQL` (`192.168.252.22`). Fuera de alcance, otra cuenta de AWS.

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
