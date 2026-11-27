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
                path.write_text("\n".join(lines) + "\n", encoding="utf-8")
            return int(fields[2])
    used = {int(line.split(":")[2]) for line in lines if len(line.split(":")) >= 3 and line.split(":")[2].isdigit()}
    gid = preferred_gid
    while gid in used:
        gid += 1
    lines.append(f"{name}:x:{gid}:vampire")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
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
    if any(len(line.split(":")) > 2 and line.split(":")[2] == "1000" and line.split(":")[0] != "vampire" for line in passwd_lines):
        raise SystemExit("Vampire OS: uid 1000 is already assigned to another account")
    if not any(line.split(":")[0] == "vampire" for line in passwd_lines):
        passwd_lines.append(f"vampire:x:1000:{group_gid}:Vampire OS User:/home/vampire:/bin/sh")
        passwd.write_text("\n".join(passwd_lines) + "\n", encoding="utf-8")
    shadow_lines = shadow.read_text(encoding="utf-8").splitlines() if shadow.exists() else []
    if not any(line.split(":")[0] == "vampire" for line in shadow_lines):
        shadow_lines.append("vampire:!:19000:0:99999:7:::")
        shadow.write_text("\n".join(shadow_lines) + "\n", encoding="utf-8")
    shadow.chmod(0o640)
    home.mkdir(parents=True, exist_ok=True)
    home.chmod(0o755)
    # Buildroot's post-build hook is not privileged. Ownership is assigned by
    # post-fakeroot-vampire.sh after the target tree enters fakeroot.
    print(
        "Vampire OS: provisioned locked local account 'vampire' "
        f"(uid 1000; video gid {video_gid}; input gid {input_gid}). "
        "Set its password from the root console before interactive login."
    )


def install_desktop_session_runtime(target: pathlib.Path) -> None:
    """Ensure desktop login entry points are present in both rootfs images."""
    if os.environ.get("VAMPIRE_EDITION", "desktop") != "desktop":
        return
    overlay_value = os.environ.get("VAMPIRE_ROOTFS_OVERLAY")
    if not overlay_value:
        raise SystemExit("Vampire OS: VAMPIRE_ROOTFS_OVERLAY is required for Desktop builds")
    overlay = pathlib.Path(overlay_value)
    required = (
        "usr/bin/vdesktop-session",
        "usr/lib/vampire/session-runtime",
        "usr/lib/vampire/settings-bootstrap",
    )
    for relative in required:
        source = overlay / relative
        if source.is_symlink() or not source.is_file():
            raise SystemExit(f"Vampire OS: required Desktop session source is missing or unsafe: {source}")
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        destination.chmod(0o755)
        print(f"Vampire OS: staged Desktop session component {destination}")


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: post-build-vampire.py TARGET_DIR")
    target = pathlib.Path(sys.argv[1])
    binaries = pathlib.Path(os.environ["BINARIES_DIR"])
    kernel = binaries / "bzImage"
    if not kernel.is_file() or kernel.stat().st_size == 0:
        raise SystemExit(f"Vampire OS: kernel image missing: {kernel}")
    configure_local_user(target)
    install_desktop_session_runtime(target)
    boot = target / "boot"
    boot.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(kernel, boot / "vmlinuz")
    (boot / "vmlinuz").chmod(0o644)
    print(f"Vampire OS: embedded install kernel at {boot / 'vmlinuz'}")


if __name__ == "__main__":
    main()
