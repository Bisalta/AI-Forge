# HLTC — Plugin `bisalta-db`: consulta de solo lectura sin credencial en contexto

- **Versión**: v15

### Cambios v14 → v15 (primera corrida contra el motor real, 22-sep-2026)

Patrick Ocampo corrió la Parte A y las seis bases del catálogo quedaron legibles. Con eso el plugin consultó por primera vez contra la base de verdad, y la corrida en vivo encontró dos cosas que ningún test del harness podía ver. Ciclo corto de fixes sobre la misma branch, decidido por Ian Vargas.

**1. `AC29` estaba verde en los tests y rojo en la realidad.** `current_setting('application_name')` devolvía `psql`, no el usuario del secreto. Medido una al lado de la otra, con el mismo rol contra la misma base:

| Mecanismo | `application_name` resultante |
|---|---|
| `-c application_name=…` dentro de `PGOPTIONS` — lo que el código hacía | `psql` |
| variable `PGAPPNAME` | el usuario del secreto |
| parámetro `application_name` en el conninfo | el usuario del secreto |

psql fija su propio `application_name` al conectar y le gana al `-c`. El test del harness sustituye `psql` por un stub y verificaba **cómo se armaba el comando**, no **qué efecto tenía**: el comando era el que el AC describía, y el efecto no. Sobrevivió a 17 triples de mutación y a un reviewer adversarial porque ninguno de los dos tenía un motor enfrente. La propiedad de `AC29` **no cambia**; cambia el mecanismo y cambia la verificación, que ahora prohíbe explícitamente la forma que se ve bien y no funciona.

**2. Las garantías de Postgres no son igual de fuertes, y el catálogo las declaraba al mismo nivel.** Patrick midió el peor caso: el rol apaga `default_transaction_read_only` con un `SET` —es un valor por omisión de la sesión, no un candado— y, por el endpoint de escritura, **creaba tablas propias en `public`**, porque en PG 14 ese esquema trae `CREATE` concedido a `PUBLIC`. Ninguna tabla existente quedó expuesta —lo comprobó sobre los 431 objetos de las seis bases— y cerró el hueco ese mismo día, en el mismo orden que se usó con `CONNECT`: primero el `GRANT CREATE ON SCHEMA public` explícito a quien ya lo usaba, recién después el `REVOKE` de `PUBLIC`. Su pedido, textual en sustancia: **que el catálogo no declare las tres garantías al mismo nivel**. La única incondicional es el endpoint `cluster-ro-`, donde el motor rechaza la escritura y no hay `SET` que lo apague. Nace `AC45`.

**3. Una cita a una versión que no existía.** La corrección del punto 3 de "Cambios v10 → v11" afirmaba que el header y los puntos 1 y 5 del brief "se corrigieron recién en v15". No hubo v15 hasta ésta: esa corrección la hizo el commit `2529071` sobre el contract v14, sin bumpear la versión. Reescrita para nombrar el commit.

**Derivados de lo que midió Patrick, registrados y sin AC propio:** `claude_lectura` ve **0 filas en `cron.job`** — la RLS de pg_cron aguanta contra `pg_read_all_data` porque el rol es `NOBYPASSRLS`, así que ningún comando de cron queda a la vista. La base `postgres` sigue fuera del alcance: `cron.job_run_details` tiene `DELETE` concedido a `PUBLIC` por diseño de pg_cron, y además se le revocó el `CONNECT` explícito que le había quedado. Y la deuda de propiedad de `D42` creció: el `CREATE` explícito sobre `public` en `proveedores_dev` y `proveedores_qa` quedó nombrado a `ian.vargas`, dueño de esas bases, así que el día que la propiedad pase a un rol de servicio hay que mover **dos** cosas, no una.

### Cambios v13 → v14 (enmienda del planner, 22-sep-2026)

**Defecto del contract, levantado por `AGENT_r1` como `contract-change-request` en vez de trabajarlo alrededor — que es exactamente lo que el protocolo pide.** v13 decidió el rol único y **no reconcilió los ACs que lo verifican**:

- `AC1` seguía exigiendo que *"existen los roles `claude_lectura` **y `neo_lectura`**"* — un resultado que el diseño de v13 ya no puede producir. Quien ejecutara el procedimiento obtendría rojo sobre una propiedad que el contract mismo derogó.
- `AC29` justificaba el `application_name` con *"para que `pg_stat_activity` distinga `claude_lectura` de `neo_lectura`"*. La propiedad que el AC afirma sigue en pie; la **razón** ya no.

**Es la tercera vez en este ciclo que ocurre lo mismo**: `v6 → v7` terminó en `ESCALATE` por esto, `RT30` lo registró con el mecanismo propuesto, `RT36` lo registró **otra vez** como reincidencia — y v13 volvió a caer. La regla está escrita dos veces en este mismo contract y no bastó ni para quien la escribió. Lo que falta no es más prosa: es el bloque `acs-afectados:` que `sdd-lint-contract.sh` debería exigir por sección de cambios.

### Cambios v12 → v13 (decisiones de Patrick Ocampo, Slack 22-sep-2026 11:27)

**1. `neo_lectura` sale. Un solo rol: `claude_lectura`.** Cierra el punto 3 de `D51`, y con un dato que invalida el supuesto anterior: **NEO no abre ninguna conexión Postgres** — ni hoy ni en el diseño de NEO QA, que dice explícito *"sin SQL ni Odoo al arrancar"*. Lee Odoo stg **por XML-RPC**, contra la aplicación y no contra la base. Y corrige su propio supuesto: NEO **no corre en la cuenta de dev** sino en la de producción, con su stack y su rol de instancia. Si algún día usara Postgres sería contra `erp-costruplaza-db`, nunca contra `sistemas-costruplaza-db` — ninguna de las 28.

**Lo que se resigna, escrito porque él lo escribió**: `pg_stat_activity` no va a distinguir consumidores el día que haya más de uno. Hoy el único es Ian Vargas, así que no distingue nada que exista. Cuando haga falta, se agrega el rol a la lista de la Parte A y se vuelve a correr — el script es idempotente. Y su razón para sacarlo ahora: *"un rol sin consumidor es una clave que rotar, una cuenta que olvidar, y sobre todo una pista falsa de que los dos mundos están conectados."*

Esto **revierte la decisión de dos roles** que venía del refinement del 18-sep. La razón de aquella —que `pg_stat_activity` distinguiera quién corrió qué— sigue siendo buena; lo que cambió es que se midió que el segundo consumidor no existe.

**2. La política IAM va sobre un patrón, no sobre ARNs exactos.** `dev/bd/claude-lectura-*`, de modo que el secreto de SQL Server queda cubierto sin escribir una política nueva. El patrón se lo copió al stack de NEO, que autoriza sobre `${Environment}/neo/accesos-lectura-*`. Consecuencia para este contract: **agregar un motor no obliga a tocar IAM**, sólo a crear el secreto con un nombre que caiga bajo el patrón.

**3. Al script de SQL Server le falta la guarda que Postgres sí tiene.** `postgres-parte-0.sql` aborta si el cluster contiene producción. **El de SQL Server no tiene equivalente — y crea un `login`, que es objeto de instancia.** Nada adentro del script dice contra qué servidor corre: lo único que lo mantiene en Dev SQL es quién escribe la cadena de conexión. Importa porque **hay otro SQL Server en juego**: NEO lee `BD-PRINCIPAL`, que es producción, y el script no sabe distinguirlas. Nace `AC44`.

**4. Para el expediente: el login de Dev SQL NO se unifica con el que NEO usa en `BD-PRINCIPAL`.** Y la razón no es higiene: **un login no existe en dos instancias a la vez**, así que unificarlos obligaría a darle a uno el servidor del otro — y uno de los dos es producción. Queda escrito para que dentro de seis meses nadie lo "ordene" sin saber eso.

### Cambios v11 → v12 (respuestas de Patrick Ocampo, Slack 22-sep-2026 11:14)

**1. Los nombres de los secretos los eligió Patrick**: `dev/bd/claude-lectura-postgres` y `dev/bd/claude-lectura-sqlserver`. Ambiente primero, como los `dev/…` que ya existen en la cuenta, y `bd` como categoría, como los `onpremise/bd/…`. Su razón: *"con eso entra en las dos convenciones que hay en vez de inventar una tercera"* — que es exactamente lo que hacía el nombre inventado por el planner en v1. Propagados a las 12 entradas del catálogo y al runbook. **Él crea los secretos con esos nombres exactos.**

**2. La regla de secretos estaba mal escrita, y el que la corrige es quien la escribió.** Patrick: *"«una conexión, un secreto» no describe lo que yo quería. Doce secretos con la misma contraseña adentro no aíslan nada — sólo multiplican por doce los lugares donde rotar y donde se puede filtrar."* La formulación correcta, que **reemplaza** a la de v10 punto 4 en todo el expediente:

> **Un secreto por credencial, y el aislamiento por política IAM por consumidor.**

Lo que importaba era que Claude y NEO no compartieran secreto, **no** que cada entrada de catálogo tuviera el suyo. Las 12 conexiones sobre 2 secretos cumplen eso. **El catálogo no cambia de forma**; lo que cambia es la regla que dice por qué está bien. `D51` queda cerrada en sus puntos (a) y (b).

**3. `neo_lectura`: sigue abierto, y no se toca el catálogo por eso.** El supuesto de Patrick —que aún no confirma— es que NEO **no entra por este plugin**: corre en su propia EC2 en la misma VPC y leería su secreto con el rol de instancia de esa máquina. Si se confirma, el catálogo está bien sin NEO y no hay nada que agregar. Instrucción textual: *"mientras tanto no toques el catálogo por eso."*

### Cambios v10 → v11 (enmienda del planner, 21-sep-2026)

Tres defectos **del contract**, señalados como `ADVISORY` por el reviewer en la ronda 1 de v10. Ninguno es del implementador.

