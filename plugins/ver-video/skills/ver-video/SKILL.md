---
name: ver-video
description: Claude ve un video local — grabaciones de pantalla de usuarios trabajando, screen recordings de bugs, demos, videos bajados de Drive. Extrae fotogramas con ffmpeg (por cambio de pantalla) y transcribe el audio con whisper corriendo LOCAL (nada sale de la máquina, sin APIs externas). Usala siempre que el usuario comparta la ruta de un archivo .webm/.mp4/.mov/.mkv, diga "mirá este video", "veamos la grabación", "analicemos cómo trabaja X", o quiera mapear un proceso manual grabado para automatizarlo — aunque no diga la palabra "video".
argument-hint: "<ruta-al-video> [pregunta o para qué lo estamos viendo]"
allowed-tools: Bash, Read
license: MIT
---

# /ver-video — Claude ve un video local

No tenés entrada de video; esta skill te da una. Un script extrae fotogramas
como JPEG (uno por cambio de pantalla detectado, con fallback uniforme) y
transcribe el audio con faster-whisper **corriendo en la máquina** — sin
APIs externas, sin keys, sin que ningún dato salga. Después vos leés cada
fotograma con `Read`, lo cruzás con la transcripción, y respondés como alguien
que vio el video.

Pensada para material interno: grabaciones de pantalla de usuarios haciendo
trabajo manual, repros de bugs, demos. Acepta rutas locales y también URLs:
enlaces de descarga directa y archivos de Google Drive **compartidos por
enlace**. Un archivo de Drive restringido (lo normal para material con datos
internos, y está bien que así sea) no se puede bajar sin login — el script lo
dice y las opciones son: bajarlo con el navegador, o **Google Drive for
Desktop**, que monta Drive como disco y convierte cada video en una ruta
local sin descarga manual. Esa es la vía recomendada para carpetas de equipo.

## Privacidad — por qué esta skill existe

Todo el procesamiento es local: ffmpeg y whisper corren en la máquina y los
artefactos quedan en un directorio temporal que se borra al final. La única
descarga de red es el **modelo** de whisper la primera vez que se transcribe
(desde HuggingFace, ~465 MB para `small`); después funciona offline. Nunca
agregues a esta skill un backend de transcripción por API externa sin pasar
por la política de herramientas aprobadas de la organización.

## Paso 0 — Preflight (silencioso cuando todo está bien)

En Windows el comando es `python`; en macOS/Linux es `python3` (en Windows
`python3` es el stub de Microsoft Store y no sirve).

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/ver_video.py" --check
```

| Salida | Significado | Acción |
|---|---|---|
| `0` (sin output) | Listo | Seguir al paso 1 sin comentar nada |
| `2` | Falta ffmpeg | El script imprime el comando exacto por OS (brew/winget/apt); corrélo o pedile al usuario |
| `3` | Falta faster-whisper | `pip install faster-whisper`. Mientras tanto la skill funciona solo con fotogramas |

Tras instalar con winget hace falta una terminal nueva para que el PATH se
actualice; si `ffmpeg` sigue sin aparecer en la misma sesión, buscá el binario
bajo `%LOCALAPPDATA%\Microsoft\WinGet\Links`.

## Paso 1 — Correr el script

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/ver_video.py" "<ruta-al-video>"
```

Flags útiles:

- `--start T` / `--end T` — enfocar una sección (`SS`, `MM:SS` o `HH:MM:SS`). Presupuesto de fotogramas más denso; ideal cuando el usuario nombra un momento o el video es largo.
- `--max-frames N` — bajar el tope (default 80, máximo duro 100). Cada fotograma son tokens de imagen; el costo del análisis lo dominan los fotogramas.
- `--resolution W` — ancho en px (default **1024**, ya pensado para leer texto de pantallas; subí a 1440 solo si un texto clave sigue ilegible).
- `--model tiny|base|small|medium|large-v3` — modelo whisper (default `small`, buen español en CPU). `tiny` para una pasada rápida.
- `--language es` — fijar idioma si la autodetección falla.
- `--no-transcript` — saltar transcripción (video sin narración conocida).
- `--no-scene` — forzar muestreo uniforme (el detector de cambios de pantalla ya cae solo a uniforme cuando el video es estático).

En videos largos la detección de escenas decodifica el video entero — puede
tardar unos minutos; avisale al usuario en vez de asumir que se colgó. La
transcripción de una grabación de 30+ minutos con `small` también toma varios
minutos en CPU.

## Paso 2 — Leer TODOS los fotogramas

El reporte lista cada ruta con su `t=MM:SS`. Leelos todos con `Read` en un
solo mensaje (llamadas paralelas) para verlos juntos y poder alinearlos con la
transcripción. No saltees fotogramas: en una grabación de trabajo manual el
detalle que importa (un campo, un click, un error en pantalla) suele estar en
un solo fotograma.

## Paso 3 — Responder

Respondé la pregunta del usuario citando tiempos (`en 03:41 abre …`). Si algo
quedó ilegible o pasó entre fotogramas, decilo y ofrecé re-correr enfocado:
`--start`/`--end` sobre ese rango da hasta 2 fps.

### Cuando el objetivo es automatizar un proceso manual

Si el video es de alguien haciendo trabajo manual y la intención es
automatizar (o el usuario lo dice), estructurá la respuesta como un **mapa del
proceso**, no como un resumen:

1. **Pasos observados** — numerados, con tiempo, sistema/pantalla donde ocurre cada uno, y qué datos se copian/transforman entre sistemas.
2. **Decisiones humanas** — dónde la persona juzga algo (aprobar, elegir, corregir) vs. dónde solo transporta datos. Lo segundo es automatizable; lo primero necesita diseño.
3. **Entradas y salidas** — de dónde salen los datos y dónde terminan.
4. **Fricciones visibles** — reintentos, esperas, errores en pantalla, doble digitación.
5. **Candidatos de automatización** — recién acá, propuestas concretas, cada una anclada a los pasos que reemplaza.

No inventes pasos que no se ven: si un tramo del video no quedó cubierto por
fotogramas, marcalo como hueco y ofrecé el re-run enfocado antes de proponerlo
como automatizable.

## Paso 4 — Limpieza

El reporte termina con el directorio de trabajo. Si el usuario no va a hacer
preguntas de seguimiento, borralo. Si puede haber seguimiento, dejalo — los
fotogramas ya leídos siguen en tu contexto y no hace falta re-correr el script
para responder más preguntas del mismo video.

## Fallas comunes

- **ffmpeg no encontrado tras instalar** → PATH viejo en la sesión; terminal nueva o ruta completa al binario.
- **Transcripción vacía con audio presente** → puede ser música/silencio (el VAD la filtra), o idioma mal detectado: probá `--language es`.
- **Primera transcripción lenta** → está bajando el modelo (una sola vez). Avisale al usuario.
- **Texto de pantalla ilegible** → re-corré la sección con `--resolution 1440 --start ... --end ...`.
- **Aviso de tope de fotogramas alcanzado** → la parte final quedó sin cubrir; re-corré con `--start` desde donde terminó la cobertura.
