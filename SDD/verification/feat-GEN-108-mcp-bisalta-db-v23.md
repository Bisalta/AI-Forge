# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `6bf9fe7` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:56736c3e5b778ea1`) · **Fecha**: 2026-09-24T21:12:07Z
- Tree: `d4861d82c03860fd146abd09fe1ed6b53d60023a` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-24T21:11:01Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-24T21:11:02Z | verde |
| 3 | type-check | — | — | 2026-09-24T21:11:03Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-24T21:11:03Z | verde |
| 5 | integration | — | — | 2026-09-24T21:11:34Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-24T21:11:34Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-24T21:11:34Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-24T21:11:34Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-24T21:11:34Z | verde |
| 10 | smoke manual | — | — | 2026-09-24T21:11:36Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-24T21:11:36Z | verde |

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
secret-scan: sin hallazgos sobre 180 archivos versionados (1 excluido: self)
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

# Addendum del planner — v23 (NO lo escribió el runner)

La escalera de arriba se corrió sobre `6bf9fe7`, que es `76f258e` (los seis casos nuevos de Patrick) más el contract v23 y el ledger de deuda: el código y los tests son los de `76f258e`. Este addendum se escribió sobre `bf817b9`, el commit que agregó la escalera.

## 1. Casos — salida literal, agrupada por prefijo de assert

```
$ out="$(bash SDD/tests/test_lista_blanca.sh 2>&1)"; ec=$?
$ for p in 'AC51/AC52 caso [0-9]+ \(' 'AC51 v20 caso [0-9]+ \(' 'AC51 v20 caso [0-9]+: el motivo lleva el tipo' 'AC51/AC52 el archivo' 'AC51 v20 el archivo' 'AC51 v20 hay casos'; do printf '%-50s ok=%s FAIL=%s\n' "$p" "$(grep -cE "^  ok +$p" <<<"$out")" "$(grep -cE "^  FAIL +$p" <<<"$out")"; done
$ echo "total del archivo: ok=$(grep -c '^  ok' <<<"$out") FAIL=$(grep -c '^  FAIL' <<<"$out") · exit=$ec"
AC51/AC52 caso [0-9]+ \(                           ok=21 FAIL=0
AC51 v20 caso [0-9]+ \(                            ok=27 FAIL=0
AC51 v20 caso [0-9]+: el motivo lleva el tipo      ok=5 FAIL=0
AC51/AC52 el archivo                               ok=2 FAIL=0
AC51 v20 el archivo                                ok=2 FAIL=0
AC51 v20 hay casos                                 ok=1 FAIL=0
total del archivo: ok=134 FAIL=0 · exit=0
```

El loop es el que se corrió: la salida es literal. (El report de v22 mostraba una plantilla del comando; ronda 1 de la review de v23, MINOR 7.) Con v22 eran 21 casos en la segunda tanda y 128 asserts en el archivo; los seis casos nuevos suman seis asserts.

## 2. Mutaciones de `AC51` sobre este árbol — salida literal del script

Es el script del report de v20 (§3) con dos arreglos que pedía la review: cuenta con `grep -c '^  FAIL'` (el patrón sin ancla contaba también la línea de resumen) y lista **el nombre** de cada assert que cae, cortado antes de los dos puntos para que no salga la descripción del caso. La (a) no está: con la firma nueva de `normalizar()` requiere un adaptador, y queda pendiente (`D65`).

```
### (b) regla de los literales E'…' apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=5
      FAIL  AC51 v20 caso 21 (postgres)
      FAIL  AC51 v20 caso 22 (postgres)
      FAIL  AC51 v20 caso 23 (postgres)
      FAIL  AC51 v20 caso 24 (postgres)
      FAIL  AC51 v20 caso 25 (postgres)
- verde (restaurado): exit=0 fail=0

### (c) regla de los corchetes apagada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 16
- verde (restaurado): exit=0 fail=0

### (d) construcción sin cerrar aceptada
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=10
      FAIL  AC51 v20 caso 12 (postgres)
      FAIL  AC51 v20 caso 13 (postgres)
      FAIL  AC51 v20 caso 14 (postgres)
      FAIL  AC51 v20 caso 15 (postgres)
      FAIL  AC51 v20 caso 16 (sqlserver)
      FAIL  AC51 v20 caso 12
      FAIL  AC51 v20 caso 13
      FAIL  AC51 v20 caso 14
      FAIL  AC51 v20 caso 15
      FAIL  AC51 v20 caso 16
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

- **(b) cae.** Con la regla apagada, los casos 21 a 25 —consultas legítimas— se rechazan como construcción sin cerrar. El 26 no cae: es el control que Patrick puso a propósito. Lo que no caía antes no era un hueco del código, sino que ningún caso de la suite era una consulta legítima de ese tipo (contract v23).
- **(c) sigue abierta en parte.** Cae sólo el caso 16, en sus dos asserts (veredicto y tipo del motivo), y el 16 cae también con (d) (`D64`).
- **(d) cae**, en los cinco casos de construcción sin cerrar y en sus asserts del tipo del motivo.
- El "caso N" sin dialecto es el assert del tipo en el motivo del mismo caso.

### El script

```bash
#!/usr/bin/env bash
# Mutaciones declaradas de AC51 v20. Cada una apaga una regla con `false &&`,
# verifica que se aplicó, mide, restaura con git checkout y verifica que se
# restauró. Registra exit code y cantidad de asserts que caen.
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/lista-blanca.js; T=SDD/tests/test_lista_blanca.sh
correr() { local o ec; o="$(bash "$T" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c '^  FAIL' <<<"$o")"; grep '^  FAIL' <<<"$o" | sed 's/:.*//; s/^/    /'; }
mutar() { local nombre="$1" viejo="$2" nuevo="$3"
  echo "### $nombre"
  printf -- '- verde (árbol real): '; correr
  python3 - "$F" "$viejo" "$nuevo" <<'PY'
import sys
p,v,n=sys.argv[1:4]; s=open(p).read(); assert s.count(v)==1,(v,s.count(v)); open(p,'w').write(s.replace(v,n))
PY
  if git diff --quiet -- "$F"; then echo "- ABORTA: la mutación no se aplicó"; return 1; fi
  printf -- '- mutado:             '; correr
  git checkout -q -- "$F"
  if ! git diff --quiet -- "$F"; then echo "- ABORTA: no se restauró"; return 1; fi
  printf -- '- verde (restaurado): '; correr
  echo; }
