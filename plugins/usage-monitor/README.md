# usage-monitor

Resumen de atribución de consumo de Claude Code (costo y tokens, por modelo / skill / agente) a partir de tu log local de OpenTelemetry. No mide "eficiencia" ni "desperdicio" — te da el dato crudo agregado; la interpretación sigue siendo tuya.

## Origen

Propuesto por Esteban Fait en `#bisalta-context-sdd` (2026-09-07), a partir de una investigación de consumo real (Gabriel Rojas, ~$3k/mes). Dos diseños posibles:

- **A · Centralizado** — todos mandan telemetría a un colector OTLP común. Requiere infraestructura nueva y una decisión de política (quién ve qué de quién) que no le corresponde a este plugin.
- **B · Descentralizado** — cada persona guarda su propio log local y comparte un resumen cuando hace falta. Escala a todo el equipo sin construir nada nuevo.

Patrick Ocampo confirmó arrancar con **B** el mismo día (2026-09-07). Este plugin implementa B.

## Cómo prender tu log

Tres variables de entorno (nativas de Claude Code, nada que instalar):

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=console
export OTEL_METRIC_EXPORT_INTERVAL=60000
```

Y redirigí la salida a un archivo al abrir `claude` (imprime a stderr):

```bash
mkdir -p ~/.claude/usage-log
claude 2>> ~/.claude/usage-log/console.log
```

Para que quede prendido siempre en tu máquina, agregá las tres `export` a tu `.zshrc`/`.bashrc` y hacé un alias que agregue la redirección. Esto es individual — nadie más lo puede prender por vos ni verlo remotamente (misma soberanía que `/usage`). `OTEL_LOG_USER_PROMPTS` se mantiene **apagado siempre** — no es necesario para este resumen y ese flag sí manda contenido de prompts a los logs (nunca a las métricas).

## Cómo generar el resumen

```bash
/usage-summary
```

o directamente:

```bash
plugins/usage-monitor/scripts/usage-summary.sh [ruta-al-log]
```

Sin argumento usa `$CLAUDE_USAGE_LOG` o `~/.claude/usage-log/console.log`.

## Qué se comparte y qué no

**Solo el resumen que imprime este comando.** Nunca el archivo de log crudo — trae `session.id`, `user.email`, `user.account_uuid`, `organization.id` y otros identificadores del `user.id` hasheado, además de crecer sin límite (cada métrica se re-emite en cada intervalo de export mientras el proceso vive). El script agrega por modelo/skill/agente y nunca imprime esos campos — `SDD/tests/test_usage_summary.sh` lo prueba explícitamente (incluida una corrida mutada que confirma que el test detecta la fuga si el filtro se rompe).

## Convención del archivo — pendiente de confirmación

La ubicación (`~/.claude/usage-log/console.log`) y la regla de "solo resumen, nunca crudo" son la propuesta de Esteban del 2026-09-07 en `#bisalta-context-sdd`. Al momento de escribir esto, Patrick todavía no confirmó por escrito si esta ruta exacta queda fija ni a quién más se extiende más allá de Gabriel — revisar ese hilo antes de asumir que está cerrado. La ruta es configurable vía `$CLAUDE_USAGE_LOG` precisamente para que un cambio de convención no requiera tocar código.