**1. La decisión central de v10 no tenía AC.** La revocación por enumeración —*"se concede desde una lista explícita, se revoca por enumeración"*— es lo que v10 cambió, y su única cobertura era **incidental**: el verde de cierre de la mutación de `AC7` sería imposible si el inverso leyera sólo `@bases_permitidas`. Eso no es un AC, es un efecto colateral. **Es el mismo defecto que causó el `ESCALATE` de v6 → v7**: cambiar el diseño sin reconciliar los ACs que lo verifican, y la disciplina está escrita dos veces en este mismo contract. Nace `AC43`.

**2. Dos líneas de la sección "Cambios v8 → v9" leen como vigentes** — *"cada base concedida lleva las dos membresías"* — cuando v10 las derogó. Están dentro de un changelog de versión, así que describen lo que era cierto entonces; pero sin marca, alguien que las lea de paso concluye lo contrario de lo que el contract manda hoy. Quedan marcadas.

**3. El brief de R1 seguía fijado en el contract v6** y describía `db_denydatawriter` como vigente en sus puntos 3 y 6. Corregidos **esos dos puntos**; el header y los puntos 1 y 5 quedaron sin tocar y se corrigieron recién en el commit `2529071`, sobre este mismo contract v14 y sin bumpear la versión — la afirmación de esta línea era más amplia de lo que el cambio hizo. (Hasta v15 esta línea decía "recién en v15", una versión que en ese momento no existía.)

Y un defecto de `CHANGELOG.md` que el reviewer clasificó como del agente pero es **prosa del planner**: la entrada `0.1.0` de `bisalta-db` presentaba `db_denydatawriter` como garantía vigente —*"el rol deja de ser la única barrera de ese motor"*—, el inverso exacto de lo que v10 decide. Corregido acá, no en el brief del agente.

### Cambios v9 → v10 (decisiones de Patrick Ocampo, Slack 21-sep-2026 12:22 y 12:44)

**1. Las seis bases de SQL Server están CONCEDIDAS**, con fecha 21-sep-2026 y solicitante Ian Vargas. Registradas en `APROBACIONES.md`.

**2. Sale `db_denydatawriter`. Cada base concedida lleva `db_datareader` y nada más.** Revierte el punto 4 de v4. Es decisión de Patrick, y pidió explícitamente que quedara escrita **con lo que se pierde**, no sólo con lo que queda: *"sin `db_denydatawriter` no queda un `DENY` explícito, así que un `GRANT` de escritura concedido por error en el futuro no tendría nada que lo anule."*
   - La tabla "Garantías por motor" vuelve a **una sola garantía** en SQL Server, y esta vez la afirmación *"el rol es la única barrera"* es cierta y no una omisión.
   - El enum de `garantias` conserva el valor `deny-escritura` —el concepto sigue siendo válido para una conexión futura— pero **ninguna entrada del catálogo lo usa**.
   - **`AC42` cambia de propiedad**: ya no afirma que el `DENY` le gane a un `GRANT`. Redacción y mutación nuevas abajo.

**3. El inverso deja de leer la lista: revoca por enumeración.** Patrick rechazó el procedimiento de baja que R1 documentó —correr el inverso con la lista completa y editarla después— porque *"depende de que alguien recuerde el orden"*. La regla que pone en su lugar:

> **Se concede desde una lista explícita, se revoca por enumeración.**

El inverso recorre `sys.databases` buscando dónde existe el user en `sys.database_principals` y lo saca de donde lo encuentre. Dos direcciones, dos fuentes de verdad: para conceder manda la lista, porque una base que nadie pidió no debe entrar; para revocar hay que encontrar el user **hasta donde nadie lo anotó**. Y cubre el caso que ni el procedimiento de R1 ni el de Patrick alcanzaban: **un user que quedó de antes de que la lista existiera**.

**4. `qa` revocada** (`REVOKE CONNECT ON DATABASE qa FROM PUBLIC`, ejecutado el 21-sep). El cluster `sistemas-costruplaza-db` queda con seis bases cerradas a PUBLIC: `portalrh_dev`, `portalrh_qa`, `construplaza`, `qa`, más `marksync_dev` y `marksync_qa` que ya venían. Las otras 20 siguen abiertas — la deuda `D45` no se cierra, pero se achica.

**5. La pregunta que R1 no pudo contestar tiene respuesta, y es medida.** Patrick verificó que su `REVOKE` del 18-sep **no rompió nada**: el delta de transacciones de tres días dio idéntico en las cuatro bases (96.375), y la serie de `portalrh.log` por día muestra que **las escrituras pararon el 17-sep** — un día antes del revoke, que fue el 18 a las 16:50. Descartó además la hipótesis del fin de semana (los sábados de agosto y septiembre sí tienen filas). Siete días clavados en 36 filas no es gente: es una tarea automática, y el 17-sep es la fecha del pase de Hermes dev → Nexa prod. **`portalrh_dev` y `portalrh_qa` siguen fuera del catálogo igual** — la decisión de v8 no se revierte; lo que cambia es que ahora se sabe que no había nada conectado.

**6. Hallazgo de Platform, no de este ciclo, pero acota una afirmación de este contract.** `sistemas-costruplaza-db` **no exporta logs a CloudWatch** (`EnabledCloudwatchLogsExports` en `null`, sin grupo de logs). Sobre ninguna de sus bases se puede contestar después *"quién se conectó"*. El bloque `observability` de este contract dice que `application_name` permite que `pg_stat_activity` atribuya del lado del motor — eso sigue siendo cierto **en el instante**, pero no queda registro persistente: `pg_stat_activity` sólo ve lo que está corriendo ahora. La bitácora local del servidor MCP es el único registro durable, y es del lado del cliente. Va a Platform (Moreno), no a este ciclo.

### Cambios v8 → v9 (regla de Patrick Ocampo, Slack 21-sep-2026 10:31; lista de Ian Vargas, 21-sep-2026)

**Freno levantado.** Patrick no dio una lista: dio una regla, y es mejor que lo que este contract tenía.

**1. El alcance de Dev SQL arranca en CERO y se agrega a pedido nombrado.** El login no toca ninguna base de negocio hasta que alguien pida una por su nombre. Cuando se pide, **se concede el mismo día y sin aprobación adicional** — sólo queda registrada con fecha y solicitante. Es el **default invertido** respecto de lo que este contract diseñó: el loop de v4–v8 concedía todo salvo las exclusiones, y no podía responder "qué se abrió y por qué". Éste arranca vacío y cada entrada tiene nombre y fecha. Y conserva la extensibilidad que Ian pidió: agregar una base no tiene fricción, sólo deja rastro.

**2. `AC7` y `AC42` cambian de universo.** Dejan de hablar de "todas las bases de usuario en línea salvo `SSISDB`" y pasan a hablar de **la lista explícita del script**. El loop deja de recorrer `sys.databases` filtrando exclusiones y pasa a recorrer una lista declarada. Redacción nueva abajo, con sus mutaciones actualizadas.

**3. Lista inicial (Ian Vargas, 21-sep-2026), verificada contra `INVENTARIO.md`:**

| Motor | Bases | Tamaño |
|---|---|---|
| SQL Server (`Dev SQL`) | `COMPRAS`, `COMPRAS_STG`, `Ecommerce`, `Ecommerce_qa`, `EXACTUS`, `BI` | **861.12 GB de 1383.16 — 62% del servidor** |
| Postgres (`sistemas-costruplaza-db`) | `proveedores_dev`, `proveedores_qa`, `smartcheck_dev`, `smartcheck_qa`, `smartfleet_dev`, `smartfleet_qa` | 6 de 29 |

**4. Asimetría de lo que la lista significa en cada motor — se declara, no se disimula.**

- En **SQL Server** la lista es real a nivel de permiso: `db_datareader` y `db_denydatawriter` son por base, así que **6 nombradas = 6 concedidas, 26 intactas**.
- En **Postgres NO**. `pg_read_all_data` es membresía de cluster: nombrar 6 bases en el catálogo **no restringe al rol a esas 6**. El rol alcanza toda base del cluster donde `CONNECT` siga concedido a PUBLIC — hoy **26 de las 29** (Patrick revocó `CONNECT` en `portalrh_dev`, `portalrh_qa` y `construplaza`). La lista de 6 es **catálogo, no permiso**: define qué consulta el MCP, no qué puede leer el rol.

Cerrarla de verdad exigiría una de dos cosas, y ninguna se toma en este ciclo: `REVOKE CONNECT … FROM PUBLIC` sobre las 20 restantes (afecta a todos los roles del cluster y exige verificar antes que ninguna app dependa de ese `CONNECT`), o cambiar ese cluster a `GRANT SELECT` por base — que revierte la decisión razonada de Patrick para `sistemas-costruplaza-db`, donde `pg_read_all_data` gana porque es un lugar de trabajo. **Queda como deuda con dueño nombrado, no como propiedad del sistema.**

**5. La aprobación de Dev SQL se reemplaza entera** por el texto del 21-sep-2026, que anula el del 18-sep. El anterior omitía `CONSTRUPLAZA_EFLOW` y además **declaraba un alcance más amplio del que va a existir**. El nuevo lleva siete puntos y una tabla `BASES CONCEDIDAS` con fecha y solicitante, más fecha de revisión al cierre del corte (17-oct-2026).

**6. Sin cambios**: `SSISDB` fuera de forma permanente, más `master`, `model`, `msdb` y `tempdb`. ~~Cada base concedida lleva las dos membresías.~~ **Derogado en v10**: lleva `db_datareader` y nada más. La credencial la genera y la carga Patrick.

### Cambios v7 → v8 (mediciones de Patrick Ocampo, Slack 18-sep-2026 16:58 y 17:15; decisiones de Ian Vargas 21-sep-2026)

Patrick midió **adentro** de las bases y corrió la Parte 0 sobre un segundo cluster. Lo que salió invalida una premisa estructural de este contract y dos heurísticas que usamos para evaluar riesgo.

