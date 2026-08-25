# Optimización de consumo de `sdd-flow` — diseño

**Fecha**: 2026-08-25 · **Ciclo**: GEN-101 · **Estado**: propuesta, pendiente de opinión de Esteban Fait
**Autor**: Gabriel Rojas + planner SDD

---

## 1. El problema, en una línea

De la factura de Opus de una sesión real de `/sdd`, **el 87% no es razonamiento: es contexto re-leído**.

## 2. Medición

### 2.1 Lo que se midió (sesión real, panel de uso)

| Métrica | Valor |
|---|---|
| Costo de sesión | $442.32 |
| Opus / Sonnet / Fable | 84% / 13% / 3% |
| Output de Opus | 1.9 M tokens |
| **Cache read de Opus** | **945.7 M tokens** |
| Cache write de Opus | 43.7 M tokens |
| Cache hit rate | 96% |
| Sesiones sobre 150k de contexto | 67% |
| Sesiones con 4+ en paralelo | 44% |
| `sdd-flow` como % del límite | 24% |

**El cálculo que ordena todo lo demás.** 1.9 M tokens de output a $25/MTok = **~$47**. Sobre $372.64 de factura de Opus, el output es el **13%**. El otro 87% es contexto que entra de nuevo en cada turno.

Con 96% de cache hit ya no queda nada que ganar por el lado del *hit rate*. Cachear abarata re-leer; no lo hace gratis. Lo que queda es **leer menos** y **re-leer menos veces**.

### 2.2 Lo que se midió en el repo

| Artefacto | Peso | Nota |
|---|---|---|
| Plugin `sdd-flow` completo | ~68.300 tok | todo el markdown |
| `standards/quality-gates.md` | ~7.200 tok | referenciado por 6 de 7 artefactos |
| `standards/archetypes.md` | ~3.570 tok | **11 secciones; un ciclo usa exactamente 1 arquetipo** |
| `standards/concerns.md` | ~1.820 tok | 10 secciones; un ciclo activa 2–4 |
| `skills/sdd-plan/SKILL.md` | ~4.320 tok | el skill más pesado |

`SDD/retro.md` RT6, medido en el ciclo GEN-94: **R0 consumió 3 rondas y ~1,0 M tokens** — un solo requerimiento.

### 2.3 El desperdicio estructural, calculado

Un ciclo carga el archivo completo pero usa una fracción:

| Archivo | Cargado | Usado (típico) | Desperdicio |
|---|---|---|---|
| `archetypes.md` | 3.570 tok | ~420 tok (1 arquetipo + cómo se usa) | **88%** |
| `concerns.md` | 1.820 tok | ~520 tok (security + observability + 1) | **71%** |
| `quality-gates.md` → implementing-agent | 7.200 tok | ~4.620 tok (§1,3,4,5,6,10) | 36% |
| `quality-gates.md` → reviewer-agent | 7.200 tok | ~5.160 tok (§1,3,5,6,7,10) | 28% |
| `quality-gates.md` → planner | 7.200 tok | ~2.840 tok (§1,2,3,10) | 61% |

Aproximadamente **7.000 tokens de peso muerto por cada spawn de agente**, re-leídos en cada turno de ese agente.

---

## 3. La jerarquía de palancas

El costo es, en esencia:

```
costo ≈ Σ ( tamaño_de_contexto × turnos ) × precio_del_tier
```

Tres multiplicandos, tres familias de palanca. **No tienen el mismo orden de magnitud** y la intuición las ordena mal.

### Palanca A — la ronda que no corrés  ·  *step function*

**La evidencia**: en GEN-94, de los ocho defectos que encontró el review, **seis eran del plan, no del código**. En los seis, el implementador cumplió literalmente lo pedido y lo pedido estaba mal (`SDD/retro.md` RT1, RT2, RT9).

Cada defecto de plan cuesta **una ronda entera**: spawn + implementación + review + `ESCALATE` + ratificación del contract + re-spawn. RT6 mide una ronda en el orden de los **300k tokens**.

