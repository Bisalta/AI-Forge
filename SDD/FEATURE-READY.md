# Feature Ready — sdd-flow v0.11.0 · hardening desde el análisis de SICOP

**Branch**: `feat-GEN-94-sicop-hardening` → `prod` · **Contract**: `SDD/contracts/2026-08-13-sicop-hardening.md` **v8** · **Proxima**: `GEN-94`

## Qué es

Seis cambios al plugin, pedidos por SICOP y Taller de Servicio tras medir el proceso en producción. Todos atacan la misma familia: **un artefacto que afirma una propiedad que no puede sostener**. Evidencia sellada contra el código equivocado, una guarda de autoría verdadera siempre, controles sin poder de detección, análisis que produce números de decisión sin pasar por review, y documentos de gobierno identificados por ruta en vez de por contenido.

| | Requerimiento | Arquetipo | Rondas |
|---|---|---|---|
| R0 | Escalera de gates viva para AI-Forge (harness, lint, secret scan) | `project-scaffold` | 3 |
| R1 | El runner sella el árbol verificado, no `HEAD` | `bugfix` | 2 |
| R2 | Identidad propia del agente en los commits | `infra` | 2 |
| R5 | Identidad de contenido (hash) de los docs que gobiernan | `infra` | 1 |
| R3 | Prueba por mutación de todo AC de detección | `infra` | 2 |
| R4 | Arquetipo `analysis` + guards de `sdd-check.sh` | `infra` | 3 |

## Decisiones que tomé por vos

- **`git stash create`, no `git write-tree`** (R1) — `write-tree` sólo captura el índice, así que un cambio sin `git add` seguiría sin quedar representado y el hash seguiría mintiendo. El documento de SICOP proponía `write-tree`.
- **La estrictez se deriva del destino del reporte, no de una bandera** (R1) — `-o` fuera de `.sdd/` exige árbol limpio y sale 4. El modo de falla que se ataca es el olvido, y una bandera que hay que recordar reproduce el olvido.
- **El enforcement de identidad va en el hook, no en la disciplina del agente** (R2) — el documento proponía `git -c user.name=... commit` por comando. Eso depende de que el agente se acuerde cada vez, que es el mismo modo de falla. Nace apagado (`SDD_AGENT_ENFORCE=1`) porque el hook corre en repos de humanos.
- **La propuesta 6 del consolidado quedó fuera** — el gate mínimo portable está planteado como oferta y necesita como insumo el script de `Bisalta/Odoo-Addons`, que este ciclo no tiene.
- **Ocho ratificaciones de contract durante la ejecución** (v1→v8). Seis de ellas cerraron defectos de mi propio plan, no del código.

## Dónde está el riesgo

**Ninguno de los seis cambios toca runtime de producto: son tooling y normas.** El riesgo real es de adopción, no de rotura.

1. **R3 sube el costo de cada AC de detección de una corrida a tres.** Lo único que lo acota es el criterio de `quality-gates.md` §10.1, que el reviewer probó contra nueve ACs reales: ocho clasifican solos. Si ese criterio se lee mal, el pipeline se encarece entero.
2. **El checklist estadístico de `analysis` es el único punto ciego estructural del ciclo.** Un ítem mal formulado no se detecta midiendo el plugin — sólo el día que alguien lo aplica a un dataset real. Dos de los siete ya eran autosatisfacibles y se corrigieron; el reviewer dio segunda lectura y los sostiene, pero ninguno de los tres somos estadísticos.
3. **R2 no está enforceando en este repo.** `SDD_AGENT_ENFORCE` está apagado (`D3`), así que los 16 commits de `sdd-agent` son disciplina del agente, no del hook. Falta decidir en qué repos se activa.

## Qué mirar en 5 minutos

1. **`plugins/sdd-flow/standards/quality-gates.md` §10** — la regla de mutación. Es el cambio de mayor rendimiento y el que te cambia el proceso. Leé §10.1: es el criterio que decide qué AC cuesta tres corridas.
2. **`plugins/sdd-flow/scripts/sdd-run-gates.sh`, bloque de sellado** — el fix de R1. Comparalo con `git rev-parse <commit>^{tree}` de cualquier reporte en `SDD/verification/`.
3. **`git log --format='%an <%ae>' origin/prod..HEAD | sort | uniq -c`** — devuelve dos identidades. Es el comando exacto que en SICOP devolvía una sola, y es toda la prueba de R2.
4. **`SDD/retro.md`** — once entradas escritas durante el ciclo. Es lo que más vale del PR y no estaba pedido por nadie.

## Estado honesto

| | |
|---|---|
| ACs | **42/42 con test verde**, cero `manual-only` |
| Gates | verde. 7 `[SKIPPED]`, todos filas `N/A` declaradas (sin formatter, sin type-check, sin build, sin e2e, sin coverage — es un repo de markdown + bash) |
| Review | `APPROVED` en los seis. Un `ESCALATE` y un `REJECTED` en el camino, los dos resueltos ratificando contract |
| Suite | 8/8 archivos de test, corrida completa en cada requerimiento |
| Rojos preexistentes | ninguno |
| Deuda dejada | **11 ítems** (`D1`-`D11`) en `SDD/debt.md`, todos `MINOR` salvo `D1` (CI ausente, `MAJOR`) |
| Advisory | sin SEO (no hay frontend) |

### Tres cosas que no hay que leer como más fuertes de lo que son

- La evidencia regenerada de R0 sella `c92c065`, un árbol que **también contiene R1**. Es honesta —nombra el árbol que efectivamente corrió— pero no es un árbol sólo-R0.
- La guarda de autoría de R2 **no está enforceando en este repo** (`D3`).
- El arquetipo `analysis` entra **sin caso golden** en el corpus propio del plugin (`D9`), o sea sin caso de regresión.

## Lo que falta y no está en este PR

- **Bump de `plugin.json` a `0.11.0`** y entrada de `CHANGELOG.md`. No lo hice porque la versión del plugin es una decisión de release tuya, no del ciclo. Los scripts ya declaran `0.12.0` (`sdd-run-gates.sh`) y `0.10.0` (los otros dos).
- **Actualizar `CLAUDE.md`** con el estado nuevo.
- La propuesta 6 del consolidado externo (gate mínimo portable para repos sin herramientas).

## Apéndice — evidencia

- Contract: [`SDD/contracts/2026-08-13-sicop-hardening.md`](SDD/contracts/2026-08-13-sicop-hardening.md) (v8, ocho ratificaciones documentadas)
- Briefs: `SDD/briefs/R0`…`R5`
- Verification reports + reportes de gates generados por el runner: `SDD/verification/`
- Retro: [`SDD/retro.md`](SDD/retro.md) · Deuda: [`SDD/debt.md`](SDD/debt.md)
- Escalera de este repo: [`SDD/docs/doc_quality_gates.md`](SDD/docs/doc_quality_gates.md)
