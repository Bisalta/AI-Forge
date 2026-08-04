---
description: Crea (o back-fillea) los seis documentos fundacionales de un proyecto — PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan — desde cero (entrevista) o derivando de un codebase existente.
argument-hint: "[greenfield | existing] [dir de salida, default docs/foundation] [only: 1,2,..]"
---

# /project-foundation — Documentos fundacionales del proyecto

Invocá el skill **`project-foundation`** para: **$ARGUMENTS**

Detectá el modo (greenfield → entrevistar; existing → derivar del código con subagentes de exploración en paralelo) y producí los seis documentos en `docs/foundation/` (o el dir que indique `$ARGUMENTS`), en el orden de dependencia PRD → TRD → (UI/UX Brief ∥ App Flow ∥ Backend Schema) → Implementation Plan, más un `README.md` índice.

Si el proyecto ya tiene docs que se solapan (plan de arquitectura, backlog, ADRs), consolidá — no dupliques. En modo `existing`, cerrá con la lista de "supuestos a confirmar".
