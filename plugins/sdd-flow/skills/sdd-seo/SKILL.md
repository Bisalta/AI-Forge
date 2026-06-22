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
