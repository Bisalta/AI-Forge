# ai-forge

Marketplace interno de **Bisalta Ltda** para tooling de Claude Code — plugins, skills y standards de desarrollo asistido por AI.

## Instalación (en cualquier proyecto)

```
/plugin marketplace add Construplaza/AI-Forge
/plugin install sdd-flow
```

Luego tipeá `/` y vas a ver los comandos del plugin (`/sdd-flow:sdd`, etc).

## Plugins disponibles

| Plugin | Versión | Qué hace |
|---|---|---|
| [**sdd-flow**](./plugins/sdd-flow) | 0.1.0 | Spec-Driven Development multi-agente: planner Opus 4.8 cierra decisiones y corta tareas, subagentes Sonnet/Haiku ejecutan, coordinación file-based `AGENT_{uuid}`. |

## Estructura

```
ai-forge/
├── .claude-plugin/marketplace.json   índice del marketplace
├── plugins/
│   └── sdd-flow/                      primer plugin (ver su README)
├── CHANGELOG.md
└── README.md
```

## Agregar un plugin nuevo

1. Crear `plugins/<nombre>/.claude-plugin/plugin.json` + sus `commands/skills/agents`.
2. Registrarlo en `.claude-plugin/marketplace.json` (`plugins[]` con `source: "./plugins/<nombre>"`).
3. Bumpear versión en el `plugin.json` del plugin y anotar en `CHANGELOG.md`.

## Versionado

SemVer por plugin (`MAJOR.MINOR.PATCH`) en cada `plugin.json`. El marketplace no tiene versión propia; lo que versiona es cada plugin. Los usuarios actualizan con `/plugin marketplace update ai-forge` + reinstalar.
