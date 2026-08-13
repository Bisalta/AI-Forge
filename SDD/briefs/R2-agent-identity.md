# Task brief — R2 · infra: identidad propia del agente en los commits

- **Agente**: `AGENT_r2` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v3 → v5** (ronda 2), sección `R2`
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening` (ya creada desde `prod`; NO crear otra)
- **Proxima subtask id**: `b7534155-2d38-4f92-af47-07a1f77e47ca` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R2.md`
- **Depende de**: R0 (harness) y R1 (`sdd-run-gates.sh` v0.11.0), ambos `APPROVED`

## Ratificación v5 — ronda 2 (tras `ESCALATE` de la ronda 1)

El review de la ronda 1 midió que la ubicación "después del chequeo de rama protegida" (Decisión de diseño punto 3 más abajo, y la fila `guard-git.sh` de la tabla de Files, ambas de v3/v4) deja el bloque de identidad aguas abajo de cuatro salidas tempranas ajenas a identidad — el propio hatch `SDD_ALLOW_BASE_COMMIT`, `command -v git`, `rev-parse --git-dir` y `HEAD` detached — así que `SDD_AGENT_ENFORCE=1` combinado con cualquiera de esas cuatro apagaba el chequeo de identidad de contrabando. El defecto era del plan (instrucción de ubicación por vecindad, no por condición), no del código: el implementador cumplió la instrucción al pie de la letra. El planner ratificó **contract v5** (commit `861b42d`): el bloque va **por encima** del hatch de rama, y entran **AC36** (interacción con `SDD_ALLOW_BASE_COMMIT`), **AC37** (`HEAD` detached) y **AC38** (tres textos normativos que afirmaban que el hatch desactiva "sólo" el chequeo de rama). El resto de la Decisión de diseño y de los ACs (AC14-AC18) no cambia — se preservan tal cual abajo como registro histórico de la ronda 1; la sección "Ratificación v5" de cada punto afectado deja la corrección explícita.

## Problema

`git log -1 --format='%an' -- <archivo>` es la forma canónica de escribir una guarda "esto lo hizo una persona, no el agente". Hoy es inexpresable: el agente commitea con la identidad git del usuario, así que la guarda es verdadera siempre, la llene quien la llene. Medición en SICOP: `git log --format='%an <%ae>' -14` devolvió una sola identidad humana para commits de agente y de PO.

`plugins/sdd-flow/hooks/guard-git.sh` ya intercepta todo `git commit` como hook `PreToolUse`, ya tolera `git -c user.email=x commit` y `git -C /path commit` (líneas 50-54), y ya resuelve el repo destino. Es el punto de enforcement disponible.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **Identidad**: nombre `sdd-agent`, email `sdd-agent@users.noreply.github.com`. Se sobreescriben con `SDD_AGENT_NAME` y `SDD_AGENT_EMAIL`.
2. **Mecanismo**: el implementing-agent commitea con `git -c user.name=... -c user.email=...`.
3. **Enforcement**: `guard-git.sh` deniega un `git commit` cuyo autor no sea la identidad de agente, **únicamente cuando `SDD_AGENT_ENFORCE=1` está en el entorno**. Con la variable ausente el hook no opina — un humano commiteando en el mismo repo no queda bloqueado. **Ratificación v5**: el chequeo va **por encima** del hatch `SDD_ALLOW_BASE_COMMIT` y de toda resolución de rama — no se apaga con `SDD_ALLOW_BASE_COMMIT=1` (AC36) ni con `HEAD` detached (AC37). Son dos guardas independientes.
4. **Regla de contract**: un AC que distingue trabajo humano de trabajo de agente sólo es válido si el repo tiene el enforcement activo. Un AC de autoría sin enforcement es tautológico, y un AC tautológico es `BLOCKER` de contract.

La alternativa de detectar al subagente desde el hook está descartada: el payload no distingue subagente de sesión principal, y una heurística invisible es peor que una variable declarada.

## Out of scope

