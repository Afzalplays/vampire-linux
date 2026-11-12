#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sh -n "$ROOT/rootfs-overlay/usr/bin/vsoftware"
cat > "$TMP/fake-vpm" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$VPM_LOG"
EOF
chmod +x "$TMP/fake-vpm"
export VAMPIRE_VPM_CMD="$TMP/fake-vpm" VPM_LOG="$TMP/log"
printf '6\n\n0\n' | sh "$ROOT/rootfs-overlay/usr/bin/vsoftware" >/dev/null
grep -qx 'doctor' "$TMP/log"
grep -qx 'list' "$TMP/log"
: > "$TMP/log"
printf '4\nsample-package\nn\n\n0\n' | sh "$ROOT/rootfs-overlay/usr/bin/vsoftware" >/dev/null
if grep -q '^install ' "$TMP/log"; then
  echo "software center ignored a declined install confirmation" >&2
  exit 1
fi
printf '4\nsample-package\ny\n\n0\n' | sh "$ROOT/rootfs-overlay/usr/bin/vsoftware" >/dev/null
grep -qx 'install sample-package -y' "$TMP/log"

cat > "$TMP/failing-vpm" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$VPM_LOG"
exit 1
MOCK
chmod +x "$TMP/failing-vpm"
: > "$TMP/log"
printf '1\n\n6\n\n0\n' | VAMPIRE_VPM_CMD="$TMP/failing-vpm" sh "$ROOT/rootfs-overlay/usr/bin/vsoftware" >/dev/null
grep -qx 'update' "$TMP/log"
grep -qx 'list' "$TMP/log"

echo "Vampire Software Center console tests passed."
