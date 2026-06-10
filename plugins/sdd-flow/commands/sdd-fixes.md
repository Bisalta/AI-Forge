---
description: Estructura una tanda de fixes/ajustes en fixes.md — intake, triage automático y visualizador editable. No implementa nada hasta orden explícita.
argument-hint: "[lista cruda de fixes/ajustes — o vacío para solo crear/abrir fixes.md]"
---

# /sdd-fixes — Batch de fixes con triage

Gestioná la tanda de fixes del repo actual sobre el archivo `fixes.md` (raíz del repo). Input del usuario: **$ARGUMENTS**

## 1. Bootstrap

Si NO existe `fixes.md` en la raíz del repo actual, crealo con este template (completá fecha y repos reales — preguntá paths de otros repos solo si algún item los requiere):

```markdown
# Batch fixes — <YYYY-MM>
Repos:
- <rol>: <path absoluto>

<!-- Estados válidos: pendiente | en-curso | hecho | bloqueado -->
```

## 2. Intake (solo si hay argumentos)

Parseá la lista cruda del usuario. Cada item → bloque:

```markdown
## F-NN — <título corto imperativo>
- Tipo: bug | visual | interacción | mejora
- Repo: front | back | ambos
- Triage: trivial | mediano | ambiguo
- Estado: pendiente
- Detalle: <repro / esperado vs actual / descripción>
```

Reglas:
- IDs `F-01, F-02, …` secuenciales. Si ya hay items, continuá desde el máximo existente. NUNCA renumeres items existentes — re-invocación = append.
- **Triage**: `trivial` = fix directo en un repo, sin diagnóstico. `mediano` = requiere diagnóstico o toca varias piezas de un repo. `ambiguo` = decisiones de diseño abiertas O acoplado front+back (cambio de contrato/endpoint).
- A cada item `ambiguo` agregale: `- Sugerencia: cerrar con /sdd-enrich antes de implementar`.
- Si un item no da info para clasificar Tipo/Repo, poné tu mejor inferencia — no interrogues al usuario por cada item.

## 3. Abrir visualizador

Abrí `fixes.md` para edición lateral, en este orden de preferencia:
1. `command -v code` disponible → `code <path absoluto>/fixes.md`
2. macOS → `open <path absoluto>/fixes.md`
3. Fallback → mostrale el path absoluto al usuario.

## 4. Cierre — NO implementes nada

Terminá mostrando: tabla resumen (ID, título, triage, repo) + conteo por triage + recordatorio de que el badge `⚡ fixes N/M` aparece en la statusline.

**Prohibido tocar código de fixes en esta invocación.** Esperá orden explícita ("dale con F-03", "arrancá en orden").

## Reglas para el resto de la sesión (al trabajar items)

- Antes de arrancar un item: `Estado: en-curso` en `fixes.md`.
- Item terminado y verificado: `Estado: hecho`. Bloqueado: `Estado: bloqueado` + nota del motivo en `Detalle`.
- Un commit por item, convención `[FIX] [Módulo] [Descripción]` (o `[IMP]` para mejoras).
- Items `Repo: ambos`: primero back, después front; commit por repo.
- Item `ambiguo` sin cerrar: NO adivines — usá `/sdd-enrich` o preguntá.
- El usuario puede editar `fixes.md` a mano en cualquier momento: releelo del disco antes de cada item.