- No toques `sdd-run-gates.sh`, `sdd-check.sh` ni `sdd-lint-contract.sh`.
- No implementes R3 ni R4.
- No cambies la política **fail-open** de `guard-git.sh`: cualquier fallo del propio hook permite la operación. Un hook roto no puede frenar al equipo.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/hooks/guard-git.sh` | (mod) bloque de identidad, ~~después~~ **ronda 2: por encima** del chequeo de rama protegida / hatch (ratificación v5) |
| `plugins/sdd-flow/agents/implementing-agent.md` | (mod) la regla de commit con identidad |
| `plugins/sdd-flow/standards/base-standards.md` | (mod) sección Git |
| `plugins/sdd-flow/standards/quality-gates.md` | (mod) la regla del AC de autoría + ronda 2: AC38, texto del hatch (`:182`) |
| `SDD/docs/doc_architecture.md` | (mod, **ronda 2**, AC38) texto del hatch (`:161`) + las 3 variables nuevas con default |
| `SDD/tests/test_guard_identity.sh` | (NEW; ronda 2: + AC36, AC37) |

## Pasos

- [x] T1.1 Leer `guard-git.sh` entero antes de tocarlo. Entender cómo arma el payload de entrada y cómo deniega, para imitar el formato exacto.
- [x] T1.2 Escribir `SDD/tests/test_guard_identity.sh` (AC14-AC18) con los helpers de `SDD/tests/lib.sh`. Repos temporales en `SDD/tests/.tmp/`, `trap ... EXIT`. **Corré el test antes del fix**: tiene que salir ≠0. Registrá comando y exit code. → `bash SDD/tests/test_guard_identity.sh` contra `guard-git.sh` sin el bloque de identidad: exit `1` (`FAIL — 2 assert(s) fallaron`, las 2 de AC14; AC15-AC18 ya pasaban trivialmente porque el hook todavía no evalúa identidad — ver verification report).
- [x] T2.1 Implementar el bloque de identidad en `guard-git.sh`.
- [x] T2.2 Propagar la regla a `implementing-agent.md` y `base-standards.md` (sección Git).
- [x] T2.3 Agregar a `quality-gates.md` la regla del AC de autoría tautológico.
- [x] T3.1 Test verde. `bash SDD/tests/run.sh` completo verde (5 archivos). `shellcheck --severity=warning` en 0.
- [x] T4.1 Verification report + binding. Evidencia de gates a `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md` — **commiteá primero, regenerá después** (el exit 4 de R1 te obliga).
- [x] T4.2 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`.

### Ronda 2 (tras `ESCALATE`, contract v5)

- [x] T5.1 Releer sección R2 del contract v5 antes de tocar nada.
- [x] T5.2 Mover el bloque de identidad (y `git_subcommand commit || allow`) por encima del hatch `SDD_ALLOW_BASE_COMMIT` en `guard-git.sh`. Mecánico, sin lógica nueva. Verificado manualmente contra los dos escenarios exactos que midió el reviewer (`ENFORCE=1 + ALLOW_BASE_COMMIT=1` y `ENFORCE=1 + detached HEAD`, ambos con commit sin identidad): los dos pasan de `ALLOW` a `DENY`.
- [x] T5.3 Agregar AC36 y AC37 a `SDD/tests/test_guard_identity.sh`, cada uno probado por mutación con su triple verde→rojo→verde. Re-verificar que las mutaciones de AC14/AC16 de la ronda 1 siguen isolando correctamente tras el move.
- [x] T5.4 AC38: corregir los tres textos (`quality-gates.md:182`, header de `guard-git.sh`, `doc_architecture.md:161`) y agregar las 3 variables nuevas con default a `doc_architecture.md`. Verificado con grep.
- [x] T5.5 Re-correr suite completa + shellcheck + secret-scan. Commitear, regenerar evidencia de gates.

## Acceptance criteria (IDs del contract v3 — no los renumeres)

- **AC14** — Con `SDD_AGENT_ENFORCE=1` y un `git commit` sin `-c user.name`/`-c user.email`, el hook deniega con el mismo código que ya usa para rama protegida, y el mensaje nombra la identidad esperada.
- **AC15** — Con `SDD_AGENT_ENFORCE=1` y `git commit -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com`, el hook permite.
- **AC16** — Sin `SDD_AGENT_ENFORCE` en el entorno, un commit sin identidad de agente **pasa**.
- **AC17** — Con `SDD_AGENT_ENFORCE=1`, `SDD_AGENT_NAME=otro-agente` y un commit que declara `user.name=otro-agente`, el hook permite.
- **AC18** — Tras un commit hecho con la identidad de agente, `git log -1 --format='%an'` devuelve `sdd-agent`. Es la prueba de que la guarda de autoría dejó de ser tautológica.

**AC14 y AC16 son ACs de detección** y forman par: AC14 exige que el hook se ponga rojo, AC16 que **no** se ponga rojo cuando no corresponde. Un hook que deniega siempre pasa AC14 y falla AC16; uno que nunca deniega pasa AC16 y falla AC14. Probá los dos por mutación, con el triple verde→rojo→verde registrado por cada uno. Sin el par, el AC no distingue un enforcement real de uno roto.

### Ronda 2 — AC36, AC37, AC38 (contract v5, tras `ESCALATE`)

