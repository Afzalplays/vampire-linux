#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home" "$TMP/run/user/1000"
chmod 0700 "$TMP/run/user/1000"
cat > "$TMP/bin/id" <<'MOCK'
#!/bin/sh
case "$1" in
  -u) echo "${VAMPIRE_TEST_UID:-0}" ;;
  -un) echo "${VAMPIRE_TEST_USER:-root}" ;;
  *) exit 2 ;;
esac
MOCK
cat > "$TMP/bin/tty" <<'MOCK'
#!/bin/sh
echo "${VAMPIRE_TEST_TTY:-/dev/tty1}"
MOCK
cat > "$TMP/bin/stat" <<'MOCK'
#!/bin/sh
if [ "$1" = -c ] && [ "$2" = %u ]; then
  case "$3" in "$HOME"|*/user/1000) echo 1000; exit 0 ;; esac
fi
if [ "$1" = -c ] && [ "$2" = %a ] && [ "$3" = */user/1000 ]; then
  echo 700
  exit 0
fi
exit 1
MOCK
cat > "$TMP/bin/vgraphical" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$VGRAPHICAL_ARGS"
MOCK
chmod +x "$TMP/bin/"*
SCRIPT="$ROOT/rootfs-overlay/usr/bin/vdesktop-session"
sh -n "$SCRIPT"
"$SCRIPT" --help | grep -q 'unprivileged vampire account'
if VAMPIRE_GRAPHICAL_CMD="$TMP/bin/vgraphical" PATH="$TMP/bin:$PATH" "$SCRIPT" >"$TMP/root.out" 2>&1; then
  echo "desktop session accepted root" >&2; exit 1
fi
grep -q 'log in as the unprivileged vampire account' "$TMP/root.out"
test ! -e "$TMP/graphical.args"
VAMPIRE_TEST_UID=1000 VAMPIRE_TEST_USER=vampire \
VAMPIRE_GRAPHICAL_CMD="$TMP/bin/vgraphical" VAMPIRE_RUNTIME_BASE="$TMP/run/user" \
VGRAPHICAL_ARGS="$TMP/graphical.args" HOME="$TMP/home" PATH="$TMP/bin:$PATH" \
  "$SCRIPT" --check
grep -Fxq -- '--check' "$TMP/graphical.args"
if VAMPIRE_TEST_UID=1000 VAMPIRE_TEST_USER=vampire VAMPIRE_TEST_TTY=/dev/ttyS0 \
VAMPIRE_GRAPHICAL_CMD="$TMP/bin/vgraphical" VAMPIRE_RUNTIME_BASE="$TMP/run/user" \
HOME="$TMP/home" PATH="$TMP/bin:$PATH" "$SCRIPT" >/dev/null 2>&1; then
  echo "desktop session accepted a serial console" >&2; exit 1
fi
mkdir -p "$TMP/real-parent"
ln -s "$TMP/real-parent" "$TMP/runtime-parent-link"
if VAMPIRE_TEST_UID=1000 VAMPIRE_TEST_USER=vampire \
VAMPIRE_GRAPHICAL_CMD="$TMP/bin/vgraphical" VAMPIRE_RUNTIME_BASE="$TMP/runtime-parent-link/run/user" \
HOME="$TMP/home" PATH="$TMP/bin:$PATH" "$SCRIPT" >/dev/null 2>&1; then
  echo "desktop session accepted a symlinked runtime ancestor" >&2; exit 1
fi
echo "Vampire non-root graphical session tests passed."
