---
description: Genera o muestra el High-Level Technical Contract (HLTC) de la tarea actual.
argument-hint: "[slug de la tarea | requerimiento]"
---

# /sdd-contract — High-Level Technical Contract

Invocá el skill **`sdd-plan`** (modo contract) para: **$ARGUMENTS**

Producí un HLTC senior-reviewable con: Objective + out-of-scope, Public contract impact, Input/output exacto, Backward compatibility, **Architectural Delta** (API/Service/Domain/Repo/Integration/Tests/Ownership/Reuse), Artifact inventory, Source of truth, Error/fallback, Validation strategy (por escenario), Risks.

Aplicá las closure rules: nada de "if needed / or / prefer / may be". Si una decisión queda abierta → pregunta-bloqueo, no la cierres sola.

Single-writer: solo el planner edita `contract.md`. Bumpeá versión en cada cambio.
