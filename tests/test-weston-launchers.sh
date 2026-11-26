#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP_LAUNCHER="$ROOT/rootfs-overlay/usr/bin/vampire-app"
test -x "$APP_LAUNCHER" || { echo "Missing tracked Vampire app launcher: $APP_LAUNCHER" >&2; ls -la "$ROOT/rootfs-overlay/usr/bin" >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/foot" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$FOOT_ARGS"
MOCK
cat > "$TMP/bin/app" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$APP_ARGS"
MOCK
cat > "$TMP/bin/terminal" <<'MOCK'
#!/bin/sh
echo terminal > "$TERMINAL_ARGS"
MOCK
chmod +x "$TMP/bin/"*

for app in launcher files settings software monitor; do
  FOOT_ARGS="$TMP/$app.args" PATH="$TMP/bin:$PATH" "$APP_LAUNCHER" "$app"
  case "$app" in
    launcher) grep -Fxq /usr/bin/vlauncher "$TMP/$app.args" ;;
    files) grep -Fxq /usr/bin/vfiles "$TMP/$app.args" ;;
    settings) grep -Fxq /usr/bin/vdesktop "$TMP/$app.args"; grep -Fxq -- --settings "$TMP/$app.args" ;;
    software) grep -Fxq /usr/bin/vsoftware "$TMP/$app.args" ;;
    monitor) grep -Fxq /usr/bin/vmonitor "$TMP/$app.args" ;;
  esac
done
if PATH="$TMP/bin:$PATH" "$APP_LAUNCHER" unknown >/dev/null 2>&1; then
  echo "Vampire app launcher accepted an unknown app" >&2; exit 1
fi
grep -q 'path=/usr/bin/vampire-terminal' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app launcher' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app files' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app settings' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app software' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'path=/usr/bin/vampire-app monitor' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"

LAUNCHER="$ROOT/rootfs-overlay/usr/bin/vlauncher"
sh "$LAUNCHER" --list > "$TMP/catalog"
grep -Fxq 'terminal|Terminal|Open Vampire Terminal' "$TMP/catalog"
grep -Fxq 'files|Files|Browse and manage files' "$TMP/catalog"
grep -q 'settings|Settings|Configure appearance' "$TMP/catalog"
sh "$LAUNCHER" --search Settings | grep -Fq 'settings|Settings|Configure appearance'
if sh "$LAUNCHER" --search no-such-app >/dev/null 2>&1; then
  echo "Vampire Launcher search returned a missing app" >&2; exit 1
fi
APP_ARGS="$TMP/app.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" --launch files
grep -Fxq files "$TMP/app.args"
TERMINAL_ARGS="$TMP/terminal.args" VAMPIRE_TERMINAL_CMD="$TMP/bin/terminal" sh "$LAUNCHER" --launch terminal
grep -q terminal "$TMP/terminal.args"
if VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" --launch nonexistent >/dev/null 2>&1; then
  echo "Vampire Launcher dispatched an unknown app" >&2; exit 1
fi
printf 'files\n0\n' | APP_ARGS="$TMP/menu.args" VAMPIRE_APP_CMD="$TMP/bin/app" sh "$LAUNCHER" > "$TMP/menu.out"
grep -q 'Enter an application ID to launch' "$TMP/menu.out"
grep -Fxq files "$TMP/menu.args"
echo "Vampire Weston desktop launcher tests passed."
