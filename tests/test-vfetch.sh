#!/usr/bin/env bash
# Contract tests for the user-facing Vampire Fetch output.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
shebang="$(head -n 1 "$ROOT_DIR/fetch/vfetch")"
[[ "$shebang" == "#!/bin/bash" ]] || { printf 'FAIL: installed VFetch requires a direct /bin/bash interpreter, got: %s\\n' "$shebang" >&2; exit 1; }
OUTPUT="$(bash "$ROOT_DIR/fetch/vfetch")"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
contains() { grep -Fq -- "$1" <<<"$OUTPUT" || fail "missing output: $1"; }

contains 'V A M P I R E'
contains 'O S'
contains '@vampire-os'
contains '────────────────────────────────────────'
contains '●'

# VFetch must not need writable temporary storage (the installed-disk
# inspection runs it against a read-only root filesystem).
UNWRITABLE_TMP="$(mktemp -d)"
chmod 500 "$UNWRITABLE_TMP"
trap 'chmod 700 "$UNWRITABLE_TMP"; rmdir "$UNWRITABLE_TMP"' EXIT
READONLY_TMP_OUTPUT="$(TMPDIR="$UNWRITABLE_TMP" bash "$ROOT_DIR/fetch/vfetch")"
grep -Fq 'V A M P I R E' <<<"$READONLY_TMP_OUTPUT" || fail 'VFetch failed without writable temporary storage'

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

# The installed database is a top-level package-name mapping. Verify that
# VFetch reports its number of entries instead of looking for a nested field.
PACKAGE_DB="$(mktemp)"
trap 'rm -f "$SERVER_CONF" "$PACKAGE_DB"' EXIT
printf '{"vfetch":{"version":"0.1"},"vpm":{"version":"0.1"},"vsh":{"version":"0.1"}}\n' > "$PACKAGE_DB"
PACKAGE_OUTPUT="$(VAMPIRE_VPM_DB="$PACKAGE_DB" bash "$ROOT_DIR/fetch/vfetch")"
grep -Fq 'Packages:   3' <<<"$PACKAGE_OUTPUT" || fail 'VFetch did not count installed VPM packages'

printf 'PASS: VFetch branding, field order and headless fallback\n'
