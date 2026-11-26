# Vampire OS installation pipeline

The live image carries a checksummed installer root filesystem at
`/install/rootfs.tar`. The archive includes the installed kernel at
`/boot/vmlinuz`, the rootfs staging validator, and the installed-root
configuration helper. The live kernel is built with the storage and ext4
drivers needed to mount an installed root filesystem directly.

## Build source integrity

Both Desktop and Server ISO builds default to the upstream Buildroot
`2025.02` release tag. Set `BUILDROOT_VERSION` only when deliberately
testing another published Buildroot tag. The builder validates the tag name,
fetches/checks out that exact tag even when a cached checkout already exists,
and verifies that HEAD resolves to the requested tag before configuring either
edition. The CI build-check workflow regression-tests these safeguards.

This pins the Buildroot framework release; it does not yet make every
third-party package archive or the complete toolchain reproducible. Those
remain separate release-engineering tasks.

## Read-only and staging operations

1. `vinstall requirements` checks disk, filesystem, Python, checksum and GRUB utilities.
2. `vinstall validate ROOTFS.tar` verifies the adjacent checksum and safely inspects the archive before disk changes.
3. `vinstall list`, `preflight` and `plan` inspect disks and show the proposed UEFI or BIOS partition layout without writing to storage.
4. `vinstall stage ROOTFS.tar EMPTY_MOUNTPOINT` extracts only into an existing empty directory.

## Guided disk installation

The live installer supports a destructive, explicit-confirmation workflow:

- UEFI: GPT, 512 MiB FAT32 EFI System Partition, ext4 root.
- BIOS: GPT, 2 MiB BIOS boot partition, ext4 root.
- It validates the archive and target disk before changes, requires the exact
  typed confirmation `ERASE /dev/DEVICE`, formats the selected disk, stages
  the root filesystem, copies the kernel, configures fstab and GRUB, installs
  GRUB for the selected firmware, and checks the expected boot files exist.
- The installed GRUB entry uses `root=PARTUUID=<GPT partition GUID>`, which
  the Linux kernel can resolve without an initramfs. The filesystem UUID is
  retained in fstab. Storage and ext4 drivers are built into the kernel.

The lower-level configuration command accepts a filesystem UUID and obtains
the kernel root PARTUUID from `VAMPIRE_ROOT_PARTUUID`:

- BIOS: `VAMPIRE_ROOT_PARTUUID=<guid> vinstall configure ROOTDIR ROOT_UUID bios`
- UEFI: `VAMPIRE_ROOT_PARTUUID=<guid> vinstall configure ROOTDIR ROOT_UUID uefi ESP_UUID`

The configurator validates UUID formats, writes fstab and grub.cfg atomically,
and refuses symlinked target configuration paths.

## Validation status

Automated tests cover archive safety, destructive confirmation, installed
root configuration, bootloader output checks, and QEMU BIOS/UEFI boot attempts
from disposable disks. A successful package/build check alone does not prove
that an ISO or installed system boots. Treat the installer as developer-stage
until the latest Desktop and Server ISO workflows both complete their rootfs,
installed-disk BIOS/UEFI, live-ISO BIOS/UEFI and checksum gates.
