# Spec — SEO frontend advisory en sdd-flow

- **Fecha**: 2026-06-22
- **Plugin**: sdd-flow
- **Estado**: diseño aprobado, pendiente implementación
- **Branch**: feat-seo-frontend-advisory

## Problema

El pipeline SDD no contempla SEO. En proyectos con frontend público (indexable), el output puede salir a Feature Ready sin title/meta, sin sitemap, con Core Web Vitals en rojo, sin structured data. Hoy nadie en el ciclo lo mira.

Pero no todo frontend necesita SEO: un dashboard interno, un panel admin o una app autenticada no se indexa. Forzar SEO en esos casos es ruido.

## Objetivo

sdd-flow trata SEO como **concern advisory** (nunca bloqueante) para proyectos con frontend, activándolo solo cuando el front es **público/indexable**, decidido explícitamente — no asumido.

## Decisiones cerradas (no re-litigar)

1. **Advisory, nunca bloquea.** El SEO reporta hallazgos; el gate humano único sigue siendo Feature Ready. Un fallo SEO **no** marca al agente BLOCKED. (Decisión del usuario: prefiere informante.)
2. **Activación por pregunta, no automática.** Tener un FE agent dispara la pregunta "¿este front es indexable público / necesita SEO?". Respuesta negativa → SEO se saltea por completo. Resuelve el caso "es front pero no ocupa SEO".
3. **Sin agente nuevo.** El checklist vive en `standards/`; lo ejecutan el `reviewer-agent` existente (en pipeline) y el skill `/sdd-seo` (on-demand). Menos superficie, mismo resultado (YAGNI).
4. **Checklist en 2 tiers.** Universal (todo front) vs Indexable-solo. Evita aplicar reglas de indexación a apps internas que igual quieren perf/a11y.
5. **Contract decision-closed.** Cuando SEO aplica, los criterios entran al contract sin lenguaje difuso ("if needed / may"), respetando las closure rules del repo.

## Componentes

### A · `standards/seo-frontend.md` (nuevo)

Checklist en dos tiers.

**Tier Universal** (aplica a cualquier front, indexable o no):
- HTML semántico (landmarks, headings jerárquicos, un solo `<h1>`).
- Core Web Vitals / perf: LCP, CLS, INP dentro de umbrales; imágenes con `width`/`height` y `loading`.
- Accesibilidad base: `lang` en `<html>`, `alt` en imágenes, foco visible, contraste.
- Sin errores de consola que rompan render.

**Tier Indexable** (solo si `seo.indexable == true`):
- `<title>` único y descriptivo + `<meta name="description">`.
- `<link rel="canonical">` correcto.
- `robots` meta / `robots.txt` coherentes; sin `noindex` accidental en páginas públicas.
- `sitemap.xml` presente y referenciado.
- Structured data JSON-LD acorde al tipo de página.
- Open Graph + Twitter cards.
- `hreflang` si el contract declara múltiples `locales`.

Cada ítem marca **severidad** (crítico / mejora) para informar, no para bloquear.

### B · Contract gate (skills `enrich-user-story` + `sdd-plan`)

- `enrich-user-story`: si el scope incluye frontend, agrega la pregunta de refinement "¿hay UI pública indexable?". El resultado setea en el contract:
  ```
  seo:
    applies: <bool>     # hay front con SEO en alcance
    indexable: <bool>   # es público indexable (activa tier Indexable)
    locales: []         # vacío = monolingüe; con valores activa hreflang
  ```
- `sdd-plan`: si `seo.applies == true`, inyecta criterios SEO **decision-closed** en el HLTC y en el/los task brief(s) del FE agent, escogiendo tier según `seo.indexable`. Si `false`, no toca el contract.

### C · Review advisory (`reviewer-agent`)

- Cuando revisa un diff de FE con `seo.applies == true`, el `reviewer-agent` (Opus, ya existe) corre el checklist de `seo-frontend.md` contra el diff.
- Escribe una sección **"SEO (advisory)"** en el testing/PR report: hallazgos + severidad + ubicación.
- **No** marca BLOCKED ni frena Feature Ready. Solo informa.

### D · Skill `/sdd-seo` (nuevo, on-demand)

- Audita el frontend actual contra `seo-frontend.md` fuera del pipeline.
- Corre Lighthouse si está disponible en el entorno; fallback a chequeo estático (parsea HTML/JSX/templates por los ítems del checklist).
- Output: reporte con hallazgos, severidad y sugerencias. No modifica código salvo orden explícita.
- Registrado en `marketplace`/`plugin.json` como command + skill, igual que `/sdd-fixes`.

## Fuera de alcance (YAGNI por ahora)

- Badge statusline `🔍 seo` — posible v+1 si se pide.
- Lighthouse CI cableado en pipeline (el skill lo corre on-demand; CI queda para después).
- Auto-fix de hallazgos SEO (el skill reporta; arreglar es orden explícita).

## Capas de integración (degradación por entorno)

Consistente con la regla del repo: el SEO advisory corre igual con o sin remote/PR. El reporte se adjunta al testing report local cuando no hay PR.

## Versionado

Feature nueva → bump menor en `plugins/sdd-flow/.claude-plugin/plugin.json` + entrada en `CHANGELOG.md` + nota en `CLAUDE.md` (estado actual).

## Archivos tocados (estimado)

- `plugins/sdd-flow/standards/seo-frontend.md` — nuevo.
- `plugins/sdd-flow/standards/base-standards.md` — referencia al checklist SEO.
- `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` — pregunta SEO + flag.
- `plugins/sdd-flow/skills/sdd-plan/SKILL.md` — inyección de criterios SEO al contract.
- `plugins/sdd-flow/agents/reviewer-agent.md` — paso SEO advisory en review.
- `plugins/sdd-flow/skills/sdd-seo/SKILL.md` + `plugins/sdd-flow/commands/sdd-seo.md` — nuevos.
- `plugins/sdd-flow/.claude-plugin/plugin.json`, `CHANGELOG.md`, `CLAUDE.md`, `README.md` — registro/versión.
