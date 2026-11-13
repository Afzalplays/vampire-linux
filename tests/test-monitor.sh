#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/proc" "$TMP/sys/class/thermal/thermal_zone0" "$TMP/bin"
printf '123456.0 120000.0\n' > "$TMP/proc/uptime"
printf '0.12 0.34 0.56 1/99 1234\n' > "$TMP/proc/loadavg"
cat > "$TMP/proc/meminfo" <<'MEM'
MemTotal:       8192000 kB
MemFree:        2048000 kB
Buffers:         512000 kB
Cached:         1024000 kB
MEM
printf '42000\n' > "$TMP/sys/class/thermal/thermal_zone0/temp"
cat > "$TMP/bin/hostname" <<'HOST'
#!/bin/sh
echo vampire-test
HOST
cat > "$TMP/bin/uname" <<'UNAME'
#!/bin/sh
echo 6.1-vampire
UNAME
cat > "$TMP/bin/df" <<'DF'
#!/bin/sh
printf 'Filesystem Size Used Avail Use%% Mounted on\n'
printf '/dev/root 10G 2G 8G 20%% /\n'
DF
chmod +x "$TMP/bin/"*
output=$(PATH="$TMP/bin:/usr/bin:/bin" VAMPIRE_PROC_ROOT="$TMP/proc" VAMPIRE_SYS_ROOT="$TMP/sys" sh "$ROOT/rootfs-overlay/usr/bin/vmonitor" --once)
grep -q 'VAMPIRE MONITOR' <<< "$output"
grep -q 'vampire-test' <<< "$output"
grep -q '6.1-vampire' <<< "$output"
grep -q 'Uptime: 1d 10h 17m' <<< "$output"
grep -q 'Load:   0.12 0.34 0.56' <<< "$output"
grep -q 'Memory: 4500 MiB used / 8000 MiB total (56%)' <<< "$output"
grep -q 'Available memory: 3500 MiB' <<< "$output"
grep -q 'Temperature (thermal_zone0): 42.0 C' <<< "$output"
grep -q '/dev/root 10G 2G 8G 20%' <<< "$output"
if sh "$ROOT/rootfs-overlay/usr/bin/vmonitor" --watch 0 >/dev/null 2>&1; then
  echo 'vmonitor accepted an invalid refresh interval' >&2; exit 1
fi
if sh "$ROOT/rootfs-overlay/usr/bin/vmonitor" unexpected >/dev/null 2>&1; then
  echo 'vmonitor accepted an unknown option' >&2; exit 1
fi
echo 'Vampire monitor telemetry tests passed.'
