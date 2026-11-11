# Vampire OS Server edition

The Server edition uses a separate Buildroot defconfig and build output.
It is console-first and omits Weston to reduce the server image footprint.
It includes the shared Vampire command tools, VPM runtime, signed-update
metadata verifier, eudev and opt-in Dropbear SSH.

## Build

```sh
VAMPIRE_EDITION=server JOBS=2 bash build/build-live-iso.sh
VAMPIRE_EDITION=server bash scripts/test-live-iso.sh
```

The resulting image is named
`out/vampire-os-0.1.0-dev-server-x86_64.iso`.

SSH is not started automatically. It requires an administrator-installed
public key and is password-disabled when started with `vssh start`. The
current server image is still a live initramfs prototype, not an installable
persistent server distribution. Persistent host keys, non-root account
provisioning, firewall policy integration, server monitoring and recovery
remain future work.
