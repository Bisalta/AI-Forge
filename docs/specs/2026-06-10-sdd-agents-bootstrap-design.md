# Design: comando `/sdd-agents` — bootstrap de coordinación multi-agente

**Fecha**: 2026-06-10 · **Plugin**: sdd-flow · **Versión target**: 0.3.0 · **Cierra**: pendiente #2 del roadmap (bootstrap `AGENT_{uuid}`)

## Problema

El protocolo de coordinación file-based entre agentes (front/back/mobile) existe solo como instalación manual hardcodeada (`cross_agent_implementations/`, BE/FE fijos, paths de una sola máquina). El plugin describe la topología `AGENT_{uuid}` pero no tiene nada ejecutable: una sesión a la que se le dice "coordiná vía sdd-flow" no encuentra mecanismo y improvisa.

## Solución

### Comando `/sdd-agents <task-slug> <agente>=<path-repo> ... [dir-compartido]`

Archivo: `plugins/sdd-flow/commands/sdd-agents.md`. Prompt-driven (sin script).

Ejemplo: `/sdd-agents dispatch-validation fe=/Users/x/Repos/Transportes be=/Users/x/Repos/Transportes-Backend`

Comportamiento:

1. **Resolver dir compartido**: último argumento si es un path absoluto a directorio; sino default `<directorio padre del repo actual>/sdd-coordination/`.
2. **Bootstrap idempotente**:
   - `README.md` del dir compartido: copiar desde template del plugin SOLO si no existe.
   - `tasks/<task-slug>/`: si ya existe, NO pisar nada — informar y mostrar kickoffs igual.
   - Crear:
     ```
     <dir>/
     ├── README.md                              ← protocolo (template del plugin)
     └── tasks/<task-slug>/
         ├── contract.md                        ← esqueleto v1
         ├── status.md                          ← tabla por agente
         ├── logs/AGENT_<slug>.md               ← uno por agente declarado
         └── messages/AGENT_<a>__to__AGENT_<b>/ ← TODOS los pares ordenados
             └── archive/                         entre agentes declarados
     ```
3. **Roles**: la sesión que corre el comando = **planner** y dueña única de `contract.md`. El planner es además uno de los agentes declarados (su slug se infiere del repo actual; si el repo actual no matchea ningún path declarado, preguntar al usuario cuál es).
4. **Output**: resumen de estructura creada + un **kickoff prompt por agente remoto**, listo para pegar en la otra sesión:
   > Sos `AGENT_<slug>` (repo `<path>`). Dir de coordinación: `<dir>/tasks/<task-slug>/`. Leé primero `<dir>/README.md` (protocolo — obligatorio) y `contract.md`. Tu inbox: `messages/AGENT_*__to__AGENT_<slug>/` (sin archive). Por turno: leé inbox → investigá/implementá en tu repo → respondé con mensaje numerado → archivá lo procesado → actualizá tu log (`logs/AGENT_<slug>.md`) y tu fila en `status.md`.
5. **NO spawnea sesiones** — las abre el usuario (spawn real = pendiente #1, fuera de scope).

### Template `templates/coordination-README.md`

Protocolo completo, generalización a N agentes del protocolo cross-agent probado:

- **Mensajes**: `messages/AGENT_<a>__to__AGENT_<b>/NNN_<slug>.md`, secuencia 3 dígitos por dirección (contando archive), frontmatter: `id, from, to, ts (ISO UTC), task, in_reply_to (null si nuevo), needs_reply (bool), priority (low|normal|high)`. Cuerpo: asunto, detalle con paths/shapes/commits exactos, `## Action requested` con checkboxes.
- **Archive**: el receptor mueve el mensaje a `archive/` del mismo dir tras procesarlo.
- **Ownership 1-way**: cada agente escribe SOLO sus outbox (`AGENT_<self>__to__*`), su log (`logs/AGENT_<self>.md`) y su fila de `status.md`. Todo lo demás es read-only.
- **Contract single-writer**: solo el planner edita `contract.md`. Cambios: cualquier agente manda mensaje `contract-change-request`; el planner ratifica, edita y bumpea versión (v1→vN) anotando changelog al pie del contract. Prohibido editar el contract sin ser planner.
- **Decisión no resuelta**: agente pone su fila de status en `BLOCKED` + mensaje al planner. NUNCA adivinar.
- **Orden de integración**: si hay dependencia entre repos, el contract declara orden de merge (ej. BE→FE).
- **Anti-patrones**: editar log/fila ajena, saltear números de secuencia, spamear mensajes status-only (batchear por turno), mutar contract sin ser planner, no archivar procesados.

### Esqueletos generados por el comando (definidos en el comando, no en template aparte)

`contract.md`:
```markdown
# Contract: <task-slug> — v1
Owner (planner): AGENT_<slug-planner> · Estado: DRAFT

## Objetivo
<qué resuelve esta tarea multi-agente>

## Agentes y repos
| Agente | Repo | Responsabilidad |

## Contrato técnico
<endpoints/shapes/interfaces exactos — sin "if needed/or/prefer/may be">

## Orden de integración
<ej. AGENT_be merge primero, después AGENT_fe>

## Changelog
- v1 (<fecha>): inicial
```

`status.md`:
```markdown
# Status: <task-slug>
| Agente | Estado | Último update (UTC) | Nota |
|---|---|---|---|
| AGENT_<a> | idle | <ts> | bootstrap |
| AGENT_<b> | idle | <ts> | bootstrap |
```
Estados: `idle | working | waiting_reply | blocked | done`.

`logs/AGENT_<slug>.md`: header + líneas timestamped append-only.

## Fuera de scope

- Spawn real de sesiones/subagentes (pendiente #1).
- Escritura de `.sdd/state.json` para statusline (pendiente #3).
- Migración del dir viejo `cross_agent_implementations/` (sigue funcionando para tareas en curso).
- Monitor/polling event-driven (cada sesión puede armar su loop; no se empaqueta hoy).

## Decisiones cerradas

- Dir compartido: argumento opcional; default `<padre del repo actual>/sdd-coordination/`.
- Naming: `AGENT_<slug>` legible (fe, be, mobile…) — el `{uuid}` del diseño se satisface con slug único por task.
- Alcance: bootstrap + kickoff prompts. Sin `/sdd-inbox`, sin monitor.
- Protocolo en template del plugin (un solo lugar versionado); README copiado al dir compartido para que sesiones sin el plugin puedan seguirlo.
- Planner = sesión que corre el comando = único writer del contract.
- Bootstrap idempotente: nunca pisa task existente.

## Criterios de éxito

- `/sdd-agents demo fe=<path1> be=<path2>` en repo cuyo padre es `Repos/` → crea `Repos/sdd-coordination/` con README + task `demo` completa (contract, status, 2 logs, 2 dirs de mensajes con archive) + imprime kickoff para `AGENT_be`.
- Re-invocar mismo comando → no pisa nada, re-imprime kickoffs.
- 3 agentes declarados → 6 dirs de mensajes (pares ordenados).
- `claude plugin validate` pasa.
