---
description: Bootstrapea (o llena) los docs fundacionales SDD/docs/doc_architecture.md y doc_verification_guide.md que el resto del ciclo SDD asume. Sin esto, enrich-user-story frena.
argument-hint: "[existing | greenfield — autodetectado si se omite]"
---

# /sdd-init — Bootstrap de docs fundacionales SDD

Invocá el skill **`sdd-init`** para: **$ARGUMENTS**

Detectá si el repo tiene codebase (modo `existing`, derivar) o está vacío (modo `greenfield`, entrevistar). Chequeá primero si ya existe `docs/foundation/` (convención del skill `project-foundation`) para NO duplicar contenido — si `02-trd.md`/`05-backend-schema.md` ya están, `doc_architecture.md` los referencia en vez de repetirlos.

Escribí `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` completos (nunca dejes `[PLACEHOLDER]` sin llenar). Cerrá con la lista de "supuestos a confirmar" si derivaste del código.

No corras esto si el usuario no lo pidió explícitamente — `/sdd`/`/sdd-enrich` no disparan este comando solos.
