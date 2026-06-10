# /sdd-fixes Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comando `/sdd-fixes` que estructura tandas de fixes en `fixes.md` (intake+triage+abrir editor) y badge `⚡ fixes N/M` en la statusline del plugin sdd-flow.

**Architecture:** Dos piezas independientes dentro de `plugins/sdd-flow/`: (1) un command markdown nuevo (prompt puro, sin código ejecutable) que define el flujo bootstrap→intake→triage→abrir; (2) extensión del hook `statusline.sh` que parsea `fixes.md` del cwd con grep. El archivo `fixes.md` en el repo de trabajo es la única fuente de verdad.

**Tech Stack:** Markdown commands de Claude Code plugins, bash (statusline hook), `claude plugin validate` como verificación.

**Spec:** `docs/specs/2026-06-09-sdd-fixes-command-design.md`

---

### Task 1: Command `commands/sdd-fixes.md`

**Files:**
- Create: `plugins/sdd-flow/commands/sdd-fixes.md`

- [ ] **Step 1: Crear el archivo del comando con este contenido exacto**

````markdown
---
description: Estructura una tanda de fixes/ajustes en fixes.md — intake, triage automático y visualizador editable. No implementa nada hasta orden explícita.
argument-hint: "[lista cruda de fixes/ajustes — o vacío para solo crear/abrir fixes.md]"
---

# /sdd-fixes — Batch de fixes con triage

Gestioná la tanda de fixes del repo actual sobre el archivo `fixes.md` (raíz del repo). Input del usuario: **$ARGUMENTS**

## 1. Bootstrap

Si NO existe `fixes.md` en la raíz del repo actual, crealo con este template (completá fecha y repos reales — preguntá paths de otros repos solo si algún item los requiere):

```markdown
# Batch fixes — <YYYY-MM>
Repos:
- <rol>: <path absoluto>

<!-- Estados válidos: pendiente | en-curso | hecho | bloqueado -->
```

## 2. Intake (solo si hay argumentos)

Parseá la lista cruda del usuario. Cada item → bloque:

```markdown
## F-NN — <título corto imperativo>
- Tipo: bug | visual | interacción | mejora
- Repo: front | back | ambos
- Triage: trivial | mediano | ambiguo
- Estado: pendiente
- Detalle: <repro / esperado vs actual / descripción>
```

Reglas:
- IDs `F-01, F-02, …` secuenciales. Si ya hay items, continuá desde el máximo existente. NUNCA renumeres items existentes — re-invocación = append.
- **Triage**: `trivial` = fix directo en un repo, sin diagnóstico. `mediano` = requiere diagnóstico o toca varias piezas de un repo. `ambiguo` = decisiones de diseño abiertas O acoplado front+back (cambio de contrato/endpoint).
- A cada item `ambiguo` agregale: `- Sugerencia: cerrar con /sdd-enrich antes de implementar`.
- Si un item no da info para clasificar Tipo/Repo, poné tu mejor inferencia — no interrogues al usuario por cada item.

## 3. Abrir visualizador

Abrí `fixes.md` para edición lateral, en este orden de preferencia:
1. `command -v code` disponible → `code <path absoluto>/fixes.md`
2. macOS → `open <path absoluto>/fixes.md`
3. Fallback → mostrale el path absoluto al usuario.

## 4. Cierre — NO implementes nada

Terminá mostrando: tabla resumen (ID, título, triage, repo) + conteo por triage + recordatorio de que el badge `⚡ fixes N/M` aparece en la statusline.

**Prohibido tocar código de fixes en esta invocación.** Esperá orden explícita ("dale con F-03", "arrancá en orden").

## Reglas para el resto de la sesión (al trabajar items)

- Antes de arrancar un item: `Estado: en-curso` en `fixes.md`.
- Item terminado y verificado: `Estado: hecho`. Bloqueado: `Estado: bloqueado` + nota del motivo en `Detalle`.
- Un commit por item, convención `[FIX] [Módulo] [Descripción]` (o `[IMP]` para mejoras).
- Items `Repo: ambos`: primero back, después front; commit por repo.
- Item `ambiguo` sin cerrar: NO adivines — usá `/sdd-enrich` o preguntá.
- El usuario puede editar `fixes.md` a mano en cualquier momento: releelo del disco antes de cada item.
````

- [ ] **Step 2: Validar manifest del plugin**

Run: `claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow`
Expected: `✔ Validation passed`

- [ ] **Step 3: Commit**

```bash
git add plugins/sdd-flow/commands/sdd-fixes.md
git commit -m "[ADD] [sdd-flow] Comando /sdd-fixes — intake+triage de batch de fixes con visualizador

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Badge `⚡ fixes N/M` en statusline

**Files:**
- Modify: `plugins/sdd-flow/hooks/statusline.sh` (reescritura completa, 27 líneas actuales)

- [ ] **Step 1: Test manual ANTES del cambio — capturar comportamiento actual**

```bash
cd "$(mktemp -d)"
printf '## F-01 — a\n- Estado: hecho\n## F-02 — b\n- Estado: pendiente\n## F-03 — c\n- Estado: en-curso\n' > fixes.md
bash /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow/hooks/statusline.sh
```

Expected (actual, pre-cambio): `[SDD]` — el badge de fixes NO existe todavía. Esto es el "test que falla".

- [ ] **Step 2: Reemplazar contenido completo de `statusline.sh` con:**

```bash
#!/usr/bin/env bash
# sdd-flow statusline — badge de fase SDD + badge de batch fixes.
# Lee .sdd/state.json (pipeline SDD) y fixes.md (batch de fixes) del cwd del proyecto.
set -euo pipefail

