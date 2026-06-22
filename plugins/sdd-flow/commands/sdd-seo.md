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
- Si `seo.applies == false` pero el usuario corrió `/sdd-seo` a propósito: avisá que el contract lo marca como no-aplica y ofrecé correr igual el **Tier Universal** (no salgas en silencio). El Tier Indexable solo si `seo.indexable == true`.

## 3. Correr la auditoría
1. **Resolver la URL** (en este orden): (a) si `$ARGUMENTS` trae una URL `http(s)://`, usala; (b) detectá el dev server por la config del repo (`vite`/`next`/`package.json scripts` → puerto, ej. `localhost:3000`, `:5173`) y verificá si ya está corriendo (`curl -sf`); (c) si no está corriendo pero hay script de dev, preguntá una vez al usuario si querés levantarlo temporalmente; (d) si no se resuelve ninguna URL, **saltá Lighthouse** y avisá que CWV/SEO runtime quedan en N/A.
2. Si hay URL **y** `command -v lighthouse` / `npx lighthouse` está disponible, corré Lighthouse contra esa URL y tomá CWV/SEO reales (apagá el server temporal al terminar si lo levantaste vos).
3. Fallback (sin URL o sin Lighthouse): chequeo estático — parseá HTML/JSX/templates por cada ítem; los ítems runtime (Core Web Vitals) se reportan **N/A**.

## 4. Reporte (advisory)
Mostrá una tabla: ítem · tier · severidad (crítico|mejora) · estado (ok|falla) · ubicación · fix sugerido. Cerrá con conteo por severidad.

## 5. Cierre
**No modifiques código** salvo que `$ARGUMENTS` incluya `fix` o el usuario lo pida explícito. Si pidió `fix`: aplicá solo los arreglos triviales y de bajo riesgo (meta tags, alt, lang, canonical), nunca cambios de arquitectura; el resto queda como recomendación.
