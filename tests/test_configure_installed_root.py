#!/usr/bin/env python3
"""Regression tests for the installed-root boot configuration contract."""
import importlib.util
import pathlib
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "scripts" / "configure-installed-root.py"
SPEC = importlib.util.spec_from_file_location("configure_installed_root", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

ROOT_UUID = "12345678-1234-5678-9abc-def012345678"
ROOT_PARTUUID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
ESP_UUID = "ABCD-1234"


class InstalledRootTests(unittest.TestCase):
    def make_root(self, base):
        root = pathlib.Path(base) / "root"
        (root / "boot").mkdir(parents=True)
        (root / "boot" / "vmlinuz").write_bytes(b"kernel")
        return root

    def test_bios_writes_partuuid_kernel_argument_and_no_esp(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            MODULE.configure(root, ROOT_UUID, "bios", root_partuuid=ROOT_PARTUUID)
            grub = (root / "boot/grub/grub.cfg").read_text()
            fstab = (root / "etc/fstab").read_text()
            self.assertIn("root=PARTUUID=" + ROOT_PARTUUID, grub)
            self.assertIn("UUID=" + ROOT_UUID + " / ext4", fstab)
            self.assertNotIn("/boot/efi", fstab)
            self.assertIn("FIRMWARE=bios", (root / "etc/vampire/install.conf").read_text())

    def test_uefi_mounts_esp_and_records_its_uuid(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            MODULE.configure(root, ROOT_UUID, "uefi", ESP_UUID, ROOT_PARTUUID)
            fstab = (root / "etc/fstab").read_text()
            metadata = (root / "etc/vampire/install.conf").read_text()
            self.assertIn("UUID=" + ESP_UUID + " /boot/efi vfat", fstab)
            self.assertIn("ESP_UUID=" + ESP_UUID, metadata)

    def test_rejects_missing_or_malformed_root_partuuid(self):
        for value in (None, "", "not-a-uuid", "12345678-1234-1234-1234-123456789012-extra"):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as temp:
                root = self.make_root(temp)
                with self.assertRaises(ValueError):
                    MODULE.configure(root, ROOT_UUID, "bios", root_partuuid=value)

    def test_rejects_esp_uuid_for_bios(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            with self.assertRaisesRegex(ValueError, "BIOS mode"):
                MODULE.configure(root, ROOT_UUID, "bios", ESP_UUID, ROOT_PARTUUID)

    def test_rejects_invalid_uefi_esp_uuid(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            with self.assertRaisesRegex(ValueError, "ESP FAT UUID"):
                MODULE.configure(root, ROOT_UUID, "uefi", "invalid", ROOT_PARTUUID)

    def test_refuses_symlinked_grub_configuration(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            grub_dir = root / "boot/grub"
            grub_dir.mkdir()
            target = pathlib.Path(temp) / "outside"
            target.write_text("do not overwrite")
            (grub_dir / "grub.cfg").symlink_to(target)
            with self.assertRaisesRegex(ValueError, "symlinked configuration"):
                MODULE.configure(root, ROOT_UUID, "bios", root_partuuid=ROOT_PARTUUID)
            self.assertEqual(target.read_text(), "do not overwrite")

    def test_uefi_esp_handoff_is_real_newline_delimited_grub_config(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            MODULE.configure(root, ROOT_UUID, "uefi", ESP_UUID, ROOT_PARTUUID)
            expected = (
                "insmod part_gpt\n"
                "insmod fat\n"
                "insmod ext2\n"
                f"search --no-floppy --fs-uuid --set=root {ROOT_UUID}\n"
                "set prefix=($root)/boot/grub\n"
                "configfile $prefix/grub.cfg\n"
            ).encode()
            handoffs = (
                root / "boot/efi/boot/grub/grub.cfg",
                root / "boot/efi/EFI/BOOT/grub.cfg",
            )
            for handoff_path in handoffs:
                handoff = handoff_path.read_bytes()
                self.assertEqual(handoff, expected)
                self.assertNotIn(b"\\\n", handoff)
                self.assertTrue(handoff.endswith(b"\n"))


    def test_rejects_symlinked_target_root(self):
        with tempfile.TemporaryDirectory() as temp:
            base = pathlib.Path(temp)
            real = self.make_root(base)
            alias = base / "alias"
            alias.symlink_to(real, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "symlinked target path component"):
                MODULE.configure(alias, ROOT_UUID, "bios", root_partuuid=ROOT_PARTUUID)

    def test_rejects_symlinked_efi_handoff_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = self.make_root(temp)
            outside = pathlib.Path(temp) / "outside"
            outside.mkdir()
            efi_boot = root / "boot/efi/EFI/BOOT"
            efi_boot.parent.mkdir(parents=True)
            efi_boot.symlink_to(outside, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "symlink"):
                MODULE.configure(root, ROOT_UUID, "uefi", ESP_UUID, ROOT_PARTUUID)
            self.assertEqual(list(outside.iterdir()), [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
