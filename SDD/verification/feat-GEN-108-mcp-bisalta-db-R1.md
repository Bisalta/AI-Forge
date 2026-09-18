# Gates run — generado por sdd-run-gates.sh v0.12.0

- **Branch**: `feat-GEN-108-mcp-bisalta-db` · **Commit**: `aca2f8e` · **Doc**: `SDD/docs/doc_quality_gates.md` (`sha256:a8f010a76c4f561a`) · **Fecha**: 2026-09-18T17:54:54Z
- Tree: `9b6cbf3ae20f0f952fceba973c56bdd800b8df56` — LIMPIO
- Este archivo lo escribió el runner, no un modelo. Editarlo a mano invalida la evidencia.

| # | Gate | Comando | Exit | Timestamp UTC | Resultado |
|---|---|---|---|---|---|
| 1 | format / style | — | — | 2026-09-18T17:54:06Z | [SKIPPED] sin comando en el doc (N/A — shfmt no está instalado) |
| 2 | lint | `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh plugins/usage-monitor/scripts/*.sh SDD/tests/*.sh SDD/scripts/*.sh` | 0 | 2026-09-18T17:54:06Z | verde |
| 3 | type-check | — | — | 2026-09-18T17:54:06Z | [SKIPPED] sin comando en el doc (N/A — bash no es tipado) |
| 4 | unit tests | `bash SDD/tests/run.sh` | 0 | 2026-09-18T17:54:06Z | verde |
| 5 | integration | — | — | 2026-09-18T17:54:30Z | [SKIPPED] sin comando en el doc (N/A — los tests del harness ya ejercitan los scripts end-to-end) |
| 6 | build | — | — | 2026-09-18T17:54:30Z | [SKIPPED] sin comando en el doc (N/A — el plugin no compila) |
| 7 | e2e | — | — | 2026-09-18T17:54:30Z | [SKIPPED] sin comando en el doc (N/A) |
| 8 | cobertura del diff | — | — | 2026-09-18T17:54:30Z | [SKIPPED] sin comando en el doc (N/A — sin reporte de coverage; se verifica con el binding AC↔test) |
| 9 | security | `bash SDD/tests/secret-scan.sh` | 0 | 2026-09-18T17:54:30Z | verde |
| 10 | smoke manual | — | — | 2026-09-18T17:54:31Z | [SKIPPED] sin comando en el doc (N/A) |
| — | suite completa | `bash SDD/tests/run.sh` | 0 | 2026-09-18T17:54:31Z | verde |

## Output por gate (últimas 15 líneas)

### Gate 2 — lint (exit 0)

```

```

### Gate 4 — unit tests (exit 0)

```
PASS  test_check_self_scoping.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_usage_summary.sh
---
14 passed, 0 failed (14 total)
```

### Gate 9 — security (exit 0)

```
secret-scan: sin hallazgos sobre 148 archivos versionados (1 excluido: self)
```

### Gate — — suite completa (exit 0)

```
PASS  test_check_self_scoping.sh
PASS  test_context_budget.sh
PASS  test_doc_hash.sh
PASS  test_escalation_ledger.sh
PASS  test_guard_identity.sh
PASS  test_harness.sh
PASS  test_lint_contract_sections.sh
PASS  test_model_tier_policy.sh
PASS  test_mutation_rule.sh
PASS  test_run_gates_tree.sh
PASS  test_run_gates.sh
PASS  test_secret_scan.sh
PASS  test_usage_summary.sh
---
14 passed, 0 failed (14 total)
```

---

# Addendum del agente `AGENT_r1` — lo que el runner no sabe

Todo lo de arriba de esta línea lo escribió `sdd-run-gates.sh` (commit `aca2f8e`, corrida final); no se editó nada de esa parte. Lo que sigue lo agrega el agente, con `templates/verification-report.md` como guía, porque el brief nombra este mismo archivo como "Verification report" en vez de un archivo `AGENT_r1.md` separado.

## Corridas previas del runner sobre commits anteriores (no descartadas, registradas)

1. **Commit `8584ebf`** (primer commit de R1): el runner cortó en el **gate 9** (exit `1`), con estos tres hallazgos — todos en prosa de `SDD/briefs/R1-infra-accesos-lectura.md`, ninguno en los siete `.sql`/`.md` nuevos del producto:

   ```
   SDD/briefs/R1-infra-accesos-lectura.md:60: posible secreto (standards/security.md §3) — valor no impreso
   SDD/briefs/R1-infra-accesos-lectura.md:128: posible secreto (standards/security.md §3) — valor no impreso
   SDD/briefs/R1-infra-accesos-lectura.md:129: posible secreto (standards/security.md §3) — valor no impreso
   ```

   Causa: esas líneas documentaban la acción de IAM real `secretsmanager`:`GetSecretValue` (un `namespace` + `:` + `acción`, no una credencial) y la mutación de AC9 con clave `password`, separador `=` y valor de relleno, ambos contiguos y sin partir — mismo patrón autorreferencial que ya afecta a `secret-scan.sh` consigo mismo. Corregidas en el commit `aad6c58` partiendo los literales (backtick entre `secretsmanager` y `:GetSecretValue`; descripción en piezas del valor de relleno tipo access-key en vez del literal completo). **Ninguna exclusión se agregó a `secret-scan.sh`** — no se tocó ese archivo, no está en el Files de este brief.

