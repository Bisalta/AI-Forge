# Orchestration — contrato de máquina del ciclo SDD

Lo que un orquestador necesita para tomar decisiones sin parsear prosa. Tres piezas: **estado** (`.sdd/state.json`), **retornos estructurados** (el último bloque JSON de cada subagente) y **reglas de spawn** (mecanismo, serialización, caps, resume).

Los markdown del protocolo (`contract.md`, `status.md`, `verification/`) siguen siendo la vista humana y la fuente de detalle. Este contrato es la vista máquina. Si difieren, gana la evidencia (`verification/`) y el state se corrige — el state es un índice, no una segunda verdad.

---

## 1. `.sdd/state.json` — estado de runtime (single-writer: el planner)

Vive en la raíz del repo donde corre `/sdd` (gitignoreado — es estado de runtime, no artefacto). **Solo el planner/orquestador lo escribe**, en cada transición (ver §4). La statusline y `/sdd-status` lo leen.

```json
{
  "version": 1,
  "task": "checkout-discounts",
  "planner": { "session": "descripcion-o-id-de-esta-sesion", "claimed_at": "2026-08-04T17:30:00Z" },
  "phase": 4,
  "phases_total": 5,
  "phase_name": "ejecucion",
  "agents_active": 2,
  "blocked": 0,
  "contract_version": "v2",
  "archetype": "api-endpoint",
  "updated_at": "2026-08-04T18:00:00Z",
  "caps": { "max_rounds": 3, "max_gate_retries": 2, "max_parallel_agents": 3 },
  "agents": [
    {
      "id": "AGENT_be",
      "repo": ".",
      "branch": "feat-GEN-30-be-discounts",
      "model": "sonnet",
      "status": "working",
      "round": 1,
      "acs": { "total": 4, "passed": 2, "missing_test": 1 },
      "gates": { "green": 5, "red": 1, "skipped": 0 },
      "spawned_at": "2026-08-04T17:40:00Z",
      "returned_at": null,
      "verdict": null,
      "commit": null,
      "blocker": null,
      "verification": "tasks/checkout-discounts/verification/AGENT_be.md"
    }
  ],
  "escalations": []
}
```

Reglas:
- **Lock de planner**: al asumir un ciclo escribís `planner` con un identificador de tu sesión. Si al arrancar encontrás un state con `planner` ajeno y `updated_at` reciente (< 2 h), **no asumas ownership** — puede haber otro planner vivo: preguntá al usuario antes de tocar nada. `updated_at` viejo = planner muerto, reclamalo escribiendo tu `planner` y anotándolo en el log.
- `phase`, `phases_total`, `agents_active`, `blocked` son **planos y obligatorios** (la statusline los lee tal cual; no anidarlos).
- `agents[].status`: `pending | spawned | working | blocked | review | done | failed`. `failed` = el subagente murió o devolvió basura no parseable — distinto de `blocked` (pidió una decisión).
- `escalations[]`: una entrada por `ESCALATE` del reviewer (`{agent, round, reason, resolved}`) — es el insumo de la retro (§6).
- Timestamps siempre UTC ISO-8601.
- Números derivables (ej. `agents_active`) se recalculan al escribir, nunca se editan a mano sueltos.

---

## 2. Retorno del implementing agent (`sdd.result`)

Todo brief instruye al agente a **terminar su output con exactamente un bloque JSON** (fenced, el último del mensaje):

```json
{
  "type": "sdd.result",
  "agent": "AGENT_be",
  "status": "done",
  "round": 1,
  "contract_version": "v2",
  "acs": [
    { "id": "AC1", "test": "tests/orders.spec.ts::\"creates order\"", "state": "pass" },
    { "id": "AC3", "test": null, "state": "manual", "note": "smoke ejecutado, ver verification" }
  ],
  "gates": [
    { "gate": "type-check", "cmd": "pnpm tsc --noEmit", "exit": 0 },
    { "gate": "unit", "cmd": "pnpm vitest run", "exit": 0 }
  ],
  "verification": "tasks/checkout-discounts/verification/AGENT_be.md",
  "files": ["src/services/discounts.ts", "tests/orders.spec.ts"],
  "commit": "abc1234",
  "blockers": [],
  "notes": "una línea, opcional"
}
```

