#!/usr/bin/env python3
"""Isolated tests for persistent Vampire settings bootstrap and recovery."""
import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
BOOTSTRAP = ROOT / "rootfs-overlay" / "usr" / "lib" / "vampire" / "settings-bootstrap"
VALIDATOR = ROOT / "rootfs-overlay" / "usr" / "bin" / "vsettings"
DEFAULTS = ROOT / "rootfs-overlay" / "etc" / "vampire" / "settings.defaults"


class SettingsBootstrapTests(unittest.TestCase):
    def run_bootstrap(self, config, backup):
        env = os.environ.copy()
        env.update({
            "VAMPIRE_SETTINGS_FILE": str(config),
            "VAMPIRE_SETTINGS_DEFAULTS": str(DEFAULTS),
            "VAMPIRE_SETTINGS_VALIDATOR": str(VALIDATOR),
            "VAMPIRE_SETTINGS_BACKUP_DIR": str(backup),
        })
        return subprocess.run(
            ["sh", str(BOOTSTRAP)],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_creates_valid_defaults_when_settings_are_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            config = base / "etc" / "settings.conf"
            result = self.run_bootstrap(config, base / "backup")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("theme=dark", config.read_text())
            self.assertEqual(config.stat().st_mode & 0o777, 0o600)

    def test_preserves_invalid_settings_backup_before_recovery(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            config = base / "settings.conf"
            config.write_text("theme=ultraviolet\n")
            backup = base / "backup"
            result = self.run_bootstrap(config, backup)
            self.assertEqual(result.returncode, 0, result.stderr)
            saved = list(backup.glob("settings.conf.invalid.*"))
            self.assertEqual(len(saved), 1)
            self.assertEqual(saved[0].read_text(), "theme=ultraviolet\n")
            self.assertIn("theme=dark", config.read_text())

    def test_refuses_symlinked_backup_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            config = base / "settings.conf"
            config.write_text("theme=invalid\\n")
            real_backup = base / "real-backup"
            real_backup.mkdir()
            backup_link = base / "backup"
            backup_link.symlink_to(real_backup, target_is_directory=True)
            result = self.run_bootstrap(config, backup_link)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("refusing symlinked settings path", result.stderr)
            self.assertEqual(config.read_text(), "theme=invalid\\n")
            self.assertEqual(list(real_backup.iterdir()), [])

    def test_refuses_symlinked_parent_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            real_dir = base / "real"
            real_dir.mkdir()
            linked_dir = base / "linked"
            linked_dir.symlink_to(real_dir, target_is_directory=True)
            config = linked_dir / "settings.conf"
            result = self.run_bootstrap(config, base / "backup")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("refusing symlinked settings path", result.stderr)
            self.assertFalse((real_dir / "settings.conf").exists())

    def test_refuses_symlinked_settings_without_touching_target(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            target = base / "real-settings.conf"
            target.write_text("theme=dark\n")
            config = base / "settings.conf"
            config.symlink_to(target)
            result = self.run_bootstrap(config, base / "backup")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("refusing symlinked settings path", result.stderr)
            self.assertTrue(config.is_symlink())
            self.assertEqual(target.read_text(), "theme=dark\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
