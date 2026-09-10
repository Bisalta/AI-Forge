---
description: Genera el resumen de atribución de consumo (costo/tokens por modelo, skill y agente) desde tu log local de OTel console — nunca el log crudo.
argument-hint: [ruta-al-log, default ~/.claude/usage-log/console.log]
allowed-tools: [Bash]
---

Corré `plugins/usage-monitor/scripts/usage-summary.sh $ARGUMENTS` (o sin argumentos si el usuario no dio ruta — usa el default documentado en el propio script) y mostrale al usuario la salida tal cual.

Si el script sale con exit 2 porque no existe el archivo, explicale que primero tiene que prender la telemetría — remitilo a `plugins/usage-monitor/README.md` para las env vars exactas — y no inventes un log ni simules datos.

Este resumen es lo único pensado para compartir (Slack, Proxima, donde haga falta). El archivo de log crudo que lee (`~/.claude/usage-log/console.log` u otra ruta) nunca se comparte ni se pega en ningún lado — trae `session.id`, `user.email` y otros identificadores que este comando deliberadamente no expone.
