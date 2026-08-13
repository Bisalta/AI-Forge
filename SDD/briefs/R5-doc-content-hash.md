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
| `SDD/tests/test_run_gates_tree.sh` | (mod, no estaba en la tabla original) — impacto directo de T2.2: AC11 (R1, ya `APPROVED`) assertea el literal `0.11.0` de `--version`; al bumpear `VERSION` a `0.12.0` ese assert rompe. Confirmé el rojo real ANTES de tocarlo (`bash SDD/tests/test_run_gates_tree.sh` con el bump ya aplicado → `FAIL AC11 --version imprime 0.11.0`, 1 assert falló, exit 1; el resto de AC7-AC10/AC12 siguió verde) y actualicé sólo el literal esperado (mismo assert, mismo poder de detección, nuevo valor correcto) — no es un ablandamiento, es la misma búsqueda de hermanos que exige AC13 de R1 |

## Pasos

- [x] T1.1 Escribir `SDD/tests/test_doc_hash.sh` (AC29-AC31) con `SDD/tests/lib.sh`. **Ojo la firma**: `assert_eq <actual> <esperado>` (`lib.sh:25`), en ese orden. Repos temporales en `SDD/tests/.tmp/`, `trap ... EXIT`. **Corré el test antes del fix**: tiene que salir ≠0. Registrá comando y exit code. — Hecho. Escribí el archivo completo (AC29-AC35, no sólo 29-31: sumé AC32-35 con el mismo tratamiento "grep" que AC38 en R2) y corrí `bash SDD/tests/test_doc_hash.sh` con `sdd-run-gates.sh` stasheado a su estado pre-R5 (`git stash push -- plugins/sdd-flow/scripts/sdd-run-gates.sh`) → **15 de 19 asserts fallaron, exit 1** (ver verification report, sección T1.1). `git stash pop` restauró el fix antes de seguir.
- [x] T2.1 Helper de hash portable en `sdd-run-gates.sh` (`shasum -a 256` → `sha256sum` → `-`), y estampado del doc con ruta **y** hash en el encabezado.
- [x] T2.2 Bumpear `VERSION` a `0.12.0`. Impacto directo: AC11 de R1 (`test_run_gates_tree.sh`) assertea el literal viejo — actualizado en la misma tarea (ver fila nueva de la tabla Files) con el rojo real confirmado antes del fix.
- [x] T3.1 `plugins/sdd-flow/templates/verification-report.md`: el doc de gates con hash.
- [x] T3.2 `plugins/sdd-flow/templates/doc-manifest.md` (NEW), una fila por doc.
- [x] T3.3 `plugins/sdd-flow/skills/sdd-init/SKILL.md`: escribir el manifiesto y comparar antes de sobrescribir, mostrando el diff cuando el hash difiere.
- [x] T3.4 `plugins/sdd-flow/agents/reviewer-agent.md`, Fase 1: comparar el hash del reporte contra el doc en el árbol, con los dos mensajes distintos.
- [x] T4.1 **Del review de R2 (ADVISORY)**: agregar al header de `plugins/sdd-flow/hooks/guard-git.sh` dos líneas que expliciten el contrato de señalización — **con `jq` presente, `deny()` y `allow()` salen los dos con exit 0 y la única diferencia observable es el JSON `permissionDecision` en stdout; sin `jq` degrada a texto en stderr con exit 2**. Medir ese hook por exit code hace que todos los escenarios se vean iguales: casi produjo un falso negativo en mi verificación y le costó un ciclo de debug al reviewer.
- [x] T5.1 Test verde. `bash SDD/tests/run.sh` completo verde (6 archivos). `shellcheck --severity=warning` en 0.
- [x] T5.2 Verification report + binding. Evidencia a `SDD/verification/feat-GEN-94-sicop-hardening-R5-gates.md` — **commiteá primero, regenerá después** (el exit 4 de R1 te obliga).
- [x] T5.3 Commit `[ADD] [GEN-94] [sdd-flow] <descripción>`, con la identidad `sdd-agent` (R2).

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
| AC29 | encabezado con ruta + hash, coincide con `shasum -a 256` real | `SDD/tests/test_doc_hash.sh::"AC29 el hash estampado coincide con los primeros 16 hex de shasum -a 256 sobre el mismo archivo"` | integration | [x] |
| AC30 | un byte distinto → hash distinto entre corridas (AC de detección: estabilidad + sensibilidad) | `SDD/tests/test_doc_hash.sh::"AC30 estabilidad - mismo contenido en dos corridas produce el mismo hash"`, `"AC30 sensibilidad - un byte distinto en el doc produce un hash distinto entre corridas"` | integration | [x] |
| AC31 | sin `shasum`/`sha256sum` en `PATH` → `sha256:-`, sale con el exit code de los gates | `SDD/tests/test_doc_hash.sh::"AC31 sin shasum ni sha256sum en el PATH - sale con el codigo de los gates (hay un rojo), no aborta"`, `"AC31 sin shasum ni sha256sum en el PATH - estampa sha256:-"` | integration | [x] |
| AC32 | `verification-report.md` registra el doc con hash, no sólo ruta | `SDD/tests/test_doc_hash.sh::"AC32 verification-report.md - registra el doc de gates con hash, no solo con ruta"` | grep (automatizado) | [x] |
| AC33 | `sdd-init/SKILL.md` exige manifiesto + diff antes de sobrescribir | `SDD/tests/test_doc_hash.sh::"AC33 sdd-init/SKILL.md - menciona SDD/docs/doc-manifest.md"`, `"AC33 sdd-init/SKILL.md - exige no sobreescribir en silencio cuando el hash difiere"`, `"AC33 sdd-init/SKILL.md - exige mostrar el diff antes de sobreescribir"` | grep (automatizado) | [x] |
| AC34 | `reviewer-agent.md` distingue evidencia podrida vs. gates que cambiaron | `SDD/tests/test_doc_hash.sh::"AC34 reviewer-agent.md - hashes iguales con evidencia que no reproduce es evidencia podrida"`, `"AC34 reviewer-agent.md - hashes distintos es un hallazgo propio, no evidencia podrida"` | grep (automatizado) | [x] |
| AC35 | `templates/doc-manifest.md` existe con una fila por doc | `SDD/tests/test_doc_hash.sh::"AC35 templates/doc-manifest.md existe"`, `"AC35 doc-manifest.md - tiene fila para doc_architecture.md"` (+ 2 más, una por doc) | grep (automatizado) | [x] |

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

