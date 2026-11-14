# Vampire Installer — storage preflight, layout preview and disk deployment

`vinstall` provides read-only storage discovery plus a confirmation-gated BIOS/UEFI disk deployment path. The destructive path is newly implemented and must still pass disposable-disk QEMU tests before it is considered release-ready.

## Commands

- `vinstall system-check` reports architecture, firmware mode, detected RAM and basic diagnostic-tool availability.
- `vinstall list` lists whole-disk devices found in sysfs, excluding partitions, loop, RAM and zram devices.
- `vinstall preflight /dev/sda` checks that the target exists, has at least 8 GiB, is not marked read-only, and has no mounted whole-disk or partition source in the current mount table. If the mount, mountinfo or swap table is missing or unreadable, preflight fails closed. It also checks kernel major:minor mount records, active swap sources, required sysfs major:minor metadata, and sysfs holders so mounted aliases and disks backing LVM/RAID/device-mapper stacks are rejected.
- `vinstall plan /dev/sda uefi` previews a GPT layout with a 512 MiB EFI System Partition and ext4 root partition.
- `vinstall plan /dev/sda bios` previews a GPT layout with a 2 MiB unformatted GRUB BIOS boot partition and ext4 root partition.
- The console launcher's installer menu can invoke this preview after a successful preflight; the preview still does not modify storage.
- `vinstall install ROOTFS.tar /dev/sda uefi` performs the guided disk deployment described below. Omit the firmware argument to detect the live firmware mode.
- `vinstall help` prints usage.

The layout planner runs the same whole-disk preflight and rejects partition paths and invalid firmware modes. The planner is explicitly **read-only**: it does not partition, format, mount, write, or alter data. UEFI is selected automatically when the live system exposes `/sys/firmware/efi`; otherwise BIOS is the default, and either mode can be specified explicitly.

The console launcher's installer menu offers the preview only after a successful preflight. Automated tests cover both layout previews, invalid firmware modes, partition rejection, menu dispatch, the 8 GiB minimum, mounted-device checks, major:minor aliases, active swap, stacked block-device holders, read-only devices, and missing active-use-table fail-closed behavior. The preflight now rejects any disk or child partition visible as mounted by major:minor, any active swap source, and any target disk backing another block device. A passing preflight is still not a guarantee that a disk is safe to erase or compatible with a future installer. Removable-media status is reported but never treated as permission to modify a device.

## Confirmation-gated disk deployment

The `install` command requires root, a matching SHA-256 file, a structurally validated Buildroot rootfs archive, the live kernel image (default `/boot/vmlinuz`), and all partitioning, filesystem, mount and GRUB tools before it starts. It then repeats the whole-disk preflight and requires the operator to type the exact string `ERASE /dev/DEVICE`. A mismatch cancels without changing the disk.

After confirmation it writes a GPT partition table. UEFI uses a 512 MiB FAT32 EFI System Partition and an ext4 root partition; BIOS uses a 2 MiB unformatted GRUB BIOS-boot partition and an ext4 root partition. It stages the checksum-verified rootfs, copies the live kernel, writes UUID-based `fstab` and GRUB configuration, installs GRUB for the selected firmware mode, syncs and unmounts the target. Temporary mount cleanup is registered before partition-table changes.

The Desktop console launcher's installer menu exposes this flow. The default ISO rootfs path is `/install/rootfs.tar`; override it with `VAMPIRE_INSTALL_ROOTFS` if needed. This command intentionally does not enable disk encryption, dual boot, LVM/RAID, Secure Boot, or preservation of existing partitions. It is an erase-and-install path only.
## Safety boundary and next work

The live image now includes a text-mode erase-and-install implementation, but it is not yet release-ready. Next work is to validate BIOS and UEFI installation to disposable virtual disks, reboot from the installed disk, test interrupted/failing installs and recovery, add encryption and recovery-key handling, and only then begin physical-device validation. Never describe the installer as production-ready before those gates pass.
