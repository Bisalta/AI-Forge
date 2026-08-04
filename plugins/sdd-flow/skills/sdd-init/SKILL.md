---
name: sdd-init
description: Bootstrapea o llena SDD/docs/doc_architecture.md y SDD/docs/doc_verification_guide.md — los dos documentos que enrich-user-story exige leer antes de cerrar decisiones. Deriva de un codebase existente o entrevista en greenfield. Detecta docs/foundation/ (project-foundation) para no duplicar contenido. Usar cuando enrich-user-story frena por falta de estos docs, o al arrancar sdd-flow en un repo nuevo.
---

# SDD Init — bootstrap de docs fundacionales

Sin `SDD/docs/doc_architecture.md`, `enrich-user-story` frena antes de la primera pregunta. Este skill existe para que ese frenazo tenga una salida dentro del propio plugin, en vez de depender de que alguien haya llenado el esqueleto `[PLACEHOLDER]` a mano.

**No implementás código ni generás los seis documentos completos de un day-zero (PRD/TRD/UI-UX/App-Flow/Backend-Schema/Implementation-Plan) — eso es responsabilidad de otra herramienta, si el equipo la usa.** Tu único output son los dos archivos que el ciclo SDD necesita: arquitectura y guía de verificación.

## Paso 0 — Detectar estado

1. ¿Existen ya `SDD/docs/doc_architecture.md` y `SDD/docs/doc_verification_guide.md` **sin** `[PLACEHOLDER]` pendiente? Si ambos están completos → avisá que no hay nada que hacer y terminá.
2. ¿Existe `docs/foundation/` (carpeta que produce el skill `project-foundation`, con `01-prd.md` .. `06-implementation-plan.md`)? Anotá cuáles de los seis existen — los vas a referenciar, no a duplicar (ver Paso 2).
3. ¿Hay codebase real (el repo tiene manifiestos de paquete, rutas, código fuente) o está vacío/recién creado? Eso decide el modo:
   - **Hay código** → modo `existing` (derivar).
   - **No hay código** (repo nuevo, o el usuario está arrancando un proyecto desde cero) → modo `greenfield` (entrevistar).
   - Si `$ARGUMENTS` fuerza el modo explícitamente, respetalo aunque contradiga la detección automática.

## Paso 1A — Modo `existing`: derivar, no inventar

Usá subagentes de exploración en paralelo para cubrir en breadth (igual que project-foundation), en vez de leer todo vos mismo:
- Stack y manifiestos (`package.json`, `Dockerfile`, CI, lockfiles).
- Layout real de carpetas (no un ejemplo — el árbol real del repo).
- Rutas/endpoints/módulos (API surface real).
- Convenciones de nombres ya en uso (observadas, no propuestas).
- Docs existentes (`docs/foundation/`, ADRs, otro `README.md` con contexto de arquitectura) que puedan ya responder alguna sección.

Con eso, llená el esqueleto (ver Paso 2) con hechos observados. Todo lo que no puedas derivar con evidencia directa del código va a la lista de "Supuestos a confirmar" del cierre (Paso 4) — nunca lo inventes como si fuera un hecho.

## Paso 1B — Modo `greenfield`: entrevistar, no adivinar

No hay código todavía, así que no hay nada que derivar. Preguntá lo mínimo necesario para llenar el esqueleto de arquitectura (no el ciclo completo de seis documentos — solo lo que `doc_architecture.md`/`doc_verification_guide.md` necesitan):
- Stack elegido (frontend/backend/DB/auth/infra) y por qué.
- Layout de carpetas que van a usar (o el que genera el scaffold que ya eligieron).
- Convenciones de nombres que quieren adoptar.
- Estrategia de testing (qué framework, qué comando corre cada tipo de test).

Agrupá las preguntas — no interrogues una por una. Si el usuario no tiene una respuesta clara para algo, proponé un default razonable y marcalo explícito como propuesta, no como decisión ya tomada.

## Paso 2 — Escribir `SDD/docs/doc_architecture.md`

Seguí el esqueleto de `templates/doc_architecture.md` sección por sección (Project Stack, Project Layout, Layer Responsibilities, Main Flows, Naming Conventions, File Placement Rules, API Contracts, Error Handling, Configuration and Environment, Anti-patterns). Nunca dejes un `[PLACEHOLDER]` en el archivo final.

**Si `docs/foundation/02-trd.md` y/o `05-backend-schema.md` ya existen** (chequeado en el Paso 0): no repitas su contenido. En las secciones que ya cubren (Project Stack, Layer Responsibilities, Data Layer, API Contracts) escribí un párrafo corto que referencia el archivo de foundation correspondiente por su path, y completá igual las secciones que esos documentos NO cubren porque son específicas de agentes SDD: **File Placement Rules** y **Anti-patterns** — esas dos siempre se llenan acá, existan o no los docs de foundation.

**Si no existen los docs de foundation**: llená las diez secciones completas con lo derivado/entrevistado.

## Paso 3 — Escribir `SDD/docs/doc_verification_guide.md`

Este archivo se genera **siempre completo**, exista o no `docs/foundation/` — ninguno de los seis documentos de foundation tiene el formato "comando exacto por tipo de cambio" que un agente necesita para decidir rápido qué correr, así que no hay nada que referenciar acá.

Seguí el esqueleto de `templates/doc_verification_guide.md`: reemplazá cada `[PLACEHOLDER]` por el comando real (leé `package.json`/Makefile/scripts del repo para sacar los comandos reales de test unitario, integración, e2e, lint, type-check, run local). Si el repo no tiene todavía un tipo de test (p. ej. no hay e2e), decilo explícito en esa sección en vez de dejar el placeholder o inventar un comando que no existe.

## Paso 4 — Cierre

Reportá:
1. Qué se creó/actualizó (los dos archivos, con diff resumido si ya existían parcialmente).
2. Si corriste en modo `existing`: lista de **"Supuestos a confirmar"** — todo lo que llenaste sin evidencia directa (igual que project-foundation).
3. Si detectaste `docs/foundation/`: qué secciones quedaron como referencia en vez de contenido propio, y a qué archivo apuntan.
4. Recordatorio: ahora `enrich-user-story` puede correr sin frenar.

## Reglas

- No generes los seis documentos de un day-zero completo — solo arquitectura y verificación.
- No dupliques contenido que ya vive en `docs/foundation/`; referencialo.
- Nunca dejes `[PLACEHOLDER]` en el archivo final.
- Nunca declares un comando de verificación que no confirmaste que existe en el repo.
- Respondé siempre en el idioma del usuario.