- **AC36** — Con `SDD_AGENT_ENFORCE=1` **y** `SDD_ALLOW_BASE_COMMIT=1` a la vez, un commit sin identidad de agente **sigue siendo denegado**. El hatch desactiva el chequeo de rama protegida, nunca el de identidad. **AC de detección** — mutación: reintroducir el bypass (`[ "${SDD_ALLOW_BASE_COMMIT:-0}" = "1" ] && allow` antes del chequeo de identidad), triple verde→rojo→verde.
- **AC37** — Con `SDD_AGENT_ENFORCE=1` y el repo en `HEAD` detached, un commit sin identidad de agente **sigue siendo denegado**. **AC de detección** — mutación: reintroducir el chequeo de detached-HEAD antes de la identidad, triple verde→rojo→verde.
- **AC38** — Los tres textos que describen el alcance del hatch dicen la verdad (`quality-gates.md`, header de `guard-git.sh`, `doc_architecture.md`): ninguno afirma que `SDD_ALLOW_BASE_COMMIT` desactiva únicamente el chequeo de rama sin decir que el de identidad sigue activo. `doc_architecture.md` además lista `SDD_AGENT_ENFORCE`/`SDD_AGENT_NAME`/`SDD_AGENT_EMAIL` con su default. Verificable con grep.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC14 | `SDD_AGENT_ENFORCE=1` + commit sin `-c user.name`/`-c user.email` → el hook deniega (mismo `deny()` que rama protegida) y el mensaje nombra la identidad esperada | `SDD/tests/test_guard_identity.sh::"AC14 enforce=1 sin -c user.name/-c user.email - el hook deniega"` + `::"AC14 enforce=1 sin identidad - el mensaje nombra la identidad esperada"` | integration | [x] |
| AC15 | `SDD_AGENT_ENFORCE=1` + commit con `-c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com` → el hook permite | `SDD/tests/test_guard_identity.sh::"AC15 enforce=1 con identidad de agente default - el hook permite"` | integration | [x] |
| AC16 | Sin `SDD_AGENT_ENFORCE` en el entorno, commit sin identidad de agente → pasa (el hook no opina) | `SDD/tests/test_guard_identity.sh::"AC16 sin SDD_AGENT_ENFORCE - commit sin identidad de agente pasa"` | integration | [x] |
| AC17 | `SDD_AGENT_ENFORCE=1` + `SDD_AGENT_NAME=otro-agente` + commit con `user.name=otro-agente` → el hook permite (el nombre esperado se deriva de la variable, no de un literal fijo) | `SDD/tests/test_guard_identity.sh::"AC17 SDD_AGENT_NAME=otro-agente con user.name=otro-agente declarado - el hook permite"` | integration | [x] |
| AC18 | Tras un commit con `-c user.name=sdd-agent -c user.email=...`, `git log -1 --format='%an'` devuelve `sdd-agent` (y el commit humano anterior conserva su propio autor) — la guarda deja de ser tautológica | `SDD/tests/test_guard_identity.sh::"AC18 commit con -c user.name=sdd-agent - git log -1 %an devuelve sdd-agent"` + `::"AC18 el commit humano anterior conserva su propio autor - la guarda ya distingue"` | integration | [x] |
| AC36 | `SDD_AGENT_ENFORCE=1` + `SDD_ALLOW_BASE_COMMIT=1` + commit sin identidad → sigue denegado (el hatch de rama no apaga identidad) | `SDD/tests/test_guard_identity.sh::"AC36 enforce=1 + SDD_ALLOW_BASE_COMMIT=1 sin identidad - sigue denegado"` | integration | [x] |
| AC37 | `SDD_AGENT_ENFORCE=1` + `HEAD` detached + commit sin identidad → sigue denegado | `SDD/tests/test_guard_identity.sh::"AC37 enforce=1 con HEAD detached sin identidad - sigue denegado"` | integration | [x] |
| AC38 | Los tres textos normativos (`quality-gates.md`, header `guard-git.sh`, `doc_architecture.md`) no afirman que el hatch desactiva únicamente rama; `doc_architecture.md` lista las 3 variables nuevas con default | `SDD/tests/test_guard_identity.sh::"AC38 header de guard-git.sh - aclara que el hatch no apaga identidad"` + `::"AC38 quality-gates.md - aclara que el hatch no apaga identidad"` + `::"AC38 doc_architecture.md - aclara que el hatch no apaga identidad"` + 3 asserts más para las variables (ver test) | unit (grep sobre contenido versionado) | [x] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe.** Tres veces en este ciclo una salida pegada quedó desfasada (retro `RT7`). Re-corré y pegá al final.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner.
- Prohibidas las mitigaciones de `quality-gates.md` §6. En particular: **ninguna exclusión por path** para hacer pasar un gate (ya costó una ronda en R0).
- Escribí los literales con forma clave-valor partidos, o el gate 9 se pone rojo.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Riesgo declarado

