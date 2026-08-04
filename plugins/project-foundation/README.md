# project-foundation

Plugin de Claude Code para crear (o back-fillear) los **seis documentos fundacionales** que todo proyecto debería tener desde el día cero: PRD, TRD, UI/UX Brief, App Flow, Backend Schema e Implementation Plan.

Funciona **greenfield** (entrevista al usuario — no puede inventar la visión de producto) y en **proyecto existente** (deriva del codebase — el prompt instruye usar subagentes de exploración en paralelo cuando el entorno los soporta, sin que eso sea un mecanismo cableado — luego confirma supuestos).

## Instalación

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install project-foundation
```

## Uso

| Comando | Qué hace |
|---|---|
| `/project-foundation:init [greenfield\|existing] [dir] [only: 1,2,..]` | Crea o back-fillea los seis documentos, en `docs/foundation/` por defecto. |

También se auto-invoca por descripción cuando el usuario pide un PRD, TRD, brief de diseño, app flow, esquema de backend o plan de implementación sin usar el comando explícito.

## Los seis documentos (orden de dependencia)

```
01-prd.md                 → qué / para quién / por qué
02-trd.md                 → cómo, técnicamente
  ├── 03-ui-ux-brief.md    → cómo se ve y se siente
  ├── 04-app-flow.md       → cómo se mueve el usuario
  └── 05-backend-schema.md → cómo se modelan los datos
06-implementation-plan.md → en qué orden se construye
```

PRD → TRD → (UI/UX Brief ∥ App Flow ∥ Backend Schema) → Implementation Plan. El PRD es la fuente de verdad; docs 3-5 se pueden redactar en paralelo una vez existen 1-2; el implementation plan secuencia todo.

## Interoperabilidad con `sdd-flow`

Si el proyecto también tiene el plugin **`sdd-flow`** instalado, escribir en la ruta por defecto `docs/foundation/` habilita, gratis, que:

- `enrich-user-story` (skill de sdd-flow) lea `01-prd.md` para anclar decisiones de actor/success-criteria en producto real, en vez de solo en arquitectura.
- `sdd-plan` (skill de sdd-flow) lea `06-implementation-plan.md` para detectar scope creep contra el roadmap declarado.
- `/sdd-init` (comando de sdd-flow) referencie `02-trd.md`/`05-backend-schema.md` en `SDD/docs/doc_architecture.md`, en vez de duplicarlos.

Nada de esto es obligatorio — `project-foundation` funciona standalone, sin `sdd-flow` instalado.

## Estructura

```
project-foundation/
├── .claude-plugin/plugin.json   manifest
├── commands/init.md              → /project-foundation:init
├── skills/project-foundation/SKILL.md
└── README.md
```

## Estado

**v0.1.0** — funciona de verdad como skill/comando (es un prompt, no requiere orquestación adicional). Empaquetado a partir del skill personal `project-foundation` para distribuirlo como standard de empresa (opcional).
