#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/sys/class/net/test0" "$TMP/run"
export VAMPIRE_SYS_NET="$TMP/sys/class/net"
export VAMPIRE_NETWORK_RUN_DIR="$TMP/run"
export VAMPIRE_DHCP_HOOK="$ROOT/rootfs-overlay/usr/lib/vampire/udhcpc.script"
export VAMPIRE_RESOLV_CONF="$TMP/resolv.conf"
cat > "$TMP/bin/udhcpc" <<'MOCK'
#!/bin/bash
if [[ "${1:-}" == "--daemon" ]]; then exec -a udhcpc sleep 60; fi
printf '%s\n' "$*" > "$DHCP_CALLS"
while [ "$#" -gt 0 ]; do
  case "$1" in
    -p) shift; "$0" --daemon >/dev/null 2>&1 & echo "$!" > "$1" ;;
  esac
  shift
done
MOCK
cat > "$TMP/bin/ifconfig" <<'MOCK'
#!/bin/sh
printf 'ifconfig %s\n' "$*" >> "$NETWORK_CALLS"
MOCK
cat > "$TMP/bin/ip" <<'MOCK'
#!/bin/sh
printf 'ip %s\n' "$*" >> "$NETWORK_CALLS"
MOCK
cat > "$TMP/bin/route" <<'MOCK'
#!/bin/sh
printf 'route %s\n' "$*" >> "$NETWORK_CALLS"
MOCK
chmod +x "$TMP/bin/"*
export DHCP_CALLS="$TMP/dhcp-calls" NETWORK_CALLS="$TMP/network-calls"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" start test0
grep -q -- '-R -b -i test0' "$DHCP_CALLS"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" status test0 | grep -q 'DHCP client: running'
PATH="$TMP/bin:$PATH" interface=test0 ip=192.0.2.25 subnet=255.255.255.0 router='192.0.2.1' dns='1.1.1.1 8.8.8.8' domain=example.test sh "$VAMPIRE_DHCP_HOOK" bound
grep -q '192.0.2.25' "$NETWORK_CALLS"
grep -q 'default gw 192.0.2.1' "$NETWORK_CALLS"
grep -q '^nameserver 1.1.1.1$' "$VAMPIRE_RESOLV_CONF"
grep -q '^nameserver 8.8.8.8$' "$VAMPIRE_RESOLV_CONF"
grep -q '^search example.test$' "$VAMPIRE_RESOLV_CONF"
if PATH="$TMP/bin:$PATH" interface=test0 ip='192.0.2.999' subnet=255.255.255.0 sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
  echo "DHCP hook accepted an invalid IPv4 address" >&2; exit 1
fi
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" stop test0
test ! -e "$VAMPIRE_RESOLV_CONF"
test ! -e "$TMP/run/test0.pid"
sleep 60 & unrelated_pid=$!
printf '%s\n' "$unrelated_pid" > "$TMP/run/test0.pid"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" stop test0
kill -0 "$unrelated_pid"
kill "$unrelated_pid"
printf '%s\n' 'nameserver 9.9.9.9' > "$VAMPIRE_RESOLV_CONF"
PATH="$TMP/bin:$PATH" interface=test0 sh "$VAMPIRE_DHCP_HOOK" deconfig
grep -q '^nameserver 9.9.9.9$' "$VAMPIRE_RESOLV_CONF"
echo "Vampire DHCP lifecycle and lease hook tests passed."
