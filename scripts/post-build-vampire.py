#!/usr/bin/env python3
"""Embed the built kernel in the target rootfs for disk installation."""
import os
import pathlib
import shutil
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: post-build-vampire.py TARGET_DIR")
    target = pathlib.Path(sys.argv[1])
    binaries = pathlib.Path(os.environ["BINARIES_DIR"])
    kernel = binaries / "bzImage"
    if not kernel.is_file() or kernel.stat().st_size == 0:
        raise SystemExit(f"Vampire OS: kernel image missing: {kernel}")
    boot = target / "boot"
    boot.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(kernel, boot / "vmlinuz")
    (boot / "vmlinuz").chmod(0o644)
    print(f"Vampire OS: embedded install kernel at {boot / 'vmlinuz'}")


if __name__ == "__main__":
    main()
