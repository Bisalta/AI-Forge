---
description: Bootstrapea (o llena) los docs fundacionales SDD/docs/doc_architecture.md, doc_verification_guide.md y doc_quality_gates.md que el resto del ciclo SDD asume. Sin esto, enrich-user-story frena y los agentes inventan comandos de validacion.
argument-hint: "[existing | greenfield — autodetectado si se omite]"
---

# /sdd-init — Bootstrap de docs fundacionales SDD

Invocá el skill **`sdd-init`** para: **$ARGUMENTS**

Detectá si el repo tiene codebase (modo `existing`, derivar) o está vacío (modo `greenfield`, entrevistar). Chequeá primero si ya existe `docs/foundation/` (convención del skill `project-foundation`) para NO duplicar contenido — si `02-trd.md`/`05-backend-schema.md` ya están, `doc_architecture.md` los referencia en vez de repetirlos.

Escribí los tres archivos completos (nunca dejes `[PLACEHOLDER]` sin llenar): `doc_architecture.md` (dónde va el código), `doc_verification_guide.md` (qué conviene correr según qué cambié) y `doc_quality_gates.md` (la escalera obligatoria con los comandos **reales** del repo — un gate que no existe se declara `N/A`, nunca se inventa). Cerrá con la lista de "supuestos a confirmar" si derivaste del código.

No corras esto si el usuario no lo pidió explícitamente — `/sdd`/`/sdd-enrich` no disparan este comando solos.
