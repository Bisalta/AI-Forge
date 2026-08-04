# ai-forge

Marketplace interno de **Bisalta Ltda** para tooling de Claude Code — plugins, skills y standards de desarrollo asistido por AI.

## Instalación (en cualquier proyecto)

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install sdd-flow@ai-forge
/plugin install project-foundation@ai-forge
```

Después corré `/reload-plugins` (o reiniciá la sesión). Tipeá `/` y vas a ver los comandos de cada plugin (`/sdd-flow:sdd`, `/project-foundation:init`, etc).

## Actualización (ya lo tenías instalado)

**No hace falta desinstalar.** El flujo es:

```
/plugin marketplace update ai-forge     ← refresca el catálogo (baja lo último de la rama default del repo)
/plugin install sdd-flow@ai-forge       ← reinstala sobre la versión anterior
/reload-plugins                         ← activa la nueva versión en la sesión actual
```

Notas:
- **El marketplace sirve lo que está en la rama default (`prod`)**: un PR abierto en AI-Forge no te llega hasta que se mergea. Si acabás de mergear un PR del plugin, corré el `marketplace update` primero — sin eso, reinstalar te da la versión vieja del catálogo cacheado.
- Podés activar **auto-update** para este marketplace: `/plugin` → tab **Marketplaces** → `ai-forge` → *Enable auto-update* (los marketplaces de terceros vienen con auto-update apagado por default). Con eso Claude Code refresca catálogo y plugins solo, y te avisa cuándo correr `/reload-plugins`.
- Verificá qué versión te quedó: `/plugin` → tab **Installed** → `sdd-flow` (compará contra el `CHANGELOG.md` de este repo).

### Entornos sin `/plugin` (Claude Code web / sesiones cloud)

En sesiones remotas el panel `/plugin` no existe (`/plugin isn't available in this environment`) — es un comando de la CLI de terminal y de la app de escritorio. Para que los plugins estén disponibles en sesiones web/cloud, declaralos en el `.claude/settings.json` **del repo donde trabajás**:

```json
{
  "extraKnownMarketplaces": {
    "ai-forge": {
      "source": { "source": "github", "repo": "Bisalta/AI-Forge" }
    }
  },
  "enabledPlugins": {
    "sdd-flow@ai-forge": true,
    "project-foundation@ai-forge": true
  }
}
```

Bonus: con eso commiteado, cualquier dev que abra ese repo (local o web) recibe el prompt para instalar los plugins — es la vía recomendada para adoptarlos como standard del equipo, sin que cada uno corra comandos a mano.

## Plugins disponibles

| Plugin | Versión | Qué hace |
|---|---|---|
| [**sdd-flow**](./plugins/sdd-flow) | 0.10.0 | Spec-Driven Development multi-agente: refinement con arquetipo/NFR/concerns, planner Opus 4.8 con threat model y ACs numerados, orquestación con estado y caps, subagentes con quality gates verificables y gate de seguridad, coordinación file-based `AGENT_{uuid}`. |
| [**project-foundation**](./plugins/project-foundation) | 0.1.0 | Crea o back-fillea los seis documentos fundacionales de un proyecto (PRD, TRD, UI/UX Brief, App Flow, Backend Schema, Implementation Plan) desde cero o derivando de un codebase existente. Interopera con `sdd-flow` si ambos están instalados. |

## Estructura

```
ai-forge/
├── .claude-plugin/marketplace.json   índice del marketplace
├── plugins/
│   ├── sdd-flow/                      SDD multi-agente (ver su README)
│   └── project-foundation/            seis docs fundacionales (ver su README)
├── CHANGELOG.md
└── README.md
```

## Cómo usar sdd-flow

### Flujo típico (del requerimiento al código)

```
/sdd-enrich <idea cruda>          → cierra decisiones, produce requerimiento
/sdd-contract <slug o req>        → genera el contrato técnico (HLTC)
/sdd <descripcion de lo que querés lograr>   → ciclo completo autónomo
```

### Qué esperar al correr `/sdd` (dónde pregunta, dónde corre solo, dónde para)

1. **Al arranque te pregunta lo mínimo** (≤2 rondas agrupadas): decisiones del requerimiento que no puede inferir del código, arquetipo si es ambiguo, tracking Proxima (si el MCP está), y **la rama base** (una vez). Todo lo inferible te lo propone como default ya elegido, con evidencia.
2. **Después corre solo** hasta Feature Ready: contract auto-aprobado (con linter de closure), task briefs, implementación, review hasta 3 rondas, gates con evidencia generada por script. Solo te interrumpe si un agente queda `BLOCKED` (falta una decisión) o un review escala (`ESCALATE`).
3. **En Feature Ready PARA — siempre.** Te entrega un brief de una pantalla (qué es, decisiones que tomó por vos, dónde está el riesgo, qué mirar en 5 minutos) y espera tu revisión. **Nunca abre el PR solo**: vos decidís, y ahí mismo le podés decir "dale, abrí el PR" (o usar `/sdd-pr` para generar la descripción). Es la decisión de diseño #2 del plugin: un solo gate humano, pero de verdad.

