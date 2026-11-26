#!/bin/sh
# Exercise every interactive submenu entry point with harmless command stubs.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
LAUNCHER="$ROOT_DIR/rootfs-overlay/usr/bin/vdesktop"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cat > "$tmp/vsettings" <<'STUB'
#!/bin/sh
printf 'vsettings' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
cat > "$tmp/vnetwork" <<'STUB'
#!/bin/sh
printf 'vnetwork' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
cat > "$tmp/vinstall" <<'STUB'
#!/bin/sh
printf 'vinstall' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
if [ "$1" = media ]; then exit 0; fi
exit 0
STUB
cat > "$tmp/vctl" <<'STUB'
#!/bin/sh
printf 'vctl' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
cat > "$tmp/vlauncher" <<'STUB'
#!/bin/sh
printf 'vlauncher' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
cat > "$tmp/vdisplay" <<'STUB'
#!/bin/sh
printf 'vdisplay' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
cat > "$tmp/vpower" <<'STUB'
#!/bin/sh
printf 'vpower' >> "$VAMPIRE_TEST_LOG"
for arg do printf ' <%s>' "$arg" >> "$VAMPIRE_TEST_LOG"; done
printf '\\n' >> "$VAMPIRE_TEST_LOG"
exit 0
STUB
chmod +x "$tmp/"*
export VAMPIRE_TEST_LOG="$tmp/commands.log"
: > "$VAMPIRE_TEST_LOG"
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
run_case 2 '2\n1\ndark\n0\n0\n'
run_case 3 '3\n1\n0\n0\n'
run_case 7 '7\n\n0\n0\n'
run_case 22 '22\n1\n0\n0\n'
run_case 23 '23\n1\n0\n0\n'
run_case 25 '25\n\n0\n'
run_case 26 '26\n0\n0\n'
grep -Fq '26) Display connector inventory' "$tmp/output" || { echo 'FAIL: display diagnostics menu entry is not visible' >&2; exit 1; }
grep -Fq 'vnetwork <status>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: network status action was not dispatched' >&2; exit 1; }
grep -Fq 'vinstall <requirements>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: installer requirements action was not dispatched' >&2; exit 1; }
grep -Fq 'vinstall <system-check>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: installer system check was not dispatched' >&2; exit 1; }
grep -Fq 'vinstall <list>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: installer disk listing was not dispatched' >&2; exit 1; }
grep -Fq 'vsettings <set> <theme> <dark>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: appearance setting was not saved' >&2; exit 1; }
grep -Fq 'vsettings <apply>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: appearance changes were not applied' >&2; exit 1; }
grep -Fq 'vctl <list>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: service list action was not dispatched' >&2; exit 1; }
grep -Fq 'vlauncher' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: Vampire Launcher was not dispatched from the main menu' >&2; exit 1; }
grep -Fq 'vdisplay' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: display diagnostics were not dispatched from the main menu' >&2; exit 1; }
grep -Fq 'vpower <status>' "$VAMPIRE_TEST_LOG" || { echo 'FAIL: power status action was not dispatched' >&2; exit 1; }
echo 'PASS: Vampire Desktop submenu navigation and command dispatch regression tests'