**1. `cfrl3owqzwof` NO es un cluster: es el sufijo DNS de la cuenta de AWS.** Todos los clusters de esa cuenta lo llevan. Las versiones v1–v7 de este contract, y `INVENTARIO.md`, lo trataron como identificador de cluster. En la cuenta de dev hay **cuatro** Aurora PostgreSQL: `dev-costruplaza-db` (14.20, sin medir), `erp-costruplaza-db` (14.20, el Odoo de stg), `erpodoo-19-dev` (17.9, **con IP pública**) y `sistemas-costruplaza-db` (14.20, de donde salieron las 29 bases). Como los roles son objetos **de cluster**, "lectura en todas las BD de la cuenta" son **cuatro decisiones, no una**.

**2. Lo mismo del lado de producción, y eso debilita una garantía que este contract declaraba.** `cr4rbgr7qlr6` también es sufijo de cuenta: las 12 bases medidas son de `sistemas-construplaza-db` específicamente, y **puede haber más clusters en esa cuenta que nadie enumeró**. El out-of-scope de v1 decía "el cluster `cluster-cr4rbgr7qlr6`" como si fuera uno solo. Se corrige: **el out-of-scope es la cuenta entera de producción, y su contenido no está enumerado.**

**3. Una letra separa dev de producción.** Dev es `sistemas-co`**`s`**`truplaza-db`; prod es `sistemas-co`**`ns`**`truplaza-db`. Queda escrito acá porque ningún mecanismo de este plugin lo detecta: el catálogo declara hosts completos y el validador no compara nombres parecidos.

**4. Ni el tamaño ni el nombre clasifican el riesgo de una base.** Medido por Patrick adentro de `sistemas-costruplaza-db`: `portalrh_qa` tiene **3.458 empleados, 3.309 contratos, 29.848 marcas diarias y 400 nóminas históricas**, con columnas `cedulaCcss`, `identificacion` y `salarioActual/Maximo/Minimo` — **en 55 MB**. `qa` tiene **212.020 clientes** con `cedula`, `salario_anterior` y `salario_nuevo`. `construplaza` tiene 975 empleados y 31 solicitantes con documentos. Y `rrhh` —la que este contract señaló por el nombre— está **vacía**. Las dos heurísticas que v4 usó para marcar riesgo fallaron, cada una en su dirección.

**5. Dos estrategias de aprovisionamiento, no una.** `pg_read_all_data` gana donde el cluster es un **lugar de trabajo** (`sistemas-costruplaza-db`: bases operativas, y el problema real era mantener `ALTER DEFAULT PRIVILEGES`). El `GRANT SELECT` por base gana donde el cluster es un **archivo**: `erp-costruplaza-db` tiene 34 bases, dieciséis de ellas clones fechados de Odoo que nadie borró (~115 GB de fotos de noviembre a agosto), con medio millón de contactos con cédula repetidos en tres fotos distintas. Decisión de Patrick para ese cluster: **sólo `stg_20260828`, con `GRANT SELECT` explícito y sin la membresía**. Sin la membresía el rol igual se conecta a las otras 33 por el `CONNECT` de PUBLIC, pero **no ve una fila** — sólo catálogos.

**6. `AC41` es un freno, no un clasificador.** La Parte 0 abortó en `erp-costruplaza-db` por tres bases con "producción" en el nombre, que resultaron ser **las tres más chicas del cluster** (72, 67 y 9 MB), mientras las que de verdad pesan no dicen "prod" en ninguna parte. Textual de Patrick: *"acertó en detenerse y erró de objetivo: filtra por nombre, y ahí el nombre miente en las dos direcciones."* `AC41` no cambia de condición — cambia lo que el contract afirma sobre ella: **detiene, no decide**. Ningún artefacto de este plugin puede decir "el cluster no tiene producción" a partir de esa guarda.

**7. `portalrh_dev` y `portalrh_qa` quedan FUERA del alcance** (decisión de Ian Vargas, 21-sep-2026). Patrick preguntó si algo se conecta a ellas con un rol distinto de `rh` —lo único que su `REVOKE CONNECT` podría haber roto— e Ian no lo sabe. En vez de responder por inferencia, se quita la dependencia: esas dos bases no entran al catálogo. `construplaza` ya está cerrada por el mismo `REVOKE`. `qa` sigue siendo decisión abierta de Patrick.

**8. Propiedad de `proveedores_dev` y `proveedores_qa`: deuda aceptada, diferida.** Las dos tienen como dueño la cuenta personal `ian.vargas`; si esa cuenta se rota o se va, las tablas quedan huérfanas — el mismo problema del `ALTER DEFAULT PRIVILEGES FOR ROLE`. Decisión de Ian: se acepta y se resuelve después; un superadmin puede mover el propietario. No bloquea este ciclo. Registrado en `SDD/debt.md`.

### Alcance vigente tras v8

| Cluster | Estrategia | Estado |
|---|---|---|
| `sistemas-costruplaza-db` (dev/qa) | `pg_read_all_data` | **menos** `portalrh_dev`, `portalrh_qa` y `construplaza`. `qa`: decisión abierta de Patrick |
| `erp-costruplaza-db` | `GRANT SELECT` por base | sólo `stg_20260828` |
| `dev-costruplaza-db` | sin definir | **sin medir** |
| `erpodoo-19-dev` | sin definir | **sin medir** — tiene IP pública |
| Cuenta de producción entera | ninguna | fuera de alcance, **y sin enumerar** |

### Cambios v6 → v7 (resolución de `ESCALATE`, 18-sep-2026)

`AGENT_r1` agotó el cap de tres rondas sobre el alcance reabierto y el reviewer emitió `ESCALATE` — **no por un defecto del implementador, sino del contract**. El v6 decidió sacar `SSISDB` del loop y **no reconcilió los dos ACs que ese loop verifica**: `AC7` seguía diciendo "todas las bases de usuario en línea" y `AC42` "cada base de usuario en línea". `SSISDB` **es** una base de usuario en línea (`database_id = 36`, `state = 0`), así que el procedimiento entregado assertaba la negación de la letra de su propio AC: quien lo ejecutara leyendo el contract lo marcaba rojo, leyendo el runbook lo marcaba verde.

Es la disciplina que este mismo contract fija dos veces —en "Cambios v3 → v4" punto 1 ("sin AC no se prueban") y en v4 punto 9, donde se nombró explícitamente qué AC tocaba el cambio— y que v6 no aplicó a su propia decisión.

**Resolución**: enmienda del planner, sin ronda nueva de implementación. `AC7` y `AC42` acotan su universo a "todas las bases de usuario en línea **salvo `SSISDB`**", y la redacción se propaga al runbook y al brief. El BLOCKER y los cuatro MAJOR de la ronda 4 quedaron cerrados y verificados uno por uno por el reviewer en la ronda 5.

### Cambios v5 → v6 (respuestas de Patrick Ocampo, Slack 2026-09-18 15:52 CST)

1. **`SSISDB` queda FUERA del loop de SQL Server.** Decisión de Patrick, con una razón más fuerte que la que este contract tenía: *"guarda los proyectos desplegados con sus parámetros y connection managers, o sea que es un lugar donde viven cadenas de conexión, más los logs de ejecución. Cero dato de negocio y sí credenciales."* Un servidor MCP cuyo propósito es que ninguna credencial pase por el contexto no puede alcanzar el lugar donde viven las cadenas de conexión. El loop la excluye por nombre, además del filtro `database_id > 4` que no la agarra (su id es 36).
2. **El aprovisionamiento de Postgres lo provee Patrick** — vuelve la decisión de v4, revertida en v5. Su Parte 0 **ya existe** y su condición es `datname ILIKE '%prod%'`, equivalente a la que este contract cerró en v4. Textual: *"No escribas el de Postgres de nuevo. El de SQL Server sí, ese no existe."* **Su `.sql` todavía no llegó**, así que `postgres-parte-0.sql` de R1 se mantiene en el árbol como implementación de referencia hasta que llegue el suyo, y entonces se compara y se reemplaza. El hallazgo `MAJOR 2` de la ronda 4 (la medición del PASO 1 no discrimina) se corrige igual sobre el nuestro: vale para los dos scripts.
3. **La aprobación de Dev SQL se reemplaza entera cuando Patrick mande el texto corregido**, no se parchea. Textual: *"Hoy hay en el expediente una aprobación con fecha que declara menos de lo que autoriza, y eso es peor que no tenerla… lo reemplazás entero, no le agregues una línea al pie."* Pendiente de que lo envíe.
4. **La política IAM lleva regla propia.** ~~*"Una conexión, un secreto, un consumidor — nada de un secreto compartido."*~~ **Reformulada por su autor en v12**, porque la primera redacción no describía lo que quería: **un secreto por credencial, y el aislamiento por política IAM por consumidor**. Doce secretos con la misma contraseña adentro no aíslan nada — multiplican por doce los lugares donde rotar y donde se puede filtrar.
5. **Dev/qa no es homogéneo, y son seis bases sensibles, no dos.** A `rrhh` y `bisalta` se suman `construplaza`, `qa` y —lo que ninguna de las dos partes había visto— **`portalrh_dev` y `portalrh_qa`, el portal de RRHH**.
6. **No hay forma de dar un subconjunto con `pg_read_all_data`.** Conectarse es leer todo y `CONNECT` lo concede PUBLIC por omisión, así que el rol llega a las 29 aunque los `GRANT` por base se corran sólo en algunas. Los dos caminos, y Patrick no ve un tercero: (a) las 29, `rrhh` incluida, asumido explícito como se hizo con Dev SQL; (b) un subconjunto, que obliga a `REVOKE CONNECT ON DATABASE <cada excluida> FROM PUBLIC`, afecta a todos los roles del cluster y exige verificar antes que ninguna app dependa de ese `CONNECT`. **Decisión abierta de Patrick.**

### FRENO VIGENTE

**El loop de SQL Server no se ejecuta hasta que Patrick defina el alcance** (*"no corras el loop de SQL Server todavía"*). El freno es sobre **ejecutar**, no sobre escribir: los doce ACs de R1 son `manual-only` y su ejecución es posterior a Feature Ready, así que corregir los procedimientos sigue siendo trabajo válido.

