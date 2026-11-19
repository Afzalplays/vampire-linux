#!/usr/bin/env python3
"""CLI regression tests for atomic and validated Vampire settings writes."""
import os
import pathlib
import subprocess
import tempfile
import unittest

SETTINGS = pathlib.Path(__file__).resolve().parents[1] / "rootfs-overlay" / "usr" / "bin" / "vsettings"


class VSettingsCliTests(unittest.TestCase):
    def run_settings(self, config, *args):
        env = os.environ.copy()
        env["VAMPIRE_SETTINGS_FILE"] = str(config)
        env["VAMPIRE_SETTINGS_DEFAULTS"] = str(SETTINGS.parents[2] / "etc" / "vampire" / "settings.defaults")
        return subprocess.run(
            ["sh", str(SETTINGS), *args],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_set_writes_valid_value_and_leaves_no_staging_file(self):
        with tempfile.TemporaryDirectory() as temp:
            config = pathlib.Path(temp) / "settings.conf"
            result = self.run_settings(config, "set", "theme", "light")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(config.read_text(), "theme=light\n")
            self.assertEqual(list(pathlib.Path(temp).glob("settings.conf.tmp.*")), [])

    def test_set_rejects_invalid_value_without_creating_file(self):
        with tempfile.TemporaryDirectory() as temp:
            config = pathlib.Path(temp) / "settings.conf"
            result = self.run_settings(config, "set", "theme", "ultraviolet")
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(config.exists())

    def test_set_refuses_symlinked_settings_file_without_touching_target(self):
        with tempfile.TemporaryDirectory() as temp:
            target = pathlib.Path(temp) / "real-settings.conf"
            target.write_text("theme=dark\n")
            config = pathlib.Path(temp) / "settings.conf"
            config.symlink_to(target)
            result = self.run_settings(config, "set", "theme", "light")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("refusing symlinked settings file", result.stderr)
            self.assertTrue(config.is_symlink())
            self.assertEqual(target.read_text(), "theme=dark\n")

    def test_reset_installs_valid_defaults_atomically(self):
        with tempfile.TemporaryDirectory() as temp:
            config = pathlib.Path(temp) / "settings.conf"
            result = self.run_settings(config, "reset")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("theme=dark", config.read_text())
            self.assertIn("voice_access=false", config.read_text())
            self.assertEqual(list(pathlib.Path(temp).glob("settings.conf.tmp.*")), [])

    def test_reset_refuses_symlinked_settings_file(self):
        with tempfile.TemporaryDirectory() as temp:
            target = pathlib.Path(temp) / "real-settings.conf"
            target.write_text("theme=dark\\n")
            config = pathlib.Path(temp) / "settings.conf"
            config.symlink_to(target)
            result = self.run_settings(config, "reset")
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(config.is_symlink())
            self.assertEqual(target.read_text(), "theme=dark\\n")

    def test_set_refuses_to_modify_invalid_existing_file(self):
        with tempfile.TemporaryDirectory() as temp:
            config = pathlib.Path(temp) / "settings.conf"
            config.write_text("theme=dark\ntheme=light\n")
            before = config.read_text()
            result = self.run_settings(config, "set", "accent", "rose")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(config.read_text(), before)


if __name__ == "__main__":
    unittest.main(verbosity=2)
