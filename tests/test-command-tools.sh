#!/usr/bin/env bash
# Safe command-level tests. All external commands are mocked in a temp directory.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/services.d" "$TMP/sys/class/net/test0" "$TMP/run"

# Test vctl dispatch without touching the live system's service directory.
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
ln -s "$TMP/external-service" "$TMP/services.d/linkedsvc"
cat > "$TMP/external-service" <<'SERVICE'
#!/bin/sh
echo executed > "$VCTL_EXTERNAL_MARKER"
SERVICE
chmod +x "$TMP/external-service"
export VCTL_EXTERNAL_MARKER="$TMP/external-marker"
if "$ROOT/rootfs-overlay/usr/bin/vctl" start linkedsvc >/dev/null 2>&1; then
  echo "vctl executed a symlinked service entry" >&2
  exit 1
fi
test ! -e "$VCTL_EXTERNAL_MARKER"

# Service enablement state must never follow a symlink or write through a symlinked parent.
printf 'mocksvc\n' > "$TMP/external-enabled"
ln -s "$TMP/external-enabled" "$TMP/enabled-link"
if VAMPIRE_ENABLED_FILE="$TMP/enabled-link" "$ROOT/rootfs-overlay/usr/bin/vctl" enable mocksvc >/dev/null 2>&1; then
  echo "vctl accepted a symlinked enabled-state file" >&2
  exit 1
fi
mkdir "$TMP/state-real"
ln -s "$TMP/state-real" "$TMP/state-link"
if VAMPIRE_ENABLED_FILE="$TMP/state-link/enabled" "$ROOT/rootfs-overlay/usr/bin/vctl" enable mocksvc >/dev/null 2>&1; then
  echo "vctl accepted a symlinked enabled-state directory" >&2
  exit 1
fi
grep -qx mocksvc "$TMP/external-enabled"

# Mock nft so firewall tests cannot modify the host firewall.
cat > "$TMP/bin/nft" <<'NFT'
#!/bin/sh
printf '%s\n' "$*" >> "$NFT_CALLS"
if [ "$1" = "-c" ] && [ "$2" = "-f" ]; then
  printf '%s\n' 'validated' >> "$NFT_CALLS"
  test -s "$3"
elif [ "$1" = "-f" ]; then
  cat "$2" > "$NFT_RULES"
fi
NFT
chmod +x "$TMP/bin/nft"
export NFT_CALLS="$TMP/nft-calls" NFT_RULES="$TMP/nft-rules"
PATH="$TMP/bin:$PATH" VAMPIRE_SSH_PORT=2222 VAMPIRE_FIREWALL_RUN_DIR="$TMP/run" sh "$ROOT/rootfs-overlay/usr/bin/vguard" apply
grep -q 'tcp dport 2222 ct state new accept' "$NFT_RULES"
grep -q '^-c -f ' "$NFT_CALLS"
grep -q 'policy drop' "$NFT_RULES"
PATH="$TMP/bin:$PATH" VAMPIRE_FIREWALL_RUN_DIR="$TMP/run" sh "$ROOT/rootfs-overlay/usr/bin/vguard" clear
grep -q 'delete table inet vampire_filter' "$NFT_CALLS"
if PATH="$TMP/bin:$PATH" VAMPIRE_FIREWALL_RUN_DIR="$TMP/run" VAMPIRE_SSH_PORT=70000 sh "$ROOT/rootfs-overlay/usr/bin/vguard" apply >/dev/null 2>&1; then
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