parts=()

STATE_FILE=".sdd/state.json"
if [[ -f "$STATE_FILE" ]] && command -v python3 >/dev/null 2>&1; then
  sdd_badge=$(python3 - "$STATE_FILE" <<'PY' 2>/dev/null || echo "[SDD]"
import json, sys
try:
    s = json.load(open(sys.argv[1]))
    phase = s.get("phase", "?")
    total = s.get("phases_total", 5)
    agents = s.get("agents_active", 0)
    blocked = s.get("blocked", 0)
    badge = f"[SDD · fase {phase}/{total} · {agents} agentes"
    if blocked:
        badge += f" · ⛔{blocked}"
    badge += "]"
    print(badge)
except Exception:
    print("[SDD]")
PY
)
  parts+=("$sdd_badge")
fi

FIXES_FILE="fixes.md"
if [[ -f "$FIXES_FILE" ]]; then
  total=$(grep -c '^- Estado:' "$FIXES_FILE" || true)
  hechos=$(grep -c '^- Estado: hecho' "$FIXES_FILE" || true)
  if [[ "${total:-0}" -gt 0 ]]; then
    parts+=("⚡ fixes ${hechos:-0}/${total}")
  fi
fi

if [[ ${#parts[@]} -gt 0 ]]; then
  out="${parts[0]}"
  for p in "${parts[@]:1}"; do out="$out · $p"; done
  echo "$out"
else
  echo "[SDD]"
fi
```

Nota técnica: `grep -c` imprime `0` pero sale con exit code 1 cuando no hay matches; el `|| true` evita que `set -e` aborte mientras la sustitución captura el `0` igual.

- [ ] **Step 3: Test post-cambio — solo fixes.md**

```bash
cd "$(mktemp -d)"
printf '## F-01 — a\n- Estado: hecho\n## F-02 — b\n- Estado: pendiente\n## F-03 — c\n- Estado: en-curso\n' > fixes.md
bash /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow/hooks/statusline.sh
```

Expected: `⚡ fixes 1/3`

- [ ] **Step 4: Test — fixes.md + state.json juntos**

```bash
mkdir -p .sdd && printf '{"phase": 2, "phases_total": 5, "agents_active": 3, "blocked": 0}' > .sdd/state.json
bash /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow/hooks/statusline.sh
```

Expected: `[SDD · fase 2/5 · 3 agentes] · ⚡ fixes 1/3`

- [ ] **Step 5: Test — directorio vacío (sin fixes.md ni state.json)**

```bash
cd "$(mktemp -d)"
bash /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow/hooks/statusline.sh
```

Expected: `[SDD]` (comportamiento original preservado)

- [ ] **Step 6: Commit**

```bash
cd /Users/gabrielrojas/Desktop/Repos/ai-forge
git add plugins/sdd-flow/hooks/statusline.sh
git commit -m "[IMP] [sdd-flow] Statusline: badge de progreso de fixes.md

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Versionado, changelog y release

**Files:**
- Modify: `plugins/sdd-flow/.claude-plugin/plugin.json` (línea `"version": "0.1.1"`)
- Modify: `CHANGELOG.md` (insertar sección bajo `## sdd-flow`)

- [ ] **Step 1: Bump versión a 0.2.0**

En `plugins/sdd-flow/.claude-plugin/plugin.json`: `"version": "0.1.1"` → `"version": "0.2.0"`.

- [ ] **Step 2: Agregar entrada al CHANGELOG (arriba de `### 0.1.1`, debajo de `## sdd-flow`)**

```markdown
### 0.2.0 — 2026-06-09
- Nuevo comando `/sdd-fixes`: estructura tandas de fixes/ajustes en `fixes.md` con intake, triage automático (trivial/mediano/ambiguo) y apertura del archivo como visualizador lateral editable. No implementa hasta orden explícita.
- Statusline: badge `⚡ fixes N/M` con progreso del batch, combinable con el badge SDD existente.
```

- [ ] **Step 3: Validar plugin + marketplace**

```bash
claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge/plugins/sdd-flow
claude plugin validate /Users/gabrielrojas/Desktop/Repos/ai-forge
```

Expected: ambos `✔ Validation passed`

- [ ] **Step 4: Commit + push**

```bash
git add plugins/sdd-flow/.claude-plugin/plugin.json CHANGELOG.md
git commit -m "[REL] [sdd-flow] v0.2.0 — comando /sdd-fixes + badge statusline

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
git push
```

- [ ] **Step 5: Actualizar clon local del marketplace (para que el install vea 0.2.0)**

```bash
git -C /Users/gabrielrojas/.claude/plugins/marketplaces/ai-forge pull
```

Expected: fast-forward al commit de release.
