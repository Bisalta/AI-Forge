#!/usr/bin/env python3
"""ver-video: extrae fotogramas y transcripción de un video local, todo en la máquina.

Pipeline: ffprobe (metadata) -> ffmpeg (fotogramas por cambio de escena, con
fallback uniforme) -> faster-whisper local (transcripción, opcional).

Imprime un reporte markdown a stdout con las rutas de los fotogramas para que
Claude los lea como imágenes. Nada sale de la máquina: sin APIs externas, sin
keys. La única descarga es el modelo de whisper la primera vez (HuggingFace).

Uso:
  python ver_video.py <video> [--start T] [--end T] [--max-frames N]
                      [--resolution W] [--model SIZE] [--language XX]
                      [--no-transcript] [--scene-threshold F] [--out-dir DIR]
  python ver_video.py --check     # preflight de dependencias
"""
from __future__ import annotations

import argparse
import http.cookiejar
import json
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

MAX_FPS = 2.0
HARD_MAX_FRAMES = 100
DEFAULT_RESOLUTION = 1024  # ancho px; las grabaciones de pantalla necesitan texto legible
DEFAULT_SCENE_THRESHOLD = 0.15  # cambios de ventana/pantalla en UI son más sutiles que cortes de cámara
DEFAULT_WHISPER_MODEL = "small"  # buen español en CPU; "tiny"/"base" más rápidos, menos fieles

VIDEO_EXTS = {".mp4", ".mkv", ".webm", ".mov", ".m4v", ".avi", ".wmv", ".flv"}

EXT_BY_MIME = {
    "video/webm": ".webm", "video/mp4": ".mp4", "video/quicktime": ".mov",
    "video/x-matroska": ".mkv", "video/x-msvideo": ".avi",
}


def is_url(source: str) -> bool:
    parsed = urllib.parse.urlparse(source)
    return parsed.scheme in ("http", "https") and bool(parsed.netloc)


def parse_drive_file_id(url: str) -> str | None:
    """ID de archivo desde las formas comunes de URL de Google Drive."""
    parsed = urllib.parse.urlparse(url)
    if "drive.google.com" not in parsed.netloc and "drive.usercontent.google.com" not in parsed.netloc:
        return None
    if "/drive/folders/" in parsed.path or "/drive/u/" in parsed.path and "/folders/" in parsed.path:
        raise SystemExit(
            "Ese enlace es de una CARPETA de Drive. Pasame el enlace del archivo "
            "(click derecho sobre el video → Compartir → Copiar enlace)."
        )
    m = re.search(r"/file/d/([\w-]{20,})", parsed.path)
    if m:
        return m.group(1)
    qs = urllib.parse.parse_qs(parsed.query)
    for key in ("id",):
        if key in qs and qs[key]:
            return qs[key][0]
    return None


def _filename_from_response(resp, fallback: str) -> str:
    cd = resp.headers.get("Content-Disposition") or ""
    m = re.search(r"filename\*=UTF-8''([^;]+)", cd)
    if m:
        return urllib.parse.unquote(m.group(1).strip())
    m = re.search(r'filename="([^"]+)"', cd)
    if m:
        return m.group(1)
    ctype = (resp.headers.get("Content-Type") or "").split(";")[0].strip().lower()
    return fallback + EXT_BY_MIME.get(ctype, ".bin")


