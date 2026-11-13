# Vampire Installer — storage preflight and layout preview

The current `vinstall` command is a **read-only storage discovery and preflight tool**. It is not a disk installer and cannot install an operating system.

## Commands

- `vinstall system-check` reports architecture, firmware mode, detected RAM and basic diagnostic-tool availability.
- `vinstall list` lists whole-disk devices found in sysfs, excluding partitions, loop, RAM and zram devices.
- `vinstall preflight /dev/sda` checks that the target exists, has at least 8 GiB, is not marked read-only, and has no mounted whole-disk or partition source in the current mount table. If the mount table is missing or unreadable, preflight fails closed.
- `vinstall plan /dev/sda uefi` previews a GPT layout with a 512 MiB EFI System Partition and ext4 root partition.
- `vinstall plan /dev/sda bios` previews a GPT layout with a 2 MiB unformatted GRUB BIOS boot partition and ext4 root partition.
- The console launcher's installer menu can invoke this preview after a successful preflight; the preview still does not modify storage.
- `vinstall help` prints usage.

The layout planner runs the same whole-disk preflight and rejects partition paths and invalid firmware modes. The planner is explicitly **read-only**: it does not partition, format, mount, write, or alter data. UEFI is selected automatically when the live system exposes `/sys/firmware/efi`; otherwise BIOS is the default, and either mode can be specified explicitly.

Automated tests cover both layout previews, invalid firmware modes, partition rejection, the 8 GiB minimum, mounted-device checks, read-only devices, and missing mount-table fail-closed behavior. A passing preflight is not a guarantee that a disk is safe to erase or compatible with a future installer. Removable-media status is reported but never treated as permission to modify a device.

## Safety boundary and next work

The live image currently has no partition editor, filesystem formatter, installer transaction engine, graphical installer, or rollback-aware target deployment. Do not describe this command as an installer. A real installer must add explicit target-selection review, show existing partitions and mount points, require separate destructive-action confirmation, support UEFI/GPT and BIOS layouts, validate encryption/recovery-key handling, and test failure recovery inside disposable virtual disks before physical-disk release.
