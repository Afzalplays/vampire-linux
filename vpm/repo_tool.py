#!/usr/bin/env python3
"""Build a static Vampire package repository index. SPDX-License-Identifier: MIT"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

NAME_RE = re.compile(r"^[a-z0-9][a-z0-9+_.-]{0,79}$")
VERSION_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9.+:~_-]{0,79}$")
REQUIRED = ("name", "version", "description", "architecture", "license", "depends", "archive")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_package_metadata(path: Path) -> dict[str, Any]:
    try:
        item = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read metadata {path}: {exc}") from exc
    if not isinstance(item, dict):
        raise ValueError(f"{path}: metadata must be a JSON object")
    missing = [key for key in REQUIRED if key not in item]
    if missing:
        raise ValueError(f"{path}: missing fields: {', '.join(missing)}")
    if not isinstance(item["name"], str) or not NAME_RE.fullmatch(item["name"]):
        raise ValueError(f"{path}: invalid package name")
    if not isinstance(item["version"], str) or not VERSION_RE.fullmatch(item["version"]):
        raise ValueError(f"{path}: invalid package version")
    for field in ("description", "architecture", "license"):
        if not isinstance(item[field], str) or not item[field].strip():
            raise ValueError(f"{path}: {field} must be a non-empty string")
    if not isinstance(item["depends"], list) or not all(
        isinstance(dep, str) and NAME_RE.fullmatch(dep) for dep in item["depends"]
    ):
        raise ValueError(f"{path}: depends must be a list of valid package names")
    archive = Path(item["archive"])
    if not archive.is_file() or archive.is_symlink():
        raise ValueError(f"{path}: archive must be an existing regular file")
    return item


def build_index(repository: str, architecture: str, metadata_paths: list[Path], output: Path) -> dict[str, Any]:
    if not NAME_RE.fullmatch(repository):
        raise ValueError("invalid repository name")
    if architecture not in ("x86_64", "aarch64", "any"):
        raise ValueError("unsupported repository architecture")
    if output.is_symlink():
        raise ValueError("repository output directory must not be a symlink")
    output.mkdir(parents=True, exist_ok=True)
    packages_dir = output / "packages"
    if packages_dir.is_symlink():
        raise ValueError("repository packages directory must not be a symlink")
    packages_dir.mkdir(parents=True, exist_ok=True)
    packages: list[dict[str, Any]] = []
    seen: set[str] = set()
    for metadata_path in metadata_paths:
        item = load_package_metadata(metadata_path)
        key = item["name"]
        if key in seen:
            raise ValueError(f"duplicate package name: {key}")
        seen.add(key)
        if item["architecture"] not in ("any", architecture):
            raise ValueError(f"{key}: package architecture does not match repository")
        source = Path(item["archive"]).resolve(strict=True)
        filename = f'{item["name"]}-{item["version"]}.tar.gz'
        destination = packages_dir / filename
        if destination.is_symlink():
            raise ValueError(f"{key}: refusing to overwrite a symlinked package destination")
        if source != destination.resolve(strict=False):
            fd, temporary_name = tempfile.mkstemp(prefix=".vpm-package-", dir=packages_dir)
            os.close(fd)
            temporary = Path(temporary_name)
            try:
                shutil.copyfile(source, temporary)
                os.replace(temporary, destination)
            finally:
                temporary.unlink(missing_ok=True)
        package = {key: item[key] for key in (
            "name", "version", "description", "architecture", "license", "depends"
        )}
        package["url"] = f"packages/{filename}"
        package["sha256"] = sha256_file(destination)
        packages.append(package)
    packages.sort(key=lambda package: package["name"])
    index = {
        "format": 1,
        "repository": repository,
        "architecture": architecture,
        "packages": packages,
    }
    index_path = output / "index.json"
    if index_path.is_symlink():
        raise ValueError("refusing to overwrite a symlinked repository index")
    fd, temporary_name = tempfile.mkstemp(prefix=".vpm-index-", dir=output, text=True)
    os.close(fd)
    temporary_index = Path(temporary_name)
    try:
        temporary_index.write_text(
            json.dumps(index, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        os.replace(temporary_index, index_path)
    finally:
        temporary_index.unlink(missing_ok=True)
    return index


def main() -> int:
    parser = argparse.ArgumentParser(description="Build and optionally sign a Vampire package repository index")
    parser.add_argument("--repository", required=True, help="repository identifier, e.g. vampire-testing")
    parser.add_argument("--architecture", default="x86_64", choices=("x86_64", "aarch64", "any"))
    parser.add_argument("--metadata", required=True, nargs="+", type=Path, help="package metadata JSON files")
    parser.add_argument("--output", required=True, type=Path, help="repository output directory")
    parser.add_argument("--signing-key", type=Path, help="minisign secret key; omit for an unsigned local test repository")
    args = parser.parse_args()
    try:
        index = build_index(args.repository, args.architecture, args.metadata, args.output)
        index_path = args.output / "index.json"
        if args.signing_key:
            if not args.signing_key.is_file():
                raise ValueError("signing key file does not exist")
            if not shutil.which("minisign"):
                raise ValueError("minisign executable is required for signing")
            subprocess.run(
                ["minisign", "-S", "-s", str(args.signing_key), "-m", str(index_path)],
                check=True,
            )
        print(f"Built {len(index['packages'])} package(s) in {index_path}")
        if args.signing_key:
            print(f"Signed index: {index_path}.minisig")
        else:
            print("WARNING: unsigned local index; do not publish or use with production clients.")
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"vpm-repo: error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
