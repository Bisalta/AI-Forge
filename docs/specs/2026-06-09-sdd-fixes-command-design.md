# Design: comando `/sdd-fixes` + badge statusline

**Fecha**: 2026-06-09 · **Plugin**: sdd-flow · **Versión target**: 0.2.0

## Problema

Trabajo recurrente de los devs: tandas grandes de fixes/ajustes/mejoras (a veces multi-repo front+back). Hoy no hay forma estándar de:
1. Volcar la lista cruda y que Claude la estructure y triagee.
2. Ver y editar el backlog de la tanda al costado mientras la sesión trabaja.
3. Ver progreso de un vistazo sin abrir nada.

## Solución

### 1. Comando `/sdd-fixes [lista cruda]`

Archivo: `plugins/sdd-flow/commands/sdd-fixes.md`.

Comportamiento al invocarlo:

1. **Bootstrap**: si no existe `fixes.md` en la raíz del repo actual, crearlo desde el template embebido en el comando (header con fecha y paths de repos involucrados + formato de item).
2. **Intake** (si hay argumentos): parsear la lista cruda del usuario y convertir cada item a bloque estructurado:
   ```markdown
   ## F-NN — <título corto>
   - Tipo: bug | visual | interacción | mejora
   - Repo: front | back | ambos
   - Triage: trivial | mediano | ambiguo
   - Estado: pendiente
   - Detalle: <repro / esperado vs actual / descripción>
   ```
   - IDs secuenciales `F-01…` continuando desde el máximo existente (re-invocación = append, nunca renumerar).
   - **Triage**: trivial (fix directo, un repo), mediano (requiere diagnóstico), ambiguo (decisiones abiertas o acoplado front+back). Items ambiguos llevan línea extra: `- Sugerencia: cerrar con /sdd-enrich antes de implementar`.
3. **Abrir visualizador**: en orden de preferencia:
   - `command -v code` → `code <path>/fixes.md` (panel lateral VS Code, editable).
   - macOS → `open <path>/fixes.md` (editor default).
   - Fallback: imprimir path absoluto.
4. **NO implementar nada**: el comando termina mostrando resumen del triage y queda a la espera de orden explícita del usuario ("dale con F-01", "arrancá en orden"). Regla para la sesión: al cerrar un item, actualizar su `Estado:` en `fixes.md` y commitear con `[FIX] [Módulo] [Descripción]`.

Estados válidos: `pendiente | en-curso | hecho | bloqueado`.

`fixes.md` se versiona en git del repo de trabajo (changelog natural de la tanda).

### 2. Badge statusline

Extender `plugins/sdd-flow/hooks/statusline.sh`:

- Si existe `fixes.md` en el cwd del proyecto: contar items por `grep -c '^- Estado:'` y hechos por `grep -c '^- Estado: hecho'`; mostrar `⚡ fixes <hechos>/<total>`.
- Si además existe `.sdd/state.json` (pipeline SDD activo), mostrar ambos badges separados por `·`.
- Si no existe `fixes.md`, comportamiento actual sin cambios.

El badge se actualiza solo: la statusline se re-evalúa por turno y la sesión actualiza `fixes.md` al cerrar items.

## Fuera de scope

- Widget HTML interactivo en desktop app (descartado: dependencia MCP no garantizada, sin soporte CLI).
- Servidor web local (overkill).
- Auto-implementación de items al correr el comando (el usuario ordena cuándo arrancar).
- Sincronización con Proxima/Jira.

## Decisiones cerradas

- Vive en plugin `sdd-flow` (distribución empresa-wide), no comando personal.
- Alcance: intake + triage + abrir. Trabajo de items requiere orden explícita.
- Mecanismo visualizador: abrir nativo (`code` → `open` → print path). Sin panel embebido.
- Badge statusline incluido, parsea `fixes.md` directo (sin estado intermedio).
- Nombre: `/sdd-fixes` (consistente con `sdd-*` existentes).
- Archivo: `fixes.md` en raíz del repo de trabajo.

## Criterios de éxito

- `/sdd-fixes` sin args en repo limpio → crea `fixes.md` template y lo abre.
- `/sdd-fixes` con lista pegada de 10 items → `fixes.md` con 10 bloques F-01…F-10 triageados, archivo abierto, resumen en chat, cero código tocado.
- Re-invocar con 3 items más → F-11…F-13 apendeados, sin renumerar.
- Statusline muestra `⚡ fixes 0/10` y pasa a `1/10` cuando la sesión marca un item `hecho`.
- `claude plugin validate` pasa; install desde marketplace funciona.
