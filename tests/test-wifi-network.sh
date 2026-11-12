#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/sys/class/net/wlan0" "$TMP/run/dhcp" "$TMP/run/wifi" "$TMP/etc/vampire"
export VAMPIRE_SYS_NET="$TMP/sys/class/net"
export VAMPIRE_NETWORK_RUN_DIR="$TMP/run/dhcp"
export VAMPIRE_WIFI_RUN_DIR="$TMP/run/wifi"
export VAMPIRE_WIFI_CONFIG_DIR="$TMP/etc/vampire"
export VAMPIRE_DHCP_HOOK="$ROOT/rootfs-overlay/usr/lib/vampire/udhcpc.script"
export VAMPIRE_RESOLV_CONF="$TMP/resolv.conf"
export WPA_ARGS="$TMP/wpa-args" DHCP_ARGS="$TMP/dhcp-args" WPA_LOG="$TMP/wpa-log"
cat > "$TMP/bin/iw" <<'MOCK'
#!/bin/sh
case "$*" in
  dev) printf 'phy#0\n\tInterface wlan0\n' ;;
  'dev wlan0 scan') printf 'BSS aa:bb:cc:dd:ee:ff\n\t signal: -42.00 dBm\n\t SSID: Test Network\n' ;;
  *) exit 1 ;;
esac
MOCK
cat > "$TMP/bin/ifconfig" <<'MOCK'
#!/bin/sh
printf 'ifconfig %s\n' "$*" >> "$NETWORK_LOG"
MOCK
cat > "$TMP/bin/route" <<'MOCK'
#!/bin/sh
printf 'route %s\n' "$*" >> "$NETWORK_LOG"
MOCK
cat > "$TMP/bin/wpa_passphrase" <<'MOCK'
#!/bin/sh
IFS= read -r passphrase
printf 'network={\n ssid="%s"\n #psk="%s"\n psk=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\n}\n' "$1" "$passphrase"
MOCK
cat > "$TMP/bin/wpa_supplicant" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" > "$WPA_ARGS"
while [ "$#" -gt 0 ]; do
  case "$1" in -P) shift; printf '%s\n' "$$" > "$1" ;; esac
  shift
done
MOCK
cat > "$TMP/bin/wpa_cli" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" >> "$WPA_LOG"
case "$*" in
  *ping*) exit 1 ;;
  *status*) printf 'wpa_state=COMPLETED\nssid=Test Network\n' ;;
  *terminate*) printf 'OK\n' ;;
  *) exit 1 ;;
esac
MOCK
cat > "$TMP/bin/udhcpc" <<'MOCK'
#!/bin/sh
printf '%s\n' "$*" > "$DHCP_ARGS"
exit 0
MOCK
chmod +x "$TMP/bin/"*
export NETWORK_LOG="$TMP/network-log"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi list | grep -q wlan0
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi scan wlan0 | grep -q 'Test Network'
printf 'correcthorsebatterystaple\n' | PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi connect wlan0 'Test Network'
CONFIG="$TMP/etc/vampire/wpa_supplicant-wlan0.conf"
test -s "$CONFIG"
test "$(stat -c '%a' "$CONFIG")" = 600
grep -q 'ssid="Test Network"' "$CONFIG"
grep -q '^psk=0123456789abcdef' "$CONFIG"
! grep -q 'correcthorsebatterystaple' "$CONFIG"
! grep -q '#psk=' "$CONFIG"
grep -q -- '-B -i wlan0' "$WPA_ARGS"
grep -q -- '-R -b -i wlan0' "$DHCP_ARGS"
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi status wlan0 | grep -q 'wpa_state=COMPLETED'
if printf 'short\n' | PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi connect wlan0 'Test Network' >/dev/null 2>&1; then
  echo "Wi-Fi accepted a short WPA passphrase" >&2; exit 1
fi
PATH="$TMP/bin:$PATH" sh "$ROOT/rootfs-overlay/usr/bin/vnetwork" wifi disconnect wlan0
grep -q 'terminate' "$WPA_LOG"
echo "Vampire Wi-Fi scan, WPA2 connect and disconnect tests passed."
