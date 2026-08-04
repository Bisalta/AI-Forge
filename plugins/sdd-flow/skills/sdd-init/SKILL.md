---
name: sdd-init
description: Bootstrapea o llena SDD/docs/doc_architecture.md, doc_verification_guide.md y doc_quality_gates.md — los documentos que el resto del ciclo SDD exige leer antes de cerrar decisiones y antes de validar. Deriva de un codebase existente o entrevista en greenfield. Detecta docs/foundation/ (project-foundation) para no duplicar contenido. Usar cuando enrich-user-story frena por falta de estos docs, o al arrancar sdd-flow en un repo nuevo.
---

# SDD Init — bootstrap de docs fundacionales

Sin `SDD/docs/doc_architecture.md`, `enrich-user-story` frena antes de la primera pregunta. Sin `SDD/docs/doc_quality_gates.md`, los agentes inventan comandos de validación. Este skill existe para que esos frenazos tengan una salida dentro del propio plugin, en vez de depender de que alguien haya llenado el esqueleto `[PLACEHOLDER]` a mano.

**No implementás código ni generás los seis documentos completos de un day-zero (PRD/TRD/UI-UX/App-Flow/Backend-Schema/Implementation-Plan) — eso es responsabilidad de otra herramienta, si el equipo la usa.** Tu output son los tres archivos que el ciclo SDD necesita: arquitectura, guía de verificación y gates de calidad.

## Paso 0 — Detectar estado

1. ¿Existen ya `SDD/docs/doc_architecture.md`, `SDD/docs/doc_verification_guide.md` y `SDD/docs/doc_quality_gates.md` **sin** `[PLACEHOLDER]` pendiente? Si los tres están completos → avisá que no hay nada que hacer y terminá.
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

## Paso 3.5 — Escribir `SDD/docs/doc_quality_gates.md`

También **siempre**, y con comandos **verificados**, no supuestos. Seguí `templates/doc_quality_gates.md`.

Diferencia con el paso anterior: `doc_verification_guide.md` es la guía curada ("qué conviene correr según qué cambié"); `doc_quality_gates.md` es la **escalera obligatoria** que corre siempre antes de declarar `done`, con exit codes registrados. Los dos existen y no se solapan.

Cómo llenarlo sin inventar:
1. Leé los manifiestos reales (`package.json` scripts, `Makefile`, `pyproject.toml`/`tox.ini`, `*.csproj`, `build.gradle`, config de CI) y sacá de ahí el comando de cada gate.
2. **Verificá lo que puedas verificar**: `--help`/`--version` del runner, o que el script exista en el manifiesto. Si un gate no existe en el repo (típico: e2e, coverage), escribí `N/A — no existe en este repo` en vez de proponer un comando que va a fallar. Ofrecé al usuario agregarlo como mejora, no lo declares como si estuviera.
3. Detectá el **perfil de calidad** del stack (`quality-gates.md` §9) y anotalo, junto con los markers prohibidos específicos (ej. `@ts-ignore` en TS, `# type: ignore` en Python).
4. Anotá los **prerequisitos de entorno** de los gates de integración/e2e (docker, `.env.test`, migraciones): son la diferencia entre un rojo real y un falso rojo.
5. Anotá los **rojos preexistentes** si al correr la suite algo ya falla en la rama base — para que ningún agente cargue con una falla que no causó. Si no corriste la suite, decilo en lugar de dejar el placeholder.
6. Anotá el **tiempo esperado** de la suite completa (aunque sea aproximado): evita que un agente interprete un test lento como un cuelgue.
7. **Gate 9 (security)**: detectá qué hay para secret scan (gitleaks/trufflehog en devDeps, CI o pre-commit) y para audit (`npm audit`, `pip-audit`, `dotnet list package --vulnerable`). Si no hay nada, declarás el fallback del grep mínimo de `standards/security.md` §3 — ese siempre se puede correr.
8. **Copiá `scripts/sdd-check.sh` del plugin a `SDD/scripts/sdd-check.sh`** (creando el dir): es el chequeo mecánico del review y el que CI puede correr — dentro del repo no depende de que el plugin esté instalado. Si ya existe, no lo pises sin avisar.

En modo `greenfield` no hay comandos que verificar todavía: escribí los del stack elegido en la entrevista y marcá el archivo como *sin verificar — validar en el primer commit con código*.

## Paso 3.6 — Paridad con CI (ofrecer, no imponer)

Los gates que corre el plugin y los que corre CI tienen que ser **los mismos comandos**, o "verde local" no significa nada. Después de escribir `doc_quality_gates.md`:

1. **Si el repo ya tiene CI** (`.github/workflows/`, `.gitlab-ci.yml`, etc.): comparalo contra la escalera. Divergencias (CI corre algo que la escalera no, o al revés) → listalas y proponé alinear **la escalera hacia CI** primero (CI es lo que ya protege el repo); lo que CI no corre y la escalera sí, ofrecé agregarlo a CI.
2. **Si no tiene CI y el remote es GitHub**: ofrecé generar `.github/workflows/sdd-gates.yml` — un job que corre la escalera en orden (mismos comandos del doc, fail-fast) + `bash SDD/scripts/sdd-check.sh origin/<base>` como paso final. Solo si el usuario acepta; no lo generes de oficio.
3. Otro CI u otra plataforma: decí qué pasos equivalentes necesitaría y dejalo como pendiente anotado, no lo inventes.

## Paso 4 — Cierre

Reportá:
1. Qué se creó/actualizó (los tres archivos, con diff resumido si ya existían parcialmente).
2. Si corriste en modo `existing`: lista de **"Supuestos a confirmar"** — todo lo que llenaste sin evidencia directa (igual que project-foundation).
3. Si detectaste `docs/foundation/`: qué secciones quedaron como referencia en vez de contenido propio, y a qué archivo apuntan.
4. Recordatorio: ahora `enrich-user-story` puede correr sin frenar.

## Reglas

- No generes los seis documentos de un day-zero completo — solo arquitectura, verificación y gates.
- No dupliques contenido que ya vive en `docs/foundation/`; referencialo.
- Nunca dejes `[PLACEHOLDER]` en el archivo final.
- Nunca declares un comando de verificación que no confirmaste que existe en el repo. Un gate ausente se declara `N/A` con razón — es información útil; un comando inventado es una trampa para el próximo agente.
- Respondé siempre en el idioma del usuario.
