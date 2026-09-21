# Inventario medido de las fuentes — 18-sep-2026

Lo que un rol de solo lectura **alcanza de verdad** en cada motor. No es documentación
de contexto: es el insumo de la Parte 0 del aprovisionamiento de Postgres (abortar si
el cluster contiene producción) y del loop por base de SQL Server.

Medido el 18-sep-2026 por Ian Vargas, con los queries de abajo. **Ninguna cifra de este
archivo está inferida.** Si alguna queda vieja, se re-mide; no se corrige a mano.

---

## Postgres — cluster `sistemas-costruplaza-db` (cuenta de dev)

> 🔴 **Corrección de v8**: las versiones anteriores de este documento titulaban esta sección "cluster `cfrl3owqzwof`". **`cfrl3owqzwof` no es un cluster: es el sufijo DNS de la cuenta de AWS**, y todos los clusters de esa cuenta lo llevan. En la cuenta de dev hay **cuatro** Aurora PostgreSQL — `dev-costruplaza-db`, `erp-costruplaza-db`, `erpodoo-19-dev` y `sistemas-costruplaza-db`. Las 29 bases de abajo son **de este último**. Como los roles de Postgres son objetos de cluster, cubrir la cuenta son cuatro decisiones, no una. Los otros tres siguen **sin medir** salvo `erp-costruplaza-db`, medido por Patrick Ocampo (34 bases, dieciséis clones fechados de Odoo).
>
> Y una letra separa dev de producción: dev es `sistemas-co`**`s`**`truplaza-db`, prod es `sistemas-co`**`ns`**`truplaza-db`.

```sql
SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY 1;
```

**29 bases.** `pg_read_all_data` es membresía de cluster y Postgres concede `CONNECT` a
PUBLIC por omisión, así que el rol **alcanza las 29 desde el momento en que existe** —
no las dos que el catálogo declara. Los `GRANT` por base no cambian eso: para cuando
corren, el acceso ya está.

| Base | Ambiente por nombre |
|---|---|
| `ambass_dev` | dev |
| `babelfish_db` | **sin sufijo** |
| `bisalta` | **sin sufijo** |
| `construplaza` | **sin sufijo** |
| `controlactivos_stg` | **stg** |
| `marksync_dev` · `marksync_qa` | dev · qa |
| `octoparse_dev` · `octoparse_qa` | dev · qa |
| `portalrh_dev` · `portalrh_qa` | dev · qa |
| `postgres` | sistema |
| `pricing_dev` · `pricing_qa` | dev · qa |
| `proveedores_dev` · `proveedores_qa` | dev · qa — **las dos del catálogo** |
| `proxima_dev` · `proxima_qa` | dev · qa |
| `qa` | **sin sufijo** (se llama así) |
| `rdsadmin` | sistema |
| `rrhh` | **sin sufijo** |
| `smartcheck_dev` · `smartcheck_qa` | dev · qa |
| `smartfleet_dev` · `smartfleet_qa` | dev · qa |
| `tallerservicio_dev` | dev |
| `textract_dev` · `textract_qa` | dev · qa |
| `wms_dev` | dev |

### Dos hechos que contradicen supuestos previos

0. 🔴 **Ni el tamaño ni el nombre clasifican el riesgo.** Medido adentro por Patrick el 18-sep-2026, y corrige lo que este documento afirmaba por inferencia: **`portalrh_qa` pesa 55 MB y contiene 3.458 empleados, 3.309 contratos, 29.848 marcas diarias y 400 nóminas históricas**, con columnas `cedulaCcss`, `identificacion` y `salarioActual/Maximo/Minimo`. `qa` tiene 212.020 clientes con `cedula` y salarios. `construplaza`, 975 empleados. Y **`rrhh` —la que este documento señaló por el nombre— está vacía**. Las dos heurísticas fallaron, cada una en su dirección. `portalrh_dev`, `portalrh_qa` y `construplaza` ya tienen revocado el `CONNECT` a PUBLIC (`datacl` de `=Tc/` a `=T/`).

1. **`controlactivos_stg` vive en el cluster de dev/qa.** La regla "stg vive con prod,
   para toda la casa" —medida sobre el cluster de producción y escrita así en el
   contract— tiene al menos un contraejemplo. Importa porque la Parte 0 aborta si alguna
   base matchea producción: si su patrón incluye `stg`, se niega a correr acá.
2. **Cinco bases no declaran ambiente en el nombre**: `babelfish_db`, `bisalta`,
   `construplaza`, `qa` y `rrhh`. El rol las lee igual. `rrhh` es la que más pesa en el
   riesgo: el nombre sugiere nómina y datos de empleados, y nada en el nombre del cluster
   dice qué tiene adentro.

---

## SQL Server — `Dev SQL` (`10.24.40.137:1433`)

```sql
SELECT d.name AS base, d.database_id AS id, d.state_desc AS estado,
       CAST(SUM(mf.size) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS gb,
       d.create_date AS creada, d.is_read_only AS solo_lectura
FROM sys.databases d
JOIN sys.master_files mf ON mf.database_id = d.database_id
WHERE d.database_id > 4
GROUP BY d.name, d.database_id, d.state_desc, d.create_date, d.is_read_only
ORDER BY d.name;
```

**32 bases de usuario, 1383.16 GB (1.35 TB) en total. Las 32 `ONLINE`. Ninguna en solo
lectura (`is_read_only = 0` en las 32).**

