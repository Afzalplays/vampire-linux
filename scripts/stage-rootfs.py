#!/usr/bin/env python3
"""Validate and safely stage a Vampire OS Buildroot rootfs tarball.

This is a host-side, non-destructive preparation step. It never discovers,
mounts, partitions, formats, or writes to block devices.
"""
import argparse
import pathlib
import shutil
import sys
import tarfile


REQUIRED = ("etc/os-release", "sbin/init", "bin/busybox")


def safe_member_name(name):
    path = pathlib.PurePosixPath(name)
    return not path.is_absolute() and all(part not in ("..", "") for part in path.parts)


def sanitize_member(member):
    if not safe_member_name(member.name):
        raise ValueError(f"unsafe archive path: {member.name}")
    if member.isdev() or member.isfifo():
        # Buildroot may include static /dev nodes even with devtmpfs enabled.
        # Skip them; the running kernel will populate /dev at boot.
        if pathlib.PurePosixPath(member.name).parts[:1] == ("dev",):
            return None
        raise ValueError(f"unsupported special file outside /dev: {member.name}")
        target = pathlib.PurePosixPath(member.linkname)
        if target.is_absolute():
            # Absolute symlinks are normal in Linux rootfs archives. Convert
            # them to equivalent relative links so extraction never writes
            # through a link into the host filesystem.
            if ".." in target.parts:
                raise ValueError(f"unsafe absolute link target: {member.name}")
            root_target = pathlib.PurePosixPath(*target.parts[1:])
            member.linkname = __import__("posixpath").relpath(
                root_target.as_posix() or ".", pathlib.PurePosixPath(member.name).parent.as_posix()
            )
        combined = pathlib.PurePosixPath(member.name).parent / pathlib.PurePosixPath(member.linkname)
        depth = 0
        for part in combined.parts:
            if part == "..":
                depth -= 1
            elif part not in ("", "."):
                depth += 1
            if depth < 0:
                raise ValueError(f"link escapes rootfs: {member.name}")
    elif member.islnk():
        target = pathlib.PurePosixPath(member.linkname)
        if target.is_absolute() or not safe_member_name(member.linkname):
            raise ValueError(f"unsafe hard-link target: {member.name}")
    return member


def validate(archive):
    with tarfile.open(archive, "r:*") as tar:
        names = set()
        for member in tar.getmembers():
            sanitize_member(member)
            names.add(pathlib.PurePosixPath(member.name).as_posix().lstrip("./"))
        missing = [name for name in REQUIRED if name not in names]
        if missing:
            raise ValueError("rootfs archive missing required paths: " + ", ".join(missing))
        return len(names)


def stage(archive, destination):
    destination = pathlib.Path(destination)
    if destination.exists():
        if not destination.is_dir() or any(destination.iterdir()):
            raise ValueError("destination must be a new or empty directory")
    else:
        destination.mkdir(parents=True, mode=0o700)
    validate(archive)
    with tarfile.open(archive, "r:*") as tar:
        # Preserve OS ownership and mode bits (including setuid) after explicit
        # path, file-type and link-target validation above. The "data" filter
        # deliberately strips these metadata bits and would break an OS rootfs.
        tar.extractall(destination, filter=lambda member, _path: sanitize_member(member))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", help="Buildroot rootfs.tar")
    parser.add_argument("destination", help="empty staging directory")
    args = parser.parse_args()
    try:
        count = validate(args.archive)
        stage(args.archive, args.destination)
    except (OSError, tarfile.TarError, ValueError) as exc:
        print(f"vrootfs-stage: error: {exc}", file=sys.stderr)
        return 1
    print(f"Validated and staged {count} rootfs entries in {args.destination}")
    print("No disk partitioning, formatting, or bootloader installation was performed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
