#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/dev" "$TMP/sys/block/vda/holders"
: > "$TMP/dev/vda"
printf '41943040\n' > "$TMP/sys/block/vda/size"
printf '0\n' > "$TMP/sys/block/vda/ro"
printf '0\n' > "$TMP/sys/block/vda/removable"
printf '252:0\n' > "$TMP/sys/block/vda/dev"
: > "$TMP/mounts"
: > "$TMP/mountinfo"
printf 'Filename Type Size Used Priority\n' > "$TMP/swaps"

cat > "$TMP/bin/id" <<'EOF'
#!/bin/sh
[ "${1:-}" = -u ] && { echo 0; exit 0; }
exit 1
EOF
chmod 0755 "$TMP/bin/id"
for tool in parted partprobe udevadm mkfs.fat mkfs.ext4 mount umount grub-install blkid; do
  cat > "$TMP/bin/$tool" <<EOF
#!/bin/sh
EOF
  if [ "$tool" = parted ]; then
    printf 'printf called > "%s"\n' "$TMP/parted-called" >> "$TMP/bin/$tool"
  else
    printf 'exit 0\n' >> "$TMP/bin/$tool"
  fi
  chmod 0755 "$TMP/bin/$tool"
done

mkdir -p "$TMP/rootfs/etc" "$TMP/rootfs/sbin" "$TMP/rootfs/bin"
printf 'NAME="Vampire OS"\n' > "$TMP/rootfs/etc/os-release"
printf '#!/bin/sh\n' > "$TMP/rootfs/sbin/init"
printf 'busybox fixture\n' > "$TMP/rootfs/bin/busybox"
tar -cf "$TMP/rootfs.tar" -C "$TMP/rootfs" .
(cd "$TMP" && sha256sum rootfs.tar > rootfs.tar.sha256)
printf 'kernel fixture\n' > "$TMP/vmlinuz"

export PATH="$TMP/bin:$PATH"
export VAMPIRE_SYS_BLOCK="$TMP/sys/block"
export VAMPIRE_DEV_ROOT="$TMP/dev"
export VAMPIRE_MOUNTS_FILE="$TMP/mounts"
export VAMPIRE_MOUNTINFO_FILE="$TMP/mountinfo"
export VAMPIRE_SWAPS_FILE="$TMP/swaps"
export VAMPIRE_ROOTFS_STAGE="$ROOT/scripts/stage-rootfs.py"
export VAMPIRE_INSTALL_CONFIGURER="$ROOT/scripts/configure-installed-root.py"
export VAMPIRE_KERNEL_IMAGE="$TMP/vmlinuz"

# A symlinked kernel must be rejected before any destructive disk command.
mv "$TMP/vmlinuz" "$TMP/vmlinuz.real"
ln -s "$TMP/vmlinuz.real" "$TMP/vmlinuz"
if "$ROOT/rootfs-overlay/usr/bin/vinstall" install "$TMP/rootfs.tar" "$TMP/dev/vda" bios > "$TMP/kernel-output" 2>&1; then
  echo 'installer accepted a symlinked live kernel' >&2
  exit 1
fi
grep -q 'live kernel must be a non-symlink regular file' "$TMP/kernel-output"
[ ! -e "$TMP/parted-called" ]
rm "$TMP/vmlinuz"
mv "$TMP/vmlinuz.real" "$TMP/vmlinuz"

if printf 'NO\n' | "$ROOT/rootfs-overlay/usr/bin/vinstall" install "$TMP/rootfs.tar" "$TMP/dev/vda" bios > "$TMP/output" 2>&1; then
  echo 'installer accepted an incorrect destructive confirmation' >&2
  exit 1
fi
grep -q 'Installation cancelled; disk was not changed' "$TMP/output"
[ ! -e "$TMP/parted-called" ]

# A disk can become mounted after the user confirms. Inject a mount on the
# second preflight and prove the installer aborts before calling parted.
REAL_AWK=$(command -v awk)
cat > "$TMP/bin/awk" <<EOF
#!/bin/sh
count=0
[ ! -f "$TMP/awk-count" ] || count=\$(cat "$TMP/awk-count")
count=\$((count + 1))
printf '%s\\n' "\$count" > "$TMP/awk-count"
if [ "\$count" -eq 2 ]; then
  printf '42 1 252:0 / /late-mount rw - ext4 /dev/vda rw\\n' > "$TMP/mountinfo"
fi
exec "$REAL_AWK" "\$@"
EOF
chmod 0755 "$TMP/bin/awk"
if printf 'ERASE %s\\n' "$TMP/dev/vda" | "$ROOT/rootfs-overlay/usr/bin/vinstall" install "$TMP/rootfs.tar" "$TMP/dev/vda" bios > "$TMP/recheck-output" 2>&1; then
  echo 'installer ignored a disk mounted after confirmation' >&2
  exit 1
fi
grep -q 'mounted at /late-mount' "$TMP/recheck-output"
[ ! -e "$TMP/parted-called" ]
echo 'installer destructive-confirmation and immediate-recheck tests: PASS'
