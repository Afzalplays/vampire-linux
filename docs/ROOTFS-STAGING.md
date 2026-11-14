# Root filesystem staging

The ISO build produces a compressed initramfs for live boot and a separate
`rootfs.tar` for installation preparation. The archive is not a disk image.

Run the host-side validator/stager after a successful Buildroot build:

```sh
python3 scripts/stage-rootfs.py out/vampire-os-0.1.0-dev-desktop-x86_64-rootfs.tar /tmp/vampire-rootfs
```

The destination must be new or empty. The tool rejects traversal paths,
absolute or root-escaping symlinks, device nodes, FIFOs, and archives missing
`etc/os-release`, `sbin/init`, or `bin/busybox`. Extraction uses Python's
`tarfile` data filter. This is a non-destructive staging operation only: it
does not partition or format disks, mount filesystems, create boot entries,
or install GRUB. Never treat a validated archive as proof that an installed
system can boot; installed-disk testing remains required.
