#!/usr/bin/env python3
"""Embed the built kernel in the target rootfs for disk installation."""
import os
import pathlib
import shutil
import sys


def ensure_group(path: pathlib.Path, name: str, preferred_gid: int) -> int:
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    for line in lines:
        fields = line.split(":")
        if len(fields) >= 4 and fields[0] == name:
            members = fields[3].split(",") if fields[3] else []
            if "vampire" not in members:
                fields[3] = ",".join([*members, "vampire"]).strip(",")
                lines[lines.index(line)] = ":".join(fields)
                path.write_text("\\n".join(lines) + "\\n", encoding="utf-8")
            return int(fields[2])
    used = {int(line.split(":")[2]) for line in lines if len(line.split(":")) >= 3 and line.split(":")[2].isdigit()}
    gid = preferred_gid
    while gid in used:
        gid += 1
    lines.append(f"{name}:x:{gid}:vampire")
    path.write_text("\\n".join(lines) + "\\n", encoding="utf-8")
    return gid


def configure_local_user(target: pathlib.Path) -> None:
    """Create a locked, unprivileged desktop account with device-access groups."""
    etc = target / "etc"
    home = target / "home" / "vampire"
    etc.mkdir(parents=True, exist_ok=True)
    passwd = etc / "passwd"
    group = etc / "group"
    shadow = etc / "shadow"
    passwd_lines = passwd.read_text(encoding="utf-8").splitlines() if passwd.exists() else []
    group_gid = ensure_group(group, "vampire", 1000)
    video_gid = ensure_group(group, "video", 27)
    input_gid = ensure_group(group, "input", 100)
    if not any(line.split(":")[0] == "vampire" for line in passwd_lines):
        passwd_lines.append(f"vampire:x:1000:{group_gid}:Vampire OS User:/home/vampire:/bin/sh")
        passwd.write_text("\\n".join(passwd_lines) + "\\n", encoding="utf-8")
    shadow_lines = shadow.read_text(encoding="utf-8").splitlines() if shadow.exists() else []
    if not any(line.split(":")[0] == "vampire" for line in shadow_lines):
        shadow_lines.append("vampire:!:19000:0:99999:7:::")
        shadow.write_text("\\n".join(shadow_lines) + "\\n", encoding="utf-8")
    shadow.chmod(0o640)
    home.mkdir(parents=True, exist_ok=True)
    try:
        import grp
        import pwd
        import os
        os.chown(home, 1000, group_gid)
    except (ImportError, OSError):
        pass
    print(
        "Vampire OS: provisioned locked local account 'vampire' "
        f"(uid 1000; video gid {video_gid}; input gid {input_gid}). "
        "Set its password from the root console before interactive login."
    )


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: post-build-vampire.py TARGET_DIR")
    target = pathlib.Path(sys.argv[1])
    binaries = pathlib.Path(os.environ["BINARIES_DIR"])
    kernel = binaries / "bzImage"
    if not kernel.is_file() or kernel.stat().st_size == 0:
        raise SystemExit(f"Vampire OS: kernel image missing: {kernel}")
    configure_local_user(target)
    boot = target / "boot"
    boot.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(kernel, boot / "vmlinuz")
    (boot / "vmlinuz").chmod(0o644)
    print(f"Vampire OS: embedded install kernel at {boot / 'vmlinuz'}")


if __name__ == "__main__":
    main()