def _stream_to_file(resp, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    total = int(resp.headers.get("Content-Length") or 0)
    done = 0
    next_mark = 0
    with open(out_path, "wb") as fh:
        while True:
            chunk = resp.read(1024 * 1024)
            if not chunk:
                break
            fh.write(chunk)
            done += len(chunk)
            if done >= next_mark:
                pct = f" ({done * 100 // total}%)" if total else ""
                print(f"[ver-video] descargando… {done // (1024*1024)} MB{pct}", file=sys.stderr)
                next_mark += 25 * 1024 * 1024


def download_source(url: str, out_dir: Path) -> Path:
    """Descarga una URL (Drive compartido-por-enlace o descarga directa) a out_dir.

    Sin login: si Drive responde con la página de inicio de sesión, el archivo
    es restringido y hay que bajarlo con el navegador (o usar Drive for
    Desktop, que lo expone como ruta local). El flujo maneja el interstitial
    de "archivo grande, no se pudo escanear" de Drive con su token confirm.
    """
    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    opener.addheaders = [("User-Agent", "ver-video/1.0 (python-urllib)")]

    drive_id = parse_drive_file_id(url)
    fetch_url = (
        f"https://drive.google.com/uc?export=download&id={drive_id}" if drive_id else url
    )
    fallback_name = f"video_{drive_id}" if drive_id else "video_descargado"

    for hop in range(3):
        try:
            resp = opener.open(fetch_url, timeout=120)
        except urllib.error.HTTPError as exc:
            raise SystemExit(f"La descarga falló: HTTP {exc.code} en {fetch_url}")
        ctype = (resp.headers.get("Content-Type") or "").lower()
        if "text/html" not in ctype:
            name = _filename_from_response(resp, fallback_name)
            out_path = out_dir / name
            print(f"[ver-video] bajando {name}…", file=sys.stderr)
            _stream_to_file(resp, out_path)
            return out_path

        page = resp.read(512 * 1024).decode("utf-8", errors="replace")
        if drive_id is None:
            raise SystemExit(
                f"La URL devolvió una página HTML, no un video: {url}\n"
                "Pasá un enlace de descarga directa o una ruta local."
            )
        if "accounts.google.com" in (resp.url or "") or "Iniciar sesión" in page or "Sign in" in page:
            raise SystemExit(
                "El archivo de Drive requiere iniciar sesión (no está compartido "
                "por enlace). Opciones: bajalo con el navegador, o usá Google "
                "Drive for Desktop y pasame la ruta local del archivo."
            )
        # Interstitial de virus-scan: formulario hacia drive.usercontent.google.com
        form_action = re.search(r'action="(https://drive\.usercontent\.google\.com/download[^"]*)"', page)
        hidden = dict(re.findall(r'<input type="hidden" name="([^"]+)" value="([^"]*)"', page))
        if form_action and hidden:
            fetch_url = form_action.group(1) + "?" + urllib.parse.urlencode(hidden)
            continue
        confirm = re.search(r"confirm=([\w-]+)", page)
        if confirm:
            fetch_url = (
                f"https://drive.google.com/uc?export=download&id={drive_id}"
                f"&confirm={confirm.group(1)}"
            )
            continue
        raise SystemExit(
            "Drive devolvió una página que no reconozco (¿cuota de descarga "
            "excedida?). Bajá el archivo con el navegador y pasame la ruta local."
        )
    raise SystemExit("Demasiados redirects de Drive sin llegar al archivo.")


def _utf8_io() -> None:
    # En Windows la consola cp1252 revienta con tildes/emoji; forzamos UTF-8.
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, OSError):
            pass


def parse_time(value: str | float | int | None) -> float | None:
    """SS, MM:SS o HH:MM:SS (acepta .ms) -> segundos."""
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    s = str(value).strip()
    if not s:
        return None
    parts = s.split(":")
    try:
        if len(parts) == 1:
            return float(parts[0])
        if len(parts) == 2:
            return int(parts[0]) * 60 + float(parts[1])
        if len(parts) == 3:
            return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
    except ValueError:
        pass
    raise SystemExit(f"No pude interpretar el tiempo: {value!r} (esperaba SS, MM:SS o HH:MM:SS)")


def format_time(seconds: float) -> str:
    total = int(round(seconds))
    hours, rem = divmod(total, 3600)
    minutes, sec = divmod(rem, 60)
    if hours:
        return f"{hours}:{minutes:02d}:{sec:02d}"
    return f"{minutes:02d}:{sec:02d}"


