#!/usr/bin/env python3
"""End-to-end tests for applying Vampire Desktop appearance preferences."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
APPLY = ROOT / "rootfs-overlay" / "usr" / "lib" / "vampire" / "settings_apply.py"
WESTON = ROOT / "rootfs-overlay" / "etc" / "xdg" / "weston" / "weston.ini"
FOOT = ROOT / "rootfs-overlay" / "etc" / "xdg" / "foot" / "foot.ini"


class SettingsApplyTests(unittest.TestCase):
    def run_apply(self, temp, settings):
        base = pathlib.Path(temp)
        settings_file = base / "settings.conf"
        settings_file.write_text(settings)
        runtime = base / "run" / "vampire"
        config_home = base / "home" / "user" / ".config"
        env = os.environ.copy()
        env.update({
            "VAMPIRE_SETTINGS_FILE": str(settings_file),
            "VAMPIRE_WESTON_BASE": str(WESTON),
            "VAMPIRE_FOOT_BASE": str(FOOT),
            "VAMPIRE_WESTON_RUNTIME_CONFIG": str(runtime / "weston.ini"),
            "XDG_CONFIG_HOME": str(config_home),
        })
        result = subprocess.run(
            ["python3", str(APPLY)],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        return result, runtime / "weston.ini", config_home / "foot" / "foot.ini"

    def test_bundled_wallpaper_is_a_valid_png_with_decodable_pixels(self):
        import struct
        import zlib

        image = (ROOT / "rootfs-overlay" / "usr" / "share" / "vampire" / "wallpaper.png").read_bytes()
        self.assertEqual(image[:8], bytes((137, 80, 78, 71, 13, 10, 26, 10)))
        offset = 8
        chunks = []
        while offset < len(image):
            length = struct.unpack(">I", image[offset:offset + 4])[0]
            kind = image[offset + 4:offset + 8]
            data = image[offset + 8:offset + 8 + length]
            crc = struct.unpack(">I", image[offset + 8 + length:offset + 12 + length])[0]
            self.assertEqual(zlib.crc32(kind + data) & 0xffffffff, crc)
            chunks.append((kind, data))
            offset += 12 + length
        self.assertEqual(chunks[0][0], b"IHDR")
        width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunks[0][1])
        self.assertEqual((width, height, depth, color, compression, filtering, interlace), (640, 360, 8, 6, 0, 0, 0))
        self.assertEqual(chunks[-1], (b"IEND", b""))
        pixels = zlib.decompress(b"".join(data for kind, data in chunks if kind == b"IDAT"))
        self.assertEqual(len(pixels), height * (1 + width * 4))
        self.assertTrue(all(pixels[row * (1 + width * 4)] == 0 for row in range(height)))

    def test_weston_uses_adaptive_aspect_preserving_wallpaper_fit(self):
        config = WESTON.read_text()
        self.assertIn("background-image=/usr/share/vampire/wallpaper.png", config)
        self.assertIn("background-type=scale-crop", config)
        self.assertNotRegex(config, r"(?m)^\s*output-mode\s*=")
        self.assertNotRegex(config, r"(?m)^\s*output-scale\s*=")

    def test_applies_theme_accent_transparency_motion_and_terminal_opacity(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(
                temp,
                "theme=light\naccent=ice\nsurface_transparency=40\n"
                "terminal_opacity=70\ntop_panel=false\nreduced_motion=true\n",
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            weston_text = weston.read_text()
            foot_text = foot.read_text()
            self.assertIn("background-color=0xfff2f2f6", weston_text)
            self.assertIn("background-image=/usr/share/vampire/wallpaper.png", weston_text)
            self.assertIn("background-type=scale-crop", weston_text)
            self.assertIn("panel-color=0x9924546b", weston_text)
            self.assertIn("panel-position=none", weston_text)
            self.assertIn("animation=none", weston_text)
            self.assertIn("alpha=0.70", foot_text)
            self.assertIn("background=f2f2f6", foot_text)

    def test_accepts_complete_shipped_settings_defaults(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(temp, (ROOT / "rootfs-overlay" / "etc" / "vampire" / "settings.defaults").read_text())
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(weston.is_file())
            self.assertTrue(foot.is_file())

    def test_rejects_invalid_settings_before_writing_runtime_files(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(temp, "theme=ultraviolet\n")
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(weston.exists())
            self.assertFalse(foot.exists())

    def test_rejects_invalid_stored_preference_even_when_not_applied_by_weston(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(temp, "dock_size=giant\n")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("invalid value for dock_size", result.stderr)
            self.assertFalse(weston.exists())
            self.assertFalse(foot.exists())

    def test_rejects_unknown_preference_instead_of_silently_ignoring_it(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(temp, "experimental_switch=true\n")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unknown setting: experimental_switch", result.stderr)
            self.assertFalse(weston.exists())
            self.assertFalse(foot.exists())

    def test_rejects_duplicate_preference_not_consumed_by_weston(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(
                temp, "dock_size=small\ndock_size=large\n"
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("duplicate setting: dock_size", result.stderr)
            self.assertFalse(weston.exists())
            self.assertFalse(foot.exists())

    def test_refuses_symlinked_runtime_configuration_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            real_runtime = base / "real-runtime"
            real_runtime.mkdir()
            runtime_link = base / "runtime"
            runtime_link.symlink_to(real_runtime, target_is_directory=True)
            settings = base / "settings.conf"
            settings.write_text("theme=dark\n")
            env = os.environ.copy()
            env.update({
                "VAMPIRE_SETTINGS_FILE": str(settings),
                "VAMPIRE_WESTON_BASE": str(WESTON),
                "VAMPIRE_FOOT_BASE": str(FOOT),
                "VAMPIRE_WESTON_RUNTIME_CONFIG": str(runtime_link / "weston.ini"),
                "XDG_CONFIG_HOME": str(base / "config"),
            })
            result = subprocess.run(
                ["python3", str(APPLY)], env=env, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("symlinked configuration path", result.stderr)
            self.assertEqual(list(real_runtime.iterdir()), [])

    def test_refuses_symlinked_settings_file(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            target = base / "real-settings.conf"
            target.write_text("theme=dark\n")
            settings = base / "settings.conf"
            settings.symlink_to(target)
            env = os.environ.copy()
            env.update({
                "VAMPIRE_SETTINGS_FILE": str(settings),
                "VAMPIRE_WESTON_BASE": str(WESTON),
                "VAMPIRE_FOOT_BASE": str(FOOT),
                "VAMPIRE_WESTON_RUNTIME_CONFIG": str(base / "run" / "weston.ini"),
                "XDG_CONFIG_HOME": str(base / "config"),
            })
            result = subprocess.run(
                ["python3", str(APPLY)], env=env, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("symlinked configuration path", result.stderr)
            self.assertEqual(target.read_text(), "theme=dark\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
