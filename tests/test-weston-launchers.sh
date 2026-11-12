#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/foot" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$FOOT_ARGS"
MOCK
chmod +x "$TMP/bin/foot"
for app in files settings software; do
  FOOT_ARGS="$TMP/$app.args" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vampire-app" "$app"
  case "$app" in
    files) grep -Fxq /usr/bin/vfiles "$TMP/$app.args" ;;
    settings) grep -Fxq /usr/bin/vdesktop "$TMP/$app.args" ;;
    software) grep -Fxq /usr/bin/vsoftware "$TMP/$app.args" ;;
  esac
done
if PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vampire-app" unknown >/dev/null 2>&1; then
  echo "Vampire app launcher accepted an unknown app" >&2; exit 1
fi
grep -q 'path=/usr/bin/vampire-terminal' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app files' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app settings' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app software' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
echo "Vampire Weston desktop launcher tests passed."
