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