def probe(video_path: Path) -> dict:
    if shutil.which("ffprobe") is None:
        raise SystemExit("ffprobe no está instalado (viene con ffmpeg). Corré --check para ver cómo instalarlo.")
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json",
         "-show_format", "-show_streams", str(video_path)],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    if result.returncode != 0:
        raise SystemExit(f"ffprobe falló sobre {video_path}: {result.stderr.strip()}")
    data = json.loads(result.stdout or "{}")
    streams = data.get("streams", [])
    fmt = data.get("format", {})
    video_stream = next((s for s in streams if s.get("codec_type") == "video"), {})
    audio_stream = next((s for s in streams if s.get("codec_type") == "audio"), None)
    duration = float(fmt.get("duration") or video_stream.get("duration") or 0)
    return {
        "duration_seconds": duration,
        "width": video_stream.get("width"),
        "height": video_stream.get("height"),
        "codec": video_stream.get("codec_name"),
        "has_audio": audio_stream is not None,
    }


def budget(duration: float, max_frames: int) -> tuple[float, int]:
    """Presupuesto de fotogramas para pasada completa (el costo en tokens manda)."""
    if duration <= 0:
        return 1.0, 1
    if duration <= 30:
        target = max(12, int(round(duration)))
    elif duration <= 60:
        target = 40
    elif duration <= 180:
        target = 60
    elif duration <= 600:
        target = 80
    else:
        target = max_frames
    target = min(target, max_frames)
    fps = min(target / duration, MAX_FPS)
    return fps, min(max_frames, max(1, int(round(fps * duration))))


def budget_focus(duration: float, max_frames: int) -> tuple[float, int]:
    """Rango pedido por el usuario: más denso, está haciendo zoom para ver detalle."""
    if duration <= 0:
        return MAX_FPS, 2
    if duration <= 15:
        target = min(max_frames, max(10, int(round(duration * MAX_FPS))))
    elif duration <= 60:
        target = min(max_frames, 80)
    else:
        target = max_frames
    fps = min(target / duration, MAX_FPS)
    return fps, min(max_frames, max(1, int(round(fps * duration))))