El motivo del freno es que la respuesta sobre qué se va a consultar describía **alcance y no uso**. Patrick pide: *"Decime qué vas a consultar esta semana, en concreto — qué base y para qué."* **Es la única pregunta que bloquea el cierre de este ciclo, y sólo la puede contestar Ian Vargas.**

### Cambios v4 → v5 (decisión de Ian Vargas, 18-sep-2026)

**El aprovisionamiento lo escribimos nosotros, los dos motores.** Revierte el punto 3 de v4: los `.sql` de Postgres de R1 **no** se reemplazan por los de Patrick. Razón: descargarlo a él de ese trabajo. Lo que sí se incorpora es todo lo que su medición encontró — la Parte 0, el hallazgo de `pg_read_all_data`, y `db_denydatawriter`.

Con eso, **la frontera de responsabilidad queda cerrada así**:

| Quién | Qué |
|---|---|
| **Este ciclo (R1)** | Escribir los `.sql` de los dos motores, la Parte 0, el loop de SQL Server, el runbook y la verificación de cada AC |
| **Patrick Ocampo** | (a) Correr los scripts — requiere privilegios de administración de cluster y de instancia. (b) **Generar las contraseñas y cargarlas en Secrets Manager**, sin que pasen por Ian ni por una sesión de IA. (c) La política IAM sobre esos secretos. (d) Decidir `SSISDB` dentro o fuera del loop. (e) Ratificar el discriminante de la Parte 0, que es mecanismo suyo y se le está cambiando la condición |
| **Ian Vargas** | Verificar que el cluster de dev/qa tenga `ReaderEndpoint` (`describe-db-clusters`) — cierra la precondición del v3 punto 4 |
| **Esteban Fait o Sebastián** | La aprobación de datos de producción que la política de uso de IA exige. Precondición de **habilitar el plugin al equipo**, no de construirlo |

**ACs nuevos** (los cambios de v4 eran de diseño y no traían cómo verificarse — sin AC no se prueban): `AC41` y `AC42`, abajo.

**El punto (b) es el único que no admite atajo**: si la contraseña viaja de Patrick a Ian para que Ian la cargue, se rompe exactamente la propiedad que este plugin existe para dar. Va de quien la genera al secreto, y de ahí sólo la lee el proceso.

### Cambios v3 → v4 (contract-change-request externo, 18-sep-2026)

Origen: mensaje de **Patrick Ocampo** en Slack (DM con Ian Vargas, 2026-09-18 12:46 CST) más los dos inventarios medidos ese mismo día. Es el primer CCR de este ciclo que no nace de un review: nace de que la persona que iba a ejecutar el aprovisionamiento midió el sistema y encontró un hueco de diseño. **Reabre R1**, que estaba `APPROVED`.

1. **`pg_read_all_data` alcanza TODO el cluster desde que el rol existe.** Postgres concede `CONNECT` a PUBLIC por omisión en toda base, y `pg_read_all_data` es membresía de cluster: nadie tiene que conceder nada. **La Parte B no es una barrera** — para cuando corre, el acceso ya existe. Medido: el rol alcanza **29 bases** en el cluster de dev/qa, no las 2 del catálogo.
2. **Nace una Parte 0**, antes de crear nada: lista las bases del cluster y **aborta si el cluster contiene alguna base `_prod`**. El discriminante **no es el nombre `stg`** — rechazar por nombre es red, no barrera, y está medido que falla en las dos direcciones: `controlactivos_stg` es un clon que vive en dev/qa, y las cinco `_stg` peligrosas son peligrosas por estar en el cluster de producción, no por llamarse así. La Parte 0 imprime además a qué bases llega cada rol de verdad, que es la única forma de ver el `CONNECT` heredado de PUBLIC (en el ACL de la base no se ve).
3. ~~**El aprovisionamiento de Postgres lo provee Patrick.**~~ **Revertido en v5**: los escribimos nosotros, los dos motores. Los hallazgos de Patrick se incorporan igual.
4. **SQL Server SÍ tiene una segunda red: `db_denydatawriter`.** Rol fijo de base que pone `DENY` sobre `INSERT`/`UPDATE`/`DELETE`, y en SQL Server el `DENY` le gana a cualquier `GRANT`. Va junto con `db_datareader` en el mismo loop. La tabla "Garantías por motor" y el enum de `garantias` del catálogo quedan corregidos: `sqlserver` pasa de una garantía a dos.
5. **IAM auth: descartado por ahora.** Clave en Secrets Manager; las genera Patrick. Deja de ser decisión abierta y pasa a mejora anotada.
6. **`ambiente` describe el cluster, no el nombre de la base.** `controlactivos_stg` sobre el cluster de dev/qa es `ambiente: dev`, y eso es cierto: dice dónde vive. Lo que hace irrepresentable a producción no es el sufijo del nombre sino que **ninguna entrada apunte al cluster de producción ni a `Prod SQL`**.
7. **Cifras corregidas contra el inventario medido** (`plugins/bisalta-db/aprovisionamiento/INVENTARIO.md`): Dev SQL tiene **32** bases de usuario, no "~35"; **1383 GB** en total; las 32 `ONLINE` y **ninguna en solo lectura**; y `CONSTRUPLAZA_EFLOW` (266.92 GB) es la segunda más grande y no estaba en el inventario que el contract citaba.
8. **Dialectos: siguen siendo dos.** Redshift y Odoo son el motivo por el que el catálogo es multi-conexión, **no trabajo de este ciclo** (decisión de Ian Vargas, 18-sep-2026). El enum de `dialecto` no cambia. Cuando entre Redshift hará falta un tercer dialecto: habla protocolo Postgres pero no acepta el mismo SQL, así que `postgres` le quedaría mal en alguna dirección.
9. **La aprobación de Dev SQL queda asentada** en `plugins/bisalta-db/aprovisionamiento/APROBACIONES.md`, textual y con su fuente, como Patrick pidió. La segunda aprobación (Esteban Fait o Sebastián, por política de datos de producción) **sigue pendiente** y es precondición de habilitar el plugin al equipo.

**`AGENT_r2` no se reabre**: ninguno de los AC11–AC40 cambia por esto, salvo el enum de `garantias` del catálogo, que se trata como parte del scope reabierto de R1 y se verifica con los tests ya existentes de `AC14`.

### Cambios v2 → v3 (ratificación del planner, 18-sep-2026)

Cuatro puntos que `AGENT_r2` levantó al ejecutar y que el contract no cerraba. Ninguno cambia un AC de R1; los cuatro están medidos, no supuestos.

1. **`AC38(a)` pasa a `N/A — razonado`.** El plugin `bisalta-db` **no trae ningún `.sh`**: su código de producto es Node plano. Medido el 18-sep-2026: bajo `bash`, un patrón sin coincidencias se pasa literal y `shellcheck` sale **2** (`openBinaryFile: does not exist`), así que agregar `plugins/bisalta-db/scripts/*.sh` al glob del gate 2 lo **pone en rojo permanente**. Sus tres archivos de test sí son bash y ya entran por `SDD/tests/*.sh`. Cuando ese plugin agregue un `.sh`, el glob se amplía en el mismo cambio. Queda escrito en `SDD/docs/doc_quality_gates.md`, gate 2. Los puntos (b) y (c) de `AC38` se mantienen y se cumplieron.
2. **La tabla de comportamiento de error suma una fila**: catálogo ilegible o inválido → exit **2**. La tabla de v2 no cubría el caso, y `AGENT_r2` lo trató como error de configuración, que es la clasificación correcta: sin catálogo válido no hay conexión que nombrar, así que no puede ser un error de conexión.
3. **`AC34` se satisface con el harness.** El AC pide que el servidor responda `initialize` y `tools/list` con exactamente las dos herramientas, corriendo sin paquetes instalados — eso corre y pasa. El handshake contra una sesión real de Claude Code **no es `AC34`**: es el riesgo de `protocolVersion` ya declarado en la sección Riesgos, y sigue abierto hasta que alguien instale el plugin. `AC34` no es `manual-only`.
4. **El endpoint de réplica es una precondición nombrada, no un supuesto.** Las dos entradas de Postgres del catálogo usan el endpoint `cluster-ro-`, derivado del de escritura, porque es lo que sostiene la garantía `endpoint-replica-lectura`. No se pudo verificar contra AWS desde esta máquina. **Si ese cluster no tuviera réplica de lectura, se quita la garantía del catálogo — no se cambia el host por el de escritura.** Verificación previa al primer uso, anotada en el README del plugin.

### Cambios v1 → v2 (ratificación del planner, 18-sep-2026)

Defecto encontrado al validar el retorno de `AGENT_r1`: `AC40` y el impact set citaban **"los doce archivos de test preexistentes"**, valor copiado de `SDD/docs/doc_quality_gates.md`, que quedó obsoleto — **hay 14** (`ls SDD/tests/test_*.sh | wc -l`, medido el 18-sep-2026). Es la clase de defecto de `SDD/retro.md` RT20: una cifra citada en prosa que drifta respecto de la realidad que describe. La corrección **no** es escribir 14: es dejar de congelar el número. `AC40` pasa a verificarse por derivación y `AC38` absorbe la corrección del doc.

**`AGENT_r1` sigue válido bajo v2**: ninguno de los AC1–AC10 cambió. No se re-spawnea.
- **Ticket**: GEN-108 (subtareas GEN-108.1 · GEN-108.2)
- **Repo**: `Bisalta/AI-Forge` · **Rama base**: `prod` · **Rama de trabajo**: `feat-GEN-108-mcp-bisalta-db`
- **Capa de integración**: git + remote → PR
- **Estado**: auto-aprobado y logueado (gate humano en Feature Ready)
- **Requerimientos**: R1 (`infra`) · R2 (`third-party-integration`) · **orden de integración R1 → R2**

---

## Objective

Que Claude Code y NEO consulten las bases de Bisalta mandando SQL y recibiendo filas, sin que ninguna credencial entre en el contexto de una sesión. La credencial no desaparece: pasa de un archivo que hoy hay que leerle al modelo a un secreto de AWS que el proceso resuelve y la sesión nunca ve.

