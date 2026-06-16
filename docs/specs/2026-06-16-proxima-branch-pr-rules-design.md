# Spec — Proxima tracking + regla branch/PR atada a task key (sdd-flow v0.5.0)

Fecha: 2026-06-16 · Proxima: GEN-30 · Branch: `feat-GEN-30-proxima-branch-rules`

## Problema

`sdd-flow` corre el ciclo SDD pero (a) no se engancha con Proxima para tracking de
tareas, y (b) su regla de branching no ata la branch a una tarea trazable. Falta una
disciplina dura: tarea Proxima → branch con el key → PR → cierre al mergear.

## Decisiones (cerradas, no re-litigar)

1. **Granularidad Proxima**: 1 **tarea madre** (la feature) + **1 subtask por agente**
   (`AGENT_{uuid}` = repo+branch). Cada branch usa el key de SU subtask.
2. **Formato de branch**: `{action}-{KEY}-{desc}` con `action ∈ feat|fix|chore|refactor|docs`.
   Ej. `feat-TRANS-24-add-endpoint`. Este formato **reemplaza** `<MODULO>-<TICKET>`
   cuando hay Proxima. **Fallback** sin Proxima / si el user declina: el viejo
   `<MODULO>-<TICKET>` (o `<MODULO>-<desc>`).
3. **Cierre de tarea**: subtask → `done` **al mergear su PR** (no en Feature Ready).
   Tarea madre → `done` cuando **todas** las subtasks están `done`.
4. **Detección de proyecto (Fase 0)**: auto si hay match único y claro (solo avisa);
   si hay varios candidatos → listar y pedir elegir.
5. **Quién llama al MCP**: **solo el planner** (centralizado). Crea madre+subtasks,
   setea estados y cierra. Los `implementing-agent` NO tocan Proxima: reportan
   estado/merge por el canal file-based y el planner ratifica. Consistente con el
   patrón single-writer del contract.
6. **Orden estricto**: tarea/subtask Proxima **primero** → branch **después**
   (el key debe existir para nombrar la branch).
7. **Base branch**: confirmar SIEMPRE antes de crear branch. Nunca commit/push directo
   a la base (`main`/`dev`/`qa`/...). Integración hacia la base de la que se copió.
8. **Capas de integración (flexibilidad por entorno)** — el flujo se adapta, detectando
   una vez al arrancar:
   - **git + remote** → branch + **PR** (capa completa).
   - **git sin remote** → branch + review obligatorio + **merge local `--no-ff`**
     (no hay PR; nunca commit directo a la base igual).
   - **no es git** → avisar y correr el ciclo SDD **sin** capa de branch/PR.
   Proxima es **ortogonal**: puede haber tracking en cualquier capa, o no haberlo en
   la capa con remote. El cierre de tarea se dispara por "integración" (PR mergeado o
   merge local), no específicamente por PR.

## Cambios por archivo

- **`commands/sdd.md`** — nueva **Fase 0: PROXIMA TRACKING** (detectar MCP → match
  proyecto → preguntar crear tareas → crear madre `in_progress`). Threading del key
  en Fase 3 (subtask por agente, branch con key) y Fase 4/5 (cierre al mergear).
- **`standards/base-standards.md`** — sección Git/branches: nuevo formato con KEY,
  fallback, regla de cierre por merge, MCP solo-planner.
- **`skills/sdd-plan/SKILL.md`** — cada task brief carga su `proxima_subtask_key` y la
  branch a usar; instrucción de crear subtask antes de la branch.
- **`agents/implementing-agent.md`** — crear branch con el key recibido en el brief;
  NO llamar a Proxima; reportar "PR abierto" / "PR mergeado" por el canal file-based.
- **`commands/sdd-agents.md`** + **`templates/coordination-README.md`** — branch naming
  con KEY y el campo `proxima_subtask_key` por agente en el status board.
- **`commands/sdd-fixes.md`** — alinear su regla de branch al nuevo formato.
- **`CLAUDE.md`** (raíz) + **`CHANGELOG.md`** + `plugin.json` — bump a **v0.5.0**.

## Fuera de scope

- Cablear el orquestador real `/sdd` (spawning de subagentes) — sigue pendiente #1.
- statusline leyendo estado real — pendiente #3.

## Verificación

- `plugin.json` valida (versión bump).
- Lectura cruzada: el formato de branch y la regla de cierre son idénticos en
  standards, sdd.md, sdd-plan, implementing-agent, sdd-agents, coordination-README,
  sdd-fixes (sin contradicción).
- Closure check: ningún "if needed / or / may" en las reglas nuevas.
