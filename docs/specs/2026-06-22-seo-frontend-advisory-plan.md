# SEO Frontend Advisory — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar SEO como concern advisory (nunca bloqueante) al pipeline sdd-flow, activado por pregunta solo cuando hay frontend indexable.

**Architecture:** Checklist de 2 tiers en `standards/`, consumido por el `reviewer-agent` existente (en pipeline) y por un skill/command nuevo `/sdd-seo` (on-demand). El contract gana un bloque `seo:` seteado en `enrich-user-story` y consumido por `sdd-plan`. Sin agente nuevo.

**Tech Stack:** Markdown (prompts/skills/commands/standards de plugin Claude Code). Sin suite de tests — la verificación es validación de JSON del manifiesto + chequeos de consistencia cruzada por `grep` (mismo patrón que las pre-push audits previas del repo).

**Spec:** [docs/specs/2026-06-22-seo-frontend-advisory-design.md](2026-06-22-seo-frontend-advisory-design.md)

**Branch:** `feat-seo-frontend-advisory` (ya creada desde `main`).

---

## File Structure

- `plugins/sdd-flow/standards/seo-frontend.md` — **nuevo**. El checklist canónico de 2 tiers. Única fuente de verdad del SEO.
- `plugins/sdd-flow/standards/base-standards.md` — **modificar**. Una línea que apunta al checklist SEO.
- `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` — **modificar**. Dimensión de decisión SEO + bloque `seo:` en el output.
- `plugins/sdd-flow/skills/sdd-plan/SKILL.md` — **modificar**. Inyección de criterios SEO al HLTC/briefs cuando `seo.applies`.
- `plugins/sdd-flow/agents/reviewer-agent.md` — **modificar**. Paso de SEO advisory en el review.
- `plugins/sdd-flow/commands/sdd-seo.md` — **nuevo**. Slash command.
- `plugins/sdd-flow/skills/sdd-seo/SKILL.md` — **nuevo**. Skill de auditoría on-demand.
- `plugins/sdd-flow/commands/sdd.md` — **modificar**. Mención del SEO advisory en las fases.
- `plugins/sdd-flow/.claude-plugin/plugin.json` — **modificar**. Bump a 0.6.0.
- `CHANGELOG.md`, `CLAUDE.md`, `plugins/sdd-flow/README.md` — **modificar**. Registro/versión.

---

### Task 1: Checklist SEO de 2 tiers

**Files:**
- Create: `plugins/sdd-flow/standards/seo-frontend.md`

- [ ] **Step 1: Escribir el checklist**

Crear `plugins/sdd-flow/standards/seo-frontend.md` con este contenido exacto:

```markdown
# SEO Frontend Standard — sdd-flow

Checklist SEO para proyectos con frontend. **Advisory**: informa, no bloquea. Activá según el bloque `seo:` del contract.

## Cómo se activa
- `seo.applies == false` → no corras este checklist.
- `seo.applies == true` → corré **Tier Universal**.
- `seo.indexable == true` → corré además **Tier Indexable**.
- `seo.locales` con ≥2 valores → activá el ítem `hreflang`.

## Tier Universal (todo front con `seo.applies`)
- [ ] HTML semántico: landmarks (`header/nav/main/footer`), headings jerárquicos, un solo `<h1>` por vista.
- [ ] Core Web Vitals dentro de umbral: LCP < 2.5s, CLS < 0.1, INP < 200ms.
- [ ] Imágenes con `width`/`height` explícitos y `loading="lazy"` salvo el hero.
- [ ] `lang` correcto en `<html>`.
- [ ] `alt` en imágenes informativas; foco visible; contraste AA.
- [ ] Sin errores de consola que rompan el render inicial.

## Tier Indexable (solo `seo.indexable == true`)
- [ ] `<title>` único y descriptivo por ruta + `<meta name="description">`.
- [ ] `<link rel="canonical">` correcto por ruta.
- [ ] `robots` meta y `robots.txt` coherentes; sin `noindex` accidental en rutas públicas.
- [ ] `sitemap.xml` presente y referenciado desde `robots.txt`.
- [ ] Structured data JSON-LD acorde al tipo de página (Article, Product, BreadcrumbList, etc).
- [ ] Open Graph (`og:title`, `og:description`, `og:image`, `og:url`) + Twitter cards.
- [ ] `hreflang` por locale si `seo.locales` tiene ≥2 entradas.

## Severidad (para reportar, no bloquear)
- **crítico**: `<title>`/meta description ausentes, `noindex` en ruta pública, `sitemap.xml` roto, LCP/CLS fuera de umbral.
- **mejora**: structured data, OG/Twitter, micro-optimizaciones de perf.

Todo hallazgo se reporta con: ubicación · ítem · severidad · fix sugerido.
```