## Out of scope

- **Auditoría por consulta.** CloudTrail registra quién obtuvo el secreto, no qué consultó. Responder "quién leyó qué" exige un servicio HTTP intermedio (Lambda + API Gateway + Cognito); evaluado y descartado por desproporcionado para este alcance.
- **La cuenta de AWS de producción entera** (sufijo `cr4rbgr7qlr6` — que es sufijo de CUENTA, no de cluster, corregido en v8; las 12 bases medidas son de `sistemas-construplaza-db`, y la cuenta puede tener más clusters sin enumerar). Ahí viven los doce catálogos medidos el 18-sep-2026, incluidos los cinco pares `_prod`/`_stg` de la empresa. Los roles de Postgres son objetos de cluster: crear un login en cualquier `_stg` es crearlo al lado de producción.
- **`Prod SQL` (`192.168.252.22`)**, en esa misma cuenta.
- **Escritura de cualquier tipo.** Una escritura necesaria se corre a mano en DBeaver, donde una persona ve lo que va a pasar antes de que pase.
- **IAM auth de Aurora.** Hoy `false` en el cluster (verificado con `describe-db-clusters`). Decisión abierta de Patrick Ocampo; si entra, cambia cómo se obtiene la credencial al conectar, no la forma del catálogo.
- **Ejecutar los scripts de R1.** Este ciclo los redacta y los verifica; los corre quien tiene privilegios de administración en cada motor.
- **Rotación de la bitácora local.** El servidor sólo agrega líneas. Registrado en `SDD/debt.md`.
- **Adopción de `postgres-mcp-hardened` (Rust).** Evaluado; queda como plan B si el equipo decide no mantener código propio.

## Público consumidor y compatibilidad

Superficie pública nueva: dos herramientas MCP. No hay consumidor previo, así que no hay compatibilidad hacia atrás que preservar. `api-compat`: `N/A — superficie nueva sin consumidores existentes`.

---

## Threat model (`security.md` §1)

1. **¿Quién puede invocarlo?** Cualquier proceso local que tenga el plugin habilitado **y** credenciales AWS con permiso de lectura sobre el secreto de esa conexión. La barrera real es IAM, no el plugin: sin permiso sobre el secreto, la conexión falla aunque la entrada del catálogo esté presente.
2. **¿Qué pasa con el rol equivocado?** Sin permiso IAM sobre el secreto, `consultar` devuelve `{ "error": "secreto_inaccesible" }` nombrando la conexión y el identificador del secreto, **sin volcar la respuesta cruda de AWS** (puede traer el ARN de la identidad llamante). Exit code 5.
3. **¿Qué pasa con input hostil?** El único campo de entrada libre es `sql`. Lo valida la lista blanca del dialecto de la conexión, **antes de conectar**: se quitan comentarios y literales, se parte en sentencias, y cada sentencia debe empezar con `SELECT` o `WITH`. Al rechazar, el error devuelve los primeros 90 caracteres de la sentencia ofensora — nunca el archivo completo, nunca un stack trace. Exit code 4.
4. **¿Qué datos toca y de quién?** Datos de proveedores, empleados y operación de Construplaza. Las conexiones de Postgres son de `dev`/`qa`. Las de SQL Server son **copias de producción** (`EXACTUS` 395 GB, `BI` 177 GB, `COMPRAS` 107 GB): los tamaños no son de desarrollo. No hay acceso por ID de recurso, así que **no hay superficie de IDOR**: la unidad de autorización es la conexión entera, no una fila.

### Riesgo aceptado, con dueño

Las filas que el servidor devuelve **quedan en el transcript de la sesión**. El objetivo del plugin es exactamente devolverlas, así que no hay diseño que lo evite sin negar la función. Ian Vargas eligió explícitamente, en el refinement del 18-sep-2026, que el **tope duro de filas y bytes sea la única barrera**, y descartó la lista de exclusión de columnas por conexión. Queda como riesgo aceptado, no como control:

- La aprobación de Esteban Fait o Sebastián para consultar datos de producción es **precondición nombrada de habilitar el plugin al equipo**, no un acceptance criterion de este contract. Está planteada por escrito a Patrick Ocampo.
- Ambos puntos se registran en `SDD/debt.md`.

## Concerns (`plugins/sdd-flow/standards/concerns.md`)

```
concerns:
  security:      blocking
  observability: blocking
  data-privacy:  blocking
  performance:   advisory   # los 120 s son tope de seguridad, no presupuesto medido
  a11y:          n/a        # sin UI
  design:        n/a        # sin UI
  api-compat:    n/a        # superficie nueva sin consumidores existentes
  i18n:          n/a        # monolingüe
  seo:           n/a        # sin frontend
```

- **security** (blocking): threat model de arriba; ACs negativos AC15–AC25, AC31, AC33, AC35.
- **observability** (blocking): AC30 (bitácora por invocación) y AC29 (`application_name` que distingue el rol del lado del motor). Cómo se detecta que se rompió: toda invocación con exit code distinto de 0 deja su línea en la bitácora con la causa.
- **data-privacy** (blocking): AC25 cierra el ítem de PII y credenciales fuera de logs y mensajes de error; AC26 y AC27 acotan los campos expuestos a lo que la consulta pida, con tope duro. Retención y borrado: `N/A — el plugin no crea datos personales nuevos, sólo lee`. Datos personales hacia terceros: **riesgo aceptado con dueño** (ver arriba), no AC.
- **performance** (advisory): `PERF1` — una consulta que recorre una tabla sin índice sobre `BI` o `EXACTUS` es responsabilidad de quien la escribe; el servidor la corta a los 120 s. El reviewer lo reporta, no lo bloquea.

## Dependencias nuevas (`security.md` §4)

**Ninguna dependencia de paquete.** Es la decisión central del contract.

| Se descartó | Por qué |
|---|---|
| `@modelcontextprotocol/server-postgres` | Deprecado en 2025 y con inyección SQL que se salta su propio modo de solo lectura: pasa el SQL sin parametrizar y permite salir de la transacción read-only para ejecutar DDL/DML con todos los privilegios de la conexión. |
| `@modelcontextprotocol/sdk` + `pg` + `mssql` | Introduce `package.json`, lockfile y árbol de `node_modules` en un repo que hoy no tiene ningún manifiesto de dependencias, y agrega el gate de audit de dependencias. El arranque con `npx -y` baja y ejecuta código de internet con credenciales de base en la mano. |

Binarios externos, invocados como CLI y **no** versionados por este repo: `psql`, `sqlcmd`, `aws`. Medido en la máquina de referencia el 18-sep-2026: `psql` 14.18 y `aws` 2.27.49 presentes, **`sqlcmd` ausente**. Cada uno ausente degrada con mensaje nombrando el binario, igual que `sdd-run-gates.sh` ya hace con `timeout`.

---

## Architectural Delta

| Capa | Delta |
|---|---|
| **API** | Dos herramientas MCP: `consultar(conexion, sql)` y `listar_conexiones()`. Transporte stdio, JSON-RPC 2.0 delimitado por saltos de línea, escrito a mano. Se declara `protocolVersion` `2024-11-05`. |
| **Service** | (NEW) `plugins/bisalta-db/scripts/servidor-mcp.js` — bucle JSON-RPC, despacho de herramientas, armado de la respuesta con topes. |
| **Domain** | (NEW) `plugins/bisalta-db/scripts/lista-blanca.js` — normalización (quitar comentarios y literales), partición en sentencias y validación por dialecto. Es el port de `consulta-lectura.sh` (archivo de OTRO repo: `Bisalta/Proveedores-Back@feat-PROV-131-api-comprassync`, carpeta `scripts/`), con su lección: la comprobación exige la palabra **al principio** de la sentencia, no en cualquier posición. |
| **Repository** | (NEW) `plugins/bisalta-db/scripts/catalogo.js` — lectura y validación de `plugins/bisalta-db/catalogo.json`. `plugins/bisalta-db/scripts/conexion.js` — resolución del secreto vía `aws` y ejecución del cliente CLI del dialecto. |
| **Integration** | AWS Secrets Manager (región `us-east-1`, cuenta de dev/qa) por el binario `aws`. Aurora PostgreSQL por `psql`. SQL Server por `sqlcmd`. |
| **Test impact** | Tres archivos nuevos en `SDD/tests/`: `test_lista_blanca.sh`, `test_catalogo.sh`, `test_servidor_mcp.sh`. Los descubre `SDD/tests/run.sh` por su glob `test_*.sh`; no se toca el runner. |
| **Ownership boundaries** | El producto distribuible vive **sólo** en `plugins/bisalta-db/`. Los tests viven **sólo** en `SDD/tests/` e invocan los scripts por su path completo, desde afuera — es la regla de `doc_architecture.md`, sección Layer Responsibilities. Los scripts SQL de R1 viven en `plugins/bisalta-db/aprovisionamiento/` porque agregar una fuente nueva exige re-correrlos: son parte de lo que se instala, no andamiaje de este repo. |
| **Reuse statement** | Los asserts salen **únicamente** de `SDD/tests/lib.sh`; ningún test define un `assert_*` propio. El patrón de fixture temporal es el de `SDD/tests/test_run_gates.sh`: directorio bajo `SDD/tests/.tmp/<nombre>-$$` con `trap ... EXIT`. El precedente de Node plano probado desde bash es `plugins/usage-monitor/scripts/parse-usage-log.js` con `SDD/tests/test_usage_summary.sh`. |

## Impact set

Símbolos y archivos existentes que se modifican, con sus consumidores grepeados:

| Archivo | Cambio | Consumidores existentes | Cobertura |
|---|---|---|---|
| `.claude-plugin/marketplace.json` | se agrega una quinta entrada `bisalta-db` | Claude Code al resolver `/plugin install`; ningún script del repo lo parsea (grep de `marketplace.json` sobre `plugins/` y `SDD/`: cero coincidencias en código) | AC36 |
| `CHANGELOG.md` | entrada nueva al tope | ninguno automatizado | sin test — es prosa |
| `SDD/docs/doc_quality_gates.md` | se agregan `plugins/bisalta-db/scripts/*.sh` al glob del gate 2 y se corrige el prerequisito de `shellcheck` | `sdd-run-gates.sh` parsea su tabla de gates | AC38 |
| `SDD/docs/doc_architecture.md` | se agrega `plugins/bisalta-db/` al layout y a las reglas de ubicación | lectura humana y de agentes | AC39 |

