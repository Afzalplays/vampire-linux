import os
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
MONITOR = ROOT / "rootfs-overlay/usr/bin/vmonitor"


class VampireMonitorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = pathlib.Path(self.tmp.name)
        self.proc = self.base / "proc"
        self.sys = self.base / "sys"
        self.proc.mkdir()
        (self.sys / "class/thermal/thermal_zone0").mkdir(parents=True)
        (self.proc / "uptime").write_text("93784.50 1234.00\n")
        (self.proc / "loadavg").write_text("0.25 0.50 0.75 1/100 123\n")
        (self.proc / "meminfo").write_text(
            "MemTotal:       8192000 kB\n"
            "MemAvailable:   2048000 kB\n"
            "MemFree:        1024000 kB\n"
        )
        (self.sys / "class/thermal/thermal_zone0/temp").write_text("42500\n")

    def run_monitor(self, *args):
        env = os.environ.copy()
        env.update({
            "VAMPIRE_PROC_ROOT": str(self.proc),
            "VAMPIRE_SYS_ROOT": str(self.sys),
            "VAMPIRE_ROOT_MOUNT": str(self.base),
        })
        return subprocess.run(
            ["/bin/sh", str(MONITOR), *args], text=True, capture_output=True, env=env, check=False
        )

    def test_once_reports_uptime_load_memory_and_temperature(self):
        result = self.run_monitor("--once")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1d 02h 03m", result.stdout)
        self.assertIn("Load:   0.25 0.50 0.75", result.stdout)
        self.assertIn("Memory: 6000 MiB used / 8000 MiB total (75%)", result.stdout)
        self.assertIn("Temperature (thermal_zone0): 42.5 C", result.stdout)

    def test_missing_telemetry_is_reported_without_crashing(self):
        for name in ("uptime", "loadavg", "meminfo"):
            (self.proc / name).unlink()
        result = self.run_monitor("--once")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Uptime: unavailable", result.stdout)
        self.assertIn("Load:   unavailable", result.stdout)
        self.assertIn("Memory: unavailable", result.stdout)

    def test_memavailable_fallback_uses_free_buffers_and_cache(self):
        (self.proc / "meminfo").write_text(
            "MemTotal: 4096000 kB\nMemFree: 1024000 kB\n"
            "Buffers: 512000 kB\nCached: 512000 kB\n"
        )
        result = self.run_monitor("--once")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Memory: 2000 MiB used / 4000 MiB total (50%)", result.stdout)

    def test_watch_interval_must_be_between_one_and_sixty(self):
        for interval in ("0", "61", "abc"):
            with self.subTest(interval=interval):
                result = self.run_monitor("--watch", interval)
                self.assertEqual(result.returncode, 2)

    def test_watch_interval_one_starts_refresh_loop(self):
        env = os.environ.copy()
        env.update({
            "VAMPIRE_PROC_ROOT": str(self.proc),
            "VAMPIRE_SYS_ROOT": str(self.sys),
            "VAMPIRE_ROOT_MOUNT": str(self.base),
        })
        result = subprocess.run(
            ["timeout", "1", "/bin/sh", str(MONITOR), "--watch", "1"],
            text=True, capture_output=True, env=env, check=False,
        )
        self.assertEqual(result.returncode, 124, result.stderr)
        self.assertIn("VAMPIRE MONITOR", result.stdout)

    def test_help_exits_successfully(self):
        result = self.run_monitor("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Usage: vmonitor", result.stdout)

    def test_unknown_option_is_rejected(self):
        result = self.run_monitor("--unknown")
        self.assertEqual(result.returncode, 2)


if __name__ == "__main__":
    unittest.main()
