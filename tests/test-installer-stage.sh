#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
mkdir -p "$TMP/bin"
printf "#!/bin/sh\\necho 0\\n" > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
export PATH="$TMP/bin:$PATH"
trap 'rm -rf "$TMP"' EXIT
ARCHIVE="$TMP/rootfs.tar"
DEST="$TMP/mounted-root"
mkdir -p "$DEST"
python3 - "$ARCHIVE" <<'PY'
import io, sys, tarfile
with tarfile.open(sys.argv[1], "w") as archive:
    for name, data in (("etc/os-release", b"NAME=Vampire OS\\n"),
                       ("sbin/init", b"init"), ("bin/busybox", b"busybox")):
        info = tarfile.TarInfo(name)
        info.size = len(data)
        archive.addfile(info, io.BytesIO(data))
PY
(cd "$TMP" && sha256sum rootfs.tar > rootfs.tar.sha256)
VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py" "$ROOT/rootfs-overlay/usr/bin/vinstall" validate "$ARCHIVE" > "$TMP/validated"
grep -q "No files were extracted" "$TMP/validated"
VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py" "$ROOT/rootfs-overlay/usr/bin/vinstall" stage "$ARCHIVE" "$DEST" > "$TMP/result"
test -s "$DEST/etc/os-release"
test -s "$DEST/sbin/init"
grep -q "No disk partitioning" "$TMP/result"
mkdir -p "$TMP/not-empty"
touch "$TMP/not-empty/keep"
if VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py" "$ROOT/rootfs-overlay/usr/bin/vinstall" stage "$ARCHIVE" "$TMP/not-empty" >/dev/null 2>&1; then
  echo "vinstall stage unexpectedly accepted a non-empty destination" >&2
  exit 1
fi
test -e "$TMP/not-empty/keep"
printf "invalid  " > "$ARCHIVE.sha256"
if VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py" "$ROOT/rootfs-overlay/usr/bin/vinstall" validate "$ARCHIVE" >/dev/null 2>&1; then
  echo "vinstall validate unexpectedly accepted a bad checksum" >&2
  exit 1
fi
if VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py" "$ROOT/rootfs-overlay/usr/bin/vinstall" stage "$ARCHIVE" "$TMP/bad-checksum" >/dev/null 2>&1; then
  echo "vinstall stage unexpectedly accepted a bad checksum" >&2
  exit 1
fi
if "$ROOT/rootfs-overlay/usr/bin/vinstall" stage "$ARCHIVE" "$TMP/missing" >/dev/null 2>&1; then
  echo "vinstall stage unexpectedly accepted a missing destination" >&2
  exit 1
fi
printf '#!/bin/sh\\necho 1000\\n' > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
if "$ROOT/rootfs-overlay/usr/bin/vinstall" stage "$ARCHIVE" "$TMP/nonroot" >/dev/null 2>&1; then
  echo "installer unexpectedly allowed non-root operation" >&2
  exit 1
fi
printf '#!/bin/sh\\necho 0\\n' > "$TMP/bin/id"
chmod +x "$TMP/bin/id"
echo "vinstall rootfs stage command tests: PASS"
