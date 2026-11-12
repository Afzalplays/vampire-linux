#!/usr/bin/env python3
"""Safely write Vampire OS Buildroot output configuration and release metadata."""
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


def main(argv):
    if len(argv) not in (3, 5):
        raise SystemExit(
            "usage: configure-build-output.py CONFIG OVERLAY "
            "[EDITION OS_CONF OS_RELEASE]"
        )
    config_path = pathlib.Path(argv[1])
    overlay = str(pathlib.Path(argv[2]).resolve())
    replace_assignment(config_path, "BR2_ROOTFS_OVERLAY", overlay,
                       allow_missing=True)
    if len(argv) == 5:
        edition, os_conf, os_release = argv[2], argv[3], argv[4]
        replace_assignment(os_conf, "EDITION", edition)
        replace_assignment(
            os_release, "PRETTY_NAME",
            f"Vampire OS 0.1.0-dev ({edition})",
        )


if __name__ == "__main__":
    main(sys.argv)
