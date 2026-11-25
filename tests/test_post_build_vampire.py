#!/usr/bin/env python3
"""Regression tests for Vampire OS post-build account and kernel provisioning."""
import importlib.util
import os
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("post_build_vampire", ROOT / "scripts/post-build-vampire.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PostBuildVampireTests(unittest.TestCase):
    def test_provisions_locked_unprivileged_account_and_device_groups(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary)
            (target / "etc").mkdir()
            (target / "etc/passwd").write_text("root:x:0:0:root:/root:/bin/sh\n")
            (target / "etc/group").write_text("root:x:0:\n")
            (target / "etc/shadow").write_text("root:*:19000:0:99999:7:::\n")
            MODULE.configure_local_user(target)
            passwd = (target / "etc/passwd").read_text()
            shadow = (target / "etc/shadow").read_text()
            groups = (target / "etc/group").read_text().splitlines()
            self.assertIn("vampire:x:1000:1000:Vampire OS User:/home/vampire:/bin/sh", passwd)
            self.assertIn("vampire:!:19000:0:99999:7:::", shadow)
            self.assertTrue(any(line.startswith("video:") and "vampire" in line.split(":")[3].split(",") for line in groups))
            self.assertTrue(any(line.startswith("input:") and "vampire" in line.split(":")[3].split(",") for line in groups))
            self.assertEqual((target / "home/vampire").stat().st_mode & 0o777, 0o755)
            self.assertEqual((target / "etc/shadow").stat().st_mode & 0o777, 0o640)

    def test_account_provisioning_is_idempotent(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary)
            (target / "etc").mkdir()
            MODULE.configure_local_user(target)
            before = {name: (target / "etc" / name).read_text() for name in ("passwd", "group", "shadow")}
            MODULE.configure_local_user(target)
            after = {name: (target / "etc" / name).read_text() for name in ("passwd", "group", "shadow")}
            self.assertEqual(before, after)

    def test_uid_collision_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = pathlib.Path(temporary)
            (target / "etc").mkdir()
            (target / "etc/passwd").write_text("other:x:1000:1000:Other:/home/other:/bin/sh\n")
            with self.assertRaises(SystemExit):
                MODULE.configure_local_user(target)


if __name__ == "__main__":
    unittest.main()
