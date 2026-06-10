# Changelog

Cambios del marketplace `ai-forge`. Orden descendente (lo más reciente primero).

## sdd-flow

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
