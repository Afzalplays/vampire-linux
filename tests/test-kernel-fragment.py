#!/usr/bin/env python3
import pathlib
import tempfile
import unittest
import importlib.util

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("configure_build_output", ROOT / "scripts/configure-build-output.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
configure = module.configure


class KernelFragmentTests(unittest.TestCase):
    def test_desktop_configures_kernel_fragment_and_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = pathlib.Path(tmp)
            overlay = repo / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc").mkdir(exist_ok=True)
            (repo / "build").mkdir()
            fragment = repo / "build/vampire-desktop-kernel.fragment"
            fragment.write_text("CONFIG_IWLWIFI=m\n", encoding="utf-8")
            (overlay / "etc/vampire/os.conf").write_text("EDITION=desktop\n", encoding="utf-8")
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n', encoding="utf-8")
            config = repo / ".config"
            config.write_text('BR2_ROOTFS_OVERLAY=""\n', encoding="utf-8")
            configure(config, overlay, "desktop")
            output = config.read_text(encoding="utf-8")
            self.assertIn(str(fragment.resolve()), output)
            self.assertIn('EDITION="desktop"', (overlay / "etc/vampire/os.conf").read_text())
            self.assertIn("Vampire OS 0.1.0-dev (desktop)", (overlay / "etc/os-release").read_text())

    def test_server_does_not_receive_desktop_kernel_fragment(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = pathlib.Path(tmp)
            overlay = repo / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc").mkdir(exist_ok=True)
            (repo / "build").mkdir()
            (overlay / "etc/vampire/os.conf").write_text("EDITION=desktop\n", encoding="utf-8")
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n', encoding="utf-8")
            config = repo / ".config"
            config.write_text('BR2_ROOTFS_OVERLAY=""\n', encoding="utf-8")
            configure(config, overlay, "server")
            self.assertNotIn("BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES", config.read_text())

if __name__ == "__main__":
    unittest.main()