**No se modifica ningún símbolo ejecutable existente.** Todo el código nuevo es aditivo, en archivos nuevos. Por eso no hay análisis de regresión de callers: la suite existente tiene que seguir verde sin cambios, y eso es AC40. **La cantidad de archivos de esa suite se deriva del árbol, no se cita acá** — una cifra congelada en prosa es exactamente lo que este cambio de versión corrige.

## Source of truth

| Dato | Dueño |
|---|---|
| Qué conexiones existen y qué garantías tiene cada una | `plugins/bisalta-db/catalogo.json` (NEW) |
| El usuario y la contraseña de cada conexión | El secreto de AWS Secrets Manager que la entrada nombra. **Nunca el catálogo, nunca el código, nunca una variable de entorno persistida.** |
| Quién puede usar una conexión | La política IAM sobre el ARN de ese secreto |
| Qué SQL es aceptable | `plugins/bisalta-db/scripts/lista-blanca.js` (NEW), por dialecto |

## Contrato de datos

### `catalogo.json`

Arreglo de objetos. El validador **rechaza cualquier campo no listado acá** y cualquier campo faltante.

| Campo | Presencia | Valores | Comportamiento ante ausencia |
|---|---|---|---|
| `nombre` | requerido | minúsculas, dígitos y guiones; único en el arreglo | el catálogo entero se rechaza |
| `dialecto` | requerido | exactamente `postgres` o `sqlserver` | el catálogo entero se rechaza |
| `ambiente` | requerido | exactamente `dev` o `qa` | el catálogo entero se rechaza |
| `host` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `puerto` | requerido | entero entre 1 y 65535 | el catálogo entero se rechaza |
| `base` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `secret_id` | requerido | identificador o ARN del secreto | el catálogo entero se rechaza |
| `region` | requerido | cadena no vacía | el catálogo entero se rechaza |
| `garantias` | requerido | arreglo de al menos un objeto. Cada objeto lleva `nombre` —exactamente `rol-solo-lectura`, `sesion-read-only`, `endpoint-replica-lectura` o `deny-escritura` (v4)— y `nivel` —exactamente `incondicional` o `condicional` (v15)—. Un objeto con `nivel` = `condicional` lleva además `condicion`, cadena no vacía; uno `incondicional` no la lleva. Ningún otro campo | el catálogo entero se rechaza |

**No existe un campo de usuario ni de contraseña.** Los dos salen del secreto, que tiene la forma estándar de RDS: un campo llamado `username` y otro llamado `password`, ambos en la carga JSON del secreto.

`ambiente` admite dos valores y nada más: producción es irrepresentable en este catálogo, no rechazada por nombre. Rechazar por nombre es red, no barrera.

### Respuesta de `consultar`

```
{
  "conexion": "<nombre>",
  "dialecto": "<postgres|sqlserver>",
  "filas": [ { ... } ],
  "filas_devueltas": <entero>,
  "truncado": <booleano>,
  "motivo_truncado": "<limite_filas|limite_bytes|null>"
}
```

- Tope de filas: **1000**. Tope de bytes de `filas` serializado: **1048576** (1 MiB).
- Al truncar, `filas` trae las primeras filas que caben, `truncado` es `true` y `motivo_truncado` nombra cuál de los dos topes se alcanzó primero. **Truncar no es un error**: la respuesta es exitosa.
- `motivo_truncado` es `null` exactamente cuando `truncado` es `false`.

### Respuesta de `listar_conexiones`

Arreglo con `nombre`, `dialecto`, `ambiente`, `base` y `garantias` de cada entrada. **No incluye `host`, `puerto`, `secret_id` ni `region`**: son superficie de reconocimiento que el consumidor no necesita.

## Comportamiento de error

| Situación | Exit code | Respuesta |
|---|---|---|
| Uso incorrecto (falta `conexion` o `sql`) | 2 | `{ "error": "uso" }` con la firma esperada |
| Nombre de conexión ausente del catálogo | 3 | `{ "error": "conexion_desconocida" }` con la lista de nombres válidos |
| Sentencia rechazada por la lista blanca | 4 | `{ "error": "no_es_lectura" }` con los primeros 90 caracteres de la sentencia ofensora |
| Secreto que no resuelve | 5 | `{ "error": "secreto_inaccesible" }` con nombre de conexión e identificador del secreto, sin la respuesta cruda de AWS |
| Conexión rechazada o caída | 6 | `{ "error": "conexion_fallida" }` con el mensaje del cliente, sin la credencial |
| `statement_timeout` alcanzado (120 s) | 7 | `{ "error": "tiempo_agotado" }` |
| Binario del cliente ausente | 8 | `{ "error": "cliente_ausente" }` nombrando el binario que falta |
| Catálogo ilegible o inválido (v3) | 2 | `{ "error": "catalogo_invalido" }` con el motivo del rechazo. Es error de configuración, no de conexión: sin catálogo válido no hay conexión que nombrar. |

## Garantías por motor (asimetría declarada, no disimulada)

| | Postgres (`dev`/`qa`) | SQL Server (`Dev SQL`) |
|---|---|---|
| Rol de solo lectura | sí — **condicional** (v15): `pg_read_all_data` no escribe, pero un `GRANT` futuro sí puede; en PG 14 `public` traía `CREATE` para `PUBLIC` y el rol creaba tablas propias hasta que se revocó el 22-sep-2026 | sí — **y es la única barrera**, literalmente, desde v10. **Condicional**: se sostiene mientras nadie conceda escritura |
| Sesión abierta en solo lectura | sí, `default_transaction_read_only=on` — **condicional** (v15): es un valor por omisión de la sesión y el rol lo apaga con un `SET`, medido el 22-sep-2026 | **no existe equivalente** |
| `DENY` de escritura sobre el rol | no aplica | **no** — `db_denydatawriter` se quitó en v10 por decisión de Patrick Ocampo. Sin él no hay `DENY` explícito, así que un `GRANT` de escritura concedido por error no tendría nada que lo anule |
| Motor que rechaza escrituras | sí, endpoint `cluster-ro-` de Aurora — **la única incondicional** (v15): la escritura la rechaza el motor y no hay `SET` que lo apague | **no hay réplica** |
| Alcance del permiso | `pg_read_all_data`, de cluster | `db_datareader`, **por base**: una base nueva no queda cubierta sola |

Que esa asimetría esté escrita en `garantias`, entrada por entrada, es lo que evita que alguien asuma que todas las conexiones son igual de seguras. **Medido el 18-sep-2026**: las 32 bases de Dev SQL están `ONLINE` y **ninguna** tiene `is_read_only`, así que del lado del motor no hay ninguna barrera — el rol y el `DENY` son todo lo que hay.

## Entrega de la credencial al cliente

- **Postgres**: archivo temporal en modo 600 creado bajo un directorio de `mkdtemp`, apuntado por `PGPASSFILE`, borrado en un `finally` que corre también cuando la consulta falla. **Prohibido `PGPASSWORD`, `PGUSER`, `PGHOST`, `--username` y `--host`** — es la invariante que los tests de `Proveedores-Back` ya fijaban y que se porta literal.
- **SQL Server**: variable de entorno `SQLCMDPASSWORD` acotada al proceso hijo. `sqlcmd` no tiene equivalente de archivo, y `-P` dejaría la contraseña visible en la tabla de procesos. La asimetría queda escrita acá.
- En los dos casos, la contraseña **nunca** viaja por `argv`.

---

## Acceptance criteria

### R1 — aprovisionamiento (`infra`)

**AC1** — En el cluster de dev/qa existe el rol `claude_lectura` —**y ningún otro rol de lectura creado por estos scripts**— con `LOGIN` y membresía de `pg_read_all_data`, sin `NOINHERIT`; una consulta de lectura sobre una tabla de `proveedores_dev` devuelve filas. (`neo_lectura` salió en v13: NEO no abre ninguna conexión Postgres.)
`manual-only: requiere privilegios de administración en el cluster y red a la VPC de dev/qa; ningún harness de este repo puede crear un rol de Postgres.`

**AC2** — Un `INSERT` ejecutado por `claude_lectura` sobre `proveedores_dev` falla con error de permiso.
`manual-only: misma razón que AC1.`
**Mutación declarada**: otorgar `INSERT` a `claude_lectura` sobre una tabla de scratch creada para la prueba; la comprobación tiene que ponerse roja; revocar el permiso y borrar la tabla de scratch.

**AC3** — El script de la parte A corrido dos veces seguidas sale 0 las dos veces y deja el mismo conjunto de roles.
`manual-only: misma razón que AC1.`

**AC4** — Tras correr el script inverso, `claude_lectura` no puede conectar al cluster.
`manual-only: misma razón que AC1.`

**AC5** — El login de solo lectura de `Dev SQL` lee de `EXACTUS`.
`manual-only: requiere el login creado por el administrador y red a 10.24.40.137.`

**AC6** — Un `INSERT` con ese login falla con error de permiso.
`manual-only: misma razón que AC5.`
**Mutación declarada**: agregar el user a `db_datawriter` en una base de scratch; la comprobación tiene que ponerse roja; quitarlo del rol y borrar la base de scratch.

**AC7** — Tras correr la parte B, el user existe **exactamente en las bases de la lista explícita del script** y en ninguna otra: ni en las bases de usuario que no están en la lista, ni en `SSISDB`, ni en las cuatro de sistema (`master`, `model`, `msdb`, `tempdb`). Con la lista vacía, el script no crea ningún user y sale 0.
`manual-only: misma razón que AC5.`
**Mutación declarada**: reemplazar el recorrido de la lista explícita por un recorrido de `sys.databases` con filtro de exclusión —la forma que el script tenía hasta v8— y volver a correr la parte B contra una instancia de prueba; la comprobación tiene que ponerse roja, porque aparecerían users en bases fuera de la lista; restaurar el recorrido por lista.

