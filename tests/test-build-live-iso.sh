#!/usr/bin/env bash
# Verify the live ISO builder rejects invalid edition values before touching output.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
log="$WORK/build.log"
set +e
VAMPIRE_EDITION=invalid \
VAMPIRE_BUILD_DIR="$WORK/build" \
VAMPIRE_OUTPUT_DIR="$WORK/out" \
bash "$ROOT_DIR/build/build-live-iso.sh" >"$log" 2>&1
status=$?
set -e
[[ "$status" -eq 2 ]] || {
  cat "$log" >&2
  printf 'Expected invalid edition to exit 2, got %s\n' "$status" >&2
  exit 1
}
grep -Fq 'VAMPIRE_EDITION must be desktop or server' "$log"
[[ ! -e "$WORK/build" && ! -e "$WORK/out" ]] || {
  printf 'Invalid edition created build/output directories\n' >&2
  exit 1
}
printf 'PASS: invalid edition is rejected before creating build outputs\n'

# The release used for both editions must be explicit and verified. This guards
# against silently building from a stale checkout left in a CI cache.
BUILDER="$ROOT_DIR/build/build-live-iso.sh"
grep -Fq 'BUILDROOT_VERSION="${BUILDROOT_VERSION:-2025.02}"' "$BUILDER"
grep -Fq 'git check-ref-format "refs/tags/$BUILDROOT_VERSION"' "$BUILDER"
grep -Fq 'git clone --depth 1 --branch "$BUILDROOT_VERSION"' "$BUILDER"
grep -Fq 'git -C "$BUILD_DIR/buildroot" fetch --depth 1 origin' "$BUILDER"
grep -Fq 'git -C "$BUILD_DIR/buildroot" checkout --detach "$BUILDROOT_VERSION"' "$BUILDER"
grep -Fq 'ACTUAL_BUILDROOT_VERSION="$(git -C "$BR_DIR" describe --tags --exact-match HEAD' "$BUILDER"
grep -Fq '[[ "$ACTUAL_BUILDROOT_VERSION" == "$BUILDROOT_VERSION" ]]' "$BUILDER"
# Desktop session entry points are invoked directly at boot/login; keep their
# executable mode explicit instead of relying on the checkout's file mode.
grep -Fq '"$OVERLAY/usr/bin/vdesktop-session" "$OVERLAY/usr/lib/vampire/settings-bootstrap"' "$BUILDER"
grep -Fq '"$OVERLAY/usr/lib/vampire/session-runtime"' "$BUILDER"
grep -Fq 'export VAMPIRE_EDITION="$EDITION"' "$BUILDER"
grep -Fq 'export VAMPIRE_ROOTFS_OVERLAY="$OVERLAY"' "$BUILDER"
grep -Fq 'install_desktop_session_runtime(target)' "$ROOT_DIR/scripts/post-build-vampire.py"
printf 'PASS: ISO builder pins and verifies the exact Buildroot release tag\\n'
printf 'PASS: ISO builder explicitly installs executable desktop session tools\\n'
