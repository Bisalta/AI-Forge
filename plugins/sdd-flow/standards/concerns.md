# Concerns transversales — qué aplica, y si bloquea o informa

Los arquetipos (`archetypes.md`) definen la **forma** del trabajo; los concerns definen las **cualidades** que atraviesan cualquier forma: seguridad, observabilidad, accesibilidad, diseño, privacidad… El patrón es el que ya probó el bloque `seo:`: se activan en el **refinement** con preguntas concretas, quedan persistidos en el requerimiento/contract como bloque `concerns:`, y cada uno está declarado **blocking o advisory** — el agente nunca decide en el momento si algo "importaba".

**Blocking** = sus ítems entran al HLTC como ACs (test o `N/A` razonado — régimen de `quality-gates.md`). **Advisory** = sección propia con IDs `<CONCERN>1..n`, el reviewer los reporta sin poder rechazar (mismo régimen que SEO). Un advisory se promueve a blocking solo por decisión explícita en el refinement.

| Concern | Se activa cuando | Default |
|---|---|---|
| `security` | siempre | **blocking** |
| `observability` | el código corre en producción (o sea: casi siempre) | **blocking** |
| `a11y` | hay UI | **blocking** (tier básico) |
| `design` | hay UI | **blocking** |
| `data-privacy` | se tocan datos personales | **blocking** |
| `api-compat` | hay contrato público consumido por terceros | **blocking** |
| `i18n` | el producto maneja ≥2 locales | **blocking** |
| `performance` | hay presupuesto declarado | **blocking con número, advisory sin él** |
| `seo` | front público | **advisory** (ya existe: bloque `seo:` + `seo-frontend.md`) |

---

## `security` — siempre activo
Checklist completo en `standards/security.md`. No hay pregunta de activación: aplica siempre. El refinement solo cierra los datos que el threat model necesita (roles, sensibilidad de datos).

## `observability` — si corre en producción, se tiene que poder operar
- Toda operación que puede fallar loguea el fallo con contexto accionable (IDs opacos, no PII — `security.md` §5).
- Acciones de negocio relevantes emiten señal (log estructurado/métrica/evento, según lo que el repo ya usa — seguí el patrón existente, no introduzcas un stack de observabilidad nuevo sin ADR).
- Pregunta de refinement: **"¿cómo te das cuenta en producción de que esto se rompió?"** — la respuesta se vuelve AC. "Mirando la base" no es una respuesta.
- Jobs y migraciones: progreso y conteos observables (ya exigido por sus arquetipos).

## `a11y` — tier básico, verificable sin auditoría externa
- Controles con label programático (no placeholder como label); imágenes informativas con `alt`.
- Operable por teclado: foco visible, orden lógico, sin trampas de foco; `Escape` cierra modales.
- Contraste AA en texto y controles.
- Errores de formulario asociados al campo (`aria-describedby` o patrón del design system), no solo color.
- Verificación: axe/eslint-plugin-jsx-a11y si el repo los tiene; si no, checklist manual sobre el diff (declarado en evidencia).

## `design` — que la UI sea del sistema, no un injerto
- **Design system primero**: componentes/tokens existentes del repo. Un componente nuevo o un valor hardcodeado (color, spacing, tipografía fuera de tokens) requiere justificación en el contract — es la versión UI del *Reuse statement*.
- **Los cuatro estados** de toda vista con datos: vacío · carga · error · éxito (ya AC por arquetipo `ui-feature`; acá aplica a cualquier arquetipo que toque UI).
- Responsive según los breakpoints que el repo ya define; interacciones destructivas con confirmación.
- Copy en el idioma/tono del producto (y por i18n si está activo — nada hardcodeado si el repo usa catálogo).
- Pregunta de refinement: **¿hay diseño de referencia** (Figma/mock/página existente)? Si hay, es la spec y se referencia en el contract; si no, "consistente con <vista existente>" — nombrada, no implícita.

## `data-privacy` — si hay datos personales, hay reglas
- Minimización: se recolecta/expone solo lo que el requerimiento necesita (campos listados en el contract).
- PII fuera de logs, URLs y mensajes de error (`security.md` §5).
- Retención/borrado: si se crean datos personales nuevos, el contract dice cuánto viven y cómo se borran (si el proyecto tiene política, se referencia; si no la tiene, la pregunta escala al humano — no la inventa el planner).
- Datos personales hacia terceros (integración): listados explícitos + base legal según la normativa que aplique al proyecto (pregunta de refinement, no supuesto).

## `api-compat` — contratos públicos no se rompen en silencio
- Cambio aditivo (campo/endpoint nuevo) → compatible, documentado.
- Breaking change (quitar/renombrar/cambiar tipo o semántica) → **versión nueva + período de deprecación + ADR**. Nunca en la misma versión.
- AC de compatibilidad: los consumidores existentes (tests de contrato o el impact set) siguen verdes sin cambios.

## `i18n` — si hay ≥2 locales, nada hardcodeado
- Strings nuevos por el catálogo del repo (con claves siguiendo la convención existente), en TODOS los locales activos (placeholder marcado si falta traducción humana — no string vacío).
- Formatos de fecha/número/moneda por locale, no concatenación manual.
- Layout tolerante a textos largos (el alemán existe).

## `performance` — con número es gate, sin número es opinión
- Pregunta de refinement: **¿hay presupuesto?** (p95 de latencia, tamaño de bundle, tiempo de query, memoria). Con número → AC verificable con el comando que lo mide. Sin número → advisory: el reviewer reporta regresiones obvias (N+1, query sin índice en tabla grande, bundle que duplica) sin bloquear.
- Nunca optimizar sin medición previa registrada (la micro-optimización especulativa es deuda, no mejora).

## `seo` — ya definido
Mecanismo y checklist en `standards/seo-frontend.md`; bloque `seo:` propio (v0.6.0). Este archivo no lo duplica — es el precedente que los demás concerns siguen.

---

## Cómo lo usa el pipeline

1. **`enrich-user-story`**: 4 flags cierran la activación (¿hay UI? ¿contrato público? ¿datos personales? ¿≥2 locales?) + la pregunta de observabilidad + presupuesto de performance si aplica. Output: bloque `concerns:` con cada concern en `blocking | advisory | n/a`.
2. **`sdd-plan`**: los blocking activos inyectan sus ítems como ACs (o `N/A` razonado ítem por ítem); los advisory como sección aparte con sus IDs.
3. **`reviewer-agent`**: verifica los blocking en Fase 2 (ítem sin AC ni `N/A` = `MAJOR` de contract) y reporta los advisory sin rechazar.