- [ ] **Step 2: Verificar que existe y tiene los 2 tiers**

Run: `grep -c '^## Tier' plugins/sdd-flow/standards/seo-frontend.md`
Expected: `2`

- [ ] **Step 3: Commit**

```bash
git add plugins/sdd-flow/standards/seo-frontend.md
git commit -m "[ADD] [sdd-flow] Standard SEO frontend — checklist 2 tiers

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Referencia desde base-standards

**Files:**
- Modify: `plugins/sdd-flow/standards/base-standards.md` (sección `## Áreas`, línea ~15-19)

- [ ] **Step 1: Leer el bloque de Áreas**

Run: `sed -n '15,28p' plugins/sdd-flow/standards/base-standards.md`
Expected: ver la sección `## Áreas (detalle en el repo standard de la empresa)`.

- [ ] **Step 2: Agregar la referencia SEO**

Insertar una línea bullet dentro de `## Áreas`, al final de su lista, con este texto exacto:

```markdown
- **SEO (frontend)**: ver `standards/seo-frontend.md`. Advisory; aplica solo si el contract trae `seo.applies == true`.
```

- [ ] **Step 3: Verificar la referencia**

Run: `grep -n 'seo-frontend.md' plugins/sdd-flow/standards/base-standards.md`
Expected: al menos 1 match.

- [ ] **Step 4: Commit**

```bash
git add plugins/sdd-flow/standards/base-standards.md
git commit -m "[IMP] [sdd-flow] base-standards apunta al checklist SEO

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Dimensión SEO en enrich-user-story

**Files:**
- Modify: `plugins/sdd-flow/skills/enrich-user-story/SKILL.md` (sección `### Mandatory decision dimensions` línea ~56, y el template de output `## Closed decisions` línea ~200)

- [ ] **Step 1: Leer las dos zonas a tocar**

Run: `sed -n '56,82p;195,215p' plugins/sdd-flow/skills/enrich-user-story/SKILL.md`
Expected: ver las dimensiones obligatorias y el template de output (Scope / Closed decisions).

- [ ] **Step 2: Agregar la dimensión SEO condicional**

Al final de la lista en `### Mandatory decision dimensions`, agregar este ítem exacto:

```markdown
- **SEO (solo si el scope incluye frontend)**: preguntá "¿hay UI pública indexable por buscadores?". Si la respuesta es no (app interna, panel admin, área autenticada), SEO no aplica. Si es sí, confirmá idiomas/locales. No asumas — preguntá.
```

- [ ] **Step 3: Agregar el bloque `seo:` al artefacto final**

En el template de output (después de `## Closed decisions`, línea ~200), agregar esta sección exacta:

```markdown
## SEO
<!-- Incluir solo si el scope tiene frontend. Si no hay front, omitir esta sección. -->
- applies: <true|false>     # hay frontend con SEO en alcance
- indexable: <true|false>   # es público indexable (activa tier Indexable)
- locales: []               # vacío = monolingüe; ≥2 entradas activan hreflang
```

- [ ] **Step 4: Verificar ambas inserciones**

Run: `grep -n 'UI pública indexable\|## SEO\|applies:' plugins/sdd-flow/skills/enrich-user-story/SKILL.md`
Expected: 3 matches (la dimensión, el header `## SEO`, y `applies:`).

- [ ] **Step 5: Commit**

```bash
git add plugins/sdd-flow/skills/enrich-user-story/SKILL.md
git commit -m "[IMP] [sdd-flow] enrich pregunta SEO y setea bloque seo: en el contract

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Inyección de criterios SEO en sdd-plan

**Files:**
- Modify: `plugins/sdd-flow/skills/sdd-plan/SKILL.md` (`## Fase A — HLTC` línea ~14 y `## Fase B — Task briefs` línea ~38)