Casos especiales: repo sin tests/gates → la primera task es `project-scaffold` (funda la infraestructura de calidad antes de la feature); pedido trivial (typo, fix chico) → te propone la vía corta `/sdd-fixes` en vez de la ceremonia completa.

### Comandos disponibles

| Comando | Cuándo usarlo |
|---|---|
| `/sdd-init` | Bootstrapea (o llena) `SDD/docs/doc_architecture.md`, `doc_verification_guide.md` y `doc_quality_gates.md` — derivando de un codebase existente o entrevistando en greenfield. Corrélo si `/sdd-enrich` frena por falta de estos docs, o al arrancar sdd-flow en un repo nuevo. |
| `/sdd <idea>` | Ciclo SDD completo: refinement → contract → specs → ejecución multi-agente. Usalo cuando tenés una tarea nueva. |
| `/sdd-enrich <idea>` | Solo la fase de refinement. Útil para cerrar decisiones antes de planear o cuando la tarea es compleja y querés separar el "qué" del "cómo". |
| `/sdd-contract <slug>` | Genera o actualiza el High-Level Technical Contract (HLTC). Útil si ya tenés el requerimiento cerrado y querés planear sin ejecutar. |
| `/sdd-verify` | Corre la escalera de gates (format → lint → type-check → tests → build → cobertura del diff) y escribe la evidencia con comando + exit code. Usalo antes de declarar algo terminado o de abrir el PR. |
| `/sdd-status` | Tablero de estado: tareas activas, estado de gates por agente, ACs sin test, bloqueos, mensajes sin procesar, versión de contract. Solo lectura. |
| `/sdd-pr` | Genera la descripción del Pull Request a partir de los cambios del repo. Usalo antes de abrir el PR. |
| `/sdd-agents` | Bootstrapea coordinación file-based multi-agente (`AGENT_<slug>`) para una task que cruza varios repos. |
| `/sdd-fixes` | Estructura una tanda de fixes/ajustes sueltos en `fixes.md`, con triage automático (trivial/mediano/ambiguo). |
| `/sdd-seo` | Auditoría SEO advisory on-demand del frontend actual contra `standards/seo-frontend.md`. |

### Cómo funciona internamente

El **planner (Opus 4.8)** toma la idea, cierra decisiones en 6 dimensiones (solution shape, output, behavior, actor, scope, success criteria), produce el HLTC y corta task briefs por `AGENT_{uuid}` (un agente = un repo + branch + working-dir). Cada task brief lleva modelo asignado (`sonnet` default, `opus` para tareas pesadas, `haiku` para triviales). Los **agentes implementadores** ejecutan; un **reviewer agent (Opus)** valida. Si un agente se bloquea por decisión no resuelta → le pregunta al planner, no adivina.

### Closure rules (el contract es innegociable)

El pipeline corre sin aprobación humana, por eso el contract debe ser preciso: **prohibido** "if needed / or / prefer / may be / when available". Si dos ingenieros lo implementarían distinto, la spec es inválida y el agente frena.

### Quality gates (probado, no "declarado como probado")

Misma lógica aplicada a la calidad del código, en `standards/quality-gates.md`:

- El contract emite **acceptance criteria numerados** (`AC1..ACn`) y cada uno tiene que quedar atado a un test concreto (`archivo::"caso"`). **AC sin test no se aprueba**, aunque la suite esté verde.
- La **escalera de gates** corre siempre antes de declarar algo terminado, con los comandos reales del repo (`SDD/docs/doc_quality_gates.md`, lo genera `/sdd-init`) — ningún agente inventa comandos.
- Cada `done` deja **evidencia con exit codes**; el reviewer re-corre el subset barato y compara en vez de creerle al reporte.
- **Prohibido ablandar el gate** (skipear un test, `@ts-ignore`, bajar un threshold, `--no-verify`). Si un gate no pasa, el agente se bloquea y pregunta — no toma el atajo. Tres de esas prohibiciones las bloquea un hook, no un prompt.
- Review con severidades y **cota de 3 rondas**: si no cierra, escala en vez de degradar los tests para salir del loop.

---

## Agregar un plugin nuevo

1. Crear `plugins/<nombre>/.claude-plugin/plugin.json` + sus `commands/skills/agents`.
2. Registrarlo en `.claude-plugin/marketplace.json` (`plugins[]` con `source: "./plugins/<nombre>"`).
3. Bumpear versión en el `plugin.json` del plugin y anotar en `CHANGELOG.md`.

## Versionado

SemVer por plugin (`MAJOR.MINOR.PATCH`) en cada `plugin.json`. El marketplace no tiene versión propia; lo que versiona es cada plugin. Cómo actualizar: ver la sección **Actualización** de arriba.