mutar "(b) regla de los literales E'…' apagada" "if (dialecto === 'postgres' && (c === 'E'" "if (false && dialecto === 'postgres' && (c === 'E'"
mutar "(c) regla de los corchetes apagada" "if (dialecto === 'sqlserver' && c === '[')" "if (false && dialecto === 'sqlserver' && c === '[')"
mutar "(d) construcción sin cerrar aceptada" "if (normalizada.sinCerrar) {" "if (false && normalizada.sinCerrar) {"
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

## 3. Binding AC ↔ test (`SDD/tests/test_lista_blanca.sh`)

Igual que el de v22 (§2 de aquel report), con una fila cambiada:

| AC | Asserts |
|---|---|
| `AC51` v20, segunda tanda | `AC51 v20 caso <índice> (<dialecto>): <motivo>` — **27**, uno por caso de `casos-adversariales-v20.js`. Los índices 21 a 25 son los que matan la mutación (b); el 26 es su control |

El test no cambió: recorre el archivo por índice, así que los casos nuevos entraron solos.

## 4. El caso 13 nombra su tipo (`D67`, agregado después de la review de v23)

En `e0a70bb` la descripción del caso 13 de `casos-adversariales-v20.js` pasó a nombrar su tipo (`literal`). Hasta ahí era el único de los cinco casos de construcción sin cerrar en el que el assert del tipo en el motivo verificaba sólo el prefijo `construccion_sin_cerrar_`. La consulta no se tocó. El tipo lo dedujo el planner de la consulta, que Ian leyó en el archivo, y no del validador: el test compara el motivo del validador contra la descripción, así que copiarlo del validador lo volvería circular.

**Triple.** La mutación hace que un literal sin cerrar se informe como identificador. Se corre dos veces, con la descripción vieja del caso 13 (`933c527`) y con la nueva: el caso 13 cae sólo con la nueva. El caso 12, que ya nombraba su tipo, cae en las dos corridas.

```
### descripción del caso 13 de 933c527 (933c527)
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=1
      FAIL  AC51 v20 caso 12
- verde (restaurado): exit=0 fail=0

### descripción del caso 13 de e0a70bb (e0a70bb)
- verde (árbol real): exit=0 fail=0
- mutado:             exit=1 fail=2
      FAIL  AC51 v20 caso 12
      FAIL  AC51 v20 caso 13
- verde (restaurado): exit=0 fail=0

Árbol al terminar: limpio
```

### El script

```bash
#!/usr/bin/env bash
# Mutación del tipo en el motivo: un literal sin cerrar se informa como
# identificador. Se corre con la descripción del caso 13 de antes (commit
# 933c527) y con la de `e0a70bb`, para mostrar que el assert endurecido
# es el que la mata.
set -u
cd "$(git rev-parse --show-toplevel)"
F=plugins/bisalta-db/scripts/lista-blanca.js; T=SDD/tests/test_lista_blanca.sh; X=SDD/tests/fixtures/casos-adversariales-v20.js
V="'construccion_sin_cerrar_' + normalizada.sinCerrar"
N="'construccion_sin_cerrar_' + (normalizada.sinCerrar === 'literal' ? 'identificador' : normalizada.sinCerrar)"
correr() { local o ec; o="$(bash "$T" 2>&1)"; ec=$?; printf 'exit=%s fail=%s\n' "$ec" "$(grep -c '^  FAIL' <<<"$o")"; grep '^  FAIL' <<<"$o" | sed 's/:.*//; s/^/    /'; }
mutar() { python3 - "$F" "$1" "$2" <<'PY'
import sys
p,v,n=sys.argv[1:4]; s=open(p).read(); assert s.count(v)==1,(v,s.count(v)); open(p,'w').write(s.replace(v,n))
PY
}
for fx in 933c527 e0a70bb; do
  echo "### descripción del caso 13 de $fx ($(git rev-parse --short $fx))"
  git checkout -q "$fx" -- "$X"
  printf -- '- verde (árbol real): '; correr
  mutar "$V" "$N"; if git diff --quiet -- "$F"; then echo "- ABORTA: la mutación no se aplicó"; exit 1; fi
  printf -- '- mutado:             '; correr
  git checkout -q -- "$F"; if ! git diff --quiet -- "$F"; then echo "- ABORTA: no se restauró"; exit 1; fi
  printf -- '- verde (restaurado): '; correr
  git checkout -q HEAD -- "$X"; echo
done
echo "Árbol al terminar: $( [ -z "$(git status --porcelain)" ] && echo limpio || echo SUCIO )"
```

El script fija `e0a70bb` en vez de `HEAD`, para que re-correrlo reproduzca la salida pegada (review de v23, ronda 3, MINOR 2); la salida de arriba es la de esa versión.

**Binding**: la excepción que el report de v22 declaraba en la fila "tipo en el motivo" (un caso que verificaba sólo el prefijo) deja de existir. Los cinco asserts verifican el tipo exacto.