- [ ] **Step 1: Leer Fase A y Fase B**

Run: `sed -n '14,56p' plugins/sdd-flow/skills/sdd-plan/SKILL.md`
Expected: ver la definición del HLTC y los task briefs.

- [ ] **Step 2: Agregar el manejo de SEO en Fase A**

Al final de `## Fase A — High-Level Technical Contract (HLTC)`, antes de `### Closure rules`, agregar:

```markdown
### SEO (si el contract trae `seo.applies == true`)
Cuando el requerimiento incluye el bloque `seo:` con `applies: true`, agregá al HLTC acceptance criteria SEO **decision-closed** (sin "if needed / may / prefer"), tomados de `standards/seo-frontend.md`:
- Siempre el Tier Universal.
- El Tier Indexable solo si `seo.indexable == true`.
- El ítem `hreflang` solo si `seo.locales` tiene ≥2 entradas.
Si `seo.applies == false` o no hay bloque `seo:`, no agregues criterios SEO.
```

- [ ] **Step 3: Agregar la bajada a los task briefs en Fase B**

Al final de `## Fase B — Task briefs por agente`, agregar:

```markdown
### SEO en el brief del FE agent
Si el HLTC tiene criterios SEO, copiálos como acceptance criteria verificables en el brief del agente de frontend, marcando el tier (Universal / Indexable). El reviewer-agent los chequea en modo advisory; no son gate de Feature Ready.
```

- [ ] **Step 4: Verificar inserciones**

Run: `grep -n '### SEO\|seo-frontend.md' plugins/sdd-flow/skills/sdd-plan/SKILL.md`
Expected: 3 matches (header Fase A, referencia al standard, header Fase B).

- [ ] **Step 5: Commit**

```bash
git add plugins/sdd-flow/skills/sdd-plan/SKILL.md
git commit -m "[IMP] [sdd-flow] sdd-plan inyecta criterios SEO al HLTC/briefs cuando aplica

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: SEO advisory en reviewer-agent

**Files:**
- Modify: `plugins/sdd-flow/agents/reviewer-agent.md` (`## Qué chequeás` línea ~10 y `## Veredicto` línea ~18)

- [ ] **Step 1: Agregar el chequeo SEO advisory**

En `## Qué chequeás`, después del ítem 6 (Standards), agregar:

```markdown
7. **SEO (advisory, solo si `seo.applies == true`)**: corré `standards/seo-frontend.md` contra el diff FE. Esto **NO** cuenta para APPROVED/REJECTED — es informativo.
```

- [ ] **Step 2: Agregar la salida advisory al veredicto**

En `## Veredicto`, después de la lista de hallazgos, agregar:

```markdown
- Si `seo.applies == true`: sección aparte **"SEO (advisory)"** con hallazgos (ubicación · ítem · severidad · fix). Estos hallazgos **nunca** disparan REJECTED ni BLOCKED — el gate humano de Feature Ready decide.
```

- [ ] **Step 3: Verificar**

Run: `grep -n 'SEO (advisory)\|seo-frontend.md' plugins/sdd-flow/agents/reviewer-agent.md`
Expected: 2 matches.

- [ ] **Step 4: Commit**

```bash
git add plugins/sdd-flow/agents/reviewer-agent.md
git commit -m "[IMP] [sdd-flow] reviewer-agent reporta SEO advisory sin bloquear

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Command + skill `/sdd-seo` on-demand

**Files:**
- Create: `plugins/sdd-flow/commands/sdd-seo.md`
- Create: `plugins/sdd-flow/skills/sdd-seo/SKILL.md`

- [ ] **Step 1: Crear el command**

Crear `plugins/sdd-flow/commands/sdd-seo.md` con este contenido exacto:

```markdown
---
description: Auditoría SEO on-demand del frontend actual contra standards/seo-frontend.md. Advisory — reporta, no modifica código salvo orden explícita.
argument-hint: "[ruta del front o vacío para autodetectar · 'fix' para aplicar arreglos tras el reporte]"
---

# /sdd-seo — Auditoría SEO advisory

