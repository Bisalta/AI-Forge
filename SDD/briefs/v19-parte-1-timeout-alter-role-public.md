# Task brief — v19 parte 1 · timeout en el rol, ALTER ROLE y esquema public en los scripts

- **Agente**: `AGENT_r1` (este brief toca plugin y aprovisionamiento; un solo agente para no tener dos en el mismo working tree) · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-09-18-bisalta-db-mcp.md` **v19**, ACs **AC28**, **AC49**, **AC50**, y el punto 5 de "Cambios v18 → v19" (descripción de la lista blanca)
- **Fuera de este brief**: `AC51` y `AC52`. Esperan el archivo de casos de Patrick Ocampo; **no los implementes ni escribas casos para ellos**.
- **Repo**: `.` · **Branch**: `feat-GEN-108-mcp-bisalta-db` (ya existe; **NO crear otra, NO commitear a `prod`**)
- **Verification report**: `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md` (nuevo)

## Problema

Leé entera la sección **"Cambios v18 → v19"** del contract y los textos de `AC28`, `AC49` y `AC50`.

## Files — lo único que tocás

| Archivo | Para qué |
|---|---|
| `plugins/bisalta-db/scripts/conexion.js` | `AC28`: `PGOPTIONS` deja de llevar `statement_timeout`. La constante del corte del proceso se mantiene (es lo que corta en los dos motores). El mensaje del error `tiempo_agotado` cuando el motor corta por `statement_timeout` **no puede citar 120000 ms**, porque el límite ya no es ése: tiene que decir que se alcanzó el límite de tiempo de la sesión, sin número. El mensaje del corte del proceso puede citar su propio valor |
| `SDD/tests/test_servidor_mcp.sh` | `AC28`: el assert que hoy exige `statement_timeout=120000` se reemplaza por uno **negativo** (con `assert_no_contains`): `PGOPTIONS` no lleva `statement_timeout`. El de `default_transaction_read_only=on` se queda |
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql` | `AC49`: `ALTER ROLE claude_lectura SET …` con los cuatro valores del contract, **fuera** del bloque condicional que crea el rol |
| `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql` | `AC50`: en cada base, primero `GRANT CREATE ON SCHEMA public` al dueño de la base y a todo rol que ya tenga objetos en `public` (enumerados desde el catálogo de la base, no escritos a mano), **después** `REVOKE CREATE ON SCHEMA public FROM PUBLIC`. Idempotente |
| `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md` | las verificaciones de `AC49` y `AC50` (como el rol, no como administrador), el `REVOKE CONNECT` sobre la base `postgres` como paso explícito con su verificación, y quitar toda mención de `statement_timeout=120000` como valor vigente |
| `plugins/bisalta-db/README.md` | la tabla de errores (tiempo agotado), toda mención de los 120 s de sentencia como límite vigente en Postgres, y la descripción de la lista blanca: **la primera capa, la que rechaza temprano y con un mensaje claro, delante de las que impiden el daño** (contract v19, punto 5). Ninguna frase puede presentarla como la barrera que impide una escritura |
| `plugins/bisalta-db/scripts/servidor-mcp.js` | **sólo** si la `description` de `consultar` cita el límite de 120 s o presenta la lista blanca como la barrera: mismo criterio que el README. Nada más del archivo |
| `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md` | la evidencia |

**No tocás**: el contract, `lista-blanca.js`, `test_lista_blanca.sh`, `SDD/retro.md`, `SDD/debt.md`, `SDD/escalations.md`, `SDD/FEATURE-READY-GEN-108.md`, `CHANGELOG.md`.

## Pasos

- [x] **T1** Leer el contract v19 y `quality-gates.md` §5, §6 y §10.
- [x] **T2** `AC28` en código y test. Suite.
- [x] **T3** `AC49` y `AC50` en los `.sql` y el runbook.
- [x] **T4** README (y la `description` si corresponde). Barrido **por concepto**: `grep -rn -i "120000\|120 s\|statement_timeout\|guarda que decide\|lista blanca"` en `plugins/bisalta-db/`, y revisar cada aparición contra v19.
- [x] **T5** Commit. Árbol limpio.
- [x] **T6** Evidencia: el runner (`sdd-run-gates.sh -o <report> --full`) sobre el árbol limpio, y un addendum con el triple de `AC28` —script que verifica que la mutación se aplicó (`git diff --quiet` distinto de 0) e imprime el exit code de las tres corridas—, el diff de los `.sql`, y el resultado del barrido de T4. Commit y push.

