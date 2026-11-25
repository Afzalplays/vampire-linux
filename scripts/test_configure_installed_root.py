import pathlib
import subprocess
import shutil
import sys
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("configure-installed-root.py")
ROOT_UUID = "12345678-1234-5678-9abc-123456789abc"
ESP_UUID = "ABCD-1234"
ROOT_PARTUUID = "87654321-4321-8765-cba9-9876543210ab"


def run(root, mode, *extra):
    return subprocess.run([sys.executable, str(SCRIPT), str(root), ROOT_UUID, mode, "--root-partuuid", ROOT_PARTUUID, *extra],
                          text=True, capture_output=True)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp) / "target"
        (root / "boot").mkdir(parents=True)
        (root / "boot/vmlinuz").write_bytes(b"kernel")
        (root / "boot/efi").mkdir()
        result = run(root, "uefi", "--esp-uuid", ESP_UUID)
        assert result.returncode == 0, result.stderr

        # The installed kernel must be a regular file, not a symlink that
        # could resolve outside the target root during boot configuration.
        kernel = root / "boot/vmlinuz"
        kernel.unlink()
        outside_kernel = pathlib.Path(tmp) / "outside-kernel"
        outside_kernel.write_bytes(b"external kernel")
        kernel.symlink_to(outside_kernel)
        result = run(root, "bios")
        assert result.returncode != 0
        assert "symlinked target kernel" in result.stderr
        kernel.unlink()
        kernel.write_bytes(b"kernel")
        fstab = (root / "etc/fstab").read_text()
        grub = (root / "boot/grub/grub.cfg").read_text()
        assert f"UUID={ROOT_UUID} / ext4" in fstab
        assert f"UUID={ESP_UUID} /boot/efi vfat" in fstab
        assert f"root=PARTUUID={ROOT_PARTUUID}" in grub
        assert "rootwait rw" in grub
        assert "initrd " not in grub
        # GRUB can initially resolve its embedded prefix on the ESP, so
        # provide the hand-off there as well as in the removable-media path.
        esp_grub = (root / "boot/efi/boot/grub/grub.cfg").read_text()
        fallback_grub = (root / "boot/efi/EFI/BOOT/grub.cfg").read_text()
        for handoff in (esp_grub, fallback_grub):
            assert f"--set=root {ROOT_UUID}" in handoff
            assert "insmod fat" in handoff
            assert "set prefix=($root)/boot/grub" in handoff
            assert "configfile $prefix/grub.cfg" in handoff
        assert (root / "etc/vampire/install.conf").read_text().find("FIRMWARE=uefi") >= 0

        result = run(root, "bios")
        assert result.returncode == 0, result.stderr
        assert "/boot/efi" not in (root / "etc/fstab").read_text()
        assert "FIRMWARE=bios" in (root / "etc/vampire/install.conf").read_text()

        result = run(root, "uefi")
        assert result.returncode != 0
        result = run(root, "legacy")
        assert result.returncode != 0
        invalid_partuuid = subprocess.run([sys.executable, str(SCRIPT), str(root), ROOT_UUID, "bios", "--root-partuuid", "not-a-guid"], text=True, capture_output=True)
        assert invalid_partuuid.returncode != 0
        assert "PARTUUID" in invalid_partuuid.stderr

        shutil.rmtree(root / "boot/grub")
        (root / "boot/grub").symlink_to(root / "etc")
        result = run(root, "bios")
        assert result.returncode != 0

        # Never follow a pre-existing symlink while writing install metadata.
        (root / "boot/grub").unlink()
        (root / "boot/grub").mkdir()
        (root / "etc/vampire/install.conf").unlink()
        (root / "etc/vampire").rmdir()
        outside = pathlib.Path(tmp) / "outside"
        outside.mkdir()
        (root / "etc/vampire").symlink_to(outside, target_is_directory=True)
        result = run(root, "bios")
        assert result.returncode != 0
        assert not (outside / "install.conf").exists()
        (root / "etc/vampire").unlink()
        (root / "etc/vampire").mkdir()
        (root / "etc/fstab").unlink()
        (root / "etc/fstab").symlink_to(outside / "fstab")
        result = run(root, "bios")
        assert result.returncode != 0
        assert not (outside / "fstab").exists()

        # Reject a symlink anywhere in the target-root ancestry, not just
        # symlinks at the final configuration directory.
        real_parent = pathlib.Path(tmp) / "real-parent"
        real_parent.mkdir()
        linked_parent = pathlib.Path(tmp) / "linked-parent"
        linked_parent.symlink_to(real_parent, target_is_directory=True)
        linked_root = linked_parent / "target"
        linked_root.mkdir()
        (linked_root / "boot").mkdir()
        (linked_root / "boot/vmlinuz").write_bytes(b"kernel")
        result = run(linked_root, "bios")
        assert result.returncode != 0
        assert not (real_parent / "target/etc/fstab").exists()
    print("installed root configuration tests: PASS")


if __name__ == "__main__":
    main()