| # | Base | id | GB | Creada |
|---|---|---|---|---|
| 1 | `ASISTENCIA` | 6 | 2.35 | 2024-07-30 |
| 2 | `BI` | 27 | 177.06 | 2024-07-31 |
| 3 | `COMPRAS` | 18 | 107.09 | 2024-07-30 |
| 4 | `COMPRAS_STG` | 35 | 107.09 | **2026-09-07** |
| 5 | `CONSTRUPLAZA_EFLOW` | 22 | **266.92** | 2024-07-30 |
| 6 | `CONSTRUPLAZA_EINTEGRA_CONFIG` | 20 | 2.77 | 2024-07-30 |
| 7 | `Construplaza_Intranet` | 25 | 33.74 | 2024-07-31 |
| 8 | `Construplaza_Security` | 7 | 0.14 | 2024-07-30 |
| 9 | `Consumos_Compras` | 8 | 2.44 | 2024-07-30 |
| 10 | `Descuento_Comercial` | 11 | 0.78 | 2024-07-30 |
| 11 | `Ecommerce` | 31 | 16.89 | 2025-10-03 |
| 12 | `Ecommerce_qa` | 33 | 56.89 | 2026-04-14 |
| 13 | `EFLOW_HISTORY` | 16 | 16.37 | 2024-07-30 |
| 14 | `ESTOCKHISTORY` | 13 | 1.95 | 2024-07-30 |
| 15 | `ETIQUETAS` | 17 | 0.14 | 2024-07-30 |
| 16 | `EXACTUS` | 26 | **396.10** | 2024-07-31 |
| 17 | `EXACTUS_SYNC` | 15 | 30.67 | 2024-07-30 |
| 18 | `IMPRESIONES` | 12 | 3.20 | 2024-07-30 |
| 19 | `JAMFOR` | 29 | 0.02 | 2025-07-15 |
| 20 | `Laserfiche_Workflow` | 10 | 11.08 | 2024-07-30 |
| 21 | `OCTOPARSE` | 34 | 0.08 | 2026-01-06 |
| 22 | `PortalClientes` | 24 | 23.59 | 2024-07-30 |
| 23 | `SDERP` | 23 | 29.56 | 2024-07-30 |
| 24 | `Sistema_Alarmas` | 5 | 1.99 | 2024-07-30 |
| 25 | `sistema_logistica` | 30 | 61.58 | 2026-01-06 |
| 26 | `sistema_logistica_qa` | 32 | 15.95 | 2025-12-29 |
| 27 | `Sistema_Proveedores` | 21 | 1.16 | 2024-07-30 |
| 28 | `SistemaLogistica` | 14 | 0.70 | 2024-07-30 |
| 29 | `SSISDB` | 36 | 5.77 | 2026-07-07 |
| 30 | `SyncDBTransportes` | 28 | 0.70 | 2026-05-21 |
| 31 | `TRANSPORTES` | 19 | 8.25 | 2024-07-30 |
| 32 | `Traslados` | 9 | 0.14 | 2024-07-30 |

### Cuatro hechos que salen de la medición

1. **Son 32, no "~35".** La cifra que el contract v1–v3 citaba venía de una estimación.
   Acá está contada.
2. **`COMPRAS` y `COMPRAS_STG` pesan exactamente lo mismo: 107.09 GB**, y la segunda se
   creó el **7-sep-2026**, once días antes de esta medición. Dos bases del mismo tamaño
   al centésimo de GB, una recién creada, es una copia. Deja de ser inferencia por
   tamaño: **es evidencia directa de que acá se clonan bases de producción**.
3. **`CONSTRUPLAZA_EFLOW` son 266.92 GB** y no estaba en el inventario que el contract
   citaba (`EXACTUS`, `BI`, `COMPRAS`). Es la **segunda base más grande** del servidor.
4. **`SSISDB` no es una base de negocio**: es el catálogo de SQL Server Integration
   Services. Su `database_id` es 36, así que el filtro `database_id > 4` **no la
   excluye** y el loop le agregaría el user. Sus tablas `catalog.*` describen paquetes,
   ejecuciones y parámetros de integración. No es un bloqueante, pero incluirla es una
   decisión, no un efecto colateral del filtro.

### Y un detalle de nombres que puede morder

`sistema_logistica` (id 30, 61.58 GB), `sistema_logistica_qa` (id 32) y `SistemaLogistica`
(id 14, 0.70 GB) son **tres bases distintas** cuyos nombres difieren sólo en separador y
capitalización. Cualquier entrada del catálogo que las nombre tiene que usar el nombre
exacto de `sys.databases`, no uno recordado.

---

## Lo que esto le cambia al aprovisionamiento

- **Postgres**: la superficie real son 29 bases, no 2. La Parte 0 de Patrick es la pieza
  que decide si eso es aceptable, y su patrón de "producción" tiene que contemplar que
  `controlactivos_stg` está acá.
- **SQL Server**: las 32 están `ONLINE`, así que hoy el filtro `state = 0` no saltea
  ninguna — el hueco de las bases OFFLINE/RESTORING sigue siendo real a futuro, no ahora.
  Ninguna está en solo lectura, así que el motor no aporta ninguna barrera: se confirma
  que el rol (`db_datareader`) es la única — desde v10 (decisión de Patrick Ocampo,
  `db_denydatawriter` se quitó) literalmente la única, sin una segunda red de `DENY`.