El enforcement nace apagado (deuda `D3`): no protege nada hasta que un repo exporte `SDD_AGENT_ENFORCE=1`. Es deliberado — el hook corre en repos de humanos.

## Rollback

`git revert`. El enforcement además se desactiva quitando la variable del entorno, sin tocar código (es AC16).

## Execution Report

- **Summary**: `plugins/sdd-flow/hooks/guard-git.sh` gana un bloque de identidad (tras el chequeo de rama protegida, sección "4"): con `SDD_AGENT_ENFORCE=1` en el entorno deniega un `git commit` cuyo `-c user.name=`/`-c user.email=` no coincide con la identidad esperada (default `sdd-agent` / `sdd-agent@users.noreply.github.com`, overrideable con `SDD_AGENT_NAME`/`SDD_AGENT_EMAIL`); sin la variable, no opina. Propagado a `implementing-agent.md` (regla de commit con identidad) y `base-standards.md` sección Git (el knob documentado). `quality-gates.md` gana la regla de que un AC de autoría sin enforcement es tautológico y `BLOCKER` de contract. Test nuevo `SDD/tests/test_guard_identity.sh` (AC14-AC18), con el triple verde→rojo→verde registrado dos veces para el par de detección AC14/AC16 (ver verification report).
- **Task status**: 8/8 pasos `[x]` — sin bloqueos. Total tasks: 8. Completed: 8. Blocked: 0. Skipped: 0.
- **Validation executed** (comando · exit code):
  - `bash SDD/tests/test_guard_identity.sh` (pre-fix, T1.2) → `1` (rojo esperado)
  - `bash SDD/tests/test_guard_identity.sh` (post-fix) → `0`
  - `bash SDD/tests/run.sh` (suite completa, 5 archivos) → `0`
  - `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` → `0`
  - `bash SDD/tests/secret-scan.sh` → `0`
  - Mutación AC14 (hook nunca deniega): `bash SDD/tests/test_guard_identity.sh` → `1` (rojo, exactamente las 2 asserts de AC14) → revertida → `0`
  - Mutación AC16 (hook evalúa identidad sin importar `SDD_AGENT_ENFORCE`): `bash SDD/tests/test_guard_identity.sh` → `1` (rojo, exactamente la assert de AC16) → revertida → `0`
  - Detalle completo, con salidas pegadas, en `SDD/verification/feat-GEN-94-sicop-hardening-R2.md`.
- **Blockers**: ninguno.
- **Files changed**: `plugins/sdd-flow/hooks/guard-git.sh` (mod) · `plugins/sdd-flow/agents/implementing-agent.md` (mod) · `plugins/sdd-flow/standards/base-standards.md` (mod) · `plugins/sdd-flow/standards/quality-gates.md` (mod) · `SDD/tests/test_guard_identity.sh` (new) · `SDD/briefs/R2-agent-identity.md` (este archivo) · `SDD/verification/feat-GEN-94-sicop-hardening-R2.md` (new) · `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md` (new, generado por el runner en un segundo commit).
- **Final statement (ronda 1)**: R2 completo — AC14-AC18 con test y binding, gates de la escalera en verde, sin mitigaciones prohibidas, sin tocar `sdd-run-gates.sh`/`sdd-check.sh`/`sdd-lint-contract.sh`/R3/R4/R5. Observación fuera de scope (no corregida, sólo declarada): `SDD/docs/doc_architecture.md:161` lista los env vars de `guard-git.sh` (`SDD_ALLOW_BASE_COMMIT`, `SDD_PROTECTED_BRANCHES`) y no menciona los 3 nuevos (`SDD_AGENT_ENFORCE`, `SDD_AGENT_NAME`, `SDD_AGENT_EMAIL`) — ese archivo no está en la tabla de Files de este brief ni en el Architectural Delta de R2 del contract, así que no lo toco; queda para que el planner decida si amerita un fix chico o deuda.

## Execution Report — Ronda 2 (tras `ESCALATE`, contract v5)

