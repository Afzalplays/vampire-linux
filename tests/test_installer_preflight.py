#!/usr/bin/env python3
"""Read-only installer preflight tests using isolated fake sysfs and device paths."""
import os
import pathlib
import subprocess
import tempfile
import unittest

INSTALLER = pathlib.Path(__file__).resolve().parents[1] / "rootfs-overlay" / "usr" / "bin" / "vinstall"


class InstallerPreflightTests(unittest.TestCase):
    def make_environment(self, base, mountinfo=""):
        base = pathlib.Path(base)
        dev_root = base / "dev"
        sys_block = base / "sys" / "block"
        proc = base / "proc"
        (sys_block / "vda" / "holders").mkdir(parents=True)
        dev_root.mkdir()
        proc.mkdir()
        (dev_root / "vda").write_bytes(b"fake device - must remain unchanged")
        attributes = {
            "size": "16777216\n",
            "ro": "0\n",
            "removable": "0\n",
            "dev": "8:0\n",
        }
        for name, value in attributes.items():
            (sys_block / "vda" / name).write_text(value)
        mounts = proc / "mounts"
        mounts.write_text("")
        mount_table = proc / "mountinfo"
        mount_table.write_text(mountinfo)
        swaps = proc / "swaps"
        swaps.write_text("Filename Type Size Used Priority\n")
        env = os.environ.copy()
        env.update({
            "VAMPIRE_DEV_ROOT": str(dev_root),
            "VAMPIRE_SYS_BLOCK": str(sys_block),
            "VAMPIRE_MOUNTS_FILE": str(mounts),
            "VAMPIRE_MOUNTINFO_FILE": str(mount_table),
            "VAMPIRE_SWAPS_FILE": str(swaps),
        })
        return env, dev_root / "vda"

    def run_installer(self, env, *args):
        return subprocess.run(
            ["sh", str(INSTALLER), *args],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_plan_is_read_only_for_unused_eligible_disk(self):
        with tempfile.TemporaryDirectory() as temp:
            env, device = self.make_environment(temp)
            before = device.read_bytes()
            result = self.run_installer(env, "plan", str(device), "bios")
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            self.assertIn("READ-ONLY PLAN", result.stdout)
            self.assertIn("No partition table was written", result.stdout)
            self.assertEqual(device.read_bytes(), before)

    def test_preflight_refuses_disk_below_minimum_size(self):
        with tempfile.TemporaryDirectory() as temp:
            env, device = self.make_environment(temp)
            (pathlib.Path(env["VAMPIRE_SYS_BLOCK"]) / "vda" / "size").write_text("1000\\n")
            result = self.run_installer(env, "preflight", str(device))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("smaller than the 8 GiB minimum", result.stdout)

    def test_preflight_refuses_read_only_disk(self):
        with tempfile.TemporaryDirectory() as temp:
            env, device = self.make_environment(temp)
            (pathlib.Path(env["VAMPIRE_SYS_BLOCK"]) / "vda" / "ro").write_text("1\\n")
            result = self.run_installer(env, "preflight", str(device))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("kernel reports this device as read-only", result.stdout)

    def test_preflight_refuses_active_swap(self):
        with tempfile.TemporaryDirectory() as temp:
            env, device = self.make_environment(temp)
            pathlib.Path(env["VAMPIRE_SWAPS_FILE"]).write_text(
                f"{device} partition 1024 0 -2\\n"
            )
            result = self.run_installer(env, "preflight", str(device))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("target disk is active swap", result.stdout)

    def test_preflight_refuses_backing_disk_with_active_holder(self):
        with tempfile.TemporaryDirectory() as temp:
            env, device = self.make_environment(temp)
            holder = pathlib.Path(env["VAMPIRE_SYS_BLOCK"]) / "vda" / "holders" / "dm-0"
            holder.mkdir()
            result = self.run_installer(env, "preflight", str(device))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("active stacked block device", result.stdout)

    def test_preflight_refuses_disk_with_mounted_partition_or_device(self):
        with tempfile.TemporaryDirectory() as temp:
            mountinfo = "36 25 8:0 / /mnt/target rw - ext4 /dev/vda rw\n"
            env, device = self.make_environment(temp, mountinfo)
            result = self.run_installer(env, "preflight", str(device))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("mounted at /mnt/target", result.stdout)
            self.assertIn("do not install", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
