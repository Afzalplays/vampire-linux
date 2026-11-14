#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/vgraphical" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$VGRAPHICAL_ARGS"
MOCK
chmod +x "$TMP/bin/vgraphical"
printf '24\n\n0\n' | VGRAPHICAL_ARGS="$TMP/args" PATH="$TMP/bin:$PATH" "$ROOT/rootfs-overlay/usr/bin/vdesktop" > "$TMP/output"
grep -q '24) Graphical session preflight' "$TMP/output"
grep -Fxq -- '--check' "$TMP/args"
echo "Vampire Desktop graphical diagnostics menu test passed."
