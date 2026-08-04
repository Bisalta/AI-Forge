# Security — sdd-flow

Seguridad como **gate verificable**, no como intención. Este archivo es el checklist del concern `security` (siempre activo, siempre blocking — ver `standards/concerns.md`) y la fuente de las reglas de supply chain. Complementa `base-standards.md` (secretos, SQL parametrizado, validación de bordes) y se verifica con el mismo mecanismo de `quality-gates.md`: ACs con test, evidencia con exit codes, review.

---

## 1. Threat model mínimo en el HLTC (4 preguntas cerradas)

Todo HLTC que exponga o modifique una superficie invocable (endpoint, comando, job disparable, webhook, mensaje de cola) responde estas cuatro preguntas **decision-closed** — sin "if needed", con valores concretos:

1. **¿Quién puede invocarlo?** Rol/scope exacto (`admin`, `owner-del-recurso`, `cualquier-autenticado`, `público`). "Cualquiera" es una respuesta válida solo si es explícita.
2. **¿Qué pasa con el rol equivocado?** Código y shape del error (ej. `403 { code: FORBIDDEN }`). Distinguir no-autenticado (401) de no-autorizado (403).
3. **¿Qué pasa con input hostil?** Por cada campo de entrada: qué lo valida, qué recibe el atacante cuando falla (sin echo del input crudo, sin stack traces).
4. **¿Qué datos toca y de quién?** Si accede a recursos por ID: cómo se verifica que el invocante puede ver **ese** recurso (no solo "un" recurso). Si toca datos personales, activa el concern `data-privacy`.

Requerimiento sin superficie invocable nueva (refactor interno, cambio de UI puro): el HLTC lo declara — `threat model: N/A — no cambia superficie invocable` — en vez de omitirlo en silencio.

## 2. Tests negativos de autorización (obligatorios, son ACs)

El planner convierte las respuestas del threat model en ACs numerados. Para **toda** superficie invocable nueva o modificada, mínimo:

- **AC de rol equivocado**: el rol sin permiso recibe exactamente el error declarado (403). No alcanza con testear que el rol correcto puede.
- **AC de no autenticado**: sin credenciales → 401 (si la superficie no es pública).
- **AC de IDOR** (si accede a recursos por ID): el usuario A **no** puede leer/modificar el recurso del usuario B. Es el bug más común en aplicaciones internas y es perfectamente testeable.
- **AC de input hostil** para los campos de mayor riesgo (los que llegan a SQL, shell, paths, HTML, headers): el payload malicioso obvio del tipo de campo se rechaza con el error declarado.

Estos ACs siguen la regla general: **sin test = BLOCKER** (`quality-gates.md` §3). Un "esto es interno, nadie lo va a atacar" no exime — lo interno es exactamente donde el IDOR vive años.

## 3. Gate de seguridad en la escalera (escalón 9)

Corre después de la cobertura del diff, con los comandos declarados en `doc_quality_gates.md`:

1. **Secret scan del diff**: gitleaks/trufflehog si el repo los tiene; si no, el grep mínimo del diff por patrones de credencial (`AKIA[0-9A-Z]{16}`, `-----BEGIN .*PRIVATE KEY`, `password|secret|token|api[_-]?key` asignados a literales no vacíos). Hallazgo = **BLOCKER**, y si el secreto ya se commiteó, rotarlo — borrarlo del archivo no lo saca de la historia.
2. **Audit de dependencias**: `npm audit` / `pip-audit` / `dotnet list package --vulnerable` / equivalente. Política por defecto: vulnerabilidad **critical/high con fix disponible** en una dependencia directa = BLOCKER; el resto se registra en el ledger de deuda con severidad. El repo puede endurecer esta política en su `doc_quality_gates.md`, nunca ablandarla en el momento.
3. **SAST** solo si el repo ya lo tiene configurado (semgrep, CodeQL local) — no instalar herramientas nuevas como parte de una feature.

Sin herramienta disponible, el escalón se declara con lo que sí corrió (el grep mínimo siempre se puede) — nunca `N/A` completo en silencio.

## 4. Supply chain: toda dependencia nueva es una decisión de arquitectura

- Una dependencia nueva (o un bump mayor) **se declara en el HLTC** con una línea de justificación y la alternativa descartada ("lo escribimos nosotros" cuenta como alternativa). Un implementing agent que necesita una dependencia no declarada → **BLOCKED, pregunta al planner** — no la mete de contrabando en el manifiesto.
- El reviewer diffea los manifiestos (`package.json`, `pyproject.toml`, `*.csproj`, lockfiles): **dependencia nueva sin decisión en el contract = MAJOR**.
- Versiones pineadas según la convención del repo (lockfile commiteado). Nunca instalar desde fuentes fuera del registry estándar del stack sin decisión explícita.

## 5. Reglas de implementación (para el implementing agent)

Además de `base-standards.md`:

- **PII fuera de los logs**: no loguear emails, tokens, passwords, documentos de identidad ni payloads completos de requests. Loguear IDs opacos.
- **Errores hacia afuera sin detalle interno**: stack traces, queries SQL y paths del server no viajan en respuestas de error. El detalle va al log, el cliente recibe el código declarado en el contract.
- **Autorización en el borde correcto**: el chequeo vive en la capa que el `Architectural Delta` declara (middleware/guard/policy) — no re-implementado ad-hoc dentro del handler, y **nunca solo en el frontend**.
- **Comparaciones de secretos en tiempo constante**, cookies de sesión `HttpOnly`/`Secure`/`SameSite` según lo que el repo ya hace — seguí el patrón existente; si no existe patrón, es una decisión del planner, no tuya.

## 6. Qué chequea el reviewer (se suma a su Fase 2)

- ¿El HLTC tiene threat model (o su `N/A` declarado)? Ausente = **BLOCKER** de contract (escalá al planner — el defecto es del plan, no del código).
- ¿Existen los ACs negativos de §2 con test, para cada superficie tocada?
- ¿El gate 9 corrió con evidencia? ¿Los manifiestos traen dependencias no declaradas?
- ¿PII en logs nuevos? ¿Detalle interno en errores hacia afuera? ¿Authz solo en el front?
