# Installer runtime prerequisites

Both Desktop and Server root filesystems now request the storage and bootloader
utilities needed for the next installer implementation stage:

- util-linux basic binaries and mount support (including sfdisk and blkid)
- GNU Parted
- dosfstools FAT formatter
- e2fsprogs (ext filesystem creation and checking)
- GRUB 2 tools with x86 legacy BIOS and x86-64 UEFI targets

The Buildroot toolchain enables wchar and locale because Parted and GRUB require
wchar support, and Parted also requires locale support.

Run `vinstall requirements` in the live environment to check the expected
commands. This is a diagnostic gate only. It does not partition, format, mount,
copy files, or install GRUB. The real installer remains disabled until the
destructive transaction, confirmation flow, cleanup and installed-disk boot
tests are implemented and reviewed.
