#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/foot" <<'MOCK'
#!/bin/sh
printf 'SHELL=%s\nTERM=%s\n' "$SHELL" "$TERM" > "$FOOT_ENV"
printf '%s\n' "$@" > "$FOOT_ARGS"
MOCK
chmod +x "$TMP/bin/foot"
FOOT_ENV="$TMP/env" FOOT_ARGS="$TMP/args" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vampire-terminal" --title Vampire
grep -Fxq 'SHELL=/usr/bin/vsh' "$TMP/env"
grep -Fxq 'TERM=xterm-256color' "$TMP/env"
grep -Fxq -- '--title' "$TMP/args"
grep -Fxq Vampire "$TMP/args"
grep -q 'path=/usr/bin/vampire-terminal' "$ROOT/rootfs-overlay/etc/xdg/weston/weston.ini"
grep -q 'font=DejaVu Sans Mono' "$ROOT/rootfs-overlay/etc/xdg/foot/foot.ini"
echo "Vampire Wayland terminal integration tests passed."