- **Summary**: `sdd-run-gates.sh` gana un helper de hash portable (`shasum -a 256` → `sha256sum` → `sha256:-`) y estampa cada reporte con **ruta y hash** del doc de gates (contract R5, AC29-AC31); `VERSION` bumpeada a `0.12.0`. Los cuatro artefactos normativos que dependen de esa identidad quedan escritos: `verification-report.md` (AC32), `sdd-init/SKILL.md` con el manifiesto + protección al regenerar (AC33), `reviewer-agent.md` distinguiendo evidencia podrida de gates que cambiaron (AC34), y el template nuevo `doc-manifest.md` (AC35). Más el fix advisory de R2 (T4.1, header de `guard-git.sh`).
- **Task status**: 8/8 pasos `[x]` (T1.1-T5.3). 0 `BLOCKED`.
- **Validation executed** (comando · exit code) — ver detalle completo en `SDD/verification/feat-GEN-94-sicop-hardening-R5.md`:
  - `bash SDD/tests/test_doc_hash.sh` contra `sdd-run-gates.sh` pre-fix (stasheado) → exit `1`, 15/19 asserts fallaron.
  - `bash SDD/tests/test_doc_hash.sh` post-fix completo (T2.1-T4.1 aplicados) → exit `0`, 19/19 `ok`.
  - Mutación AC30 ×2 (hash constante; hash que siempre difiere por PID) → verde→rojo→verde, cada una aislada a su sub-check.
  - `bash SDD/tests/test_run_gates_tree.sh` con `VERSION=0.12.0` y AC11 sin actualizar → exit `1` (1 assert); con el literal actualizado → exit `0`, 19/19.
  - `bash SDD/tests/run.sh` (suite completa, 6 archivos) → exit `0`.
  - `shellcheck --severity=warning plugins/sdd-flow/scripts/*.sh plugins/sdd-flow/hooks/*.sh SDD/tests/*.sh` → exit `0`. Confirmado por medición (no supuesto) que el único SC2016 nuevo a severidad default cae en una línea YA contada en la deuda `D4` (2 hallazgos preexistentes en `sdd-run-gates.sh`, no 3 nuevos).
  - `bash SDD/tests/secret-scan.sh` (con `git add` hecho primero — D8: sin stagear no escanea los archivos nuevos) → exit `0`, 88 archivos.
- **Blockers**: ninguno.
- **Files changed**: ver "Files" arriba (7 declarados + 1 no declarado, `test_run_gates_tree.sh`, justificado en su propia fila).
- **Final statement**: los 7 ACs (AC29-AC35) tienen test real y pasan; AC30 (detección) probado por mutación doble con el triple registrado; ningún gate `[SKIPPED]` sin razón; cero mitigaciones prohibidas; el único diff fuera de la tabla original de Files es una actualización de literal en un test ya `APPROVED` de R1, consecuencia directa y documentada de T2.2.
