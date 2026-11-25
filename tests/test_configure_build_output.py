#!/usr/bin/env python3
"""Regression tests for Buildroot rootfs post-build/fakeroot hooks."""
import importlib.util
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "configure_build_output", ROOT / "scripts/configure-build-output.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ConfigureBuildOutputTests(unittest.TestCase):
    def test_registers_post_build_and_fakeroot_hooks_for_desktop(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            overlay = root / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc").mkdir(exist_ok=True)
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n')
            (overlay / "etc/vampire/os.conf").write_text('EDITION="unknown"\n')
            (root / "scripts").mkdir()
            (root / "scripts/post-build-vampire.py").write_text("# post-build\n")
            (root / "scripts/post-fakeroot-vampire.sh").write_text("# post-fakeroot\n")
            (root / "build").mkdir()
            (root / "build/vampire-installer-kernel.fragment").write_text("# installer\n")
            (root / "build/vampire-desktop-kernel.fragment").write_text("# desktop\n")
            config = root / "defconfig"
            config.write_text("BR2_x86_64=y\n")
            MODULE.configure(config, overlay, "desktop")
            rendered = config.read_text()
            self.assertIn("BR2_ROOTFS_POST_BUILD_SCRIPT=", rendered)
            self.assertIn("BR2_ROOTFS_POST_FAKEROOT_SCRIPT=", rendered)
            self.assertIn(str((root / "scripts/post-fakeroot-vampire.sh").resolve()), rendered)
            self.assertIn("BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=", rendered)
            self.assertIn('EDITION="desktop"', (overlay / "etc/vampire/os.conf").read_text())
            self.assertIn('PRETTY_NAME="Vampire OS 0.1.0-dev (desktop)"', (overlay / "etc/os-release").read_text())

    def test_rejects_missing_fakeroot_hook(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            overlay = root / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n')
            (overlay / "etc/vampire/os.conf").write_text('EDITION="unknown"\n')
            (root / "scripts").mkdir()
            (root / "scripts/post-build-vampire.py").write_text("# post-build\n")
            (root / "build").mkdir()
            (root / "build/vampire-installer-kernel.fragment").write_text("# installer\n")
            config = root / "defconfig"
            config.write_text("BR2_x86_64=y\n")
            with self.assertRaises(ValueError):
                MODULE.configure(config, overlay, "server")


if __name__ == "__main__":
    unittest.main()