- `status`: `done | blocked | failed`. Con `blocked`, `blockers[]` lleva la pregunta concreta al planner (`{question, needed_decision}`).
- `acs[].state`: `pass | fail | manual | missing` — `missing` es admisión honesta de AC sin test; el orquestador lo trata como no-done.
- `gates[]` tiene que ser **consistente con el reporte del runner** (`sdd-run-gates.sh` emite su propia línea `{"type":"sdd.gates",...}` y el archivo generado): si el `sdd.result` dice verde y el reporte generado dice rojo, gana el reporte y el `done` se rechaza.
- El bloque **complementa** el Execution Report y `verification/` — no los reemplaza. Es el índice parseable; el detalle vive en los markdown.

## 3. Retorno del reviewer agent (`sdd.review`)

```json
{
  "type": "sdd.review",
  "agent": "AGENT_be",
  "round": 2,
  "verdict": "REJECTED",
  "findings": [
    { "sev": "MAJOR", "loc": "src/services/discounts.ts:41", "msg": "caller jobs/retry.ts sin regresión ni justificación", "fix": "test de regresión sobre retryOrders" }
  ],
  "seo_advisory": []
}
```

`verdict`: `APPROVED | REJECTED | ESCALATE`. `findings[].sev`: `BLOCKER | MAJOR | MINOR | ADVISORY`.

---

## 4. Protocolo del orquestador

### Transiciones (escribir state ANTES y DESPUÉS de cada spawn)

1. **Antes de spawnear**: agente → `spawned`, `spawned_at` = ahora. *Recién después* spawneás. Así un crash a mitad de spawn es detectable (spawned sin returned = sospechoso al reanudar).
2. **Al retornar**: parseá el último bloque JSON del output. Si no parsea o no es `sdd.result` → `status: failed` (un reintento de spawn como máximo; segundo fallo → reportar al humano). Si parsea: `returned_at`, `commit`, contadores de `acs`/`gates` al state.
3. **Aceptación de un `done` — no confíes, validá el artefacto** (barato, sin re-correr nada):
   - el archivo `verification` existe y tiene la tabla de gates con exit codes;
   - ningún `acs[].state` es `missing` ni `fail`;
   - ningún gate aplicable con `exit != 0` sin corrida verde posterior;
   - `contract_version` del result == versión vigente.
   Si algo falla → tratá el `done` como `working` y devolvé el hallazgo al agente (cuenta ronda).
4. **Review**: agente → `review`, spawneá `reviewer-agent`, parseá `sdd.review`, escribí `verdict` y (si `REJECTED`) round+1. `ESCALATE` → entrada en `escalations[]` y decisión del planner.
5. **`blocked`**: respondé la pregunta (ratificando contract si hace falta — bump de versión) y re-spawneá con la decisión en el brief. Un blocked NO consume ronda de review.

### Mecanismo de spawn

- **Con Agent tool disponible**: un subagente por brief — `implementing-agent` del plugin, **pasando el modelo del brief** (`sonnet`/`opus`/`haiku`) como override del spawn; el frontmatter del agente es solo el default. Review: `reviewer-agent` (opus).
- **Sin Agent tool** (entorno sin subagentes): **degradá a ejecución inline** — la sesión ejecuta los briefs en serie, uno por uno, respetando igual el resto del contrato (state, evidencia, retornos como bloques al cerrar cada brief). Avisá una vez qué modo estás usando. Degradar es correcto; romper no.
- El prompt de spawn lleva: el brief completo, la ruta del contract (+ versión vigente), la ruta de `doc_quality_gates.md`, y la instrucción del bloque `sdd.result`.

### Serialización por repo (regla dura)

**Máximo un agente activo por repo a la vez.** Dos agentes en paralelo sobre el mismo working tree se pisan (archivos, index de git, servers de test). Si dos briefs tocan el mismo repo: se serializan (orden del contract), o el planner los asigna a **git worktrees separados** declarándolo en el brief. Agentes de repos distintos sí corren en paralelo, hasta `max_parallel_agents`.