def _run_ffmpeg(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")


def _range_args(start: float | None, end: float | None) -> list[str]:
    args: list[str] = []
    if start is not None:
        args += ["-ss", f"{start:.3f}"]
    if end is not None:
        args += ["-to", f"{end:.3f}"]
    return args


def extract_uniform(
    video_path: Path, out_dir: Path, fps: float, resolution: int,
    max_frames: int, start: float | None = None, end: float | None = None,
) -> list[dict]:
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("frame_*.jpg"):
        old.unlink()
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    cmd += _range_args(start, end)
    cmd += [
        "-i", str(video_path),
        "-vf", f"fps={fps},scale={resolution}:-2",
        "-frames:v", str(max_frames),
        "-q:v", "3",
        str(out_dir / "frame_%04d.jpg"),
    ]
    result = _run_ffmpeg(cmd)
    if result.returncode != 0:
        raise SystemExit(f"ffmpeg falló extrayendo fotogramas: {result.stderr.strip()}")
    offset = start or 0.0
    files = sorted(out_dir.glob("frame_*.jpg"))
    return [
        {"path": str(p), "timestamp_seconds": round(offset + i / fps, 2) if fps > 0 else offset,
         "source": "uniforme"}
        for i, p in enumerate(files)
    ]


def extract_scene(
    video_path: Path, out_dir: Path, threshold: float, resolution: int,
    max_frames: int, start: float | None = None, end: float | None = None,
    min_scene_frames: int = 8,
) -> list[dict]:
    """Un fotograma por cambio de pantalla detectado. Cae a uniforme cuando:
    - el video es estático y detecta muy pocos cambios, o
    - la versión de ffmpeg no soporta el modo vfr disponible.

    ffmpeg >= 8 eliminó -vsync (ahora es -fps_mode); probamos la opción moderna
    primero y la vieja como fallback, para funcionar en cualquier instalación.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in out_dir.glob("frame_*.jpg"):
        old.unlink()

    select = f"eq(n\\,0)+gt(scene\\,{threshold})"
    vf = f"select='{select}',metadata=mode=print:file=-,scale={resolution}:-2"
    base = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y"]
    base += _range_args(start, end)
    tail = [
        "-i", str(video_path),
        "-vf", vf,
        "-frames:v", str(max_frames),
        "-q:v", "3",
        str(out_dir / "frame_%04d.jpg"),
    ]

    result = None
    for vfr_args in (["-fps_mode", "vfr"], ["-vsync", "vfr"]):
        # el flag de modo va justo antes de la salida
        cmd = base + tail[:-1] + vfr_args + tail[-1:]
        result = _run_ffmpeg(cmd)
        if result.returncode == 0:
            break
        lowered = (result.stderr or "").lower()
        if "unrecognized option" not in lowered and "option not found" not in lowered:
            break  # falló por otra razón; no insistir con el otro flag

    if result is None or result.returncode != 0:
        print("[ver-video] detección de escenas falló, uso muestreo uniforme…", file=sys.stderr)
        return _uniform_fallback(video_path, out_dir, resolution, max_frames, start, end)

    pts_times: list[float] = []
    for stream in (result.stdout or "", result.stderr or ""):
        for line in stream.splitlines():
            for tok in line.strip().split():
                if tok.startswith("pts_time:"):
                    try:
                        pts_times.append(float(tok.split(":", 1)[1]))
                    except ValueError:
                        pass

    files = sorted(out_dir.glob("frame_*.jpg"))
    if len(files) < min_scene_frames:
        print(
            f"[ver-video] solo {len(files)} cambios de pantalla detectados "
            "(video estático) — uso muestreo uniforme…",
            file=sys.stderr,
        )
        for f in files:
            f.unlink()
        return _uniform_fallback(video_path, out_dir, resolution, max_frames, start, end)

    offset = start or 0.0
    if len(pts_times) < len(files):
        pts_times += [0.0] * (len(files) - len(pts_times))
    return [
        {"path": str(p), "timestamp_seconds": round(offset + pts_times[i], 2),
         "source": "cambio-de-pantalla"}
        for i, p in enumerate(files)
    ]


def _uniform_fallback(
    video_path: Path, out_dir: Path, resolution: int, max_frames: int,
    start: float | None, end: float | None,
) -> list[dict]:
    meta = probe(video_path)
    eff_start = start if start is not None else 0.0
    eff_end = end if end is not None else meta["duration_seconds"]
    duration = max(0.1, eff_end - eff_start)
    fps, _ = budget(duration, max_frames)
    return extract_uniform(video_path, out_dir, fps, resolution, max_frames, start, end)


def extract_audio(video_path: Path, out_path: Path) -> Path:
    """WAV mono 16 kHz — lo que espera whisper; queda local, se borra con el workdir."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
        "-i", str(video_path),
        "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1",
        str(out_path),
    ]
    result = _run_ffmpeg(cmd)
    if result.returncode != 0:
        raise SystemExit(f"ffmpeg falló extrayendo audio: {result.stderr.strip()}")
    return out_path


def transcribe(
    audio_path: Path, model_size: str, language: str | None,
    start: float | None = None, end: float | None = None,
) -> tuple[list[dict] | None, str]:
    """Transcripción 100% local con faster-whisper. (None, motivo) si no se puede."""
    try:
        from faster_whisper import WhisperModel
    except ImportError:
        return None, (
            "faster-whisper no está instalado — el video queda solo con fotogramas. "
            "Para habilitar transcripción local: pip install faster-whisper"
        )

    print(f"[ver-video] transcribiendo con whisper local (modelo {model_size})…", file=sys.stderr)
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments_iter, info = model.transcribe(
        str(audio_path), language=language, vad_filter=True,
    )
    segments = []
    for seg in segments_iter:
        text = seg.text.strip()
        if not text:
            continue
        if start is not None and seg.end < start:
            continue
        if end is not None and seg.start > end:
            continue
        segments.append({"start": round(seg.start, 2), "end": round(seg.end, 2), "text": text})
    detected = getattr(info, "language", None) or "?"
    return segments, f"whisper local ({model_size}, idioma detectado: {detected})"


