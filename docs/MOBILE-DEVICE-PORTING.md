# Vampire Mobile reference-device inventory

A generic ARM64 QEMU image cannot become a phone image until a real device target is selected. The read-only helper `scripts/mobile-device-report.sh` gathers Android model, device codename, SoC/platform, bootloader state, slot metadata, kernel command line and partition names from an attached Android phone.

## Collect a report

1. Install Android Platform Tools on a computer.
2. Enable USB debugging on the phone and authorize that computer.
3. Run `bash scripts/mobile-device-report.sh` from this repository.
4. Review and redact any details before sharing the report.

The script only reads device properties and partition listings. It does not reboot, unlock, erase, flash or otherwise modify the phone.

The report is used to decide whether the device has an unlockable boot chain and enough public kernel/device-tree/firmware sources for a responsible port. Do not flash generic ARM64 images to a phone.
