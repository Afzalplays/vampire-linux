#!/bin/sh
# Exercise every interactive submenu entry point with harmless command stubs.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LAUNCHER="$ROOT_DIR/rootfs-overlay/usr/bin/vdesktop"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cat > "$tmp/vsettings" <<'STUB'
#!/bin/sh
exit 0
STUB
cat > "$tmp/vnetwork" <<'STUB'
#!/bin/sh
exit 0
STUB
cat > "$tmp/vinstall" <<'STUB'
#!/bin/sh
exit 0
STUB
cat > "$tmp/vctl" <<'STUB'
#!/bin/sh
exit 0
STUB
chmod +x "$tmp/"*
run_case() {
  menu_choice=$1
  input=$2
  output="$tmp/output"
  if ! printf '%b' "$input" | PATH="$tmp:/usr/bin:/bin" sh "$LAUNCHER" >"$output" 2>&1; then
    cat "$output" >&2
    echo "FAIL: launcher exited while opening submenu $menu_choice" >&2
    exit 1
  fi
  if grep -Eqi 'command not found|not found$|Invalid choice' "$output"; then
    cat "$output" >&2
    echo "FAIL: submenu $menu_choice did not dispatch cleanly" >&2
    exit 1
  fi
}
# Each submenu is entered, exited with 0, then the main launcher exits with 0.
run_case 2 '2\n0\n0\n'
run_case 3 '3\n0\n0\n'
run_case 7 '7\n\n\n0\n'
run_case 22 '22\n0\n0\n'
run_case 23 '23\n0\n0\n'
echo 'PASS: all Vampire Desktop console submenu entry points dispatch correctly'
