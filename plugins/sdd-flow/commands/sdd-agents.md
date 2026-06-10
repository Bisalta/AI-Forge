---
description: Bootstrapea coordinación file-based multi-agente (AGENT_<slug>) para una task multi-repo — estructura de contract/status/logs/mensajes + kickoff prompts por agente.
argument-hint: "<task-slug> <agente>=<path-repo> <agente>=<path-repo> ... [path dir compartido]"
---

# /sdd-agents — Bootstrap de coordinación multi-agente

Creá la infraestructura de coordinación para una task que cruza repos. Input: **$ARGUMENTS**

## 1. Parsear argumentos

- Primer token: `<task-slug>` (kebab-case).
- Tokens `nombre=path`: agentes — `nombre` se vuelve `AGENT_<nombre>`, `path` es el repo absoluto de ese agente.
- Último token sin `=`, si es path absoluto: dir compartido. Si no se dio: usar `<directorio padre del repo actual>/sdd-coordination/`.
- Mínimo 2 agentes. Si falta algo, preguntá UNA vez con todo lo que falte.

## 2. Identificar al planner

La sesión que corre este comando es el **planner** (único writer de `contract.md`). Su slug: el agente cuyo `path` matchea el repo actual. Si ninguno matchea, preguntale al usuario cuál de los agentes declarados es esta sesión.

## 3. Bootstrap (idempotente — NUNCA pisar lo existente)

Con `<dir>` = dir compartido y `<slug>` = task-slug:

1. `<dir>/README.md`: si no existe, copialo desde el template del plugin `templates/coordination-README.md` (resolvé el path del plugin instalado; si no lo encontrás, reproducí el protocolo desde tu conocimiento de este comando indicando versión). Si existe, no lo toques.
2. Si `<dir>/tasks/<slug>/` ya existe: NO crees ni modifiques nada de esa task — informá que ya estaba bootstrapeada y saltá al paso 4.
3. Crear:
   - `<dir>/tasks/<slug>/contract.md`:
     ```markdown
     # Contract: <slug> — v1
     Owner (planner): AGENT_<planner> · Estado: DRAFT

     ## Objetivo
     <qué resuelve esta task multi-agente — completalo con lo que sepas del contexto de la sesión; si no hay contexto, dejá la pregunta explícita al usuario>

     ## Agentes y repos
     | Agente | Repo | Rama base | Responsabilidad |
     |---|---|---|---|
     | AGENT_<a> | <path> | <dev si existe, sino default — confirmar con usuario> | <inferida o pendiente> |

     ## Contrato técnico
     <endpoints/shapes/interfaces EXACTOS. Closure rules: prohibido "if needed/or/prefer/may be". DRAFT hasta que el planner lo cierre.>

     ## Orden de integración
     <ej. AGENT_be mergea primero, AGENT_fe después — o "sin dependencia de merge">

     ## Changelog
     - v1 (<fecha UTC>): inicial
     ```
   - `<dir>/tasks/<slug>/status.md`:
     ```markdown
     # Status: <slug>
     | Agente | Estado | Último update (UTC) | Nota |
     |---|---|---|---|
     | AGENT_<a> | idle | <ts> | bootstrap |
     ```
     (una fila por agente; estados válidos: `idle | working | waiting_reply | blocked | done`)
   - `<dir>/tasks/<slug>/logs/AGENT_<x>.md` por cada agente:
     ```markdown
     # Log AGENT_<x> — task <slug>
     - <ts UTC> · bootstrap
     ```
   - `<dir>/tasks/<slug>/messages/AGENT_<a>__to__AGENT_<b>/archive/` por **cada par ordenado** de agentes declarados (N agentes → N×(N−1) dirs).

## 4. Output

Mostrá:

1. **Árbol** de lo creado (o "ya existía" por pieza).
2. **Kickoff prompt por cada agente que NO es esta sesión**, en bloque copiable:

   > Sos `AGENT_<x>` (repo `<path>`). Coordinación multi-agente en `<dir>/tasks/<slug>/`. Leé PRIMERO `<dir>/README.md` — protocolo obligatorio — y después `contract.md` (verificá versión vigente). Tu inbox: `<dir>/tasks/<slug>/messages/AGENT_*__to__AGENT_<x>/` (lo que no esté en `archive/`). Por turno: leé inbox en orden → trabajá en tu repo → respondé con mensaje numerado → mové procesados a `archive/` → apendeá a `logs/AGENT_<x>.md` → actualizá tu fila de `status.md`. **Todo tu trabajo va en branch propia desde la rama base que declara el contract (si no está declarada, proponela al planner y esperá confirmación) — NUNCA commits directos a ramas normales; integrás SOLO vía PR y reportás el link por mensaje.** Ante decisión no cubierta por el contract: fila en `blocked` + mensaje al planner (`AGENT_<planner>`). NUNCA adivines. El contract lo edita SOLO el planner — pedí cambios con mensaje `contract-change-request`.

3. Recordatorio al planner (esta sesión): sos dueño de `contract.md` — cerralo (DRAFT → CLOSED) antes de que los agentes implementen; primer paso típico: mandar mensaje kickoff `001` a cada agente con el alcance de su parte.

## Reglas

- Este comando NO spawnea sesiones ni subagentes — el usuario abre cada sesión y pega su kickoff.
- NO implementes nada de la task en esta invocación.
- Si el usuario después pide "atendé el inbox", seguí el protocolo del README del dir compartido.