### Caps (para que "autónomo" no sea "infinito")

| Cap | Default | Al alcanzarlo |
|---|---|---|
| `max_rounds` (review por brief) | 3 | `ESCALATE` al planner (ya normado en `quality-gates.md` §7.4) |
| `max_gate_retries` (mismo gate rojo, mismo agente) | 2 | `blocked` — el tercer intento idéntico no va a ser distinto |
| `max_parallel_agents` | 3 | encolar |
| re-spawn por `failed` | 1 | reportar al humano y parar ese brief |

Los caps viven en el state (el usuario puede pedirlos distintos al arrancar `/sdd`); el orquestador nunca los sube solo a mitad de ciclo.

---

## 5. Resume (las sesiones se mueren; el ciclo no)

Al arrancar, `/sdd` chequea si existe `.sdd/state.json` con `phase < 5`:

1. Si existe → **ofrecé reanudar** (mostrando task, fase, estado por agente) antes de empezar nada nuevo. Reanudar ≠ reejecutar: los agentes en `done` con veredicto `APPROVED` no se relanzan.
2. Agente en `spawned`/`working` con `returned_at: null` → su sesión murió a mitad de trabajo. Verificá el estado real (¿hay commits en su branch? ¿avanzó su `verification/`?) y re-spawneá **desde su brief**, indicándole que puede haber trabajo parcial en la branch — que lo lea, no que lo repita a ciegas.
3. State corrupto/no parseable → renombralo a `.sdd/state.json.bak`, avisá, y arrancá limpio. Nunca frenes el ciclo por un state roto.
4. `.sdd/` va en `.gitignore` (agregalo si falta). El state no viaja en PRs.

---

## 6. Retro (el sistema aprende o repite)

`SDD/retro.md`, append-only, una línea por evento — la escribe el planner:

```
- 2026-08-04 · checkout-discounts · ESCALATE AGENT_be ronda 3 · el contract no cerraba el redondeo de descuentos → regla nueva candidata a doc_architecture
- 2026-08-04 · checkout-discounts · gate integration falló 2 veces por .env.test ausente → prerequisito agregado a doc_quality_gates
```

Se escribe en el momento (al resolver un `ESCALATE`, al cerrar un blocker repetido, al descubrir un prerequisito no documentado). En Feature Ready el planner la relee: si un patrón se repite, propone el ajuste al doc que corresponda (`doc_architecture`, `doc_quality_gates`, standards). Sin esto, cada ciclo tropieza con la misma piedra.

### 6.1 Evento contable (para `SDD/escalations.md`)

Un subconjunto de lo anterior necesita clasificación explícita, no sólo una línea narrativa: **toda ratificación de contract (bump de versión) motivada por un defecto**, sea cual sea la puerta procedural por la que llegó —

- `ESCALATE` (rondas agotadas) o `REJECTED` con causa que exigió cambiar el contract;
- `BLOCKED` cuya resolución fue ratificar el contract, no sólo responder una pregunta dejándolo intacto;
- una re-review (incluida una que resultó en `APPROVED` del trabajo) que encontró que **el contract mismo** incumplía una regla que él mismo declaraba.

**No cuenta** una ratificación que sólo amplía scope por una decisión externa, sin que nada de lo ya escrito estuviera mal (agregar un requerimiento nuevo porque llegó un pedido, no porque el anterior tuviera un defecto).

La `Clase` de cada evento (`plan` · `decisión` · `medición` · `otro`) la decide el planner en el mismo acto de ratificar — ver `SDD/escalations.md` para el formato y `SDD/scripts/sdd-escalation-tally.sh` para el conteo. `plan` cubre las dos formas: el implementador cumplió literalmente lo pedido y estaba mal, **o** lo detectó antes de implementarlo y preguntó (`BLOCKED`) — en ambas el defecto vive en lo que el contract pedía, no en el juicio de quien lo ejecutó.
