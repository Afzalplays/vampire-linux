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
        (build / "vampire-desktop-kernel.fragment").write_text("CONFIG_IWLWIFI=m\\n")
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
            self.assertIn('EDITION="desktop"',
                          (overlay / "etc/vampire/os.conf").read_text())

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
