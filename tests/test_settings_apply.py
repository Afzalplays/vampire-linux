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
            self.assertIn("panel-color=0x9924546b", weston_text)
            self.assertIn("panel-position=none", weston_text)
            self.assertIn("animation=none", weston_text)
            self.assertIn("alpha=0.70", foot_text)
            self.assertIn("background=f2f2f6", foot_text)

    def test_rejects_invalid_settings_before_writing_runtime_files(self):
        with tempfile.TemporaryDirectory() as temp:
            result, weston, foot = self.run_apply(temp, "theme=ultraviolet\n")
            self.assertNotEqual(result.returncode, 0)
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
            settings.write_text("theme=dark\\n")
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
