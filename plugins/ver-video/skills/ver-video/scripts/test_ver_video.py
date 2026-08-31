#!/usr/bin/env python3
"""Tests de ver_video.py — generan videos sintéticos con ffmpeg, sin red.

Correr:  python -m unittest test_ver_video -v   (desde scripts/)
"""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ver_video  # noqa: E402

FFMPEG = shutil.which("ffmpeg") is not None


def make_video(path: Path, seconds: float = 12.0, with_audio: bool = True,
               scene_cuts: bool = False) -> None:
    """testsrc (o mosaicos alternados para simular cambios de pantalla) + tono."""
    if scene_cuts:
        # dos fuentes alternadas cada 2s => cambios duros detectables
        vf = (
            f"testsrc=duration={seconds}:size=640x360:rate=10,"
            "geq=r='if(lt(mod(floor(T/2),2),1),255,X)':g='Y':b='128'"
        )
        video_in = ["-f", "lavfi", "-i", vf]
    else:
        video_in = ["-f", "lavfi", "-i", f"testsrc=duration={seconds}:size=640x360:rate=10"]
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *video_in]
    if with_audio:
        cmd += ["-f", "lavfi", "-i", f"sine=frequency=440:duration={seconds}", "-shortest",
                "-c:a", "aac"]
    cmd += ["-c:v", "libx264", "-pix_fmt", "yuv420p", str(path)]
    subprocess.run(cmd, check=True, capture_output=True)


class PureTests(unittest.TestCase):
    def test_parse_time(self):
        self.assertEqual(ver_video.parse_time("90"), 90.0)
        self.assertEqual(ver_video.parse_time("1:30"), 90.0)
        self.assertEqual(ver_video.parse_time("1:00:05"), 3605.0)
        self.assertIsNone(ver_video.parse_time(None))
        with self.assertRaises(SystemExit):
            ver_video.parse_time("abc")

    def test_format_time(self):
        self.assertEqual(ver_video.format_time(65), "01:05")
        self.assertEqual(ver_video.format_time(3665), "1:01:05")

    def test_parse_drive_file_id(self):
        fid = "1gRHpIGmgAKWEz4BZDcgPagkP8gNyy6Uu"
        self.assertEqual(
            ver_video.parse_drive_file_id(f"https://drive.google.com/file/d/{fid}/view?usp=drivesdk"), fid)
        self.assertEqual(
            ver_video.parse_drive_file_id(f"https://drive.google.com/open?id={fid}"), fid)
        self.assertEqual(
            ver_video.parse_drive_file_id(f"https://drive.google.com/uc?export=download&id={fid}"), fid)
        self.assertIsNone(ver_video.parse_drive_file_id("https://example.com/video.mp4"))
        with self.assertRaises(SystemExit):
            ver_video.parse_drive_file_id("https://drive.google.com/drive/folders/13_wXYZabcdefghij")

    def test_is_url(self):
        self.assertTrue(ver_video.is_url("https://drive.google.com/file/d/x/view"))
        self.assertFalse(ver_video.is_url(r"C:\Users\p\video.mp4"))
        self.assertFalse(ver_video.is_url("/home/p/video.mp4"))

    def test_budget_caps(self):
        fps, target = ver_video.budget(12.0, 100)
        self.assertLessEqual(fps, ver_video.MAX_FPS)
        self.assertLessEqual(target, 100)
        fps, target = ver_video.budget(3600.0, 100)
        self.assertLessEqual(target, 100)
        fps_f, target_f = ver_video.budget_focus(10.0, 100)
        self.assertGreaterEqual(fps_f, fps)  # el modo enfocado es más denso


@unittest.skipUnless(FFMPEG, "ffmpeg no está instalado")
class PipelineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = Path(tempfile.mkdtemp(prefix="ver-video-test-"))
        cls.video = cls.tmp / "prueba.mp4"
        make_video(cls.video, seconds=12.0, with_audio=True)
        cls.video_mudo = cls.tmp / "mudo.mp4"
        make_video(cls.video_mudo, seconds=6.0, with_audio=False)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def test_probe(self):
        meta = ver_video.probe(self.video)
        self.assertAlmostEqual(meta["duration_seconds"], 12.0, delta=0.6)
        self.assertTrue(meta["has_audio"])
        self.assertEqual(meta["width"], 640)
        meta2 = ver_video.probe(self.video_mudo)
        self.assertFalse(meta2["has_audio"])

    def test_extract_uniform(self):
        out = self.tmp / "frames_uniform"
        frames = ver_video.extract_uniform(self.video, out, fps=1.0,
                                           resolution=320, max_frames=100)
        self.assertGreaterEqual(len(frames), 10)
        self.assertLessEqual(len(frames), 13)
        ts = [f["timestamp_seconds"] for f in frames]
        self.assertEqual(ts, sorted(ts))
        for f in frames:
            self.assertTrue(Path(f["path"]).exists())

    def test_extract_uniform_focused(self):
        out = self.tmp / "frames_focus"
        frames = ver_video.extract_uniform(self.video, out, fps=2.0, resolution=320,
                                           max_frames=100, start=5.0, end=8.0)
        self.assertTrue(frames)
        for f in frames:
            self.assertGreaterEqual(f["timestamp_seconds"], 5.0)
            self.assertLessEqual(f["timestamp_seconds"], 8.6)

    def test_extract_scene_or_fallback(self):
        # No exigimos modo escena (depende del contenido); sí que haya frames
        # válidos y que el flag vfr moderno/viejo no reviente en este ffmpeg.
        out = self.tmp / "frames_scene"
        frames = ver_video.extract_scene(self.video, out, threshold=0.15,
                                         resolution=320, max_frames=100)
        self.assertGreaterEqual(len(frames), 5)
        for f in frames:
            self.assertTrue(Path(f["path"]).exists())
            self.assertIn(f["source"], ("cambio-de-pantalla", "uniforme"))

    def test_extract_audio(self):
        wav = ver_video.extract_audio(self.video, self.tmp / "a" / "audio.wav")
        self.assertTrue(wav.exists())
        self.assertGreater(wav.stat().st_size, 100_000)  # ~12s de wav 16k mono

    def test_cli_no_transcript_utf8(self):
        out_dir = self.tmp / "cli_run"
        result = subprocess.run(
            [sys.executable, str(Path(__file__).parent / "ver_video.py"),
             str(self.video), "--no-transcript", "--out-dir", str(out_dir),
             "--max-frames", "20", "--resolution", "320"],
            capture_output=True, text=True, encoding="utf-8",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("# ver-video: reporte", result.stdout)
        self.assertIn("## Fotogramas", result.stdout)
        self.assertIn("Duración", result.stdout)  # la tilde sobrevivió al stdout

    def test_cli_video_sin_audio(self):
        out_dir = self.tmp / "cli_mudo"
        result = subprocess.run(
            [sys.executable, str(Path(__file__).parent / "ver_video.py"),
             str(self.video_mudo), "--out-dir", str(out_dir),
             "--max-frames", "10", "--resolution", "320"],
            capture_output=True, text=True, encoding="utf-8",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("no tiene pista de audio", result.stdout)

    def test_cli_check_runs(self):
        result = subprocess.run(
            [sys.executable, str(Path(__file__).parent / "ver_video.py"), "--check"],
            capture_output=True, text=True, encoding="utf-8",
        )
        self.assertIn(result.returncode, (0, 2, 3))


if __name__ == "__main__":
    unittest.main(verbosity=2)
