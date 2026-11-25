import importlib.util
import json
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).with_name("configure-build-output.py")
SPEC = importlib.util.spec_from_file_location("configure_build_output", SCRIPT)
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class BuildOutputConfigurationTests(unittest.TestCase):
    def make_fixture(self, root):
        build = root / "build"
        build.mkdir()
        scripts = root / "scripts"
        scripts.mkdir()
        (scripts / "post-build-vampire.py").write_text("# test hook\\n")
        (scripts / "post-fakeroot-vampire.sh").write_text("# test hook\\n")
        (build / "vampire-desktop-kernel.fragment").write_text("CONFIG_IWLWIFI=m\\n")
        (build / "vampire-installer-kernel.fragment").write_text("CONFIG_EXT4_FS=y\\n")
        overlay = root / 'rootfs & overlay | "special"'
        (overlay / "etc/vampire").mkdir(parents=True)
        (overlay / "etc/vampire/os.conf").write_text(
            'NAME="Vampire OS"\nEDITION="live"\n')
        (overlay / "etc/os-release").write_text(
            'NAME="Vampire OS"\nPRETTY_NAME="Vampire OS 0.1.0-dev"\n')
        config = root / ".config"
        config.write_text('BR2_X86_64=y\nBR2_ROOTFS_OVERLAY=""\n')
        return config, overlay

    def test_overlay_path_and_edition_are_configured_before_rootfs_build(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            config, overlay = self.make_fixture(root)
            module.configure(config, overlay, "server")
            self.assertIn(
                "BR2_ROOTFS_OVERLAY=" + json.dumps(str(overlay.resolve())),
                config.read_text())
            self.assertIn("BR2_ROOTFS_POST_BUILD_SCRIPT=", config.read_text())
            self.assertIn("BR2_ROOTFS_POST_FAKEROOT_SCRIPT=", config.read_text())
            self.assertIn("BR2_ROOTFS_POST_FAKEROOT_SCRIPT=", config.read_text())
            fragments = next(line for line in config.read_text().splitlines()
                             if line.startswith("BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="))
            self.assertIn("vampire-installer-kernel.fragment", fragments)
            self.assertNotIn("vampire-desktop-kernel.fragment", fragments)
            self.assertIn('EDITION="server"',
                          (overlay / "etc/vampire/os.conf").read_text())
            self.assertIn(
                'PRETTY_NAME="Vampire OS 0.1.0-dev (server)"',
                (overlay / "etc/os-release").read_text())

    def test_desktop_edition_is_written_to_overlay(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            config, overlay = self.make_fixture(root)
            module.configure(config, overlay, "desktop")
            self.assertIn("BR2_ROOTFS_POST_BUILD_SCRIPT=", config.read_text())
            fragments = next(line for line in config.read_text().splitlines()
                             if line.startswith("BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES="))
            self.assertIn("vampire-installer-kernel.fragment", fragments)
            self.assertIn("vampire-desktop-kernel.fragment", fragments)
            self.assertIn('EDITION="desktop"',
                          (overlay / "etc/vampire/os.conf").read_text())

    def test_installer_kernel_fragment_keeps_boot_storage_drivers_builtin(self):
        fragment = (SCRIPT.parent.parent / "build/vampire-installer-kernel.fragment").read_text()
        for option in ("CONFIG_DEVTMPFS=y", "CONFIG_EXT4_FS=y", "CONFIG_VFAT_FS=y",
                       "CONFIG_EFI_PARTITION=y", "CONFIG_MSDOS_PARTITION=y",
                       "CONFIG_BLK_DEV_NVME=y", "CONFIG_ATA=y", "CONFIG_VIRTIO_BLK=y"):
            with self.subTest(option=option):
                self.assertIn(option, fragment)

    def test_duplicate_assignment_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / ".config"
            config.write_text('KEY=""\nKEY=""\n')
            with self.assertRaises(ValueError):
                module.replace_assignment(config, "KEY", "value")

    def test_unknown_edition_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            config, overlay = self.make_fixture(root)
            with self.assertRaises(ValueError):
                module.configure(config, overlay, "preview")


if __name__ == "__main__":
    unittest.main()
