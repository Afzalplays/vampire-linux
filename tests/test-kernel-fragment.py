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
    def test_installer_fragment_has_builtin_boot_storage(self):
        fragment = (ROOT / "build/vampire-installer-kernel.fragment").read_text()
        for symbol in (
            "CONFIG_EXT4_FS=y",
            "CONFIG_ISO9660_FS=y",
            "CONFIG_VFAT_FS=y",
            "CONFIG_BLK_DEV_NVME=y",
            "CONFIG_VIRTIO_BLK=y",
            "CONFIG_SATA_AHCI=y",
            "CONFIG_USB_STORAGE=y",
            "CONFIG_USB_XHCI_PCI=y",
        ):
            self.assertIn(symbol, fragment)

    def test_desktop_configures_kernel_fragment_and_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = pathlib.Path(tmp)
            overlay = repo / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc").mkdir(exist_ok=True)
            (repo / "build").mkdir()
            (repo / "scripts").mkdir()
            (repo / "scripts/post-build-vampire.py").write_text("# fixture\\n", encoding="utf-8")
            installer_fragment = repo / "build/vampire-installer-kernel.fragment"
            installer_fragment.write_text("CONFIG_EXT4_FS=y\n", encoding="utf-8")
            fragment = repo / "build/vampire-desktop-kernel.fragment"
            fragment.write_text("CONFIG_IWLWIFI=m\n", encoding="utf-8")
            (overlay / "etc/vampire/os.conf").write_text("EDITION=desktop\n", encoding="utf-8")
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n', encoding="utf-8")
            config = repo / ".config"
            config.write_text('BR2_ROOTFS_OVERLAY=""\n', encoding="utf-8")
            configure(config, overlay, "desktop")
            output = config.read_text(encoding="utf-8")
            self.assertIn(str(installer_fragment.resolve()), output)
            self.assertIn(str(fragment.resolve()), output)
            self.assertIn(str((repo / "scripts/post-build-vampire.py").resolve()), output)
            self.assertIn('EDITION="desktop"', (overlay / "etc/vampire/os.conf").read_text())
            self.assertIn("Vampire OS 0.1.0-dev (desktop)", (overlay / "etc/os-release").read_text())

    def test_server_does_not_receive_desktop_kernel_fragment(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = pathlib.Path(tmp)
            overlay = repo / "rootfs-overlay"
            (overlay / "etc/vampire").mkdir(parents=True)
            (overlay / "etc").mkdir(exist_ok=True)
            (repo / "build").mkdir()
            (repo / "scripts").mkdir()
            (repo / "scripts/post-build-vampire.py").write_text("# fixture\\n", encoding="utf-8")
            (overlay / "etc/vampire/os.conf").write_text("EDITION=desktop\n", encoding="utf-8")
            (overlay / "etc/os-release").write_text('PRETTY_NAME="Vampire OS"\n', encoding="utf-8")
            config = repo / ".config"
            config.write_text('BR2_ROOTFS_OVERLAY=""\n', encoding="utf-8")
            installer_fragment = repo / "build/vampire-installer-kernel.fragment"
            installer_fragment.write_text("CONFIG_EXT4_FS=y\n", encoding="utf-8")
            configure(config, overlay, "server")
            output = config.read_text()
            self.assertIn(str(installer_fragment.resolve()), output)
            self.assertNotIn("vampire-desktop-kernel.fragment", output)

if __name__ == "__main__":
    unittest.main()
