#!/usr/bin/env python3
"""Write deterministic fstab and GRUB configuration into a staged target root."""
import argparse
import os
import pathlib
import re
import tempfile

UUID = re.compile(r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$")
FAT_UUID = re.compile(r"^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$")


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink() or path.parent.is_symlink():
        raise ValueError(f"refusing symlinked configuration path: {path}")
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp_name, 0o644)
        os.replace(temp_name, path)
    finally:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass


def configure(root, root_uuid, mode, esp_uuid=None):
    root = pathlib.Path(root).resolve()
    if not root.is_dir():
        raise ValueError("target root must be an existing directory")
    if not UUID.fullmatch(root_uuid):
        raise ValueError("root filesystem UUID must be a canonical UUID")
    if mode not in ("uefi", "bios"):
        raise ValueError("firmware mode must be uefi or bios")
    if mode == "uefi":
        if not esp_uuid or not FAT_UUID.fullmatch(esp_uuid):
            raise ValueError("UEFI mode requires an ESP FAT UUID in XXXX-XXXX form")
    elif esp_uuid:
        raise ValueError("BIOS mode must not receive an EFI System Partition UUID")

    etc = root / "etc"
    boot_grub = root / "boot" / "grub"
    for directory in (etc, root / "boot", boot_grub):
        if directory.exists() and directory.is_symlink():
            raise ValueError(f"refusing symlinked target directory: {directory}")
    if not (root / "boot" / "vmlinuz").is_file():
        raise ValueError("target root is missing /boot/vmlinuz")

    fstab = [
        f"UUID={root_uuid} / ext4 defaults,noatime 0 1",
    ]
    if mode == "uefi":
        fstab.append(f"UUID={esp_uuid} /boot/efi vfat umask=0077 0 2")
    fstab += [
        "proc /proc proc nosuid,nodev,noexec 0 0",
        "sysfs /sys sysfs nosuid,nodev,noexec 0 0",
        "devpts /dev/pts devpts gid=5,mode=620 0 0",
        "tmpfs /run tmpfs mode=0755,nosuid,nodev 0 0",
        "tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0",
    ]
    grub = [
        "set default=0",
        "set timeout=5",
        "insmod part_gpt",
        "insmod ext2",
        "search --no-floppy --fs-uuid --set=root " + root_uuid,
        "menuentry 'Vampire OS' {",
        "    linux /boot/vmlinuz root=UUID=" + root_uuid + " rootwait ro",
        "}",
        "",
    ]
    atomic_write(etc / "fstab", "\n".join(fstab) + "\n")
    atomic_write(boot_grub / "grub.cfg", "\n".join(grub))
    metadata = f"FIRMWARE={mode}\nROOT_UUID={root_uuid}\n"
    if esp_uuid:
        metadata += f"ESP_UUID={esp_uuid}\n"
    atomic_write(etc / "vampire" / "install.conf", metadata)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_root")
    parser.add_argument("root_uuid")
    parser.add_argument("firmware", choices=("uefi", "bios"))
    parser.add_argument("--esp-uuid")
    args = parser.parse_args()
    try:
        configure(args.target_root, args.root_uuid, args.firmware, args.esp_uuid)
    except (OSError, ValueError) as exc:
        parser.exit(1, f"vinstall-configure: error: {exc}\n")
    print(f"Configured staged Vampire OS root for {args.firmware.upper()} boot.")
    print("No partitions, filesystems, or bootloader were modified.")


if __name__ == "__main__":
    main()
