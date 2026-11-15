# Vampire OS Boot, Installer and Recovery Design

**Target:** x86_64 / AMD64. Vampire OS currently has Desktop and Server developer live ISOs with virtual BIOS/UEFI smoke-test coverage. This document defines the remaining boot, installation and recovery requirements. A text-mode, confirmation-gated erase-and-install path is implemented; virtual-disk installation and installed-disk reboot validation remain release blockers.

## Firmware and boot modes
- UEFI boot is the primary target, with Secure Boot support designed around signed boot components and documented key enrollment.
- Legacy BIOS boot is a compatibility target where the bootloader supports it.
- Bootable USB and virtual-machine ISO media are required.
- Test UEFI with OVMF and legacy BIOS with SeaBIOS in CI/QEMU before hardware release.

## Boot menu
- Vampire OS Live Desktop.
- Vampire Server Live / rescue shell.
- Install Vampire OS.
- Memory diagnostic, only if a tested utility is shipped.
- Recovery / boot repair.
- Firmware setup entry when supported by firmware.

## Installer
- [x] Guided text-mode erase-and-install path exposed from the Vampire Desktop console launcher (graphical installer still pending).
- Hardware preflight: CPU architecture, RAM, storage, firmware mode and network.
- Language, keyboard, timezone, hostname and user creation.
- [x] GPT erase-and-install layout for UEFI (FAT32 ESP + ext4 root) and BIOS (GRUB BIOS boot partition + ext4 root). Manual partitioning remains pending.
- UEFI EFI System Partition and legacy BIOS-compatible layout.
- Optional full-disk encryption with recovery-key handling.
- [x] Firmware-specific GRUB target selection and exact typed destructive confirmation before disk changes.
- Network/repository selection, edition and optional software groups.
- Installation log, error recovery and post-install validation.
- Never format, repartition or overwrite a disk without clear user confirmation.

## First boot
- Initialise Vampire Desktop or Server services.
- Detect hardware and offer optional driver/firmware packages.
- Verify repository trust configuration before enabling updates.
- Show first-run security and privacy checklist.
- Provide offline recovery and documentation.

## Recovery and rollback
- Rescue environment with storage/network diagnostics.
- Bootloader repair, filesystem checks and log export.
- Previous-system snapshot/deployment rollback when supported.
- Recovery must not overwrite user data by default.
- Document recovery-media creation and tested restore procedure.

## Release acceptance
A release candidate must boot on UEFI and legacy BIOS VMs, install to a blank virtual disk, reboot from installed disk, recover from a simulated failed update and pass a disk-layout test matrix. Hardware support is published only after physical-device testing.


## Implemented developer-stage preflight

The live root filesystem includes vinstall list, preflight, plan, media and install commands. The installer validates its rootfs archive and checksum, discovers the ISO payload read-only, requires a whole-disk preflight and exact typed confirmation, stages the OS, writes UUID-based configuration and installs GRUB. It is an experimental erase-and-install implementation, not yet a release-ready installer. See [INSTALLER-PREFLIGHT.md](INSTALLER-PREFLIGHT.md) for its exact scope and limitations.

## Root filesystem staging constraints

The rootfs staging helper validates archive paths, rejects duplicate normalized
entries, special files outside `/dev`, unsafe symbolic/hard links and
Windows-style separators before extraction. It preserves ownership and mode
metadata required by the installed system. A formatted ext4 target may contain
its standard empty `lost+found` directory; staging preserves that directory
but rejects any other pre-existing content, a non-empty `lost+found`, or a
symlink destination. These checks prevent installation from silently merging
an existing filesystem into the new operating system.
