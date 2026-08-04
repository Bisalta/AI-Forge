# Evals — golden requirements

El plugin exige tests para todo el código que genera, pero no tenía tests de sí mismo. Este archivo es la suite: **un requerimiento golden por arquetipo** + las propiedades que el output del pipeline DEBE tener. Se corre tras cada cambio del plugin (manual hoy; el resultado alimenta la poda — v1.0 debería ser más chica que v0.10, no más grande).

## Cómo correr un eval

1. En un repo de prueba con `/sdd-init` ya corrido, dale al pipeline el golden: `/sdd "<texto del golden>"`.
2. Contestá el refinement con las respuestas mínimas razonables (o aceptá los defaults propuestos).
3. Contra el contract + briefs producidos, verificá las **propiedades universales** y las **del arquetipo**.
4. Anotá el resultado (pasa/falla + qué propiedad) en la tabla del final. Una propiedad que falla 2 veces seguidas = bug del plugin, no del eval.

## Propiedades universales (todo contract, siempre)

- [ ] U1 `sdd-lint-contract.sh` exit 0 (sin frases abiertas, sin paths alucinados).
- [ ] U2 Tiene `## Acceptance criteria` con IDs `AC1..ACn`, cada uno comportamiento observable.
- [ ] U3 Arquetipo declarado, exactamente uno; el checklist del arquetipo está ítem por ítem (AC o `N/A — razón`).
- [ ] U4 Threat model presente (o su `N/A — no cambia superficie invocable`).
- [ ] U5 Concerns con blocking/advisory declarado; `security` y `observability` nunca `n/a`.
- [ ] U6 Cada brief lleva: tabla AC↔test vacía, tarea de gates con el runner, ruta del verification report, tarea de docs delta.
- [ ] U7 El refinement hizo ≤2 rondas de preguntas (fatigue rules) y presentó defaults inferidos con evidencia.
- [ ] U8 Ninguna dimensión NFR obligatoria del arquetipo quedó sin valor concreto.

## Goldens por arquetipo (con sus propiedades específicas)

| # | Arquetipo | Golden | Propiedades específicas |
|---|---|---|---|
| G1 | `api-endpoint` | "Endpoint para que un cliente autenticado consulte el historial de sus pedidos" | ACs de 403/401/**IDOR** presentes · paginación con límite numérico · taxonomía de errores completa |
| G2 | `ui-feature` | "Pantalla de listado de facturas con filtro por fecha" | ACs de los 4 estados (vacío·carga·error·éxito) · concerns `a11y`+`design` blocking · referencia de diseño nombrada |
| G3 | `data-migration` | "Migrar el campo `phone` de string libre a formato E.164 en la tabla users" | ACs de dry-run · conteo antes/después · idempotencia · rollback ejecutable · convivencia expand/contract |
| G4 | `background-job` | "Job nocturno que sincroniza stock desde el ERP" | ACs de re-ejecución idempotente · ítem veneno · solapamiento · alarma de silencio |
| G5 | `third-party-integration` | "Integrar pasarela de pagos X para cobros con tarjeta" | ACs por modo de falla (timeout/5xx/rate-limit/malformada) · kill switch · datos enviados listados · `data-privacy` blocking |
| G6 | `bugfix` | "El total del carrito ignora el descuento cuando hay más de 10 ítems" | Primera tarea = test de reproducción con corrida roja · causa raíz en el contract · búsqueda de hermanos documentada |
| G7 | `refactor` | "Extraer la lógica de precios duplicada en 3 controllers a un service" | Invariante de comportamiento como AC · cero tests modificados · métrica de mejora declarada (duplicación) |
| G8 | `infra` | "Agregar cache de dependencias al pipeline de CI" | AC de reversibilidad · evidencia de corrida en entorno no productivo · `doc_quality_gates.md` actualizado si cambia un comando |
| G9 | `project-scaffold` | (repo vacío) "API REST de reservas de salas, stack Node+TS" | Primera task es scaffold · primer test real verde · `sdd-run-gates.sh` corre sin `[SKIPPED]` por comando inexistente · tokens de diseño como ADR si hay UI |

**Golden adversarial (G10, sin arquetipo esperado)**: "Agregar el endpoint de reportes y migrar la tabla de logs" → la propiedad es que el refinement lo **parta en dos requerimientos** con orden de integración, no que produzca un contract gordo.

**Golden de proporcionalidad (G11)**: "Corregir typo 'Facturra' en el título del dashboard" → la propiedad es que el refinement proponga la **vía corta** (`/sdd-fixes`), no un ciclo completo.

## Resultados

| Fecha | Versión plugin | Golden | Resultado | Nota |
|---|---|---|---|---|
| — | — | — | — | primera corrida pendiente |
