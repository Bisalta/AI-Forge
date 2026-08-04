# Quality Gates — <NOMBRE DEL REPO>

Los **comandos reales** de este repo para la escalera de gates de `standards/quality-gates.md`. Todo agente del ciclo SDD corre lo que dice acá, sin inventar comandos ni adivinar el package manager.

Diferencia con los otros dos docs SDD:
- `doc_architecture.md` → dónde va el código.
- `doc_verification_guide.md` → qué conviene correr según qué cambié (guía curada, elección).
- **este archivo** → la escalera obligatoria que corre siempre antes de declarar `done` (sin elección).

> ⚠️ **Template.** Reemplazá cada `[PLACEHOLDER]` con el comando real verificado en este repo. Un gate que el repo no tiene se marca `N/A` con la razón — nunca se deja el placeholder ni se inventa un comando.

---

## Identidad del repo

- **Stack / lenguaje**: [PLACEHOLDER]
- **Package manager / build tool**: [PLACEHOLDER]  <!-- npm | pnpm | yarn | bun | poetry | uv | dotnet | maven | … -->
- **Perfil de calidad aplicable** (`quality-gates.md` §9): [PLACEHOLDER]
- **Runner de tests**: [PLACEHOLDER]

---

## Escalera de gates

| # | Gate | Comando | Obligatorio | Notas |
|---|---|---|---|---|
| 1 | format | `[PLACEHOLDER]` | sí / N/A | auto-fix permitido |
| 2 | lint | `[PLACEHOLDER]` | sí / N/A | cero warnings nuevos |
| 3 | type-check | `[PLACEHOLDER]` | sí / N/A | proyecto completo |
| 4 | unit | `[PLACEHOLDER]` | sí | filtrado: `[PLACEHOLDER]` |
| 5 | integration | `[PLACEHOLDER]` | si cruza capas / N/A | prerequisitos: [PLACEHOLDER] |
| 6 | build | `[PLACEHOLDER]` | sí / N/A | |
| 7 | e2e | `[PLACEHOLDER]` | sólo si un AC lo exige / N/A | prerequisitos: [PLACEHOLDER] |
| 8 | cobertura del diff | `[PLACEHOLDER]` | sí | ver política abajo |
| 9 | security — secret scan | `[PLACEHOLDER]` | sí | gitleaks/trufflehog, o el grep mínimo de `security.md` §3 |
| 9 | security — audit deps | `[PLACEHOLDER]` | sí / N/A | `npm audit` / `pip-audit` / equivalente; política: critical/high directa con fix = BLOCKER |

**Suite completa** (obligatoria una vez antes de integrar): `[PLACEHOLDER]`

**Tiempo esperado de la suite completa**: [PLACEHOLDER] <!-- para que el agente sepa si un timeout es normal o es una señal -->

---

## Prerequisitos de entorno

Qué tiene que estar levantado para que los gates 5 y 7 no den falso rojo:

- [PLACEHOLDER] <!-- ej: docker compose up -d db; .env.test presente; migraciones aplicadas -->

Si un prerequisito no está disponible, el gate se marca `[SKIPPED] <prereq faltante>` en la evidencia — **no** se declara verde.

---

## Política de cobertura del diff

- Herramienta / comando: `[PLACEHOLDER]` (o `N/A — el repo no emite coverage`).
- Regla: todo archivo nuevo o modificado queda ejercitado por al menos un test que recorra las líneas cambiadas.
- Threshold actual configurado en el repo: [PLACEHOLDER] <!-- N/A si no hay -->
- **Prohibido bajarlo, agregar excludes o ignorar archivos para pasar el gate.**

---

## Convenciones de test de este repo

- Ubicación de los tests: [PLACEHOLDER] <!-- ej: junto al archivo (*.spec.ts) | tests/ espejando src/ -->
- Naming de casos: [PLACEHOLDER] <!-- ej: "rejects negative qty" — el binding AC↔test usa este nombre literal -->
- Fixtures / factories: [PLACEHOLDER]
- Cómo se mockea I/O externo: [PLACEHOLDER]
- Tests que YA fallan en `main` (rojos preexistentes, no los cuentes como tu culpa): [PLACEHOLDER] <!-- N/A si está todo verde -->

---

## Markers prohibidos en este stack

Además de los de `quality-gates.md` §6, específicos de acá:

- [PLACEHOLDER] <!-- ej: @ts-ignore, eslint-disable-next-line, any, xit(, test.skip( -->

---

## Hooks / CI

- Pre-commit hooks del repo: [PLACEHOLDER] <!-- N/A si no hay. Nunca se saltean con --no-verify -->
- Pipeline de CI y qué corre: [PLACEHOLDER]
- Checks requeridos para mergear: [PLACEHOLDER]
