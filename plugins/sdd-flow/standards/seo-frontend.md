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
