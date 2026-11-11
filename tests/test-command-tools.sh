#!/usr/bin/env bash
# Safe command-level tests. All external commands are mocked in a temp directory.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/services.d"

# Test vctl dispatch without touching the live system's service directory.
sed "s|DIR=/etc/vampire/services.d|DIR=$TMP/services.d|" "$ROOT/rootfs-overlay/usr/bin/vctl" > "$TMP/vctl"
cat > "$TMP/services.d/mocksvc" <<'SERVICE'
#!/bin/sh
printf '%s\n' "$1" >> "$VCTL_CALLS"
SERVICE
chmod +x "$TMP/vctl" "$TMP/services.d/mocksvc"
export VCTL_CALLS="$TMP/vctl-calls"
"$TMP/vctl" list | grep -qx mocksvc
"$TMP/vctl" start mocksvc
"$TMP/vctl" restart mocksvc
printf 'start\nstop\nstart\n' > "$TMP/expected-vctl"
diff -u "$TMP/expected-vctl" "$VCTL_CALLS"
if "$TMP/vctl" start '../mocksvc' >/dev/null 2>&1; then
  echo "vctl accepted a path traversal service name" >&2
  exit 1
fi

# Mock nft so firewall tests cannot modify the host firewall.
cat > "$TMP/bin/nft" <<'NFT'
#!/bin/sh
printf '%s\n' "$*" >> "$NFT_CALLS"
if [ "$1" = "-f" ]; then
  cat > "$NFT_RULES"
fi
NFT
chmod +x "$TMP/bin/nft"
export NFT_CALLS="$TMP/nft-calls" NFT_RULES="$TMP/nft-rules"
PATH="$TMP/bin:$PATH" VAMPIRE_SSH_PORT=2222 sh "$ROOT/rootfs-overlay/usr/bin/vguard" apply
grep -q 'tcp dport 2222 ct state new accept' "$NFT_RULES"
grep -q 'policy drop' "$NFT_RULES"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vguard" clear
grep -q 'delete table inet vampire_filter' "$NFT_CALLS"
if PATH="$TMP/bin:$PATH" VAMPIRE_SSH_PORT=70000 sh "$ROOT/rootfs-overlay/usr/bin/vguard" apply >/dev/null 2>&1; then
  echo "vguard accepted an invalid SSH port" >&2
  exit 1
fi

# Mock udhcpc; pass an explicit interface to avoid depending on host sysfs.
cat > "$TMP/bin/udhcpc" <<'DHCP'
#!/bin/sh
printf '%s\n' "$*" > "$DHCP_CALLS"
DHCP
chmod +x "$TMP/bin/udhcpc"
export DHCP_CALLS="$TMP/dhcp-calls"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" start test0
grep -q -- '-n -q -i test0' "$DHCP_CALLS"

echo "Vampire command integration tests passed."
