# Vampire Installer — storage preflight MVP

The current vinstall command is a **read-only storage discovery and preflight tool**.
It is not a disk installer and cannot install an operating system.

## Commands

- `vinstall system-check` reports architecture, firmware mode, detected RAM and basic diagnostic-tool availability.
- `vinstall list` lists whole-disk devices found in sysfs, excluding partitions, loop, RAM and zram devices.
- `vinstall preflight /dev/sda` checks that the target exists, has at least 8 GiB,
  is not marked read-only, and has no mounted whole-disk or partition source in
  the current mount table. If the mount table is missing or unreadable, preflight
  fails closed rather than approving a disk without this safety check.
- `vinstall help` prints usage.

Partition device paths are rejected as targets. Linux sysfs partition records are resolved beneath their parent disk, matching the kernel's normal `/sys/block/DISK/PARTITION` layout.

The script reads sysfs and the mount table only. It does not invoke partitioning,
formatting, mounting, bootloader installation, or filesystem-writing utilities.
The automated preflight test also verifies that `system-check` rejects a non-x86_64 image and accepts the x86_64 target architecture. It also checks the 8 GiB minimum and confirms removable-media warnings are non-destructive.\n\nA passing preflight is not a guarantee that a disk is safe to erase or compatible
with a future installer. USB/removable status is reported but never treated as
permission to modify a device.

## Safety boundary and next work

The live image currently has no partition editor, filesystem formatter, installer
transaction engine, graphical installer, or rollback-aware target deployment.
Do not describe this command as an installer. A real installer must add an
explicit target-selection review, show existing partitions and mount points,
require a separate destructive-action confirmation, support UEFI/GPT and BIOS
layouts, validate encryption/recovery-key handling, and test failure recovery
inside disposable virtual disks before any physical-disk release.

## Read-only firmware layout proposal

The current developer installer also supports:

```sh
vinstall plan /dev/sda uefi
vinstall plan /dev/sda bios
```

It first runs the same fail-closed storage preflight, then prints a proposed
GPT layout: a 512 MiB FAT32 EFI System Partition plus ext4 root for UEFI, or
a 2 MiB GRUB BIOS boot partition plus ext4 root for legacy BIOS. If the mode
is omitted, the live environment's firmware mode is detected. This command
is informational only: it does not create a partition table, format, mount,
or write to the target. The minimum 8 GiB preflight threshold is not a promise
that the proposed layout is suitable for production; actual installer sizing,
user confirmation, encryption, installation and reboot tests remain future work.
