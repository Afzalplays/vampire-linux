#!/usr/bin/env python3
"""Vampire OS VPM environment diagnostics. SPDX-License-Identifier: MIT"""
import os
import pathlib
import shutil
import sys

def main():
    config = pathlib.Path(os.environ.get("VPM_CONFIG", "/etc/vpm/vpm.json"))
    cache = pathlib.Path(os.environ.get("VPM_CACHE", "~/.cache/vpm")).expanduser()
    root = pathlib.Path(os.environ.get("VPM_ROOT", "/"))
    checks = [
        ("Python >= 3.10", sys.version_info >= (3, 10), sys.version.split()[0]),
        ("Minisign", shutil.which("minisign") is not None, shutil.which("minisign") or "missing"),
        ("VPM config", config.is_file(), str(config)),
        ("Cache writable", cache.exists() or os.access(cache.parent, os.W_OK), str(cache)),
        ("Install target", root.exists(), str(root)),
        ("Root permission", os.geteuid() == 0 or root != pathlib.Path("/"), "required for installing into /"),
    ]
    print("VAMPIRE OS / VPM DIAGNOSTICS")
    print("============================")
    for label, ok, detail in checks:
        status = "OK" if ok else "WARN"
        print("[{}] {}: {}".format(status, label, detail))
    return 0 if all(item[1] for item in checks) else 1

if __name__ == "__main__":
    raise SystemExit(main())
