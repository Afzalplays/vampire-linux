#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/sys/class/net/test0" "$TMP/run" "$TMP/proc"
export VAMPIRE_SYS_NET="$TMP/sys/class/net"
export VAMPIRE_NETWORK_RUN_DIR="$TMP/run"
export VAMPIRE_PROC_ROOT="$TMP/proc"
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
export PATH="$TMP/bin:$PATH"
export DHCP_CALLS="$TMP/dhcp-calls" NETWORK_CALLS="$TMP/network-calls"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" start test0
grep -Fq 'ip link set dev test0 up' "$NETWORK_CALLS"
grep -q -- '-R -b -i test0' "$DHCP_CALLS"
dhcp_pid="$(cat "$TMP/run/test0.pid")"
mkdir -p "$TMP/proc/$dhcp_pid"
printf 'udhcpc\\0-b\\0-i\\0test0\\0' > "$TMP/proc/$dhcp_pid/cmdline"
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

# A subnet mask must be a contiguous prefix, not merely four in-range octets.
before_calls="$(wc -l < "$NETWORK_CALLS")"
for invalid_mask in 255.0.255.0 255.255.255.1 255.255.255.256; do
  if PATH="$TMP/bin:$PATH" interface=test0 ip=192.0.2.25 subnet="$invalid_mask" sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
    echo "DHCP hook accepted non-contiguous or out-of-range subnet mask: $invalid_mask" >&2; exit 1
  fi
done
after_calls="$(wc -l < "$NETWORK_CALLS")"
test "$before_calls" = "$after_calls"

before_calls="$(wc -l < "$NETWORK_CALLS")"
if PATH="$TMP/bin:$PATH" interface=test0 ip=192.0.2.25 subnet=255.255.255.0 router='192.0.2.999' sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
  echo "DHCP hook accepted an invalid router address" >&2; exit 1
fi
after_calls="$(wc -l < "$NETWORK_CALLS")"
test "$before_calls" = "$after_calls"

before_calls="$(wc -l < "$NETWORK_CALLS")"
if PATH="$TMP/bin:$PATH" interface=test0 ip=192.0.2.25 subnet=255.255.255.0 dns='1.1.1.1 8.8.8.999' sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
  echo "DHCP hook accepted an invalid DNS address" >&2; exit 1
fi
after_calls="$(wc -l < "$NETWORK_CALLS")"
test "$before_calls" = "$after_calls"

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
# DHCP must not follow a resolver-file symlink or overwrite its target.
printf '%s\n' 'nameserver 4.4.4.4' > "$TMP/resolver-target"
ln -s "$TMP/resolver-target" "$TMP/resolver-link"
if PATH="$TMP/bin:$PATH" VAMPIRE_RESOLV_CONF="$TMP/resolver-link" interface=test0 ip=192.0.2.25 subnet=255.255.255.0 sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
  echo "DHCP hook followed a symlinked resolver file" >&2; exit 1
fi
grep -q '^nameserver 4.4.4.4$' "$TMP/resolver-target"
rm -f "$TMP/resolver-link"
mkdir "$TMP/real-resolver-dir"
ln -s "$TMP/real-resolver-dir" "$TMP/resolver-dir-link"
if PATH="$TMP/bin:$PATH" VAMPIRE_RESOLV_CONF="$TMP/resolver-dir-link/resolv.conf" interface=test0 ip=192.0.2.25 subnet=255.255.255.0 sh "$VAMPIRE_DHCP_HOOK" bound >/dev/null 2>&1; then
  echo "DHCP hook followed a symlinked resolver directory" >&2; exit 1
fi
test ! -e "$TMP/real-resolver-dir/resolv.conf"
echo "Vampire DHCP lifecycle and lease hook tests passed."
