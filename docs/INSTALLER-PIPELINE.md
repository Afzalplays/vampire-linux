# Vampire OS staged installation pipeline

The live image now carries a separate Buildroot root filesystem archive at
`/install/rootfs.tar`. It is checksummed independently from the ISO. The
archive includes the installed kernel at `/boot/vmlinuz`, the Vampire rootfs
staging validator, and the installed-root configuration helper.

## Current supported operations

1. `vinstall requirements` checks the disk, filesystem and GRUB utilities.
2. `vinstall list`, `preflight` and `plan` inspect disks and show the proposed
   UEFI or BIOS partition layout without writing to storage.
3. `vinstall stage ROOTFS.tar EMPTY_MOUNTPOINT` validates the archive and
   verifies the adjacent `.sha256` sidecar, then extracts it only into an existing empty directory. The destination should
   be the root of a filesystem that an administrator has already mounted.
4. `vinstall configure ROOTDIR ROOT_UUID bios` writes the root fstab and GRUB
   configuration for a staged BIOS installation.
5. For UEFI, pass the EFI System Partition FAT UUID:
   `vinstall configure ROOTDIR ROOT_UUID uefi ESP_UUID`.

The configuration helper requires a canonical root UUID, an EFI FAT UUID for
UEFI, and an existing `/boot/vmlinuz`. It atomically writes fstab, grub.cfg and
`/etc/vampire/install.conf`, and refuses symlinked target configuration paths.

## Not yet a complete disk installer

These commands do not partition a disk, format filesystems, mount partitions,
or run `grub-install`. There is no destructive install transaction or automatic
live-media protection yet. Do not treat this pipeline as an unattended or
one-command disk installer. Those steps require separate device-safety gates,
explicit destructive confirmation, cleanup/recovery handling, and successful
BIOS and UEFI boot tests from an installed disk.
