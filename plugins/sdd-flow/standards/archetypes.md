# Archetypes — la forma del requerimiento

Un endpoint y una migración de datos no se prueban igual, no fallan igual y no arriesgan lo mismo. Hasta acá el pipeline los trataba igual, y la diferencia dependía de que el planner improvisara bien. Este archivo fija **qué exige cada tipo de trabajo**, para que la consistencia no dependa del criterio del momento.

**Regla**: todo requerimiento se clasifica en **exactamente un arquetipo** (decision-closed — se elige en el refinement, el usuario confirma). Si un trabajo parece dos arquetipos ("endpoint + migración"), son **dos requerimientos** con orden de integración declarado, no uno gordo. El arquetipo determina: qué dimensiones del bloque `nfr:` son obligatorias de cerrar, qué tipos de test se exigen, y qué ítems entran al HLTC como ACs.

**Proporcionalidad**: la DoD no se negocia, la ceremonia sí. Trabajo trivial (cambio localizado, sin superficie invocable nueva, sin schema, sin decisión de diseño — el triage `trivial` de `/sdd-fixes`) no necesita este pipeline completo: va por `/sdd-fixes` con su mini-DoD (branch propia + test del cambio + `sdd-run-gates.sh` verde + PR). Forzar la ceremonia completa para un typo entrena al equipo a esquivar el proceso también cuando importa.

Cada checklist es **mínimo obligatorio**, no techo: el planner agrega lo que el caso pida. Ítem no aplicable → `N/A` con razón en el HLTC, nunca omisión silenciosa.

---

## `api-endpoint` — superficie invocable nueva o modificada

- **NFR obligatorias**: `authz` · `volume` (paginación/límites) · `idempotency` (si muta) · `observability`.
- **Tests exigidos**: integration del happy path + los ACs negativos de `security.md` §2 (403/401/IDOR/input hostil) + unit de la lógica de dominio.
- **Checklist → ACs**:
  - Taxonomía de errores completa: cada código que puede devolver, con shape declarado.
  - Paginación/límite si devuelve colecciones (sin "después vemos": límite concreto).
  - Idempotencia declarada si muta (¿retry del cliente duplica el efecto?).
  - Backward compatibility del contrato público, o el breaking change con versión + ADR.
  - Timeout y comportamiento ante dependencia caída (si llama a otro servicio).
  - Si otro agente consume este endpoint: **contract fixtures** ejecutables (ver `sdd-plan` — pares request/response que ambos lados testean).

## `ui-feature` — pantalla, componente o flujo de UI

- **NFR obligatorias**: `observability` (errores de UI se reportan, no se tragan) · `authz` si la vista expone datos por rol.
- **Tests exigidos**: component/unit de la lógica de presentación + e2e **solo** si cambia un flujo de usuario completo.
- **Checklist → ACs**:
  - **Los cuatro estados**: vacío · carga · error · éxito. Cada uno con AC propio — es la causa #1 de UI que "funciona" en demo y se siente inmadura en producción.
  - Validación de formularios con mensajes concretos (no "algo salió mal").
  - Concerns `a11y` y `design` activos (ver `concerns.md`); `seo` si es público.
  - Datos sensibles no viajan a la vista si el rol no los debe ver (filtrar en el server, no con CSS).

## `data-migration` — schema o datos existentes cambian

- **NFR obligatorias**: `migration` (plan completo) · `volume` (cuántas filas/documentos) · `idempotency` · `observability` (progreso y conteos logueados).
- **Tests exigidos**: test de la migración sobre dataset representativo (fixture con los casos raros conocidos: nulls, duplicados, encodings) + test del rollback.
- **Checklist → ACs**:
  - **Dry-run obligatorio**: modo que reporta qué haría sin escribir.
  - **Conteo antes/después** verificable (filas afectadas esperadas vs reales; divergencia = abortar).
  - **Idempotente**: correrla dos veces no corrompe (o lockea y lo dice).
  - **Rollback ejecutable** (script o plan concreto, no "restauramos backup" sin haberlo probado).
  - Compatibilidad durante el deploy: ¿el código viejo convive con el schema nuevo el rato que dura el rollout? (expand/contract si no).
  - Ventana y orden declarados si bloquea tablas.

## `background-job` — cron, worker, consumer de cola

- **NFR obligatorias**: `idempotency` (los jobs SIEMPRE se re-ejecutan) · `observability` (cómo sé que corrió, cuánto tardó, qué procesó) · `volume` · `rollout`.
- **Tests exigidos**: unit de la lógica + test de re-entrega/re-ejecución (el mismo mensaje dos veces) + test del path de veneno (mensaje malformado no tumba el worker).
- **Checklist → ACs**:
  - Idempotencia real: procesar el mismo ítem dos veces = un solo efecto.
  - Manejo de veneno: ítem imposible de procesar → dead-letter/skip logueado, el job sigue.
  - Timeout y reintentos con backoff declarados (números, no "razonable").
  - Solapamiento: ¿qué pasa si la corrida anterior no terminó? (lock, skip o paralelo seguro — decidido).
  - Alarma de silencio: cómo se detecta que el job dejó de correr (no solo que falló).