def check(args: argparse.Namespace) -> int:
    """Preflight. 0 = listo; 2 = falta ffmpeg; 3 = sin whisper (solo fotogramas)."""
    system = platform.system()
    missing = [b for b in ("ffmpeg", "ffprobe") if shutil.which(b) is None]
    try:
        import faster_whisper  # noqa: F401
        has_whisper = True
    except ImportError:
        has_whisper = False

    if not missing and has_whisper:
        return 0  # silencio: no hay nada que arreglar

    if missing:
        print(f"[ver-video] falta: {', '.join(missing)}", file=sys.stderr)
        hint = {
            "Darwin": "  brew install ffmpeg",
            "Windows": "  winget install -e --id Gyan.FFmpeg  (abrí una terminal nueva después)",
            "Linux": "  sudo apt install ffmpeg   # o: sudo dnf install ffmpeg",
        }.get(system, "  instalá ffmpeg con tu gestor de paquetes")
        print(hint, file=sys.stderr)
    if not has_whisper:
        print(
            "[ver-video] sin transcripción: faster-whisper no está instalado.\n"
            "  pip install faster-whisper   # (en Mac/Linux: pip3)\n"
            "  Los videos se analizan solo con fotogramas hasta instalarlo.",
            file=sys.stderr,
        )
    return 2 if missing else 3