**Lo que ya está identificado y sin implementar** (pendiente #1 del `CLAUDE.md`, escrito durante GEN-94):

1. `sdd-lint-contract.sh` detecta frases abiertas y paths alucinados, pero **no secciones obligatorias ausentes**. Por eso un contract sin threat model se auto-aprobó y costó la ronda de RT1.
2. El self-review de `sdd-plan` no verifica cada AC contra el out-of-scope de su propio requerimiento. Por eso RT2: un AC insatisfacible sin tocar lo prohibido.
3. El Delta ubica código por vecindad ("tras X") en vez de por la condición que debe valer. Por eso RT9.

**Los tres son chequeos mecánicos sobre texto que el planner ya escribió.** Cuestan cientos de tokens y matan rondas de cientos de miles.

> **El token más barato es la ronda que nunca corrés.** Recortar archivos es lineal; matar una ronda es un escalón.

### Palanca B — el contexto que no cargás  ·  *lineal × turnos*

Seccionar los standards y que cada rol cargue su subconjunto:

- **`archetypes.md`**: cargar **el arquetipo elegido**, no los diez. El refinement ya obliga a elegir exactamente uno — la selección existe, sólo no se usa para filtrar. Ahorro: ~3.150 tok por contexto.
- **`concerns.md`**: cargar los concerns **activos**. El bloque `concerns:` ya los declara. Ahorro: ~1.300 tok.
- **`quality-gates.md`**: partir por secciones y que cada rol cargue las suyas. Ahorro: 2.000–4.400 tok según el rol.
- **Frontmatter de skills**: **ninguno de los 7 skills declara `model:`**. Es una palanca del harness que está sin usar.

### Palanca C — el tier del modelo  ·  *lineal × tokens*

| Modelo | Input $/MTok | Output $/MTok | Contexto |
|---|---|---|---|
| Opus 5 | $5.00 | $25.00 | 1 M |
| Opus 4.8 | $5.00 | $25.00 | 1 M |
| Sonnet 5 | $3.00 (intro $2.00 hasta 31-ago-2026) | $15.00 (intro $10.00) | 1 M |
| Haiku 4.5 | $1.00 | $5.00 | **200 K** |

**Hallazgo que cambia la premisa**: los agents usan **alias de tier** (`model: opus`, `model: sonnet`), no IDs pinneados. Los alias resuelven al último de cada tier, así que **en runtime ya corre Opus 5 / Sonnet 5**. Lo desactualizado es la prosa: `README.md`, la `description` del `plugin.json`, `commands/sdd.md:8` y `skills/sdd-plan/SKILL.md:8` (que sí escribe `claude-opus-4-8` a mano).

Y **Opus 5 cuesta exactamente lo mismo que Opus 4.8**. Corregir la prosa **no ahorra un peso** — es capacidad gratis. La regla que evita que vuelva a envejecer: **el plugin declara tier, nunca versión.**

**Haiku**: el techo es 200 K y el **67% de las sesiones corre sobre 150 K**. Entra donde el contexto es chico y el trabajo determinístico — `write-pr-report`, `sdd-status`, triage de `/sdd-fixes` — y en el implementing-agent cuando el brief es trivial. Ese slot (`haiku si trivial`) existe desde v0.1 y **nunca se usó**: en GEN-94 fueron sonnet×4, opus×2, **haiku×0**.

### Palanca D — las sesiones en paralelo  ·  *fuera del plugin*

44% del consumo ocurrió con 4+ sesiones simultáneas. Cada una carga su contexto completo. Es disciplina de trabajo, no código — se documenta y no se implementa.

---

## 4. Lo que NO se toca, y por qué

- **El reviewer no se abarata.** Corre en Opus y ahí se queda. En GEN-94 encontró 8 defectos, 6 de ellos del plan. Es el detector: bajarle el tier es apagar justo lo que atrapa los defectos que cuestan rondas.
- **El planner sigue en Opus.** Es el que decide, y sus errores son los caros.
- **No se pinnean IDs de modelo.** Ese es el bug actual con otra versión encima.

---

## 5. Orden propuesto

| # | Trabajo | Arquetipo | Palanca | Bloqueante |
|---|---|---|---|---|
| R1 | Validación de consumo — instrumentar y medir de verdad | `analysis` | — | no |
| R2 | Des-pinnear modelos de la prosa + regla "tier, nunca versión" | `refactor` | C | no |
| R3 | Tiering: Haiku en mecánico + activar el slot trivial | `refactor` | C | no |
| R4 | Linter de secciones obligatorias + self-review de ACs vs out-of-scope | `refactor` | **A** | no |
| R5 | Seccionar standards y cargar por rol/selección | `refactor` | B | **sí — espera opinión de Esteban** |

R1–R4 no dependen de nadie externo y corren ya. **R5 es el invasivo** — toca la superficie normativa que todos los agentes leen — y es el que va a consulta.

---

## 6. Honestidad sobre lo que no sabemos

Los ratios de desperdicio (88%, 71%, 36%) están **medidos**. El ahorro en dólares **no está medido**: depende de cuántos turnos vive cada contexto, y eso hoy no se instrumenta. Por eso R1 es `analysis` y va primero — para cerrar el lazo con números, no con estimaciones.

No prometemos un porcentaje de ahorro. Prometemos medirlo.

---

## 7. La pregunta para Esteban

**R5 parte `quality-gates.md`, `archetypes.md` y `concerns.md` en secciones cargadas por rol.** Es donde está el desperdicio estructural medido, y también donde está el riesgo: esos tres archivos son la superficie normativa que hace que un ciclo SDD sea auditable. Partirlos mal significa que un agente deja de leer una regla que sí le aplicaba.

1. ¿Vale el riesgo, o preferís que primero corramos R1–R4 y midamos cuánto queda?
2. Si entra: ¿la partición la gobierna el **rol** (implementing / reviewer / planner) o la **selección** (arquetipo y concerns elegidos)? Son ejes distintos y se pueden combinar.
3. ¿Hay algún consumidor de estos standards fuera de `sdd-flow` que debamos considerar antes de partirlos?
