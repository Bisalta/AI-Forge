# Changelog

Cambios del marketplace `ai-forge`. Orden descendente (lo más reciente primero).

## sdd-flow

### 0.5.0 — 2026-06-16
- **Integración Proxima**: nueva Fase 0 en `/sdd` — detecta el MCP `proxima`, matchea proyecto (auto si único, pregunta si ambiguo), pregunta al usuario si crear tareas y crea la **tarea madre** `in_progress`. En Fase 3, **subtask por agente** (`parentKey`); cada branch usa el key de su subtask. **Single-writer Proxima**: solo el planner llama al MCP; los implementing-agents reportan estado por el canal file-based.
- **Branch atada al task key**: nuevo formato `{action}-{KEY_MADRE}-{agente}-{desc}` (single-repo sin slug) que reemplaza `<MODULO>-<TICKET>` cuando hay Proxima; fallback al viejo formato sin Proxima. Orden estricto: tarea Proxima primero → branch después. Nota: las subtasks Proxima no tienen key (solo UUID) — la branch usa siempre el key de la tarea madre; las subtasks se cierran por su UUID.
- **Cierre por integración**: subtask → `done` cuando se integra (no en Feature Ready); tarea madre → `done` cuando todas las subtasks están `done`.
- **Capas de integración (flexibilidad por entorno)**: el flujo se adapta — git+remote → PR; git sin remote → branch + review + merge local `--no-ff`; no-git → corre el ciclo sin capa de branch/PR. Proxima es ortogonal a la capa (sirve en local, sin remote, o sin git). Funciona también sin el MCP `proxima` configurado (Fase 0 cae a fallback).
- Aplicado en `commands/sdd.md`, `standards/base-standards.md`, `skills/sdd-plan`, `agents/implementing-agent`, `commands/sdd-agents` (columnas Proxima key / Branch en el contract + kickoff), `templates/coordination-README.md` (sección Proxima single-writer) y `commands/sdd-fixes`. Spec en `docs/specs/2026-06-16-proxima-branch-pr-rules-design.md`.

### 0.4.0 — 2026-06-10
- Regla dura de branching en todo el flujo: cada feature/fix nace en branch propia (`<MODULO>-<TICKET>`), rama base elegida y confirmada siempre, NUNCA commits directos a ramas normales, integración SOLO vía PR. Aplicada en `base-standards.md`, `/sdd-fixes` (branch+PR por item), protocolo de coordinación (`coordination-README.md`) y kickoffs de `/sdd-agents` (rama base declarada en contract).

### 0.3.0 — 2026-06-10
- Nuevo comando `/sdd-agents`: bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) — estructura de task (contract single-writer, status, logs, mensajes numerados por par direccional) + kickoff prompts por agente. Cierra pendiente #2 del roadmap.
- Template `coordination-README.md`: protocolo completo generalizado a N agentes (mensajes con frontmatter, archive, ownership 1-way, BLOCKED ante ambigüedad, orden de integración).

### 0.2.0 — 2026-06-09
- Nuevo comando `/sdd-fixes`: estructura tandas de fixes/ajustes en `fixes.md` con intake, triage automático (trivial/mediano/ambiguo) y apertura del archivo como visualizador lateral editable. No implementa hasta orden explícita.
- Statusline: badge `⚡ fixes N/M` con progreso del batch, combinable con el badge SDD existente.

### 0.1.1 — 2026-06-09
- Fix: manifest `plugin.json` inválido bloqueaba `/plugin install` (`agents: Invalid input`). Se eliminan las claves `commands`/`skills`/`agents` — apuntaban a los directorios default que Claude Code auto-descubre, y el schema de `agents` espera array de archivos, no string de directorio.

### 0.1.0 — 2026-06-09
- Esqueleto inicial del plugin SDD multi-agente.
- Comandos: `/sdd`, `/sdd-enrich`, `/sdd-contract`, `/sdd-status`, `/sdd-pr`.
- Skills: `enrich-user-story`, `sdd-plan`, `write-pr-report`.
- Agentes: `implementing-agent` (Sonnet), `reviewer-agent` (Opus).
- Hook statusline + standards + templates de contexto.
- Pendiente: cableo del orquestador real (spawn de subagentes, protocolo `AGENT_{uuid}`).
