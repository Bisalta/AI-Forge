---
description: Claude ve un video (ruta local o URL de Drive/descarga directa) — extrae fotogramas y transcripción local, y responde preguntas sobre lo que pasa en pantalla.
argument-hint: <ruta-o-url-del-video> [pregunta o para qué lo estamos viendo]
allowed-tools: [Bash, Read]
---

Invocá la skill `ver-video` (definida en SKILL.md de este plugin) con los argumentos del usuario: $ARGUMENTS

Seguí el pipeline completo de la skill: preflight → correr el script (frames + transcripción local) → leer TODOS los fotogramas con Read → responder anclado en frames y transcript. Si el usuario no dio argumentos, pedile la ruta o URL del video antes de continuar. Si el video es de alguien haciendo trabajo manual, estructurá la respuesta como mapa del proceso según la skill.