Auditá el frontend del repo actual contra el checklist `standards/seo-frontend.md`. Input: **$ARGUMENTS**

## 1. Resolver alcance
- Si `$ARGUMENTS` trae una ruta, auditá esa. Si no, autodetectá el front (package.json / framework / carpetas de UI).
- Si no hay frontend en el repo, decílo y terminá.

## 2. Determinar tiers
- Sin contract con bloque `seo:` → corré Tier Universal y preguntá una vez "¿es indexable público?" para decidir el Tier Indexable.
- Con bloque `seo:` disponible → respetalo (`applies`/`indexable`/`locales`).

## 3. Correr la auditoría
1. Si `command -v lighthouse` o `npx lighthouse` está disponible y hay un server/URL, corré Lighthouse y tomá CWV/SEO reales.
2. Fallback sin Lighthouse: chequeo estático — parseá HTML/JSX/templates por cada ítem del checklist.

## 4. Reporte (advisory)
Mostrá una tabla: ítem · tier · severidad (crítico|mejora) · estado (ok|falla) · ubicación · fix sugerido. Cerrá con conteo por severidad.

## 5. Cierre
**No modifiques código** salvo que `$ARGUMENTS` incluya `fix` o el usuario lo pida explícito. Si pidió `fix`: aplicá solo los arreglos triviales y de bajo riesgo (meta tags, alt, lang, canonical), nunca cambios de arquitectura; el resto queda como recomendación.
```

- [ ] **Step 2: Crear el skill**

Crear `plugins/sdd-flow/skills/sdd-seo/SKILL.md` con este contenido exacto:

```markdown
---
name: sdd-seo
description: Auditoría SEO on-demand del frontend actual contra el checklist seo-frontend.md. Advisory — reporta hallazgos con severidad; no modifica código salvo orden explícita. Usar fuera o dentro del pipeline SDD para proyectos con front.
---

# SEO Audit (advisory)

Auditás el frontend contra `standards/seo-frontend.md` y devolvés un reporte. **No bloqueás nada** — sos informante.

## Proceso
1. **Alcance**: ruta dada o autodetectada (package.json / framework / carpetas de UI). Sin front → terminá avisando.
2. **Tiers**: respetá el bloque `seo:` del contract si existe; si no, corré Tier Universal y preguntá una vez si es indexable público para el Tier Indexable.
3. **Auditoría**: Lighthouse si está disponible (CWV/SEO reales); fallback a chequeo estático parseando HTML/JSX/templates.
4. **Reporte**: tabla ítem · tier · severidad · estado · ubicación · fix. Conteo por severidad.

## Reglas
- Advisory: nunca marcás BLOCKED ni frenás Feature Ready.
- No tocás código salvo orden explícita (`fix`). Si arreglás, solo triviales/bajo riesgo (meta, alt, lang, canonical); nunca arquitectura.
- Severidad según `standards/seo-frontend.md`.
```

- [ ] **Step 3: Verificar frontmatter de ambos**

Run: `head -4 plugins/sdd-flow/commands/sdd-seo.md && echo '---' && head -4 plugins/sdd-flow/skills/sdd-seo/SKILL.md`
Expected: ambos abren con `---` y traen `description:` (command) / `name: sdd-seo` (skill).

- [ ] **Step 4: Commit**

```bash
git add plugins/sdd-flow/commands/sdd-seo.md plugins/sdd-flow/skills/sdd-seo/SKILL.md
git commit -m "[ADD] [sdd-flow] Command y skill /sdd-seo — auditoría SEO advisory on-demand

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Mención del SEO advisory en el orquestador

**Files:**
- Modify: `plugins/sdd-flow/commands/sdd.md` (`### 4. EJECUCIÓN` línea ~42 y `### 1. DECISION-CLOSED REFINEMENT` línea ~27)

- [ ] **Step 1: Leer las fases 1 y 4**

Run: `sed -n '27,49p' plugins/sdd-flow/commands/sdd.md`
Expected: ver el texto de refinement y ejecución.

- [ ] **Step 2: Agregar nota SEO en Fase 1**

Al final de `### 1. DECISION-CLOSED REFINEMENT`, agregar:

```markdown
- Si el scope tiene frontend, el refinement cierra el bloque `seo:` (applies/indexable/locales) — ver `enrich-user-story`.
```

- [ ] **Step 3: Agregar nota SEO en Fase 4**

Al final de `### 4. EJECUCIÓN`, agregar:

```markdown
- Si `seo.applies == true`, el reviewer-agent adjunta una sección **SEO (advisory)** al testing/PR report. No bloquea Feature Ready.
```

- [ ] **Step 4: Verificar**

Run: `grep -n 'seo:\|SEO (advisory)' plugins/sdd-flow/commands/sdd.md`
Expected: 2 matches.

- [ ] **Step 5: Commit**

```bash
git add plugins/sdd-flow/commands/sdd.md
git commit -m "[IMP] [sdd-flow] /sdd menciona el SEO advisory en refinement y ejecución

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Versionado y registro

**Files:**
- Modify: `plugins/sdd-flow/.claude-plugin/plugin.json` (`"version": "0.5.0"` línea 3)
- Modify: `CHANGELOG.md` (tope)
- Modify: `CLAUDE.md` (sección "Estado actual")
- Modify: `plugins/sdd-flow/README.md`

- [ ] **Step 1: Bump de versión**

En `plugins/sdd-flow/.claude-plugin/plugin.json`, cambiar `"version": "0.5.0"` por `"version": "0.6.0"`.

- [ ] **Step 2: Validar JSON**

Run: `python3 -m json.tool plugins/sdd-flow/.claude-plugin/plugin.json > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Entrada en CHANGELOG**

Agregar al tope de `CHANGELOG.md` (debajo del header, antes de v0.5.0) una entrada `## [0.6.0]` que describa: SEO frontend advisory (checklist 2 tiers en standards, bloque `seo:` en contract vía enrich, inyección en sdd-plan, review advisory en reviewer-agent, command/skill `/sdd-seo`). Referenciar el spec `docs/specs/2026-06-22-seo-frontend-advisory-design.md`.

- [ ] **Step 4: Actualizar CLAUDE.md y README**

- `CLAUDE.md`: agregar a la sección "Estado actual" un párrafo **v0.6.0** resumiendo el SEO advisory + el nuevo comando en la línea de comandos de la estructura (`sdd-seo`).
- `plugins/sdd-flow/README.md`: listar `/sdd-seo` entre los comandos disponibles con una línea de descripción.

- [ ] **Step 5: Verificar versión propagada**

Run: `grep -rn '0.6.0' plugins/sdd-flow/.claude-plugin/plugin.json CHANGELOG.md`
Expected: match en ambos archivos.

- [ ] **Step 6: Commit**

```bash
git add plugins/sdd-flow/.claude-plugin/plugin.json CHANGELOG.md CLAUDE.md plugins/sdd-flow/README.md
git commit -m "[REL] [sdd-flow] v0.6.0 — SEO frontend advisory

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage** (cada componente del spec → task):
- A · `standards/seo-frontend.md` → Task 1 ✅ + ref en Task 2.
- B · Contract gate (enrich + sdd-plan) → Task 3 (enrich, bloque `seo:`) + Task 4 (sdd-plan, inyección) ✅.
- C · Review advisory (reviewer-agent) → Task 5 ✅.
- D · Skill `/sdd-seo` → Task 6 ✅.
- Decisión "advisory nunca bloquea" → reforzada en Tasks 1, 4, 5, 6 ✅.
- Decisión "activación por pregunta, no auto" → Task 3 (enrich pregunta) ✅.
- Versionado → Task 8 ✅.
- Orquestador `/sdd` (no estaba explícito en el spec pero es coherente) → Task 7.

**Placeholder scan:** sin TBD/TODO; todo contenido nuevo está escrito completo. Las ediciones a archivos existentes referencian anclas reales (líneas verificadas con `grep`/`sed` arriba).

**Type/naming consistency:** el bloque `seo:` usa los mismos campos en todos lados — `applies`, `indexable`, `locales` (Tasks 3, 4, 5, 6, 7). El nombre del standard es `seo-frontend.md` en todas las referencias. El command/skill se llama `sdd-seo` consistente.

**Nota de orden:** Task 1 (standard) antes que todo lo que lo referencia. Task 8 (versión) al final.