## `third-party-integration` — servicio externo nuevo

- **NFR obligatorias**: `authz` (credenciales: dónde viven, cómo rotan) · `observability` · `rollout` (feature flag o kill switch).
- **Tests exigidos**: unit contra el cliente mockeado + contract test del shape esperado de la API externa + test de cada modo de falla declarado.
- **Checklist → ACs**:
  - Modos de falla del tercero cerrados: timeout, 5xx, rate limit, respuesta malformada — comportamiento propio declarado para cada uno (retry/circuit/fallback/error al usuario).
  - Kill switch: se puede apagar la integración sin deploy.
  - Credenciales por secret store del repo, nunca en código ni config commiteada.
  - Datos que se le mandan al tercero listados (activa `data-privacy` si hay PII).
  - Sandbox/mock para desarrollo declarado (los devs no pegan a producción del tercero).

## `bugfix` — comportamiento existente está mal

- **NFR obligatorias**: ninguna adicional (hereda las del área tocada).
- **Tests exigidos**: **el test que reproduce el bug, escrito ANTES del fix, con la corrida roja registrada** (`quality-gates.md` §5) + regresión del impact set.
- **Checklist → ACs**:
  - Causa raíz identificada y escrita en el contract (no "se arregló": qué estaba mal y por qué).
  - Búsqueda de hermanos: ¿el mismo patrón roto existe en otro lado? (grep documentado; hermanos encontrados → deuda o scope).
  - El fix no cambia comportamiento no relacionado (diff mínimo).

## `refactor` — cambia la forma, no el comportamiento

- **NFR obligatorias**: ninguna nueva — la invariante ES el NFR.
- **Tests exigidos**: la suite existente del área, verde **antes y después** (misma suite, cero tests modificados — tocar un test en un refactor es señal de que no era un refactor).
- **Checklist → ACs**:
  - Invariante declarada: "cero cambios de comportamiento observable" como AC verificable con la suite previa.
  - Si el área a refactorizar no tiene tests → **primero** se escriben tests de caracterización del comportamiento actual (es scope del refactor, no opcional).
  - Métrica de mejora declarada (qué mejora: acoplamiento, duplicación, líneas, dependencia cíclica — algo medible, no "queda más limpio").
  - Sin features ni fixes de contrabando: bug encontrado durante el refactor → se registra, no se arregla en el mismo diff.

## `project-scaffold` — el repo todavía no puede sostener calidad

El caso greenfield tiene una trampa: la escalera de gates nace toda `N/A` (no hay runner, ni lint, ni CI) — el sistema de calidad está apagado justo cuando se funda el proyecto. Por eso, **en un repo sin escalera funcional, la primera task de cualquier `/sdd` es SIEMPRE `project-scaffold`**, antes del primer requerimiento funcional. No es opcional ni se mezcla con la feature: es su prerequisito.

- **NFR obligatorias**: ninguna funcional — el scaffold ES la infraestructura.
- **Tests exigidos**: **un primer test real que pasa** (no un placeholder `expect(true)`): un test de humo del entry point o de la primera unidad de dominio.
- **Checklist → ACs**:
  - Layout de carpetas según `doc_architecture.md` (que `/sdd-init` acaba de generar/entrevistar).
  - Runner de tests instalado y corriendo (el comando exacto queda en `doc_quality_gates.md`, verificado, no supuesto).
  - Lint + formatter + type-check configurados según el perfil del stack (`quality-gates.md` §9), con el primer pase verde.
  - `doc_quality_gates.md` **re-verificado contra la realidad**: cada comando declarado corre (el runner `sdd-run-gates.sh` termina sin gates `[SKIPPED]` por comando inexistente).
  - Scripts del plugin copiados a `SDD/scripts/` y `.sdd/` en `.gitignore`.
  - CI mínimo si hay remote (la escalera, mismos comandos — paridad desde el día cero).
  - Si hay UI: design tokens / librería base elegida **como ADR** (el concern `design` de todo lo que siga referencia esa decisión).
- Al terminar, la escalera está viva: el primer requerimiento funcional ya corre con gates de verdad.

## `infra` — CI, deploy, config de plataforma, tooling

- **NFR obligatorias**: `rollout` (cómo se prueba sin romper a todos, cómo se revierte) · `observability`.
- **Tests exigidos**: verificación ejecutable del cambio (el pipeline corre, el deploy dry-run pasa) — "debería funcionar" no es evidencia.
- **Checklist → ACs**:
  - Reversible: el cambio se puede deshacer con un revert (o el plan de vuelta está escrito).
  - Sin secretos nuevos en texto plano; los que se muevan, rotados.
  - Efecto sobre los devs declarado (¿cambia el comando local? → `doc_quality_gates.md` actualizado).
  - Cambio probado en entorno no productivo primero, con evidencia.

