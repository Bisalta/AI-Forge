# Manifiesto de docs — <NOMBRE DEL REPO>

Identidad de **contenido** de los tres documentos que `/sdd-init` genera en `SDD/docs/`. Lo escribe **`/sdd-init`**, nunca a mano: cada fila registra el hash del doc **al momento de generarse**, para poder detectar después si alguien lo trabajó a mano desde esa generación (protección de `skills/sdd-init/SKILL.md`, sección "Manifiesto de identidad y protección al regenerar").

> ⚠️ **Template.** `/sdd-init` reemplaza cada `[PLACEHOLDER]` al generar o regenerar los docs de este repo, y actualiza la fila correspondiente cada vez que un doc se reescribe. El hash de un doc **nunca** va dentro del propio documento que describe — escribirlo ahí cambiaría el hash que declara.

Por qué existe: `sdd-run-gates.sh` estampa cada reporte de gates con hash, no sólo con ruta (`standards/quality-gates.md` §5) — una ruta sola no identifica un contenido, y `doc_quality_gates.md` puede cambiar varias veces por día durante el propio ciclo SDD. Este archivo es la referencia contra la que ese hash se puede comparar en cualquier momento, no sólo en la corrida que lo generó.

- **Función de hash**: `sha256`, primeros 16 caracteres hexadecimales — mismo formato que estampa `sdd-run-gates.sh` (`sha256:xxxxxxxxxxxxxxxx`; `sha256:-` si ni `shasum` ni `sha256sum` están disponibles en la máquina que generó la fila).
- **Cuándo se actualiza una fila**: sólo `/sdd-init`, al generar o regenerar el doc correspondiente — nunca a mano, nunca otro script.
- **Antes de sobreescribir**: si el hash del doc en el árbol difiere del hash de esta fila, alguien lo trabajó a mano desde la última generación — `/sdd-init` muestra el diff y pide confirmación antes de pisarlo; no lo hace en silencio.

| Doc | Hash (sha256, 16 hex) | Generado (UTC) | Por |
|---|---|---|---|
| `SDD/docs/doc_architecture.md` | `sha256:[PLACEHOLDER]` | `[PLACEHOLDER — YYYY-MM-DDThh:mm:ssZ]` | `/sdd-init` |
| `SDD/docs/doc_verification_guide.md` | `sha256:[PLACEHOLDER]` | `[PLACEHOLDER — YYYY-MM-DDThh:mm:ssZ]` | `/sdd-init` |
| `SDD/docs/doc_quality_gates.md` | `sha256:[PLACEHOLDER]` | `[PLACEHOLDER — YYYY-MM-DDThh:mm:ssZ]` | `/sdd-init` |

Una fila que todavía dice `[PLACEHOLDER]` en `Hash` es un doc que `/sdd-init` no generó todavía en este repo — no es un hash real, no lo uses para comparar.