def main() -> int:
    _utf8_io()
    ap = argparse.ArgumentParser(
        prog="ver-video",
        description="Extrae fotogramas y transcripción local de un video para que Claude lo vea.",
    )
    ap.add_argument("source", nargs="?", help="Ruta al archivo de video local")
    ap.add_argument("--check", action="store_true", help="Preflight de dependencias y salir")
    ap.add_argument("--start", type=str, default=None, help="Inicio del rango (SS, MM:SS o HH:MM:SS)")
    ap.add_argument("--end", type=str, default=None, help="Fin del rango")
    ap.add_argument("--max-frames", type=int, default=80, help="Tope de fotogramas (máx duro 100)")
    ap.add_argument("--resolution", type=int, default=DEFAULT_RESOLUTION,
                    help=f"Ancho en px (default {DEFAULT_RESOLUTION}, pensado para leer texto en pantalla)")
    ap.add_argument("--scene-threshold", type=float, default=DEFAULT_SCENE_THRESHOLD,
                    help="Sensibilidad del detector de cambios de pantalla (0-1)")
    ap.add_argument("--no-scene", action="store_true", help="Forzar muestreo uniforme")
    ap.add_argument("--model", type=str, default=DEFAULT_WHISPER_MODEL,
                    choices=["tiny", "base", "small", "medium", "large-v3"],
                    help="Modelo whisper local")
    ap.add_argument("--language", type=str, default=None,
                    help="Idioma ISO (es, en, …). Default: detección automática")
    ap.add_argument("--no-transcript", action="store_true", help="Saltar la transcripción")
    ap.add_argument("--out-dir", type=str, default=None, help="Directorio de trabajo (default: temp)")
    args = ap.parse_args()

    if args.check:
        return check(args)
    if not args.source:
        ap.error("falta la ruta del video o una URL (o usá --check)")

    max_frames = min(args.max_frames, HARD_MAX_FRAMES)
    work = Path(args.out_dir).expanduser().resolve() if args.out_dir else Path(
        tempfile.mkdtemp(prefix="ver-video-"))
    work.mkdir(parents=True, exist_ok=True)
    print(f"[ver-video] directorio de trabajo: {work}", file=sys.stderr)

    if is_url(args.source):
        video = download_source(args.source, work / "descarga")
    else:
        video = Path(args.source).expanduser().resolve()
        if not video.exists():
            raise SystemExit(f"No existe el archivo: {video}")
    if video.suffix.lower() not in VIDEO_EXTS:
        print(f"[ver-video] aviso: {video.suffix} no es una extensión de video conocida, sigo igual",
              file=sys.stderr)

    meta = probe(video)
    duration = meta["duration_seconds"]
    start = parse_time(args.start)
    end = parse_time(args.end)
    if start is not None and duration > 0 and start >= duration:
        raise SystemExit(f"--start {start:.0f}s está más allá del final del video ({duration:.0f}s)")
    if start is not None and end is not None and end <= start:
        raise SystemExit("--end tiene que ser mayor que --start")
    focused = start is not None or end is not None
    eff_start = start if start is not None else 0.0
    eff_end = end if end is not None else duration
    eff_duration = max(0.0, eff_end - eff_start)

    frames_dir = work / "frames"
    if args.no_scene or focused:
        fps, target = (budget_focus if focused else budget)(eff_duration, max_frames)
        print(f"[ver-video] extrayendo ~{target} fotogramas a {fps:.3f} fps…", file=sys.stderr)
        frames = extract_uniform(video, frames_dir, fps, args.resolution, max_frames, start, end)
    else:
        print("[ver-video] detectando cambios de pantalla…", file=sys.stderr)
        frames = extract_scene(video, frames_dir, args.scene_threshold,
                               args.resolution, max_frames, start, end)

    truncated = (
        len(frames) >= max_frames
        and frames
        and frames[0].get("source") == "cambio-de-pantalla"
        and eff_duration > 0
        and frames[-1]["timestamp_seconds"] < eff_start + eff_duration * 0.9
    )

    transcript: list[dict] | None = None
    transcript_note = ""
    if args.no_transcript:
        transcript_note = "transcripción desactivada (--no-transcript)"
    elif not meta["has_audio"]:
        transcript_note = "el video no tiene pista de audio — solo fotogramas"
    else:
        audio = extract_audio(video, work / "audio.wav")
        transcript, transcript_note = transcribe(audio, args.model, args.language, start, end)

    if transcript:
        (work / "transcripcion.txt").write_text(
            "\n".join(f"[{format_time(s['start'])}] {s['text']}" for s in transcript),
            encoding="utf-8",
        )

    # ---- reporte ----
    print()
    print("# ver-video: reporte")
    print()
    print(f"- **Archivo:** {video}")
    print(f"- **Duración:** {format_time(duration)} ({duration:.1f}s)")
    if meta.get("width"):
        print(f"- **Resolución original:** {meta['width']}x{meta['height']} ({meta.get('codec')})")
    if focused:
        print(f"- **Rango analizado:** {format_time(eff_start)} → {format_time(eff_end)}")
    mode = frames[0]["source"] if frames else "n/a"
    print(f"- **Fotogramas:** {len(frames)} ({mode}, {args.resolution}px de ancho)")
    if transcript is not None:
        print(f"- **Transcripción:** {len(transcript)} segmentos ({transcript_note})")
    else:
        print(f"- **Transcripción:** no disponible — {transcript_note}")

    if truncated:
        print()
        print("> **Aviso:** se llegó al tope de fotogramas antes de cubrir todo el rango — "
              "la parte final del video quedó sin fotogramas. Volvé a correr con "
              "`--start`/`--end` sobre la sección faltante.")
    if not focused and duration > 600:
        print()
        print(f"> **Aviso:** el video dura {int(duration // 60)} minutos; la cobertura es "
              "dispersa. Para detalle fino, repetí sobre una sección con `--start`/`--end`.")

    print()
    print("## Fotogramas")
    print()
    print("**Leé cada ruta de abajo con la herramienta Read para ver la imagen.** "
          "Están en orden cronológico; `t=` es el tiempo absoluto en el video.")
    print()
    for f in frames:
        print(f"- `{f['path']}` (t={format_time(f['timestamp_seconds'])})")

    print()
    print("## Transcripción")
    print()
    if transcript:
        print("```")
        for seg in transcript:
            print(f"[{format_time(seg['start'])}] {seg['text']}")
        print("```")
    elif transcript is not None:
        print("_El audio no contiene habla detectable._")
    else:
        print(f"_{transcript_note}_")

    print()
    print("---")
    print(f"_Directorio de trabajo: `{work}` — borralo cuando termines de analizar._")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
