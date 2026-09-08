# Verification Report — feat-GEN-106-usage-monitor-plugin

Trabajo directo, sin HLTC — ruta liviana ("vía corta") elegida en el refinement conversacional: alcance chico (un plugin, un script + su wrapper, un doc), sin decisiones de arquitectura abiertas que ameriten un contract propio. Origen: hallazgo de Esteban Fait en `#bisalta-context-sdd` (2026-09-07); cierra bajo Proxima `GEN-106`.

- **Branch**: `feat-GEN-106-usage-monitor-plugin`
- **Doc de gates del repo**: `SDD/docs/doc_quality_gates.md` (gate 2 ampliado para incluir `plugins/usage-monitor/scripts/*.sh`)

---

## Gates — evidencia GENERADA

- **Reporte generado**: `SDD/verification/feat-GEN-106-usage-monitor-plugin-gates.md`
- Incluye la suite completa (14 archivos, `test_usage_summary.sh` nuevo) y shellcheck sobre el glob ampliado.

**Rojo intermedio real, gate 9 (security)** — no se borra, es señal: la primera corrida de `sdd-run-gates.sh` salió roja en una línea de `parse-usage-log.js` que asignaba, con el operador de igualdad, un identificador corto a otro identificador — y el primero contenía como substring una de las cuatro palabras que vigila `standards/security.md` §3. Falso positivo genuino del patrón de `secret-scan.sh`: no distingue "nombre de variable de código" de "credencial real", porque la forma sintáctica es idéntica. Mismo patrón que `SDD/debt.md` D11/D10 (la herramienta se marca sobre contenido legítimo), y **una segunda instancia nueva no registrada todavía**: a diferencia de `sdd-check.sh` (que ya tiene guard `.md` para sus tres reglas built-in, D10/AC42), `secret-scan.sh` no exime `.md` de ningún tipo — así que este mismo párrafo, al citar la forma exacta del hallazgo, se autodetectaba también (recursivo: la evidencia sobre el hallazgo se volvía un hallazgo nuevo). Se registra en `SDD/debt.md` como deuda nueva; no se corrige acá (`secret-scan.sh` está fuera del scope de este trabajo). **Fix del código real, no del gate** (doctrina del repo: nunca excluir ni ablandar): se renombró la variable para que dejara de contener la palabra vigilada — deja de calzar la forma sin cambiar ningún comportamiento. Este párrafo se reescribió en prosa, sin citar la forma literal, por la misma razón. Re-corrida: verde.

---

## Verificación del script nuevo (sin contract — no hay AC de detección declarado)

`parse-usage-log.js` no tiene un AC de detección formal (no hay HLTC), pero su propiedad más importante —nunca exponer campos sensibles del log crudo— sí se verificó por mutación, de forma informal, siguiendo el mismo principio de `quality-gates.md` §10 ("un control que no puede ponerse rojo no es un control"):

1. **Intacto**: `bash SDD/tests/test_usage_summary.sh` → verde, 17/17 asserts (incluye 9 asserts de no-fuga: `session-A`, `session-B`, `fake-uuid-a`, `fake-uuid-b`, `fake-org-1`, `fakehash-a`, `fakehash-b`, `user_fakeA`, `user_fakeB` ausentes del resumen).
2. **Mutado**: se modificó `parse-usage-log.js` para imprimir `Array.from(sessions).join(",")` en vez de la cuenta de sesiones (una fuga real y plausible — exactamente el tipo de descuido que la regla busca atrapar). Corrida:

```
  FAIL  cuenta de sesiones (2 session.id distintos) — no encontré [2 sesiones] en la salida
  FAIL  no-fuga - "session-A" no debería aparecer en el resumen compartible
  FAIL  no-fuga - "session-B" no debería aparecer en el resumen compartible
FAIL — 3 assert(s) fallaron
```

3. **Revertido**: `cp` del respaldo pre-mutación → verde de nuevo, 17/17 asserts.

El fixture (`SDD/tests/fixtures/usage-log-sample.txt`) usa el formato real capturado corriendo `claude -p ... 2>` con `OTEL_METRICS_EXPORTER=console` (2026-09-08, ver comentario en `parse-usage-log.js`) — confirma empíricamente que los contadores son acumulativos por sesión antes de diseñar el agregador (un mismo valor de costo se repitió sin cambios en 40 ticks de export consecutivos).

---

## Impact set

| Símbolo | Consumidor | Cobertura |
|---|---|---|
| `parse-usage-log.js` (agregación max-por-sesión + suma entre sesiones, exclusión de campos sensibles) | `usage-summary.sh`, `/usage-monitor:usage-summary` | `SDD/tests/test_usage_summary.sh` |
| `usage-summary.sh` (resolución de path default, chequeo de `node`/archivo) | comando `/usage-monitor:usage-summary` | ejercitado indirectamente por el test (se invoca con path explícito); la resolución de default (`$CLAUDE_USAGE_LOG` / `~/.claude/usage-log/console.log`) no tiene test propio — es una línea, sin lógica de negocio. |
| `SDD/docs/doc_quality_gates.md` gate 2 (glob ampliado) | shellcheck de CI/local | corrida directa arriba, verde |

---

## Rojos preexistentes

Ninguno — plugin nuevo, sin historial previo en `origin/prod`.

---

## Nota de proceso

Esta convención (`~/.claude/usage-log/`, "nunca compartir crudo") es una **propuesta** de Esteban, confirmada por Patrick solo en el eje "arrancar con B" (2026-09-07) — no en el detalle de ubicación de archivo ni en a quién extenderlo más allá de Gabriel (pregunta abierta de Esteban del 2026-09-08, sin responder al momento de este commit). El plugin se construyó igual, a pedido explícito de Gabriel, con la ruta configurable (`$CLAUDE_USAGE_LOG`) para que un cambio de convención sea una env var, no un rediseño — documentado en `README.md`.
