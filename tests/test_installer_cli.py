#!/usr/bin/env python3
"""Non-destructive command-line contract tests for the Vampire installer."""
import pathlib
import subprocess
import unittest

INSTALLER = pathlib.Path(__file__).resolve().parents[1] / "rootfs-overlay" / "usr" / "bin" / "vinstall"


class InstallerCliTests(unittest.TestCase):
    def run_installer(self, *args):
        return subprocess.run(
            ["sh", str(INSTALLER), *args],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_help_is_available_without_root_or_disk_access(self):
        result = self.run_installer("help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("install ROOTFS.tar /dev/DEVICE", result.stdout)
        self.assertIn("erases the selected whole disk", result.stdout)

    def test_unknown_command_fails_with_usage(self):
        result = self.run_installer("not-a-command")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_preflight_requires_exactly_one_device_argument(self):
        result = self.run_installer("preflight")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_install_rejects_missing_arguments_before_any_privilege_check(self):
        result = self.run_installer("install", "rootfs.tar")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)
        self.assertNotIn("root privileges", result.stderr)

    def test_plan_rejects_unknown_firmware_before_disk_access(self):
        result = self.run_installer("plan", "/dev/not-a-real-disk", "coreboot")
        self.assertEqual(result.returncode, 2)
        self.assertIn("firmware mode must be uefi or bios", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
