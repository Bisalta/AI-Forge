---
description: Corre la escalera de gates de calidad sobre el trabajo actual (format, lint, type-check, tests, build, cobertura del diff, security) y escribe el verification report con comandos y exit codes reales.
argument-hint: "[area o filtro opcional — por default, el diff contra la rama base]"
---

# /sdd-verify — Gates de calidad + evidencia

Invocá el skill **`sdd-verify`** para: **$ARGUMENTS**

Leé `SDD/docs/doc_quality_gates.md` para los comandos reales del repo (si no existe, derivalos del repo y avisá que conviene correr `/sdd-init` para persistirlos). Corré la escalera en el orden fijo de `standards/quality-gates.md` §4, cortando al primer rojo.

Registrá comando exacto + exit code + output por cada gate en el verification report (`templates/verification-report.md`). Corré también los chequeos mecánicos del §7.1 sobre el diff: tests borrados/skipeados, markers prohibidos, binding AC↔test, archivos sin cobertura.

Cerrá con veredicto: `GATES VERDES` · `GATES ROJOS` · `EVIDENCIA INCOMPLETA`. **Nunca declares un gate que no corriste.**
