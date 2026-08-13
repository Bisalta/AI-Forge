# Task brief — R2 · infra: identidad propia del agente en los commits

- **Agente**: `AGENT_r2` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v3**, sección `R2`
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening` (ya creada desde `prod`; NO crear otra)
- **Proxima subtask id**: `b7534155-2d38-4f92-af47-07a1f77e47ca` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R2.md`
- **Depende de**: R0 (harness) y R1 (`sdd-run-gates.sh` v0.11.0), ambos `APPROVED`

## Problema

`git log -1 --format='%an' -- <archivo>` es la forma canónica de escribir una guarda "esto lo hizo una persona, no el agente". Hoy es inexpresable: el agente commitea con la identidad git del usuario, así que la guarda es verdadera siempre, la llene quien la llene. Medición en SICOP: `git log --format='%an <%ae>' -14` devolvió una sola identidad humana para commits de agente y de PO.

`plugins/sdd-flow/hooks/guard-git.sh` ya intercepta todo `git commit` como hook `PreToolUse`, ya tolera `git -c user.email=x commit` y `git -C /path commit` (líneas 50-54), y ya resuelve el repo destino. Es el punto de enforcement disponible.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **Identidad**: nombre `sdd-agent`, email `sdd-agent@users.noreply.github.com`. Se sobreescriben con `SDD_AGENT_NAME` y `SDD_AGENT_EMAIL`.
2. **Mecanismo**: el implementing-agent commitea con `git -c user.name=... -c user.email=...`.
3. **Enforcement**: `guard-git.sh` deniega un `git commit` cuyo autor no sea la identidad de agente, **únicamente cuando `SDD_AGENT_ENFORCE=1` está en el entorno**. Con la variable ausente el hook no opina — un humano commiteando en el mismo repo no queda bloqueado.
4. **Regla de contract**: un AC que distingue trabajo humano de trabajo de agente sólo es válido si el repo tiene el enforcement activo. Un AC de autoría sin enforcement es tautológico, y un AC tautológico es `BLOCKER` de contract.

La alternativa de detectar al subagente desde el hook está descartada: el payload no distingue subagente de sesión principal, y una heurística invisible es peor que una variable declarada.

## Out of scope

- No toques `sdd-run-gates.sh`, `sdd-check.sh` ni `sdd-lint-contract.sh`.
- No implementes R3 ni R4.
- No cambies la política **fail-open** de `guard-git.sh`: cualquier fallo del propio hook permite la operación. Un hook roto no puede frenar al equipo.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/hooks/guard-git.sh` | (mod) bloque de identidad, **después** del chequeo de rama protegida |
| `plugins/sdd-flow/agents/implementing-agent.md` | (mod) la regla de commit con identidad |
| `plugins/sdd-flow/standards/base-standards.md` | (mod) sección Git |
| `plugins/sdd-flow/standards/quality-gates.md` | (mod) la regla del AC de autoría |
| `SDD/tests/test_guard_identity.sh` | (NEW) |

## Pasos

- [ ] T1.1 Leer `guard-git.sh` entero antes de tocarlo. Entender cómo arma el payload de entrada y cómo deniega, para imitar el formato exacto.
- [ ] T1.2 Escribir `SDD/tests/test_guard_identity.sh` (AC14-AC18) con los helpers de `SDD/tests/lib.sh`. Repos temporales en `SDD/tests/.tmp/`, `trap ... EXIT`. **Corré el test antes del fix**: tiene que salir ≠0. Registrá comando y exit code.
- [ ] T2.1 Implementar el bloque de identidad en `guard-git.sh`.
- [ ] T2.2 Propagar la regla a `implementing-agent.md` y `base-standards.md` (sección Git).
- [ ] T2.3 Agregar a `quality-gates.md` la regla del AC de autoría tautológico.
- [ ] T3.1 Test verde. `bash SDD/tests/run.sh` completo verde (5 archivos). `shellcheck --severity=warning` en 0.
- [ ] T4.1 Verification report + binding. Evidencia de gates a `SDD/verification/feat-GEN-94-sicop-hardening-R2-gates.md` — **commiteá primero, regenerá después** (el exit 4 de R1 te obliga).
- [ ] T4.2 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`.

## Acceptance criteria (IDs del contract v3 — no los renumeres)

- **AC14** — Con `SDD_AGENT_ENFORCE=1` y un `git commit` sin `-c user.name`/`-c user.email`, el hook deniega con el mismo código que ya usa para rama protegida, y el mensaje nombra la identidad esperada.
- **AC15** — Con `SDD_AGENT_ENFORCE=1` y `git commit -c user.name=sdd-agent -c user.email=sdd-agent@users.noreply.github.com`, el hook permite.
- **AC16** — Sin `SDD_AGENT_ENFORCE` en el entorno, un commit sin identidad de agente **pasa**.
- **AC17** — Con `SDD_AGENT_ENFORCE=1`, `SDD_AGENT_NAME=otro-agente` y un commit que declara `user.name=otro-agente`, el hook permite.
- **AC18** — Tras un commit hecho con la identidad de agente, `git log -1 --format='%an'` devuelve `sdd-agent`. Es la prueba de que la guarda de autoría dejó de ser tautológica.

**AC14 y AC16 son ACs de detección** y forman par: AC14 exige que el hook se ponga rojo, AC16 que **no** se ponga rojo cuando no corresponde. Un hook que deniega siempre pasa AC14 y falla AC16; uno que nunca deniega pasa AC16 y falla AC14. Probá los dos por mutación, con el triple verde→rojo→verde registrado por cada uno. Sin el par, el AC no distingue un enforcement real de uno roto.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC14 | | | | [ ] |
| AC15 | | | | [ ] |
| AC16 | | | | [ ] |
| AC17 | | | | [ ] |
| AC18 | | | | [ ] |

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

- **Summary**:
- **Task status**:
- **Validation executed** (comando · exit code):
- **Blockers**:
- **Files changed**:
- **Final statement**:
