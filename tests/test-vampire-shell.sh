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
printf '%s\n' "${VAMPIRE_SHELL:-}" "${VAMPIRE_SHELL_VERSION:-}" > "$VSH_ENV"
MOCK
chmod +x "$TMP/bin/bash-mock"
export VSH_ARGS="$TMP/args" VSH_ENV="$TMP/env"
VAMPIRE_BASH_CMD="$TMP/bin/bash-mock" VAMPIRE_SHELL_RC="$TMP/etc/vampire/shellrc" "$VSH" -c 'printf test'
grep -qx -- '--noprofile' "$VSH_ARGS"
grep -qx -- '--rcfile' "$VSH_ARGS"
grep -qx -- '-c' "$VSH_ARGS"
grep -qx '1' "$VSH_ENV"
grep -qx '0.1.0-dev' "$VSH_ENV"
"$VSH" --version | grep -q 'Vampire Shell 0.1.0-dev'
"$VSH" --help | grep -q 'Bash as its execution engine'
if VAMPIRE_BASH_CMD="$TMP/missing" VAMPIRE_SHELL_RC="$TMP/etc/vampire/shellrc" "$VSH" -c true >/dev/null 2>&1; then
  echo "vsh accepted a missing Bash executable" >&2
  exit 1
fi
echo "Vampire Shell launcher tests passed."