## `analysis` — el entregable es una conclusión o una cifra que alimenta una decisión

Cubre el trabajo cuyo entregable es una conclusión o una cifra que alimenta una decisión, con producto en documentos o notebooks en vez de código de aplicación: un backtest, un barrido, una estimación. No falla como falla el código: un análisis roto no tira una excepción, produce un número con cara de dato que cambia una decisión de producto. Por eso el checklist es el del método, no el del runtime.

- **NFR obligatorias**: `observability` (la corrida que produce la cifra es reproducible por otro) · `data-privacy` cuando el dataset tiene PII.
- **Tests exigidos**: el test estadístico que **falsaría** la conclusión, corrido y reportado con su valor; más la re-derivación de cada cifra citada desde su fuente.
- **Checklist → ACs**:
  - Hipótesis nula declarada antes de mirar el resultado.
  - El test que falsaría la conclusión, nombrado y corrido; su resultado se reporta gane o pierda.
  - Toda cifra re-derivada desde la fuente, con la salida de la consulta adjunta (`quality-gates.md` §5).
  - Sensibilidad declarada: qué pasa con la conclusión al excluir las filas defectuosas, y si las exclusiones se concentran en pocas unidades.
  - Unidad de análisis y unidad de agrupamiento declaradas, con el número de grupos. Cuando las observaciones se agrupan, la inferencia se hace a nivel del grupo, y el reporte nombra la técnica usada.
  - Tamaño de muestra (filas y grupos) y tamaño de efecto mínimo detectable declarados, con el número: contra qué efecto, a qué α y a qué potencia. La potencia calculada con el efecto observado no cuenta.
  - La conclusión se escribe con su incertidumbre, no como afirmación categórica.

**Por qué los ítems de agrupamiento y de potencia están escritos así** (no es estilo, es el defecto que ya cometieron): la primera redacción de este arquetipo pedía "unidad de análisis declarada, y el test a esa unidad" y "potencia declarada, con el número", y las dos eran **satisfacibles cometiendo el error que previenen**. Declarar "la unidad de análisis es la fila" cumplía la primera corriendo el test al nivel equivocado — que es el error que motivó el ítem —, porque nada obligaba a que la unidad declarada fuera aquella en la que las observaciones son independientes. Y la potencia calculada con el efecto observado es una transformación monótona del p-valor: declararla repite lo que el p-valor ya dijo. El tamaño de efecto mínimo detectable es lo único que separa "no hay efecto" de "no hay datos", que es la distinción por la que se pidió el análisis.

---

## Criterio de brief trivial (asignación de `haiku`)

Un brief es **trivial** cuando cumple **las cuatro** condiciones. Si falla una, no es trivial.
La duda resuelve a no-trivial.

| # | Condición |
|---|---|
| 1 | Toca **≤2 archivos de fuente o test** (no cuenta el verification report ni evidencia — todo brief los escribe, así que contarlos haría que ningún brief fuera nunca trivial) |
| 2 | **No agrega dependencias** |
| 3 | Su arquetipo es `refactor` o `infra` |
| 4 | **Ninguno de sus ACs es de detección** (`quality-gates.md` §10.1) |

La cuarta es la que más filtra, y a propósito: un AC de detección exige el triple de mutación,
que es donde un modelo barato falla caro — no por no saber aplicar la mutación, sino por no
notar que las tres corridas salieron iguales (`SDD/retro.md` RT11).

**`bugfix` no entra en la condición 3, a propósito** (corregido tras revisión externa, GEN-101):
`quality-gates.md` §4 exige que la evidencia de un bugfix sea el par rojo→verde de su test de
reproducción — el mismo modo de falla que la condición 4 existe para evitar (no notar que dos
corridas no se distinguen). Admitir `bugfix` como trivial mientras la condición 4 lo excluye por
la misma razón habría dejado el criterio tirando en dos direcciones para ese arquetipo.

Este criterio existe porque «`haiku` si trivial» sin definición no se usó nunca: en el ciclo
GEN-94 los seis agentes fueron `sonnet`×4 y `opus`×2, `haiku`×0. Un default sin criterio es un
default que nadie ejerce.

## Cómo lo usa el pipeline

1. **`enrich-user-story`** pregunta/confirma el arquetipo (dimensión obligatoria) y cierra las NFR que el arquetipo exige — bloque `nfr:` en el requerimiento.
2. **`sdd-plan`** inyecta el checklist del arquetipo como ACs del HLTC (o `N/A` con razón, ítem por ítem) y exige los tipos de test declarados acá en el binding.
3. **`reviewer-agent`** verifica el checklist del arquetipo como parte de la Fase 2 — un ítem del checklist sin AC ni `N/A` razonado es hallazgo `MAJOR` de contract.
