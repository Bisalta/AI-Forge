---
description: Genera la descripcion de Pull Request a partir de los cambios actuales del repo.
---

# /sdd-pr — Pull Request Report

Invocá el skill **`write-pr-report`**. Generá una descripción de PR concisa (150-300 palabras), reviewer-friendly, agrupada por área (API/Services/Domain/Tests).

No expongas artefactos internos (`tasks_for_AI`, specs, "execution report", "AI-generated"). Estructura fija: Summary / What Changed / Validation (Automated+Manual) / Reviewer Notes / Risks / Rollback.