**AC8** — Cada conexión del catálogo tiene un secreto en Secrets Manager con los dos campos de la forma estándar de RDS, legible con la política IAM declarada en el runbook.
`manual-only: requiere permisos de escritura en Secrets Manager de la cuenta de dev/qa.`

**AC9** — `bash SDD/tests/secret-scan.sh` sale 0 sobre el árbol con los scripts de R1 agregados.
**Mutación declarada**: insertar en el archivo nuevo `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` un literal con forma de credencial (clave, separador y valor contiguos); el scan tiene que salir distinto de 0 nombrando el archivo y la línea sin imprimir el valor; revertir la línea.

**AC10** — El runbook declara explícitamente que una base nueva de SQL Server no queda cubierta hasta re-correr la parte B.

### R2 — catálogo

**AC11** — Una entrada de catálogo cuyo `ambiente` no es `dev` ni `qa` hace que el validador salga distinto de 0 nombrando la entrada.
**Mutación declarada**: cambiar el `ambiente` de la primera entrada de `catalogo.json` a `stg`; `test_catalogo.sh` tiene que ponerse rojo; restaurar el valor original.

**AC12** — Ninguna entrada del catálogo tiene como `host` algo que contenga `cluster-cr4rbgr7qlr6` ni `192.168.252.22`, y el validador rechaza el catálogo si aparece.
**Mutación declarada**: agregar una entrada con `host` `192.168.252.22`; el validador tiene que salir distinto de 0; borrar la entrada.

**AC13** — El validador rechaza una entrada que traiga un campo no declarado en el contrato de datos.
**Mutación declarada**: agregar un campo `usuario` a una entrada; el validador tiene que salir distinto de 0; borrarlo.

**AC14** — El validador rechaza una entrada con `garantias` vacío.
**Mutación declarada**: vaciar el arreglo `garantias` de una entrada; el validador tiene que salir distinto de 0; restaurarlo.

### R2 — lista blanca

**AC15** — Las diez escrituras simples se rechazan con exit 4: `UPDATE`, `DELETE`, `INSERT`, `TRUNCATE`, `DROP`, `ALTER`, `GRANT`, un bloque `DO`, `CALL` y `COPY`.
**Mutación declarada**: hacer que `validarSql` devuelva siempre aceptado; `test_lista_blanca.sh` tiene que ponerse rojo; revertir.

**AC16** — Las cinco escrituras que llevan una subconsulta adentro se rechazan con exit 4: `DELETE … WHERE id IN (SELECT …)`, `INSERT … SELECT`, `UPDATE … = (SELECT …)`, `CREATE TABLE … AS SELECT` y `CREATE VIEW … WITH (…) AS SELECT`.
**Mutación declarada**: reemplazar el anclaje al principio de la sentencia por una búsqueda de `SELECT` o `WITH` en cualquier posición — la lista blanca laxa que pasaba once de los doce tests originales. `test_lista_blanca.sh` tiene que ponerse rojo en estos cinco casos; revertir el anclaje.

**AC17** — Una escritura detrás de una lectura (`SELECT 1; DELETE FROM …`) se rechaza con exit 4.
**Mutación declarada**: validar únicamente la primera sentencia en vez de todas; `test_lista_blanca.sh` tiene que ponerse rojo; revertir.

**AC18** — Un `UPDATE` que aparece dentro de un comentario, y un `DELETE FROM x` que aparece dentro de un literal de texto, **se aceptan**: el validador sale 0.

**AC19** — Un CTE (`WITH a AS (SELECT 1) SELECT * FROM a`) y tres sentencias de lectura seguidas **se aceptan**: el validador sale 0.

**AC20** — En dialecto `postgres`, una sentencia que contiene una apertura de comilla de dólar se rechaza con exit 4.
**Mutación declarada**: quitar la regla de comilla de dólar del dialecto `postgres`; el caso de `test_lista_blanca.sh` que la cubre tiene que ponerse rojo; revertir.

**AC21** — En dialecto `sqlserver`, se rechazan con exit 4: `EXEC`, `EXECUTE`, un identificador que empieza con `sp_`, uno que empieza con `xp_`, y cualquier `;` que quede tras quitar comentarios y literales.
**Mutación declarada**: quitar las reglas del dialecto `sqlserver` y hacerlo caer en las reglas comunes; los cinco casos tienen que ponerse rojos; revertir.

**AC22** — Dos lecturas encadenadas con `;` **se aceptan** en dialecto `postgres` y **se rechazan** en dialecto `sqlserver`, con la misma entrada.
**Mutación declarada**: hacer que `validarSql` ignore el parámetro de dialecto y aplique siempre las reglas comunes; el caso de sensibilidad tiene que ponerse rojo; revertir.

### R2 — credencial

**AC23** — El código fuente de `plugins/bisalta-db/scripts/` no contiene `PGPASSWORD`, `PGUSER`, `PGHOST`, `--username`, `--host` ni `-P `.
**Mutación declarada**: agregar una línea que exporte `PGPASSWORD` en `conexion.js`; `test_servidor_mcp.sh` tiene que ponerse rojo; borrar la línea.

**AC24** — Tras una consulta que falla al conectar, no queda ningún directorio temporal del servidor bajo el directorio temporal del sistema.
**Mutación declarada**: quitar el `finally` que borra el directorio temporal; `test_servidor_mcp.sh` tiene que ponerse rojo; restaurarlo.

**AC25** — Ni la bitácora, ni la respuesta, ni ningún mensaje de error contienen el valor de la contraseña ni la carga cruda del secreto.
**Mutación declarada**: hacer que la bitácora escriba la carga del secreto; `test_servidor_mcp.sh` tiene que ponerse rojo; revertir.

### R2 — topes, sesión y bitácora

**AC26** — Una consulta cuyo resultado supera las 1000 filas devuelve exactamente 1000, con `truncado` en `true` y `motivo_truncado` en `limite_filas`.

**AC27** — Una consulta cuyo resultado serializado supera 1048576 bytes devuelve las filas que caben, con `truncado` en `true` y `motivo_truncado` en `limite_bytes`.

**AC28** — El comando que el servidor construye para una conexión `postgres` incluye `default_transaction_read_only=on` y `statement_timeout=120000`.

**AC29** — El comando que el servidor construye lleva un `application_name` igual al `username` del secreto, para que `pg_stat_activity` atribuya del lado del motor. **Desde v15 el valor viaja en la variable `PGAPPNAME`, y `PGOPTIONS` no lleva `application_name`**: medido contra el motor real, psql le gana al `-c application_name` de `PGOPTIONS` y la sesión quedaba nombrada `psql`. **Mutaciones declaradas (v15)**: (a) quitar `PGAPPNAME` del entorno del comando pone rojo el assert positivo; (b) devolver `application_name` a `PGOPTIONS` pone rojo el assert negativo — cada una enrojece exactamente uno de los dos. (Hasta v12 la razón era distinguir `claude_lectura` de `neo_lectura`; con el rol único de v13 **ya no distingue consumidores** —`D53`, aceptado— pero la atribución al rol sigue siendo útil y el AC no cambia de propiedad.)

**AC30** — La bitácora escribe una línea JSON por invocación con conexión, dialecto, hash de la consulta, filas devueltas, si truncó, duración y exit code.

### R2 — modos de falla

**AC31** — Un nombre de conexión ausente del catálogo devuelve exit 3 con la lista de nombres válidos, **sin invocar el binario `aws`**.
**Mutación declarada**: mover la comprobación de existencia de la conexión a después de resolver el secreto; el caso que afirma que `aws` no se invocó tiene que ponerse rojo; revertir el orden.

**AC32** — Con el binario del cliente ausente del `PATH`, `consultar` devuelve exit 8 nombrando el binario que falta.

**AC33** — Un secreto que no resuelve devuelve exit 5 nombrando la conexión y el identificador del secreto, y la respuesta **no contiene** la salida cruda del binario `aws`.
**Mutación declarada**: hacer que el mensaje de error concatene la salida cruda de `aws`; el caso tiene que ponerse rojo; revertir.

### R2 — protocolo MCP y empaquetado

**AC34** — El servidor responde `initialize` y luego `tools/list` con exactamente las herramientas `consultar` y `listar_conexiones`, corriendo con `node` sin ningún paquete instalado.

**AC35** — `listar_conexiones` no devuelve `host`, `puerto`, `secret_id` ni `region` en ninguna entrada.
**Mutación declarada**: agregar `host` a la proyección; `test_servidor_mcp.sh` tiene que ponerse rojo; quitarlo.

**AC36** — `.claude-plugin/marketplace.json` lista `bisalta-db` con `source` `./plugins/bisalta-db`, y ese directorio tiene un `.claude-plugin/plugin.json` nuevo con una versión SemVer.

**AC37** — Quitar la entrada de una conexión del catálogo hace que `consultar` sobre ese nombre devuelva exit 3, sin reiniciar el servidor ni tocar código. Es el kill switch local que exige el arquetipo.

**AC38** — `SDD/docs/doc_quality_gates.md` queda consistente con el árbol en tres puntos, cada uno medido y no supuesto: (a) el glob del gate 2 incluye los scripts del plugin nuevo; (b) la cantidad de archivos de test que la sección "Suite completa" declara coincide con `ls SDD/tests/test_*.sh | wc -l`, o la cifra se reemplaza por esa derivación; (c) el tiempo medido de la suite se re-mide y se escribe con su fecha.
**Mutación declarada**: cambiar a `99` la cantidad de archivos de test declarada en el doc; la verificación de (b) tiene que ponerse roja; restaurar el valor correcto.

**AC39** — `SDD/docs/doc_architecture.md` incluye `plugins/bisalta-db/` en el layout y en las reglas de ubicación de archivos.

