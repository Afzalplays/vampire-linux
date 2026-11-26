#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VSSH="$ROOT/rootfs-overlay/usr/bin/vssh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
sh -n "$VSSH"
grep -qi 'Password authentication and root login are disabled' "$VSSH"
grep -q '/var/lib/vampire/ssh/dropbear_ed25519_host_key' "$VSSH"
grep -q 'authorize vampire' "$VSSH"
grep -q 'BR2_PACKAGE_DROPBEAR=y' "$ROOT/build/vampire_server_defconfig"
mkdir -p "$TMP/bin" "$TMP/home/vampire"
printf 'vampire:x:1000:1000:Vampire User:%s/home/vampire:/bin/sh\n' "$TMP/" > "$TMP/passwd"

cat > "$TMP/bin/id" <<'MOCK'
#!/bin/sh
if [ "${1:-}" = -u ]; then echo 0; else exit 1; fi
MOCK
cat > "$TMP/bin/chown" <<'MOCK'
#!/bin/sh
exit 0
MOCK
cat > "$TMP/bin/pidof" <<'MOCK'
#!/bin/sh
exit 1
MOCK
cat > "$TMP/bin/dropbearkey" <<'MOCK'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  if [ "$1" = -f ]; then shift; printf 'TEST_HOST_KEY\n' > "$1"; exit 0; fi
  shift
done
exit 2
MOCK
cat > "$TMP/bin/dropbear" <<'MOCK'
#!/bin/sh
printf '%s\n' "$@" > "$DROPBEAR_ARGS"
MOCK
chmod +x "$TMP/bin/"*
export DROPBEAR_ARGS="$TMP/dropbear.args"
export VAMPIRE_PASSWD_FILE="$TMP/passwd"
export VAMPIRE_HOME_ROOT="$TMP/home"
export VAMPIRE_SSH_HOST_KEY="$TMP/var/lib/vampire/ssh/host_key"
export PATH="$TMP/bin:$PATH"
PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGV4YW1wbGUtdGVzdC1rZXktcGF5bG9hZA test-key'

# Regular users receive their own private .ssh directory and authorized_keys.
"$VSSH" authorize vampire "$PUBKEY"
test -d "$TMP/home/vampire/.ssh"
test "$(stat -c %a "$TMP/home/vampire/.ssh")" = 700
test "$(stat -c %a "$TMP/home/vampire/.ssh/authorized_keys")" = 600
grep -Fxq 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGV4YW1wbGUtdGVzdC1rZXktcGF5bG9hZA' "$TMP/home/vampire/.ssh/authorized_keys"

# Repeated authorization is idempotent; malformed and root onboarding are refused.
"$VSSH" authorize vampire "$PUBKEY"
test "$(wc -l < "$TMP/home/vampire/.ssh/authorized_keys")" -eq 1
if "$VSSH" authorize vampire 'ssh-rsa AAAA invalid' >/dev/null 2>&1; then
  echo "vssh accepted an unsupported SSH key type" >&2; exit 1
fi
if "$VSSH" authorize root "$PUBKEY" >/dev/null 2>&1; then
  echo "vssh allowed root SSH authorization" >&2; exit 1
fi

# Dropbear starts only with a regular user's key, using public-key-only mode
# and an explicit host key; the root-login prohibition remains enabled.
"$VSSH" start
grep -Fxq -- '-s' "$DROPBEAR_ARGS"
grep -Fxq -- '-g' "$DROPBEAR_ARGS"
grep -Fxq -- '-p' "$DROPBEAR_ARGS"
grep -Fxq -- '22' "$DROPBEAR_ARGS"
test -s "$VAMPIRE_SSH_HOST_KEY"
test "$(stat -c %a "$VAMPIRE_SSH_HOST_KEY")" = 600

# Symlinked SSH state must fail closed.
rm -rf "$TMP/home/vampire/.ssh"
ln -s "$TMP/outside" "$TMP/home/vampire/.ssh"
if "$VSSH" authorize vampire "$PUBKEY" >/dev/null 2>&1; then
  echo "vssh followed a symlinked .ssh directory" >&2; exit 1
fi

echo "Vampire SSH non-root onboarding, permissions, key validation and daemon policy tests passed."
