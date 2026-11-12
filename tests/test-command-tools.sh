#!/usr/bin/env bash
# Safe command-level tests. All external commands are mocked in a temp directory.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/services.d" "$TMP/sys/class/net/test0" "$TMP/run"

# Test vctl dispatch without touching the live system's service directory.
: # vctl uses isolated environment overrides below
cat > "$TMP/services.d/mocksvc" <<'SERVICE'
#!/bin/sh
printf '%s\n' "$1" >> "$VCTL_CALLS"
SERVICE
chmod +x "$TMP/services.d/mocksvc"
export VCTL_CALLS="$TMP/vctl-calls"
export VAMPIRE_SERVICE_DIR="$TMP/services.d"
export VAMPIRE_ENABLED_FILE="$TMP/services.enabled"
"$ROOT/rootfs-overlay/usr/bin/vctl" list | grep -q "mocksvc (disabled)"
"$ROOT/rootfs-overlay/usr/bin/vctl" start mocksvc
"$ROOT/rootfs-overlay/usr/bin/vctl" restart mocksvc
printf 'start\nstop\nstart\n' > "$TMP/expected-vctl"
diff -u "$TMP/expected-vctl" "$VCTL_CALLS"
if "$ROOT/rootfs-overlay/usr/bin/vctl" start '../mocksvc' >/dev/null 2>&1; then
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

# Mock udhcpc; pass an isolated interface tree so tests never touch host networking.
cat > "$TMP/bin/udhcpc" <<'DHCP'
#!/bin/sh
printf '%s\n' "$*" > "$DHCP_CALLS"
DHCP
chmod +x "$TMP/bin/udhcpc"
export DHCP_CALLS="$TMP/dhcp-calls"
PATH="$TMP/bin:$PATH" VAMPIRE_NETWORK_RUN_DIR="$TMP/run" VAMPIRE_SYS_NET="$TMP/sys/class/net" VAMPIRE_DHCP_HOOK="$ROOT/rootfs-overlay/usr/lib/vampire/udhcpc.script" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" start test0
grep -q -- '-R -b -i test0' "$DHCP_CALLS"
echo "Vampire command integration tests passed."