**AC40** — `bash SDD/tests/run.sh` sale 0 con los tres archivos de test nuevos, y **ningún archivo de test preexistente se modifica**: `git diff --name-only origin/prod..HEAD -- 'SDD/tests/test_*.sh'` lista exactamente los tres nuevos y ninguno más. La cantidad de tests preexistentes **no se cita como constante** en ningún lado: se deriva del árbol.

**AC41** — La Parte 0 corrida contra un cluster que contiene al menos una base cuyo nombre termina en `_prod` **aborta con exit distinto de 0**, sin crear ningún rol; corrida contra un cluster sin ninguna `_prod`, sale 0 y continúa. El discriminante es **lo que el cluster contiene**, nunca el nombre de la base que se quiere consultar.
`manual-only: requiere un cluster Postgres real; ningún harness de este repo levanta uno.`
**Mutación declarada**: cambiar la condición de aborto de `_prod` a `_stg`; corrida contra el cluster de dev/qa (que contiene `controlactivos_stg` y ninguna `_prod`), la Parte 0 tiene que abortar — o sea, la comprobación de que continúa se pone roja; restaurar la condición.

**AC42** — Tras correr la parte B de SQL Server, el user tiene en **cada base de la lista explícita** la membresía `db_datareader` **y ninguna otra**: ni `db_denydatawriter` (quitada en v10), ni `db_datawriter`, ni `db_owner`. Un `INSERT` falla por **ausencia de permiso**, no por `DENY`.
`manual-only: requiere la instancia de Dev SQL; misma razón que AC5.`
**Mutación declarada**: agregar el user a `db_datawriter` en una base de scratch de la lista; el `INSERT` tiene que pasar — o sea, la comprobación de que falla se pone roja. Quitarlo de `db_datawriter`: el `INSERT` vuelve a fallar por ausencia de permiso. **Ojo**: sin `db_denydatawriter` ya no hay `DENY` que anule un `GRANT`, así que esta mutación mide exactamente lo que v10 dejó — que la única capacidad del login es leer.

**AC43** — `sqlserver-inverso.sql` saca a `bisalta_lectura` de **toda base `ONLINE` donde el user exista**, incluidas las que no están en `@bases_permitidas` y las cuatro de sistema, y **no lee `@bases_permitidas` en ningún punto**. Una base que no esté `ONLINE` no se puede tocar: el script lo reporta y el procedimiento declara la consecuencia.
`manual-only: requiere la instancia de Dev SQL; misma razón que AC5.`
**Mutación declarada**: crear a mano el user `bisalta_lectura` en una base de usuario que **no** esté en `@bases_permitidas`, y correr el inverso — tiene que sacarlo de ahí también. Después, reemplazar el cursor del inverso por uno que recorra `@bases_permitidas` (la forma que el script tenía hasta v9): la comprobación tiene que ponerse roja, porque el user sobreviviría en esa base. Restaurar la enumeración.

**AC44** — `sqlserver-parte-a.sql` **aborta si no corre contra la instancia declarada**. Compara `SERVERPROPERTY('MachineName')` contra el nombre esperado de Dev SQL y, si no coincide, emite `RAISERROR` con severidad 16 y activa `SET NOEXEC ON` — o sea que no crea el login. Es el equivalente en SQL Server de lo que `postgres-parte-0.sql` hace para Postgres, y hace falta porque un `login` es objeto **de instancia** y nada más en el script dice contra qué servidor corre.
`manual-only: requiere la instancia de Dev SQL; misma razón que AC5.`
**Precondición del planner**: el valor esperado que Patrick sacó del registro de SSM es `EC2AMAZ-2RGHL0C`, y él mismo pidió que **se confirme midiendo** — `SELECT SERVERPROPERTY('MachineName')` conectado a Dev SQL — antes de fijarlo en el script. Textual: *"si no coincide, el valor manda sobre el mío."* Hasta que se mida, el script lleva el valor de Patrick con la comprobación pendiente anotada.
**Mutación declarada**: cambiar el nombre esperado por el de cualquier otra instancia; correr el script contra Dev SQL tiene que **abortar** sin crear el login — o sea, la comprobación de que crea el login se pone roja. Restaurar el nombre correcto.

**AC45** — Cada garantía del catálogo declara su `nivel`, y `listar_conexiones` lo devuelve. El validador rechaza: una garantía escrita como cadena suelta; un `nivel` fuera de `incondicional`/`condicional`; una garantía `condicional` sin `condicion`; una `incondicional` con `condicion`; un campo desconocido dentro de la garantía. En el catálogo distribuido, **cada conexión Postgres declara exactamente una garantía incondicional y es `endpoint-replica-lectura`**, y **ninguna conexión SQL Server declara una incondicional**. Las dos últimas propiedades se derivan del catálogo real, no de una cifra.
**Mutaciones declaradas**: (a) quitar del validador la regla "una garantía `condicional` exige `condicion`" pone rojos los dos asserts que la verifican; (b) declarar `endpoint-replica-lectura` como `condicional` en una sola entrada de Postgres pone rojo el assert derivado del catálogo.

## Checklist del arquetipo

- `third-party-integration` → **sandbox/mock para desarrollo**: `N/A — las conexiones de Postgres del catálogo son de dev/qa, que ya son el ambiente no productivo. Para SQL Server no hay sandbox posible: Dev SQL es una copia de producción, y decirlo es más honesto que llamarlo sandbox.`
- `third-party-integration` → **rate limit del tercero**: `N/A — un motor de base de datos no aplica rate limit; el control de carga es el statement_timeout y el tope de filas.`
- `infra` → **efecto sobre los devs**: cubierto por AC38.

---

## Estrategia de validación (por escenario)

1. **Lista blanca sin base**: los rechazos y las aceptaciones se afirman por exit code **antes de conectar**, igual que los doce tests de `Proveedores-Back`. Una validación que corriera después ya habría mandado la sentencia.
2. **Catálogo sin base**: el validador corre sobre archivos de fixture en `SDD/tests/.tmp/`.
3. **Protocolo MCP sin base**: se alimenta stdin con las tramas JSON-RPC y se afirma sobre stdout.
4. **Conexión real**: sólo los ACs marcados `manual-only`, cuando R1 esté ejecutado.
5. **Mutación**: los veinte ACs de detección llevan su triple verde → rojo → verde, con comando literal y exit code de cada corrida.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| ~~El `protocolVersion` declarado no es el que Claude Code negocia hoy.~~ | ✅ **CERRADO el 22-sep-2026.** El plugin se instaló desde el marketplace local en una sesión real de Claude Code: cargó, negoció `2024-11-05`, descubrió `consultar` y `listar_conexiones`, y las invocó **sin un solo ajuste**. Es la primera vez que el plugin corre fuera del harness. Verificado en vivo además: `AC35` (la respuesta de `listar_conexiones` no trae `host`, `puerto`, `secret_id` ni `region`), `AC33` (el error de secreto nombra conexión e identificador **sin volcar la salida de `aws`**) y la lista blanca cortando antes de conectar sobre `SELECT 1; DELETE … WHERE id IN (SELECT …)` — el caso que mató a la versión laxa, además escondido detrás de una lectura. |
| El mecanismo exacto por el que un plugin declara un servidor MCP stdio no está verificado en este repo — ningún plugin existente lo hace. | Primera tarea del brief de R2: verificarlo contra la documentación y dejarlo escrito. Si no se puede, queda `BLOCKED` y pregunta. |
| ~~`sqlcmd` ausente en la máquina de referencia…~~ | ✅ **CERRADO el 22-sep-2026**: instalado `sqlcmd` **1.10.0 (go-sqlcmd)** — que **no es** el cliente clásico de ODBC que el runbook asumía. Verificado empíricamente que todo lo que los procedimientos dan por hecho se sostiene: `SQLCMDPASSWORD` **se lee** (sin la variable intenta pedir la clave por teclado; con ella va directo a conectar, así que la invariante de "la contraseña nunca por `argv`" vale); `-b` sale **1** ante error, y sin `-b` la conexión rechazada **también** sale 1; y `-Q`, `-d`, `-E`, `-W` y `-s` existen en su modo de compatibilidad. La ejecución real sigue dependiendo del login que crea Patrick. |
| `shellcheck` ausente: el gate 2 saldría `[SKIPPED]`, nunca verde. | Prerequisito declarado en los dos briefs: instalarlo antes de la primera corrida de gates. |
| La suite tarda ~62 s hoy y los triples de mutación la alargan. | El umbral de `doc_quality_gates.md` se revisa con el número medido al cerrar, igual que en GEN-101. |
| Las filas de copias de producción quedan en el transcript. | Riesgo aceptado con dueño (ver arriba). No hay mitigación técnica en este alcance. |
| ~~El cluster de dev/qa podría no tener réplica de lectura…~~ | ✅ **CERRADO el 22-sep-2026**: `describe-db-clusters` sobre `sistemas-costruplaza-db` devuelve `ReaderEndpoint = sistemas-costruplaza-db.cluster-ro-cfrl3owqzwof.us-east-1.rds.amazonaws.com`, idéntico al host que declaran las seis entradas de Postgres del catálogo. La garantía `endpoint-replica-lectura` se sostiene. (`IAMDatabaseAuthenticationEnabled` sigue en `false`, consistente con la decisión de v4.) |
| ~~**El `secret_id` de las 12 entradas del catálogo no lo acordó nadie.**~~ | ✅ **CERRADO.** (a) y (b) en v12: Patrick eligió `dev/bd/claude-lectura-postgres` y `dev/bd/claude-lectura-sqlserver`, y reformuló su propia regla a *"un secreto por credencial, aislamiento por política IAM por consumidor"*, bajo la cual el esquema de 12 conexiones sobre 2 secretos es correcto. (c) en v13: `neo_lectura` salió del diseño, así que **ningún artefacto manda crearlo**. `D51` figura cerrada en el ledger. |
| Una cifra citada en prosa drifta respecto del árbol que describe — ya pasó en este mismo contract entre v1 y v2. | `AC38` y `AC40` se verifican por derivación del árbol, no contra un número escrito. Registrado en `SDD/retro.md`. |