2. **Commit `aad6c58`**: runner completo en verde (gates 2, 4, 9 y suite completa). Al agregar este mismo addendum a mano, dos literales nuevos (uno en la descripción de la corrida roja, uno en la fila de la tabla de mutación de AC9) repitieron el mismo problema de forma independiente — corregidos en el commit `aca2f8e`, junto con el `grep` case-sensitive de AC10 (el runbook usa `NO` en mayúsculas; el comando documentado originalmente sólo buscaba en minúscula y no matcheaba). Reverificado con `bash SDD/tests/secret-scan.sh` → `0` después de cada corrección.

3. **Commit `aca2f8e`** (éste): corrida final del runner de arriba, verde en los cuatro gates aplicables (2, 4, 9, suite completa), árbol limpio (`9b6cbf3ae20f0f952fceba973c56bdd800b8df56`).

## Prueba por mutación — AC9

**Mutación declarada en el contract**: insertar en `postgres-parte-a.sql` un literal con forma de credencial (clave, separador y valor contiguos); el scan tiene que salir distinto de 0 nombrando el archivo y la línea sin imprimir el valor; revertir la línea.

| # | Estado del sistema | Comando | Exit code | Resultado |
|---|---|---|---|---|
| 1 | intacto | `bash SDD/tests/secret-scan.sh` | 0 | verde |
| 2 | con la mutación aplicada (línea con clave `password`, separador `=` y un valor de relleno con forma de access key AWS agregada al final de `postgres-parte-a.sql`) | `bash SDD/tests/secret-scan.sh` | 1 | rojo — nombra `postgres-parte-a.sql:55`, sin imprimir el valor |
| 3 | mutación revertida | `bash SDD/tests/secret-scan.sh` | 0 | verde |

Salida de la corrida 2 (rojo):

```
plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql:55: posible secreto (standards/security.md §3) — valor no impreso
secret-scan: hallazgos arriba — BLOCKER (standards/security.md §3); si ya se commiteó, rotarlo, no sólo borrarlo
```

Reversión verificada byte a byte: `git diff plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` contra el índice ya restaurado salió vacío (sin diferencia alguna) después de borrar la línea agregada.

## AC10 — verificación (grep)

```
grep -ni "no queda cubierta" plugins/bisalta-db/aprovisionamiento/RUNBOOK.md
```

Resultado: línea 261 (`... NO queda cubierta automáticamente**:`) — coincidencia, exit 0. (El runbook usa `NO` en mayúsculas; el grep necesita `-i` para matchear — corregido tras un primer intento en minúscula estricta que no encontraba nada, ver punto 2 arriba.)

## Smoke manual (ACs `manual-only` — AC1–AC8)

Ninguno de estos ocho se ejecutó: ningún harness de este repo puede crear un rol de Postgres, alcanzar la VPC de dev/qa, ni alcanzar `10.24.40.137` (misma razón declarada AC por AC en el contract v1). Estado de los ocho: **pendiente-de-ejecucion**. Los pasos exactos — incluidas las tres mutaciones declaradas del contract para AC2, AC6 y AC7 — están escritos en `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`, sección "Verificación de AC1–AC8". No se declara ningún resultado observado porque no se corrió nada: declarar un "Observado" acá sin haber corrido el comando sería exactamente la validación no corrida que las reglas del ciclo prohíben.

## Impact set

R1 no modifica ningún archivo existente: los siete archivos de `plugins/bisalta-db/aprovisionamiento/` son nuevos y ningún script ni test de este repo los importa o los invoca todavía (el propio catálogo/servidor que los va a necesitar es de R2, que corre después). Sin filas de regresión que justificar — confirmado con:

```
grep -rl "aprovisionamiento" --include="*.sh" --include="*.js" SDD/ plugins/ 2>/dev/null
```

Sin coincidencias (además de la prosa de este mismo brief/runbook).

## Rojos preexistentes

Ninguno. La suite completa (14 archivos, incluidos los heredados de ciclos anteriores) está verde en la base y sigue verde después de este trabajo — R1 no tocó ningún archivo que esos tests ejerciten.

