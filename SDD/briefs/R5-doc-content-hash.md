# Task brief — R5 · infra: identidad de contenido de los docs que gobiernan

- **Agente**: `AGENT_r5` · **Modelo**: `sonnet`
- **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v5**, sección `R5` (AC29-AC35)
- **Arquetipo**: `infra`
- **Repo**: `.` · **Branch**: `feat-GEN-94-sicop-hardening` (ya creada; NO crear otra)
- **Proxima subtask id**: `f4eda231-5311-4e5b-9273-ae4de883b192` (informativo — **vos no tocás Proxima**)
- **Verification report**: `SDD/verification/feat-GEN-94-sicop-hardening-R5.md`
- **Depende de**: R0, R1 y R2, los tres `APPROVED`

## Problema

El ciclo versiona el contract con rigor y lo **valida** —un `done` con `contract_version` viejo se rechaza— pero los tres documentos de `SDD/docs/` contra los que se escribe ese contract no declaran identidad ninguna. El runner estampa `**Doc**: <ruta>` en `plugins/sdd-flow/scripts/sdd-run-gates.sh:220`, y **una ruta no identifica un contenido**.

Con `.sdd/` gitignoreado por diseño, el verification report es el único registro durable del ciclo, y es justo ahí donde falta la identidad del doc que definió los gates.

Medición externa que descarta el sustituto obvio ("total está en git, y el contract tiene fecha"): en un repo de 8 días, `doc_quality_gates.md` acumuló **31 cambios, 8 de ellos en un solo día**. Los contracts llevan fecha, no hora. Y no es un repo patológico: desde la v0.7.0 el docs delta es parte del `done`, o sea el ciclo modifica sus propios documentos de gobierno en cada vuelta, **por diseño**.

Fijar el **commit** del doc tampoco sirve: un archivo modificado sin commitear hace que el sha del último commit mienta. Es la misma clase que `HEAD` en R1, `git ls-files` en `D8` y `git stash create` en `D7` — ver `SDD/retro.md` `RT8`.

## Decisión de diseño (cerrada en el contract — no la re-abras)

1. **`sha256`**, estampado como `sha256:` seguido de los **primeros 16 caracteres hexadecimales**.
2. **Portabilidad**: calculalo con `shasum -a 256`; si ese binario no está, con `sha256sum`. Si no está ninguno, estampá `sha256:-`.
3. **El sellado nunca aborta** — misma política que el sellado de árbol de R1.
4. **Manifiesto**: `sdd-init` escribe `SDD/docs/doc-manifest.md` con el hash de cada doc al generarse. El hash **no** va dentro del propio documento: escribirlo ahí cambiaría el hash que declara.
5. **Protección al regenerar**: hash distinto significa que alguien trabajó ese doc a mano, y entonces no se sobrescribe sin mostrar el diff. No es regla nueva — `plugins/sdd-flow/skills/sdd-init/SKILL.md:70` ya la exige para los scripts; lo que faltaba era la identidad que la regla necesita.
6. **La review compara**: hashes iguales con evidencia que no reproduce significa evidencia podrida; hashes distintos significa que los gates se movieron durante el ciclo, y lleva mensaje propio. Hoy los dos casos producen salida idéntica.

## Out of scope

- No toques el parser de la tabla, `run_gate()` ni el bloque de sellado de árbol de R1 en `sdd-run-gates.sh`. Lo tuyo es el helper de hash y la línea del encabezado.
- No toques `guard-git.sh` salvo la tarea T4.1 de abajo.
- No implementes R3 ni R4.

## Files

| Path | Qué |
|---|---|
| `plugins/sdd-flow/scripts/sdd-run-gates.sh` | (mod) helper de hash portable + estampado del doc en el encabezado |
| `plugins/sdd-flow/templates/verification-report.md` | (mod) el doc de gates se registra con hash |
| `plugins/sdd-flow/skills/sdd-init/SKILL.md` | (mod) escribe el manifiesto y protege al regenerar |
| `plugins/sdd-flow/templates/doc-manifest.md` | (NEW) |
| `plugins/sdd-flow/agents/reviewer-agent.md` | (mod) Fase 1: comparar hashes, distinguir los dos casos |
| `SDD/tests/test_doc_hash.sh` | (NEW) |
| `plugins/sdd-flow/hooks/guard-git.sh` | (mod) sólo el header, tarea T4.1 |

## Pasos

