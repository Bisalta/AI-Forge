# Protocolo de coordinación multi-agente — sdd-flow

Coordinación async file-based entre N agentes Claude, cada uno trabajando en su propio repo/sesión. Sin canales real-time: todo pasa por archivos markdown en este directorio. Cualquier sesión (con o sin el plugin sdd-flow) puede participar leyendo este README.

## Estructura

```
sdd-coordination/
├── README.md                                ← este protocolo
└── tasks/<task-slug>/
    ├── contract.md                          ← contrato técnico (single-writer: solo el planner)
    ├── status.md                            ← tabla de estado, una fila por agente
    ├── logs/AGENT_<slug>.md                 ← log append-only por agente
    └── messages/AGENT_<a>__to__AGENT_<b>/   ← un dir por par direccional
        ├── NNN_<slug>.md                    ← mensajes activos (no procesados)
        └── archive/                         ← procesados
```

## Roles

- **Planner**: el agente que bootstrapeó la task. Único con permiso de escritura sobre `contract.md`. Cierra decisiones; los demás le preguntan.
- **Agente** (`AGENT_<slug>`): trabaja en su repo, implementa contra el contract, se comunica por mensajes.

## Mensajes

Archivo: `messages/AGENT_<a>__to__AGENT_<b>/NNN_<slug>.md` — `NNN` secuencia de 3 dígitos por dirección, continuando desde el máximo existente **incluyendo `archive/`**. Nunca saltear ni reusar números.

```md
---
id: 004
from: AGENT_be
to: AGENT_fe
ts: 2026-06-10T15:30:00Z
task: <task-slug>
in_reply_to: 003        # null si abre thread
needs_reply: true       # false si es FYI
priority: normal        # low | normal | high
---

# Asunto en una línea

Cuerpo específico: paths exactos, nombres de funciones, shapes de request/response,
hashes de commit, números de PR. Nada vago.

## Action requested
- [ ] TODO concreto 1
- [ ] TODO concreto 2

## Context
Snippets, referencias a mensajes previos, decisiones.
```

**Archive**: el RECEPTOR mueve el mensaje a `archive/` del mismo dir después de procesarlo. Mensaje fuera de archive = pendiente.

## Ownership 1-way (regla dura)

Cada agente escribe SOLO:
- sus outbox: `messages/AGENT_<self>__to__*/`
- su log: `logs/AGENT_<self>.md` (append-only, líneas con timestamp UTC)
- su fila en `status.md`
- `archive/` de sus inbox (mover mensajes procesados)

Todo lo demás es **read-only**. Editar el log, la fila de status o el outbox de otro agente rompe el protocolo.

## Contract — single-writer

- Solo el **planner** edita `contract.md`.
- Cualquier otro agente que necesite un cambio manda mensaje con slug `contract-change-request` describiendo el cambio exacto y por qué.
- El planner ratifica (o rechaza por mensaje), edita el contract, bumpea versión (v1→v2→…) y anota el cambio en el `## Changelog` del contract.
- Implementar contra una versión del contract distinta a la vigente = error del agente.
- Closure rules del contract: prohibido "if needed / or / prefer / may be / when available". Si dos ingenieros lo implementarían distinto, el contract está mal — mandar `contract-change-request`.

## Decisiones no resueltas → BLOCKED

Si una decisión necesaria no está en el contract: el agente pone su fila de `status.md` en `blocked`, manda mensaje al planner con la pregunta concreta, y NO avanza sobre esa parte. **Nunca adivinar.**

## status.md

| Estado | Significado |
|---|---|
| `idle` | sin trabajo activo en esta task |
| `working` | implementando |
| `waiting_reply` | mandó mensaje con `needs_reply: true`, espera |
| `blocked` | decisión abierta o dependencia externa — ver nota |
| `done` | su parte verificada y mergeada |

Actualizar la propia fila (estado + timestamp UTC + nota corta) al final de cada turno de trabajo.

## Branches y PRs (regla dura)

- **Todo trabajo va en branch propia — NUNCA commits directos a ramas normales** (`main`, `dev`, `qa`, …).
- La **rama base** de cada agente se declara en el contract (sección Agentes y repos o Contrato técnico); si no está declarada, el agente la propone al planner y espera confirmación antes de crear la branch.
- Branch:
  - **Con Proxima**: `{action}-{KEY}-{desc}` (`action ∈ feat|fix|chore|refactor|docs`, `KEY` = subtask Proxima del agente, ej. `feat-TRANS-24-add-endpoint`). El key sale de la tabla del contract (lo pone el planner ANTES de que el agente cree la branch).
  - **Sin Proxima**: `<MODULO>-<TICKET>` (sin ticket: `<MODULO>-<task-slug>`).
- **Integración SOLO vía PR** contra la base. El número/link del PR se informa por mensaje y se anota en el log propio.

## Proxima (single-writer)

- SOLO el **planner** llama al MCP `proxima` (crear tarea madre, subtasks, set_status, cerrar). Los agentes NO tocan Proxima.
- El agente reporta por mensaje + `status.md`: "PR abierto" (link), "CI verde", "PR mergeado". El planner traduce eso a Proxima.
- **Cierre por merge**: la subtask de un agente pasa a `done` cuando su PR se mergea; la tarea madre cuando todas las subtasks están `done`.

## Orden de integración

Si hay dependencias entre repos, el contract declara orden de **merge de PRs** (ej. PR de `AGENT_be` mergea primero, después el de `AGENT_fe`). No mergear fuera de orden.

## Turno de trabajo de un agente

1. Leer inbox (`messages/*__to__AGENT_<self>/`, sin archive) — procesar en orden de secuencia.
2. Leer `contract.md` (verificar versión) y `status.md`.
3. Investigar/implementar en su propio repo, según convenciones de ese repo — **siempre en su branch de trabajo, integrando vía PR**.
4. Responder con mensaje(s) numerado(s) — batchear: un mensaje por destinatario por turno, no spamear.
5. Archivar los mensajes procesados.
6. Apendear resumen del turno a su log.
7. Actualizar su fila de `status.md`.

## Anti-patrones

- Editar archivos de otro agente (log, fila de status, outbox ajeno).
- Saltear o reusar números de secuencia.
- Mensajes status-only en spam — el status va en `status.md`, los mensajes piden o informan cosas accionables.
- Mutar `contract.md` sin ser el planner.
- Dejar mensajes procesados sin archivar (el otro agente los re-procesa infinitamente).
- Adivinar ante ambigüedad en vez de bloquear y preguntar.
