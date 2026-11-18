#!/usr/bin/env python3
"""Write deterministic fstab and GRUB configuration into a staged target root."""
import argparse
import os
import pathlib
import re
import tempfile

UUID = re.compile(r"^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$")
FAT_UUID = re.compile(r"^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$")


def reject_symlink_components(path):
    """Reject symlinks in every existing component without resolving through them."""
    absolute = pathlib.Path(os.path.abspath(os.fspath(path)))
    for component in reversed((absolute, *absolute.parents)):
        if component.is_symlink():
            raise ValueError(f"refusing symlinked target path component: {component}")


def atomic_write(path, content):
    reject_symlink_components(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    reject_symlink_components(path)
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


def configure(root, root_uuid, mode, esp_uuid=None, root_partuuid=None):
    root = pathlib.Path(os.path.abspath(os.fspath(root)))
    reject_symlink_components(root)
    if not root.is_dir():
        raise ValueError("target root must be an existing directory")
    if not UUID.fullmatch(root_uuid):
        raise ValueError("root filesystem UUID must be a canonical UUID")
    if not root_partuuid or not UUID.fullmatch(root_partuuid):
        raise ValueError("root partition PARTUUID must be a canonical GPT UUID")
    if mode not in ("uefi", "bios"):
        raise ValueError("firmware mode must be uefi or bios")
    if mode == "uefi":
        if not esp_uuid or not FAT_UUID.fullmatch(esp_uuid):
            raise ValueError("UEFI mode requires an ESP FAT UUID in XXXX-XXXX form")
    elif esp_uuid:
        raise ValueError("BIOS mode must not receive an EFI System Partition UUID")

    etc = root / "etc"
    boot_grub = root / "boot" / "grub"
    vampire_etc = etc / "vampire"
    for directory in (etc, root / "boot", boot_grub, vampire_etc):
        if directory.is_symlink():
            raise ValueError(f"refusing symlinked target directory: {directory}")
        if directory.exists() and not directory.is_dir():
            raise ValueError(f"target configuration path is not a directory: {directory}")
    for config_file in (etc / "fstab", boot_grub / "grub.cfg", vampire_etc / "install.conf"):
        if config_file.is_symlink():
            raise ValueError(f"refusing symlinked configuration file: {config_file}")
    kernel = root / "boot" / "vmlinuz"
    if kernel.is_symlink():
        raise ValueError("refusing symlinked target kernel: /boot/vmlinuz")
    if not kernel.is_file():
        raise ValueError("target root is missing a regular /boot/vmlinuz file")

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
        "    linux /boot/vmlinuz root=PARTUUID=" + root_partuuid + " rootwait rw console=tty0 console=ttyS0,115200n8 loglevel=4",
        "}",
        "",
    ]
    atomic_write(etc / "fstab", "\n".join(fstab) + "\n")
    atomic_write(boot_grub / "grub.cfg", "\n".join(grub))
    if mode == "uefi":
        # The removable-media GRUB executable starts from the ESP. Give it a
        # small hand-off config there so it can locate the real menu on the
        # ext4 root filesystem instead of looking for /boot on the FAT ESP.
        esp_grub = root / "boot" / "efi" / "EFI" / "BOOT" / "grub.cfg"
        esp_handoff = [
            "search --no-floppy --fs-uuid --set=root " + root_uuid,
            "set prefix=($root)/boot/grub",
            "configfile $prefix/grub.cfg",
            "",
        ]
        atomic_write(esp_grub, "\\n".join(esp_handoff))
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
    parser.add_argument("--root-partuuid", required=True)
    args = parser.parse_args()
    try:
        configure(args.target_root, args.root_uuid, args.firmware, args.esp_uuid, args.root_partuuid)
    except (OSError, ValueError) as exc:
        parser.exit(1, f"vinstall-configure: error: {exc}\n")
    print(f"Configured staged Vampire OS root for {args.firmware.upper()} boot.")
    print("No partitions, filesystems, or bootloader were modified.")


if __name__ == "__main__":
    main()
