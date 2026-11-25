#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/scripts" "$TMP/out" "$TMP/stage"
cp "$ROOT/scripts/test-rootfs-artifact.sh" "$TMP/scripts/"
base_paths=(
  etc/os-release sbin/init bin/busybox boot/vmlinuz
  usr/lib/vampire/stage-rootfs.py usr/lib/vampire/configure-installed-root.py
)
desktop_paths=(
  usr/bin/vsettings usr/lib/vampire/settings_apply.py
  usr/lib/vampire/settings-bootstrap etc/vampire/settings.defaults
  etc/xdg/weston/weston.ini etc/xdg/foot/foot.ini
  usr/bin/vdesktop usr/bin/vgraphical usr/bin/vampire-app
  usr/bin/vampire-terminal
)
make_archive() {
  local edition="$1"
  local -a paths=("${base_paths[@]}")
  if [[ "$edition" == desktop ]]; then paths+=("${desktop_paths[@]}"); fi
  mkdir -p "$TMP/stage"
  local path
  for path in "${paths[@]}"; do
    mkdir -p "$TMP/stage/$(dirname "$path")"
    : > "$TMP/stage/$path"
  done
  tar -cf "$TMP/out/vampire-os-0.1.0-dev-$edition-x86_64-rootfs.tar" -C "$TMP/stage" .
  (cd "$TMP/out" && sha256sum "vampire-os-0.1.0-dev-$edition-x86_64-rootfs.tar" > "vampire-os-0.1.0-dev-$edition-x86_64-rootfs.tar.sha256")
}
make_archive desktop
(
  cd "$TMP"
  bash scripts/test-rootfs-artifact.sh
)
rm -f "$TMP/stage/usr/bin/vampire-app"
tar -cf "$TMP/out/vampire-os-0.1.0-dev-desktop-x86_64-rootfs.tar" -C "$TMP/stage" .
(cd "$TMP/out" && sha256sum "vampire-os-0.1.0-dev-desktop-x86_64-rootfs.tar" > "vampire-os-0.1.0-dev-desktop-x86_64-rootfs.tar.sha256")
if (cd "$TMP" && bash scripts/test-rootfs-artifact.sh) >"$TMP/missing.out" 2>&1; then
  echo "Desktop artifact validator accepted a missing graphical app launcher" >&2
  exit 1
fi
grep -Fq 'usr/bin/vampire-app' "$TMP/missing.out"
make_archive server
(
  cd "$TMP"
  VAMPIRE_EDITION=server bash scripts/test-rootfs-artifact.sh
)
echo "Rootfs artifact edition and Desktop payload contract tests: PASS"
