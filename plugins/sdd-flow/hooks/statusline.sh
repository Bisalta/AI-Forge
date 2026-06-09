#!/usr/bin/env bash
# sdd-flow statusline — muestra fase SDD + agentes activos.
# Stub: lee .sdd/state.json del proyecto si existe. Cableo real en fase de implementacion.
set -euo pipefail

STATE_FILE=".sdd/state.json"
if [[ -f "$STATE_FILE" ]] && command -v python3 >/dev/null 2>&1; then
  python3 - "$STATE_FILE" <<'PY' 2>/dev/null || echo "[SDD]"
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
else
  echo "[SDD]"
fi
