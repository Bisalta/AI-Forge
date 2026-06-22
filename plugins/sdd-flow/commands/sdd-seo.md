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