## Reglas innegociables

- **Ninguna conexión a ninguna base.** `AC49` y `AC50` son `manual-only`; su verificación contra el motor la hace el planner.
- Mitigaciones prohibidas (`quality-gates.md` §6). Ninguna dependencia nueva. Bash 3.2.
- No declares una validación que no corriste.
- Si algo del contract es ambiguo, `blocked` con la pregunta. No elijas.

## Retorno

El último bloque es el JSON `sdd.result` (`plugins/sdd-flow/standards/orchestration.md` §2).

## Execution Report

- **Total tasks**: 6 (T1-T6). **Completed**: 6. **Blocked**: 0. **Skipped**: 0.
- **AC ↔ test binding**: ver tabla completa en `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md`.
  - `AC28`: `SDD/tests/test_servidor_mcp.sh::"AC28 el comando abre la sesión en solo lectura"` y `::"AC28 PGOPTIONS no lleva statement_timeout (el límite lo fija el rol, AC49)"` — `pass`, con triple de mutación verde→rojo→verde.
  - `AC49`: `manual-only` — código (`postgres-parte-a.sql`) y runbook (`RUNBOOK.md`, sección "AC49") listos; verificación contra el motor real diferida al planner (regla innegociable: ninguna conexión a ninguna base) — `manual`.
  - `AC50`: `manual-only` — código (`postgres-parte-b.sql`) y runbook (`RUNBOOK.md`, sección "AC50", incluido el `REVOKE CONNECT` sobre `postgres` como paso explícito) listos; verificación contra el motor real diferida al planner — `manual`.
- **Gates corridos**: `bash plugins/sdd-flow/scripts/sdd-run-gates.sh --full -o SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1-gates.md` → exit 0, `{"green":4,"red":0,"skipped":7}`. Detalle y comandos por gate en ese reporte generado; addendum de mutación e impact set en `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md`.
- **Rojos preexistentes**: ninguno — la suite (`bash SDD/tests/run.sh`) corrió `17 passed, 0 failed (17 total)` tanto en la base de partida (commit `ba4ff79`) como después de este trabajo (commit `b5e9239`), medido explícitamente con un checkout temporal a `ba4ff79` y vuelta a la branch.
- **Files changed**: `plugins/bisalta-db/scripts/conexion.js`, `SDD/tests/test_servidor_mcp.sh`, `plugins/bisalta-db/aprovisionamiento/postgres-parte-a.sql`, `plugins/bisalta-db/aprovisionamiento/postgres-parte-b.sql`, `plugins/bisalta-db/aprovisionamiento/RUNBOOK.md`, `plugins/bisalta-db/README.md`, `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1.md` (nuevo), `SDD/verification/feat-GEN-108-mcp-bisalta-db-v19-parte-1-gates.md` (nuevo, generado por el runner), este brief.
- **Fuera de alcance, no tocado**: `plugins/bisalta-db/scripts/lista-blanca.js`, `SDD/tests/test_lista_blanca.sh`, el contract, `SDD/retro.md`, `SDD/debt.md`, `SDD/escalations.md`, `SDD/FEATURE-READY-GEN-108.md`, `CHANGELOG.md`.
- **Docs delta**: no aplica — el cambio no tocó capas/rutas/contratos del Architectural Delta ni agregó comandos de verificación nuevos; `doc_quality_gates.md` y `doc_architecture.md` quedan sin cambios.
- **Contabilidad**: sin `MINOR` encontrados por este agente ni `N/A` nuevos que registrar en `SDD/debt.md`; sin dependencias nuevas; sin decisión arquitectónica nueva que requiera ADR.
