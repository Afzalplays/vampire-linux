#!/usr/bin/env bash
# Contract tests for the user-facing Vampire Fetch output.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="$(bash "$ROOT_DIR/fetch/vfetch")"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
contains() { grep -Fq -- "$1" <<<"$OUTPUT" || fail "missing output: $1"; }

contains 'V A M P I R E'
contains 'O S'
contains '@vampire-os'
contains '────────────────────────────────────────'
contains '●'

previous=0
for field in \
  'OS:' 'Host:' 'Kernel:' 'Uptime:' 'Packages:' 'Shell:' 'Display:' \
  'DE:' 'WM:' 'Theme:' 'Terminal:' 'CPU:' 'GPU:' 'Memory:' 'Local IP:' 'Locale:'; do
  line="$(grep -n -m1 -F "$field" <<<"$OUTPUT" | cut -d: -f1)"
  [[ -n "$line" ]] || fail "missing system field: $field"
  (( line > previous )) || fail "system fields are out of order at: $field"
  previous="$line"
done

# The fetch command must remain usable when optional desktop/session variables
# are absent, as is normal on a text-only Server installation.
MINIMAL_OUTPUT="$(env -u WAYLAND_DISPLAY -u DISPLAY -u XDG_CURRENT_DESKTOP \
  -u XDG_SESSION_DESKTOP -u XDG_SESSION_TYPE -u GTK_THEME -u TERM_PROGRAM \
  bash "$ROOT_DIR/fetch/vfetch")"
grep -Fq 'OS:' <<<"$MINIMAL_OUTPUT" || fail 'minimal environment lost OS field'
grep -Fq 'Locale:' <<<"$MINIMAL_OUTPUT" || fail 'minimal environment lost Locale field'

# The same binary must identify the headless Server edition from image metadata.
SERVER_CONF="$(mktemp)"
trap 'rm -f "$SERVER_CONF"' EXIT
printf 'EDITION="server"\n' > "$SERVER_CONF"
SERVER_OUTPUT="$(VAMPIRE_OS_CONF="$SERVER_CONF" bash "$ROOT_DIR/fetch/vfetch")"
grep -Fq 'Host:       Vampire Server' <<<"$SERVER_OUTPUT" || fail 'Server edition reported the wrong host'
grep -Fq 'DE:         None (headless)' <<<"$SERVER_OUTPUT" || fail 'Server edition reported a desktop environment'

printf 'PASS: VFetch branding, field order and headless fallback\n'
