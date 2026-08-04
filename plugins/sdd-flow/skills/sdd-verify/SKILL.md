---
name: sdd-verify
description: Corre la escalera de gates de calidad (format, lint, type-check, unit, integration, build, e2e, cobertura del diff, security) sobre el trabajo actual y produce el verification report con comandos, exit codes y output real. Usar antes de declarar una tarea done, antes de abrir PR, o cuando alguien pregunta si algo esta probado.
---

# SDD Verify — correr los gates y dejar evidencia

Convertís "creo que está probado" en un artefacto auditable. **No implementás features y no arreglás el diseño**: corrés gates, registrás resultados y reportás lo que falta. Si un gate se pone rojo, podés arreglar la causa si es trivial y está dentro del scope del trabajo actual; si no, lo reportás como bloqueo.

Normativa: `standards/quality-gates.md`. Comandos del repo: `SDD/docs/doc_quality_gates.md`.

## Paso 0 — Resolver la escalera

1. Leé `SDD/docs/doc_quality_gates.md`. Si **no existe**: no inventes comandos. Derivalos ahora del repo (`package.json` scripts, `Makefile`, `pyproject.toml`, `*.csproj`, config de CI) y avisá al usuario que conviene correr `/sdd-init` para persistirlos — pero seguí adelante con lo derivado, anotando en el reporte que la escalera fue derivada y no está persistida.
2. Identificá el alcance a verificar: diff contra la rama base (`git diff --name-only <base>...HEAD`) más el working tree sucio. Si no es un repo git, verificá el árbol completo y decilo.
3. Determiná qué gates aplican: los que el repo no tiene son `N/A` con razón; e2e sólo si un AC lo exige o cambió un flujo de usuario.

## Paso 1 — Correr la escalera en orden

Orden fijo de `quality-gates.md` §4: format → lint → type-check → unit → integration → build → e2e → cobertura del diff → security. **Corta al primer rojo**: arreglá o reportá, y reiniciá desde ese escalón — no sigas corriendo escalones caros sobre un árbol que ya sabés roto.

Por cada gate registrá: comando exacto, exit code, timestamp UTC, últimas ~15 líneas de output relevante. Nunca resumas un output como "verde" sin haber capturado el exit code.

Antes de declarar terminado, corré la **suite completa** al menos una vez (no sólo el filtro por área).

## Paso 2 — Distinguir rojo propio de rojo preexistente

Si algo falla y no parece relacionado con el diff: corré ese mismo gate en la rama base (`git stash` o worktree separado) y anotá el resultado. Un rojo que también falla en la base se reporta como **preexistente**, con el sha de la base — no se arregla de contrabando ni se declara como culpa del trabajo actual.

## Paso 3 — Chequeos mecánicos sobre el diff

Aunque los gates estén verdes, corré `SDD/scripts/sdd-check.sh <base>` si existe (lo instala `/sdd-init`; exit 2 = BLOCKERs candidatos — confirmá cada uno contra el contract). Complementá con lo que el script no cubre (`quality-gates.md` §7.1):

1. ¿Se aflojó alguna assertion existente (`toEqual` → `toBeTruthy`, tolerancias, casos borrados de table tests)?
2. ¿Cada test declarado en el binding AC↔test existe literal en su archivo?
3. ¿Hay archivo nuevo/modificado sin ningún test que lo ejercite?

Sin el script, hacé también sus greps a mano (tests skipeados/eliminados, supresores, `any` nuevo, configs ablandadas).

Un hallazgo acá pesa más que un gate verde: el gate verde puede ser consecuencia del hallazgo.

## Paso 4 — Escribir el reporte

Escribí (o actualizá) el verification report siguiendo `templates/verification-report.md`:

- Multi-agente: `tasks/<task-slug>/verification/AGENT_<slug>.md` en el directorio de coordinación (un archivo por agente — el ownership 1-way del protocolo no permite escribir en el del otro).
- Single-repo / sin coordinación: `SDD/verification/<branch>.md`.

Incluí siempre: tabla de gates con exit codes, impact set, rojos preexistentes, y — si es bugfix — las dos corridas del test de reproducción.

## Paso 5 — Veredicto

Cerrá con un veredicto corto y honesto:

- `GATES VERDES` — todos los aplicables en verde, con evidencia; listo para review/PR.
- `GATES ROJOS` — lista de fallas con archivo:línea y qué falta para cerrarlas.
- `EVIDENCIA INCOMPLETA` — corrió menos de lo necesario (prerequisito faltante, comando ausente, AC sin test). Decí exactamente qué falta.

Nunca cierres en verde con un gate `[SKIPPED]` sin decirlo en la primera línea del veredicto.

## Reglas

- **Nunca declares un gate que no corriste.** Es la única regla que no tiene excepción.
- No ablandes un gate para que pase (ver mitigaciones prohibidas, `quality-gates.md` §6). Si no se puede pasar, es un bloqueo, no un threshold.
- No refactorices de paso: tu output es evidencia, no un diff nuevo.
- Respondé siempre en el idioma del usuario.