- [ ] T1.1 Escribir `SDD/tests/test_doc_hash.sh` (AC29-AC31) con `SDD/tests/lib.sh`. **Ojo la firma**: `assert_eq <actual> <esperado>` (`lib.sh:25`), en ese orden. Repos temporales en `SDD/tests/.tmp/`, `trap ... EXIT`. **Corré el test antes del fix**: tiene que salir ≠0. Registrá comando y exit code.
- [ ] T2.1 Helper de hash portable en `sdd-run-gates.sh` (`shasum -a 256` → `sha256sum` → `-`), y estampado del doc con ruta **y** hash en el encabezado.
- [ ] T2.2 Bumpear `VERSION` a `0.12.0`.
- [ ] T3.1 `plugins/sdd-flow/templates/verification-report.md`: el doc de gates con hash.
- [ ] T3.2 `plugins/sdd-flow/templates/doc-manifest.md` (NEW), una fila por doc.
- [ ] T3.3 `plugins/sdd-flow/skills/sdd-init/SKILL.md`: escribir el manifiesto y comparar antes de sobrescribir, mostrando el diff cuando el hash difiere.
- [ ] T3.4 `plugins/sdd-flow/agents/reviewer-agent.md`, Fase 1: comparar el hash del reporte contra el doc en el árbol, con los dos mensajes distintos.
- [ ] T4.1 **Del review de R2 (ADVISORY)**: agregar al header de `plugins/sdd-flow/hooks/guard-git.sh` dos líneas que expliciten el contrato de señalización — **con `jq` presente, `deny()` y `allow()` salen los dos con exit 0 y la única diferencia observable es el JSON `permissionDecision` en stdout; sin `jq` degrada a texto en stderr con exit 2**. Medir ese hook por exit code hace que todos los escenarios se vean iguales: casi produjo un falso negativo en mi verificación y le costó un ciclo de debug al reviewer.
- [ ] T5.1 Test verde. `bash SDD/tests/run.sh` completo verde (6 archivos). `shellcheck --severity=warning` en 0.
- [ ] T5.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R5-gates.md` — **commiteá primero, regenerá después** (el exit 4 de R1 te obliga).
- [ ] T5.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent` (R2).

## Acceptance criteria (IDs del contract v5 — no los renumeres)

- **AC29** — El encabezado del reporte estampa el doc con ruta **y** hash, y ese hash coincide con los primeros 16 hex de `shasum -a 256 <doc>` sobre el mismo archivo.
- **AC30** — Cambiar un byte del doc de gates entre dos corridas produce dos hashes distintos en los dos reportes.
- **AC31** — Sin `shasum` ni `sha256sum` en el `PATH`, el runner estampa `sha256:-` y sale con el código que corresponde al resultado de los gates, sin abortar.
- **AC32** — `plugins/sdd-flow/templates/verification-report.md` registra el doc con hash, no sólo con ruta. Grep.
- **AC33** — `plugins/sdd-flow/skills/sdd-init/SKILL.md` exige escribir el manifiesto y comparar antes de sobrescribir, mostrando el diff cuando el hash difiere. Grep.
- **AC34** — `plugins/sdd-flow/agents/reviewer-agent.md` distingue los dos casos con mensajes distintos. Grep.
- **AC35** — `plugins/sdd-flow/templates/doc-manifest.md` existe con una fila por cada uno de los tres docs de `SDD/docs/`.

**AC30 es el AC de detección de este requerimiento**: su condición de aprobación es "el hash cambia cuando el contenido cambia". Un hash constante —o uno que se recalcula mal y siempre difiere— produce salidas indistinguibles de uno correcto si sólo mirás una corrida. Probalo por mutación con el triple verde→rojo→verde registrado.

## AC ↔ test binding (llenalo vos)

| AC | Comportamiento | Test | Tipo | Estado |
|----|----------------|------|------|--------|
| AC29 | | | | [ ] |
| AC30 | | | | [ ] |
| AC31 | | | | [ ] |
| AC32 | | | | [ ] |
| AC33 | | | | [ ] |
| AC34 | | | | [ ] |
| AC35 | | | | [ ] |

## Reglas innegociables

- Nunca declares una validación que no corriste. Toda cifra reportada va con la salida del comando que la produce.
- **Capturá la evidencia pegada a mano DESPUÉS del último cambio al archivo que describe** (`RT7`). En R2 se detectó solo antes del review: hacé lo mismo.
- **Verificá cómo se mide antes de creerle a la medición.** Dos veces en este ciclo un chequeo dio "todo igual" porque se medía la señal equivocada.
- **No verifiques lint con `git ls-files`** (`D8`): no lista archivos sin `git add`. Usá el glob del gate.
- Literales con forma clave-valor, **partidos**, o el gate 9 se pone rojo.
- Falta una decisión que el contract no cierra → **BLOCKED**, preguntá al planner.
- Prohibidas las mitigaciones de `plugins/sdd-flow/standards/quality-gates.md` §6, en particular **cualquier exclusión por path** para hacer pasar un gate.
- No toques `SDD/contracts/`, `SDD/debt.md`, `SDD/retro.md` ni `.sdd/state.json`.

## Rollback

`git revert`. El estampado es aditivo: un reporte sin hash sigue siendo legible.

## Execution Report

- **Summary**:
- **Task status**:
- **Validation executed** (comando · exit code):
- **Blockers**:
- **Files changed**:
- **Final statement**:
