import importlib.util
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).with_name("configure-build-output.py")
SPEC = importlib.util.spec_from_file_location("configure_build_output", SCRIPT)
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


class BuildOutputConfigurationTests(unittest.TestCase):
    def test_overlay_path_with_sed_metacharacters_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            config = root / ".config"
            overlay = root / 'rootfs & overlay | "special"'
            overlay.mkdir()
            config.write_text("BR2_X86_64=y\nBR2_ROOTFS_OVERLAY=\"\"\n")
            module.replace_assignment(
                config, "BR2_ROOTFS_OVERLAY", str(overlay.resolve()))
            self.assertIn(
                "BR2_ROOTFS_OVERLAY=" + __import__("json").dumps(str(overlay.resolve())),
                config.read_text())

    def test_duplicate_assignment_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / ".config"
            config.write_text("KEY=\"\"\nKEY=\"\"\n")
            with self.assertRaises(ValueError):
                module.replace_assignment(config, "KEY", "value")

    def test_metadata_is_written_without_shell_or_sed_interpolation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = pathlib.Path(tmp)
            os_conf = root / "os.conf"
            os_release = root / "os-release"
            os_conf.write_text('NAME="Vampire OS"\nEDITION="desktop"\n')
            os_release.write_text('NAME="Vampire OS"\nPRETTY_NAME="old"\n')
            module.replace_assignment(os_conf, "EDITION", "server")
            module.replace_assignment(
                os_release, "PRETTY_NAME", "Vampire OS 0.1.0-dev (server)")
            self.assertIn('EDITION="server"', os_conf.read_text())
            self.assertIn(
                'PRETTY_NAME="Vampire OS 0.1.0-dev (server)"',
                os_release.read_text())


if __name__ == "__main__":
    unittest.main()
