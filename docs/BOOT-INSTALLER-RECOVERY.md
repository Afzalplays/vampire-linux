# Vampire OS Boot, Installer and Recovery Design

**Target:** x86_64 / AMD64. This document defines requirements; it does not claim a working installer or bootable ISO exists.

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
- Branded graphical installer for Desktop; guided text installer for Server.
- Hardware preflight: CPU architecture, RAM, storage, firmware mode and network.
- Language, keyboard, timezone, hostname and user creation.
- Guided erase-and-install alongside manual partitioning.
- UEFI EFI System Partition and legacy BIOS-compatible layout.
- Optional full-disk encryption with recovery-key handling.
- Bootloader target selection and warning before disk changes.
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

The live root filesystem now includes vinstall list and
vinstall preflight /dev/DEVICE. This is a read-only inventory and basic
safety check, not an installer. See [INSTALLER-PREFLIGHT.md](INSTALLER-PREFLIGHT.md)
for its exact scope and limitations.
