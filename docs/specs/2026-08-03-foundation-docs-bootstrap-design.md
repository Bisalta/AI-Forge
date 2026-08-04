# Spec — Bootstrap de docs fundacionales (`/sdd-init`) en sdd-flow

- **Fecha**: 2026-08-03
- **Plugin**: sdd-flow
- **Estado**: diseño aprobado, implementado en esta misma rama
- **Branch**: feat-foundation-docs-bootstrap

## Problema

El ciclo SDD asume que `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` ya existen y están llenos. El skill `enrich-user-story` es explícito: **"You MUST read `SDD/docs/doc_architecture.md` before asking any questions. If you cannot access or read this file, stop and inform the user."**

Pero el propio plugin solo shippea esos dos archivos como **esqueletos con `[PLACEHOLDER]`** en `templates/` — no trae ningún comando que los llene. Resultado: en cualquier repo que no haya escrito esos docs a mano de antemano, `/sdd`/`/sdd-enrich` se frena en el primer paso, sin ruta de recuperación dentro del propio plugin.

Comparado contra un skill externo (`project-foundation`, que genera seis documentos fundacionales — PRD/TRD/UI-UX/App Flow/Backend Schema/Implementation Plan — tanto por entrevista en greenfield como derivando de un codebase existente), quedaron tres gaps concretos:

1. Sin bootstrap: nada en sdd-flow deriva o entrevista para llenar `doc_architecture.md`/`doc_verification_guide.md`.
2. `enrich-user-story` cierra las dimensiones *actor/contexto de uso* y *success criteria* ancladas solo en arquitectura (código), nunca en intención de producto (personas, jobs-to-be-done, métricas) — no hay ninguna fuente de ese tipo en el flujo.
3. `sdd-plan` no tiene visibilidad de ningún roadmap/fases más amplio al definir el alcance de una feature — puede aceptar scope que en realidad pertenece a una fase futura sin detectarlo.

## Objetivo

Cerrar el punto de entrada bloqueado sin duplicar lo que un proyecto ya pueda tener en `docs/foundation/` (convención de `project-foundation`), y sin convertir sdd-flow en un generador de los seis documentos completos — eso sigue siendo responsabilidad de una herramienta de day-zero, no del ciclo por-feature de sdd-flow.

## Decisiones cerradas (no re-litigar)

1. **Nuevo comando `/sdd-init`**, no automático dentro de `/sdd`. El usuario lo corre explícitamente cuando `enrich-user-story` frena, o de entrada al iniciar un repo nuevo con sdd-flow. `/sdd`/`/sdd-enrich` NO lo disparan solos — evita sorpresas de un comando que escribe archivos sin que se pidiera.
2. **Dos modos, igual que project-foundation**: *existing* (deriva del codebase — package manifests, rutas, schema, CI) y *greenfield* (entrevista corta, sin inventar). Autodetecta por presencia de código; el usuario puede forzar con el argumento.
3. **No duplica `docs/foundation/`**. Si ya existen `02-trd.md` y/o `05-backend-schema.md` (project-foundation ya corrió), `doc_architecture.md` se escribe como **índice delgado** que referencia esos archivos para el contenido de stack/layout/capas/contratos, y solo agrega lo que es específico de agentes SDD y no vive en el TRD: *File Placement Rules* y *Anti-patterns*. Si no existen, `doc_architecture.md` se llena completo (deriva/entrevista propia, acotada a arquitectura — no genera los otros cinco documentos).
4. **`doc_verification_guide.md` siempre se genera fresco**, exista o no `docs/foundation/`. Ninguno de los seis documentos de project-foundation tiene un equivalente al formato "comando exacto por tipo de cambio" — es el formato correcto para que un agente decida rápido qué correr, se mantiene tal cual está diseñado hoy.
5. **`enrich-user-story` lee el PRD si existe, sin bloquear si no existe.** A diferencia de `doc_architecture.md` (lectura obligatoria, bloqueante), `docs/foundation/01-prd.md` es una fuente **opcional**: si está, ancla actor/contexto y success criteria en personas y métricas reales; si no está, sigue funcionando como hoy (grounding solo en arquitectura) — no todos los repos van a tener corrido project-foundation.
6. **`sdd-plan` consulta `docs/foundation/06-implementation-plan.md` si existe**, también opcional/no bloqueante: al declarar out-of-scope, chequea si el alcance propuesto choca con una fase futura declarada ahí, y si choca lo señala explícitamente en el HLTC en vez de aceptarlo en silencio.

## Componentes

### A · `commands/sdd-init.md` + `skills/sdd-init/SKILL.md` (nuevo)

- Comando corto que invoca el skill.
- El skill hace todo el trabajo pesado: detecta modo, chequea `docs/foundation/`, deriva o entrevista, escribe los dos archivos (nunca placeholders), termina con una lista de "supuestos a confirmar" (mismo patrón que project-foundation).

### B · `skills/enrich-user-story/SKILL.md` (modificado)

- Se agrega, después del `SDD/docs/doc_architecture.md` obligatorio, una lectura opcional de `docs/foundation/01-prd.md`. Si existe, se usa para fundamentar los defaults sugeridos en las dimensiones de actor y success criteria, igual que hoy se fundamentan en arquitectura para solution shape/output.

### C · `skills/sdd-plan/SKILL.md` (modificado)

- En "Antes de planear", se agrega el chequeo opcional de `docs/foundation/06-implementation-plan.md` para detectar scope creep contra fases declaradas.

## Fuera de alcance (YAGNI por ahora)

- `/sdd-init` no genera PRD/UI-UX/App-Flow/Backend-Schema/Implementation-Plan completos — eso es trabajo de una herramienta de day-zero (`project-foundation` u otra), no de sdd-flow.
- No se resuelve la elección de carpeta (`SDD/docs/` vs `docs/foundation/`) a nivel de convención de empresa — `/sdd-init` se adapta a lo que encuentre, no fuerza una migración.
- No se cablea ejecución real de subagentes para `/sdd-init` (mismo estado que el resto del orquestador `/sdd` — pendiente #1 del roadmap general).
