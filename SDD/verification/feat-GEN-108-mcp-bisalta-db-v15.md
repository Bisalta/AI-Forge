# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `2d5582b` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-23T17:36:22Z
- Tree: `0be1146c9f52c46ed6297f1d1455a5a09541e9fd` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-23T17:35:15Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-23T17:35:15Z | verde |
| 3 | type-check | — | — | 2026-09-23T17:35:16Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-23T17:35:16Z | verde |
| 5 | integration | — | — | 2026-09-23T17:35:50Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-23T17:35:50Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-23T17:35:50Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-23T17:35:50Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-23T17:35:50Z | verde |
| 10 | smoke manual | — | — | 2026-09-23T17:35:51Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-23T17:35:51Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 164 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_lista_blanca.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_servidor_mcp.sh
PASS  test_usage_summary.sh
---
17 passed, 0 failed (17 total)
```


---

# Addendum del planner — ciclo corto de v15 (NO lo escribió el runner)

Todo lo que sigue a esta línea lo escribió el planner. Lo de arriba es del runner y no se tocó.

**Alcance**: los commits posteriores al último `APPROVED` de R1 (`2529071`) que corrigen artefactos ya aprobados — `2583be1`, `047643c`, `5e29179`, `b711c18` y `2d5582b`. Por `quality-gates.md` §7.5 vuelven al loop: este reporte es el insumo de esa review, no su veredicto.

## 1. Triples de mutación — salida literal del script, re-ejecutado el 23-sep-2026

Las cuatro mutaciones declaradas en el contract v15 (`AC29` a/b, `AC45` a/b) más una adicional (`AC45` c) que el contract no declara. El script restaura con `git checkout` y al final exige árbol limpio. Cada rojo nombra el assert exacto que cayó: **las corridas se distinguen**, que es lo que hace a un triple un triple.

### AC29 (a) — se quita PGAPPNAME del entorno del comando
- verde (árbol real):   ok=2 fail=0
- rojo  (mutado):       ok=1 fail=1
    FAIL  AC29 el comando lleva el usuario del secreto en PGAPPNAME — no encontré [PGAPPNAME claude_lectura] en la salida
- verde (restaurado):   ok=2 fail=0

### AC29 (b) — application_name vuelve a PGOPTIONS
- verde (árbol real):   ok=2 fail=0
- rojo  (mutado):       ok=1 fail=1
    FAIL  AC29 PGOPTIONS no lleva application_name (psql le gana al -c) — encontré [application_name] y no debería estar
- verde (restaurado):   ok=2 fail=0

### AC45 (a) — se quita del validador la regla 'condicional exige condicion'
- verde (árbol real):   ok=9 fail=0
- rojo  (mutado):       ok=7 fail=2
    FAIL  AC45 una garantía condicional sin declarar de qué depende se rechaza — esperado [distinto-de-cero], obtenido [cero]
    FAIL  AC45 el rechazo nombra la condicion ausente — no encontré [condicion] en la salida
- verde (restaurado):   ok=9 fail=0

### AC45 (b) — el endpoint de réplica se declara condicional en proveedores-dev
- verde (árbol real):   ok=9 fail=0
- rojo  (mutado):       ok=8 fail=1
    FAIL  AC45 cada conexión Postgres declara el endpoint de réplica como su única garantía incondicional — esperado [ok], obtenido [mal:proveedores-dev]
- verde (restaurado):   ok=9 fail=0

Árbol al terminar: limpio

### AC45 (c, adicional — no declarada en el contract) — la proyección pública aplana las garantías a sus nombres
- verde (árbol real):   ok=2 fail=0
  (mutación aplicada: proyectar() devuelve sólo nombres)
- rojo  (mutado):       ok=0 fail=2
    FAIL  AC45 listar_conexiones propaga el nivel de cada garantía — no encontré ["nivel"] en la salida
    FAIL  AC45 listar_conexiones distingue la garantía incondicional — no encontré ["incondicional"] en la salida
- verde (restaurado):   ok=2 fail=0

Árbol al terminar: limpio

**Por qué la (c)**: el assert de que `listar_conexiones` propague el nivel nunca se había visto fallar. `proyectar()` pasa `garantias` entero, así que no hay una línea de "nivel" que mutar — la barrera es que la proyección no aplane. La mutación la aplana a nombres y los dos asserts caen.

**Una mutación que antes no corrió**: la primera vez que se ejecutó la (a) de `AC45`, con un `perl` entre comillas dobles, el shell se comió los backticks de la regex y la mutación **no se aplicó**; la corrida "roja" salió sin ningún `FAIL`. Se detectó porque el rojo no apareció, y se rehízo con Python. El script de este addendum verifica que cada mutación se haya aplicado antes de medir (ver la línea "mutación aplicada" de la (c)).

## 2. Verificación contra el sistema real (manual — ningún harness la puede hacer)

`AC29` es un AC de **efecto externo**: lo que afirma vive en `pg_stat_activity`, no en el comando. La suite lo daba verde con el defecto adentro (`RT48`). Por eso se verificó contra la base, a través del **plugin instalado** en una sesión reiniciada después de la reinstalación, el 23-sep-2026:

- `SELECT current_setting('application_name')` en las **seis** conexiones de Postgres del catálogo (`proveedores-dev`, `proveedores-qa`, `smartcheck-dev`, `smartcheck-qa`, `smartfleet-dev`, `smartfleet-qa`): las seis devuelven `claude_lectura`. Antes del fix, `psql`.
- En `proveedores-dev`, además: `current_user = claude_lectura`, `default_transaction_read_only = on`, `pg_is_in_recovery() = t`.
- `listar_conexiones`: las doce entradas con `nivel` por garantía; ninguna expone `host`, `puerto`, `secret_id` ni `region`.

La comparación de mecanismos que motivó el fix, medida con el mismo rol contra la misma base el 23-sep (psql directo, no por el plugin): `PGOPTIONS -c application_name=…` → `psql`; `PGAPPNAME` → `claude_lectura`; `application_name` en el conninfo → `claude_lectura`.

## 3. Lo que este reporte no cubre

- La verificación de Patrick Ocampo sobre el aprovisionamiento de Postgres (431 objetos legibles, cero escribibles, `CREATE TABLE` rechazado, 22-sep) está en Slack, **no en un artefacto del repo**.
- SQL Server: nada ejecutado todavía. `AC44` sigue con el valor esperado sin confirmar.
- Este reporte, como todo verification report de este ciclo, **queda fuera del árbol que el runner selló** (`D34`/`D35`).

## 4. El script, para re-correrlo

```bash
#!/usr/bin/env bash
# Triples de mutación de v15 (AC29, AC45). Cada mutación: verde → rojo → verde.
# Restaura por `git checkout -- <archivo>` y al final exige árbol limpio.
set -u
cd "$(git rev-parse --show-toplevel)"
CON=plugins/bisalta-db/scripts/conexion.js
VAL=plugins/bisalta-db/scripts/catalogo.js
CAT=plugins/bisalta-db/catalogo.json

