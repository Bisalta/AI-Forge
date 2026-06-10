# /sdd-agents Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comando `/sdd-agents` que bootstrapea la estructura de coordinación file-based multi-agente (`AGENT_<slug>`) y entrega kickoff prompts por agente — cierra pendiente #2 del roadmap sdd-flow.

**Architecture:** Protocolo completo en `templates/coordination-README.md` (un solo lugar versionado, se copia al dir compartido). Comando markdown prompt-driven que resuelve dir, crea estructura idempotente, instancia esqueletos de contract/status/logs e imprime kickoffs. Cero código ejecutable nuevo.

**Tech Stack:** Markdown commands de Claude Code plugins, `claude plugin validate`, smoke test manual en `mktemp -d`.

**Spec:** `docs/specs/2026-06-10-sdd-agents-bootstrap-design.md`

---

### Task 1: Template del protocolo `templates/coordination-README.md`

**Files:**
- Create: `plugins/sdd-flow/templates/coordination-README.md`

- [ ] **Step 1: Crear archivo con el contenido del protocolo** (contenido completo en la sección "Contenido Template" al final de este plan — un solo bloque para no duplicarlo aquí; el ejecutor lo copia literal).

- [ ] **Step 2: Commit**

```bash
git add plugins/sdd-flow/templates/coordination-README.md
git commit -m "[ADD] [sdd-flow] Template protocolo de coordinacion multi-agente AGENT_<slug>

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Comando `commands/sdd-agents.md`

**Files:**
- Create: `plugins/sdd-flow/commands/sdd-agents.md` (contenido completo en sección "Contenido Comando" al final).

- [ ] **Step 1: Crear archivo del comando**

- [ ] **Step 2: Validar plugin**

Run: `claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow`
Expected: `✔ Validation passed`

- [ ] **Step 3: Commit**

```bash
git add plugins/sdd-flow/commands/sdd-agents.md
git commit -m "[ADD] [sdd-flow] Comando /sdd-agents — bootstrap de coordinacion multi-agente

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Smoke test estructural

- [ ] **Step 1: Simular bootstrap en dir temporal siguiendo las instrucciones del comando al pie de la letra** (agentes `fe` y `be`, task `demo`, dir compartido `<tmp>/sdd-coordination`). Crear: README copiado del template, `tasks/demo/contract.md`, `status.md`, `logs/AGENT_fe.md`, `logs/AGENT_be.md`, `messages/AGENT_fe__to__AGENT_be/archive/`, `messages/AGENT_be__to__AGENT_fe/archive/`.

- [ ] **Step 2: Verificar estructura**

```bash
find <tmp>/sdd-coordination -type d | sort
find <tmp>/sdd-coordination -type f | sort
```

Expected: 2 dirs de mensajes con sus archive, 2 logs, contract.md, status.md, README.md.

- [ ] **Step 3: Verificar idempotencia** — repetir bootstrap, confirmar que nada se pisa (mtimes intactos).

---

### Task 4: Release 0.3.0

**Files:**
- Modify: `plugins/sdd-flow/.claude-plugin/plugin.json` (`"version": "0.2.0"` → `"0.3.0"`)
- Modify: `CHANGELOG.md` (entrada 0.3.0 arriba de 0.2.0)
- Modify: `CLAUDE.md` (estructura: agregar `sdd-agents` a commands y `coordination-README.md` a templates; estado: v0.3.0, pendiente #2 cerrado)

- [ ] **Step 1: Bump + changelog**

```markdown
### 0.3.0 — 2026-06-10
- Nuevo comando `/sdd-agents`: bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) — estructura de task (contract single-writer, status, logs, mensajes numerados por par direccional) + kickoff prompts por agente. Cierra pendiente #2.
- Template `coordination-README.md`: protocolo completo generalizado a N agentes.
```

- [ ] **Step 2: Validar ambos manifests, commit `[REL]`, push, refresh clon marketplace**

```bash
claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow
claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge
git add -A && git commit -m "[REL] [sdd-flow] v0.3.0 — /sdd-agents bootstrap multi-agente

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push
git -C /Users/gabrielrojas/.claude/plugins/marketplaces/ai-forge pull
```

---

## Contenido Template (`templates/coordination-README.md`)

El ejecutor copia este bloque completo (sin el fence externo) al archivo. Ver archivo final en repo tras Task 1 — contenido canónico definido en la implementación, secciones obligatorias: Estructura, Mensajes (formato+frontmatter+secuencia), Archive, Ownership 1-way, Contract single-writer, BLOCKED, Orden de integración, Estados de status.md, Anti-patrones.

## Contenido Comando (`commands/sdd-agents.md`)

Ídem — secciones obligatorias: frontmatter (description, argument-hint), parseo de argumentos, resolución de dir, bootstrap idempotente con esqueletos exactos (contract v1, status, logs), pares ordenados de mensajes, inferencia del slug del planner por repo actual, output con kickoff prompts, regla "no spawnear".
