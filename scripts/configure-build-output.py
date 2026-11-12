#!/usr/bin/env python3
"""Safely configure Buildroot and edition metadata before rootfs creation."""
import json
import pathlib
import sys


def replace_assignment(path, key, value, *, allow_missing=False):
    path = pathlib.Path(path)
    lines = path.read_text().splitlines()
    prefix = key + "="
    matches = [index for index, line in enumerate(lines) if line.startswith(prefix)]
    if len(matches) > 1:
        raise ValueError(f"{path}: duplicate {key} assignments")
    rendered = prefix + json.dumps(value)
    if matches:
        lines[matches[0]] = rendered
    elif allow_missing:
        lines.append(rendered)
    else:
        raise ValueError(f"{path}: missing {key} assignment")
    path.write_text("\n".join(lines) + "\n")


def configure(config_path, overlay_path, edition):
    if edition not in ("desktop", "server"):
        raise ValueError(f"unsupported edition: {edition}")
    overlay = pathlib.Path(overlay_path).resolve()
    replace_assignment(config_path, "BR2_ROOTFS_OVERLAY", str(overlay),
                       allow_missing=True)
    # These files are part of the rootfs overlay. Update them before Buildroot
    # creates target/ and rootfs.cpio.gz so the booted image gets correct data.
    replace_assignment(overlay / "etc/vampire/os.conf", "EDITION", edition)
    replace_assignment(
        overlay / "etc/os-release", "PRETTY_NAME",
        f"Vampire OS 0.1.0-dev ({edition})",
    )


def main(argv):
    if len(argv) != 4:
        raise SystemExit(
            "usage: configure-build-output.py CONFIG OVERLAY desktop|server"
        )
    configure(argv[1], argv[2], argv[3])


if __name__ == "__main__":
    main(sys.argv)