cuenta() { # $1 test, $2 prefijo de AC → "ok=N fail=M" + líneas FAIL
  local out; out="$(bash "SDD/tests/$1" 2>&1)"
  printf 'ok=%s fail=%s\n' "$(grep -cE "ok +$2" <<<"$out")" "$(grep -cE "FAIL +$2" <<<"$out")"
  grep -E "FAIL +$2" <<<"$out" | sed 's/^ */    /'
}
triple() { # $1 nombre, $2 test, $3 AC, $4 función que muta
  echo "### $1"
  echo "- verde (árbol real):   $(cuenta "$2" "$3" | head -1)"
  "$4"
  echo "- rojo  (mutado):       $(cuenta "$2" "$3" | head -1)"; cuenta "$2" "$3" | tail -n +2
  git checkout -q -- "$CON" "$VAL" "$CAT"
  echo "- verde (restaurado):   $(cuenta "$2" "$3" | head -1)"
  echo
}

m29a() { perl -0pi -e 's/      PGAPPNAME: usuario,\n//' "$CON"; }
m29b() { perl -0pi -e 's/(\x27 -c statement_timeout=\x27 \+ TIMEOUT_SENTENCIA_MS),/$1 + \x27 -c application_name=\x27 + usuario,/' "$CON"; }
m45a() { python3 - "$VAL" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read()
i=s.index("        if (garantia.nivel === 'condicional'")
j=s.index('\n', s.index('}', s.index('tiene que declarar'))) + 1
open(p,'w').write(s[:i]+s[j:])
PY
}
m45b() { node -e 'const fs=require("fs"),p=process.argv[1],c=JSON.parse(fs.readFileSync(p,"utf8"));const l=Array.isArray(c)?c:c.conexiones;const g=l.find(x=>x.nombre==="proveedores-dev").garantias.find(x=>x.nombre==="endpoint-replica-lectura");g.nivel="condicional";g.condicion="mutacion";fs.writeFileSync(p,JSON.stringify(c,null,2)+"\n")' "$CAT"; }

triple "AC29 (a) — se quita PGAPPNAME del entorno del comando" test_servidor_mcp.sh AC29 m29a
triple "AC29 (b) — application_name vuelve a PGOPTIONS" test_servidor_mcp.sh AC29 m29b
triple "AC45 (a) — se quita del validador la regla 'condicional exige condicion'" test_catalogo.sh AC45 m45a
triple "AC45 (b) — el endpoint de réplica se declara condicional en proveedores-dev" test_catalogo.sh AC45 m45b

echo "Árbol al terminar: $( [ -z "$(git status --porcelain -- plugins SDD/tests)" ] && echo limpio || echo SUCIO )"
```
