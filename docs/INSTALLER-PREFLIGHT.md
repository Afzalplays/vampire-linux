# Vampire Installer — storage preflight MVP

The current vinstall command is a **read-only storage discovery and preflight tool**.
It is not a disk installer and cannot install an operating system.

## Commands

- `vinstall system-check` reports architecture, firmware mode, detected RAM and basic diagnostic-tool availability.
- `vinstall list` lists whole-disk devices found in sysfs, excluding partitions, loop, RAM and zram devices.
- `vinstall preflight /dev/sda` checks that the target exists, has at least 8 GiB,
  is not marked read-only, and has no mounted whole-disk or partition source in
  the current mount table.
- `vinstall help` prints usage.

Partition device paths are rejected as targets. Linux sysfs partition records are resolved beneath their parent disk, matching the kernel's normal `/sys/block/DISK/PARTITION` layout.

The script reads sysfs and the mount table only. It does not invoke partitioning,
formatting, mounting, bootloader installation, or filesystem-writing utilities.
A passing preflight is not a guarantee that a disk is safe to erase or compatible
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