- **Summary**: el review de la ronda 1 midió que la ubicación "después del chequeo de rama protegida" dejaba el bloque de identidad aguas abajo de cuatro salidas tempranas ajenas a identidad — el hatch `SDD_ALLOW_BASE_COMMIT`, `command -v git`, `rev-parse --git-dir` y `HEAD` detached —, así que el enforcement se apagaba de contrabando con `SDD_ALLOW_BASE_COMMIT=1` o `HEAD` detached. El defecto era del plan (mi ejecución fue literal a la instrucción del brief/Delta de v3/v4), y el planner ratificó **contract v5** con la ubicación corregida y AC36/AC37/AC38 nuevos. Esta ronda: (1) mové el bloque de identidad (y `git_subcommand commit || allow`) por encima del hatch en `guard-git.sh` — mecánico, sin lógica nueva, verificado manualmente contra los dos escenarios exactos del reviewer antes de tocar el test; (2) agregué AC36 y AC37 a `test_guard_identity.sh`, cada uno probado por mutación con su propio triple aislado; (3) re-verifiqué que las mutaciones AC14/AC16 de la ronda 1 siguen isolando correctamente tras el move (con la salvedad declarada: la mutación "nunca deniega" ahora rompe AC14+AC36+AC37 juntos, porque los tres comparten la misma condición de denegación — es un resultado correcto, no una regresión de aislamiento); (4) AC38: corregí los tres textos y agregué las 3 variables nuevas a `doc_architecture.md`, con un test de grep nuevo (no manual-only) en el mismo archivo de test.
- **Task status**: 5/5 pasos de ronda 2 `[x]` — sin bloqueos. Total tasks (ronda 1 + ronda 2): 13. Completed: 13. Blocked: 0. Skipped: 0.
- **Validation executed** (comando · exit code):
  - `bash SDD/tests/test_guard_identity.sh` (tras mover el bloque, antes de agregar AC36/AC37 al test) → `0` (AC14-AC18 no se rompieron con el move)
  - Verificación manual de los dos escenarios exactos del reviewer contra el hook ya movido (`ENFORCE=1+ALLOW_BASE_COMMIT=1` y `ENFORCE=1+detached HEAD`, ambos sin identidad): las dos pasan de `ALLOW` a `DENY` — ver verification report para la salida JSON completa
  - `bash SDD/tests/test_guard_identity.sh` con AC36+AC37+AC38 agregados → `0` (15/15 `ok`)
  - Mutación AC14 (re-verificación post-move, hook nunca deniega): → `1` (rojo — 4 asserts: las 2 de AC14 + AC36 + AC37, ver nota de aislamiento arriba) → revertida → `0`
  - Mutación AC16 (re-verificación post-move, hook evalúa identidad siempre): → `1` (rojo, exactamente la assert de AC16) → revertida → `0`
  - Mutación AC36 (reintroduce bypass del hatch): → `1` (rojo, exactamente la assert de AC36) → revertida → `0`
  - Mutación AC37 (reintroduce bypass de detached HEAD): → `1` (rojo, exactamente la assert de AC37) → revertida → `0`
  - `bash SDD/tests/run.sh` (suite completa, 5 archivos) → `0`
  - `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` → `0`
  - `bash SDD/tests/secret-scan.sh` → `0`
  - `grep` de AC38 (3 textos corregidos + 3 variables listadas) → cubierto por los 6 asserts nuevos del test, todos `ok`
  - Detalle completo, con salidas pegadas después del último cambio a cada archivo (`RT7`), en `SDD/verification/feat-GEN-94-sicop-hardening-R2.md`.
- **Blockers**: ninguno.
- **Files changed (ronda 2, delta sobre la ronda 1)**: `plugins/sdd-flow/hooks/guard-git.sh` (mod, move + header) · `plugins/sdd-flow/standards/quality-gates.md` (mod, AC38) · `SDD/docs/doc_architecture.md` (mod, AC38 — antes fuera de scope declarado, ahora ratificado explícitamente por el coordinador) · `SDD/tests/test_guard_identity.sh` (mod, +AC36/+AC37/+AC38) · `SDD/briefs/R2-agent-identity.md` (este archivo) · `SDD/verification/feat-GEN-94-sicop-hardening-R2.md` (mod) · `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md` (regenerado, ronda 2).
- **Final statement**: R2 ronda 2 completo — AC36, AC37 y AC38 con test y binding; AC14-AC18 re-verificados sin regresión tras el move; 4 triples de mutación registrados (2 re-verificación + 2 nuevos); gates de la escalera en verde; sin mitigaciones prohibidas; `SDD/docs/doc_architecture.md` corregido con autorización explícita del coordinador (ya no es la observación fuera de scope de la ronda 1). `base-standards.md` e `implementing-agent.md` no requerían cambios en esta ronda (AC38 sólo nombra 3 archivos, y ninguno de esos dos contenía la afirmación falsa — verificado con grep, cero coincidencias).
