# ver-video

**Claude ve un video.** Grabaciones de pantalla de usuarios trabajando, repros de bugs, demos — pegás la ruta (o una URL) y Claude extrae fotogramas, transcribe el audio y responde como alguien que vio el video. El caso que motivó el plugin: mapear un proceso manual grabado para decidir cómo automatizarlo.

## Privacidad — el punto entero del diseño

Todo corre **en tu máquina**: ffmpeg extrae los fotogramas y [faster-whisper](https://github.com/SYSTRAN/faster-whisper) transcribe en CPU local. Sin APIs externas, sin API keys, ningún dato del video sale del equipo. La única descarga es el modelo de whisper la primera vez (~465 MB, HuggingFace); después funciona offline. Esto lo hace apto para material interno con datos de clientes, alineado con la política de herramientas aprobadas.

## Install

```
/plugin marketplace add Bisalta/AI-Forge
/plugin install ver-video
```

Requisitos: Python 3.9+ y ffmpeg (`brew install ffmpeg` / `winget install Gyan.FFmpeg`), y `pip install faster-whisper` para transcripción. El preflight de la skill (`--check`) imprime el comando exacto que falte por OS.

## Uso

```
/ver-video ~/Downloads/EXPD-3515.webm cómo es el proceso que hace la usuaria?
/ver-video grabacion.mp4 --start 3:02 --end 4:56    # zoom denso a una sección
/ver-video https://drive.google.com/file/d/<id>/view resumen
```

Videos en Drive: los archivos compartidos **por enlace** se descargan solos; los restringidos (lo normal para material interno — y está bien) requieren bajarlos con el navegador o, mejor, **Google Drive for Desktop**, que convierte cada video en una ruta local.

## Qué hace por dentro

1. `ffprobe` — metadata (duración, resolución, ¿tiene audio?).
2. `ffmpeg` — un fotograma JPEG (1024 px) por **cambio de pantalla** detectado, con fallback a muestreo uniforme si el video es estático. Compatible con ffmpeg viejo y 8+/9 (`-fps_mode` con fallback `-vsync`).
3. `faster-whisper` — transcripción local con timestamps (default modelo `small`, buen español; degrada limpio a solo-fotogramas si no hay audio o no está instalado).
4. Claude lee cada fotograma como imagen y responde citando tiempos. Para videos de trabajo manual, produce un **mapa del proceso**: pasos por sistema, decisiones humanas vs. transporte de datos, fricciones y candidatos de automatización.

Límites: tope 100 fotogramas / 2 fps (el costo en tokens lo dominan las imágenes); para videos >10 min conviene re-correr secciones con `--start`/`--end`.

## Tests

```
cd skills/ver-video/scripts && python -m unittest test_ver_video -v
```

13 tests; generan videos sintéticos con ffmpeg, sin red.
