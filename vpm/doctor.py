#!/usr/bin/env python3
"""Vampire OS VPM environment diagnostics. SPDX-License-Identifier: MIT"""
import json
import os
import pathlib
import shutil
import sys
from urllib.parse import urlparse


def repository_status(config: pathlib.Path) -> tuple[bool, str]:
    try:
        document = json.loads(config.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return False, "cannot read repository configuration: " + str(exc)
    repositories = document.get("repositories") if isinstance(document, dict) else None
    if not isinstance(repositories, list) or not repositories:
        return False, "no signed package repositories configured"
    for index, repository in enumerate(repositories, 1):
        if not isinstance(repository, dict):
            return False, "repository {} is not an object".format(index)
        name = repository.get("name")
        url = repository.get("url")
        public_key = repository.get("minisign_public_key")
        parsed = urlparse(url) if isinstance(url, str) else None
        if not name or not parsed or parsed.scheme != "https" or not parsed.netloc:
            return False, "repository {} needs a name and HTTPS URL".format(index)
        if not isinstance(public_key, str) or not public_key.strip() or "REPLACE_WITH" in public_key:
            return False, "repository {} has no real minisign public key".format(name)
    return True, "{} signed repository/repositories configured".format(len(repositories))


def main():
    config = pathlib.Path(os.environ.get("VPM_CONFIG", "/etc/vpm/vpm.json"))
    cache = pathlib.Path(os.environ.get("VPM_CACHE", "~/.cache/vpm")).expanduser()
    root = pathlib.Path(os.environ.get("VPM_ROOT", "/"))
    repo_ok, repo_detail = repository_status(config) if config.is_file() else (False, "config file missing")
    checks = [
        ("Python >= 3.10", sys.version_info >= (3, 10), sys.version.split()[0]),
        ("Minisign", shutil.which("minisign") is not None, shutil.which("minisign") or "missing"),
        ("VPM config", config.is_file(), str(config)),
        ("Signed repository", repo_ok, repo_detail),
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
