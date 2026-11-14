import pathlib
import subprocess
import sys
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("configure-installed-root.py")
ROOT_UUID = "12345678-1234-5678-9abc-123456789abc"
ESP_UUID = "ABCD-1234"


def run(root, mode, *extra):
    return subprocess.run([sys.executable, str(SCRIPT), str(root), ROOT_UUID, mode, *extra],
                          text=True, capture_output=True)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp) / "target"
        (root / "boot").mkdir(parents=True)
        (root / "boot/vmlinuz").write_bytes(b"kernel")
        result = run(root, "uefi", "--esp-uuid", ESP_UUID)
        assert result.returncode == 0, result.stderr
        fstab = (root / "etc/fstab").read_text()
        grub = (root / "boot/grub/grub.cfg").read_text()
        assert f"UUID={ROOT_UUID} / ext4" in fstab
        assert f"UUID={ESP_UUID} /boot/efi vfat" in fstab
        assert f"root=UUID={ROOT_UUID}" in grub
        assert (root / "etc/vampire/install.conf").read_text().find("FIRMWARE=uefi") >= 0

        result = run(root, "bios")
        assert result.returncode == 0, result.stderr
        assert "/boot/efi" not in (root / "etc/fstab").read_text()
        assert "FIRMWARE=bios" in (root / "etc/vampire/install.conf").read_text()

        result = run(root, "uefi")
        assert result.returncode != 0
        result = run(root, "legacy")
        assert result.returncode != 0

        (root / "boot/grub").rmdir()
        (root / "boot/grub").symlink_to(root / "etc")
        result = run(root, "bios")
        assert result.returncode != 0
    print("installed root configuration tests: PASS")


if __name__ == "__main__":
    main()
