#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VSH="$ROOT/rootfs-overlay/usr/bin/vsh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/etc/vampire"
cp "$ROOT/rootfs-overlay/etc/vampire/shellrc" "$TMP/etc/vampire/shellrc"
cat > "$TMP/bin/bash-mock" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$VSH_ARGS"
printf '%s\n' "${VAMPIRE_SHELL:-}" "${VAMPIRE_SHELL_VERSION:-}" "${BASH_ENV:-}" > "$VSH_ENV"
MOCK
chmod +x "$TMP/bin/bash-mock"
export VSH_ARGS="$TMP/args" VSH_ENV="$TMP/env"
VAMPIRE_BASH_CMD="$TMP/bin/bash-mock" VAMPIRE_SHELL_RC="$TMP/etc/vampire/shellrc" "$VSH" -c 'printf test'
grep -qx -- '--noprofile' "$VSH_ARGS"
grep -qx -- '--rcfile' "$VSH_ARGS"
grep -qx -- '-c' "$VSH_ARGS"
grep -qx '1' "$VSH_ENV"
grep -qx '0.1.0-dev' "$VSH_ENV"
grep -qx "$TMP/etc/vampire/shellrc" "$VSH_ENV"
"$VSH" --version | grep -q 'Vampire Shell 0.1.0-dev'
"$VSH" --help | grep -q 'Bash as its execution engine'
if VAMPIRE_BASH_CMD="$TMP/missing" VAMPIRE_SHELL_RC="$TMP/etc/vampire/shellrc" "$VSH" -c true >/dev/null 2>&1; then
  echo "vsh accepted a missing Bash executable" >&2
  exit 1
fi
echo "Vampire Shell launcher tests passed."

# Exercise the real interactive profile and ensure programmable completion is
# loaded only in interactive mode, not merely present as an unreferenced file.
cp "$ROOT/rootfs-overlay/etc/vampire/completion.bash" "$TMP/completion.bash"
printf 'complete -p vpower\\nexit\\n' | \
  VAMPIRE_COMPLETION_FILE="$TMP/completion.bash" \
  VAMPIRE_HISTORY_FILE="$TMP/history" \
  bash --noprofile --rcfile "$TMP/etc/vampire/shellrc" -i >"$TMP/interactive.log" 2>&1
grep -Fq ' -F _vampire_complete vpower' "$TMP/interactive.log" || {
  cat "$TMP/interactive.log" >&2
  echo "interactive Vampire Shell did not load programmable completion" >&2
  exit 1
}
echo "Vampire Shell interactive completion profile test passed."
