#!/usr/bin/env python3
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest

DOCTOR = pathlib.Path(__file__).with_name("doctor.py")


class DoctorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp.name)
        self.config = self.root / "vpm.json"
        self.cache = self.root / "cache"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        minisign = self.bin / "minisign"
        minisign.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        minisign.chmod(0o755)

    def tearDown(self):
        self.temp.cleanup()

    def run_doctor(self, repositories):
        self.config.write_text(json.dumps({"repositories": repositories}), encoding="utf-8")
        env = os.environ.copy()
        env.update({
            "VPM_CONFIG": str(self.config),
            "VPM_CACHE": str(self.cache),
            "VPM_ROOT": str(self.root),
            "PATH": str(self.bin) + os.pathsep + env.get("PATH", ""),
        })
        return subprocess.run(
            [sys.executable, str(DOCTOR)],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_empty_repository_list_is_reported(self):
        result = self.run_doctor([])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no signed package repositories configured", result.stdout)

    def test_placeholder_public_key_is_rejected(self):
        result = self.run_doctor([{
            "name": "stable",
            "url": "https://packages.example.invalid/vampire/x86_64",
            "minisign_public_key": "REPLACE_WITH_REAL_MINISIGN_PUBLIC_KEY",
        }])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no real minisign public key", result.stdout)

    def test_valid_repository_configuration_passes(self):
        result = self.run_doctor([{
            "name": "stable",
            "url": "https://packages.example.test/vampire/x86_64",
            "minisign_public_key": "RWQ-real-test-key",
        }])
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("[OK] Signed repository", result.stdout)


if __name__ == "__main__":
    unittest.main()
