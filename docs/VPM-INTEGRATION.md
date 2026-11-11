# VPM in the live image

The development image includes the VPM Python client and its doctor command:

```sh
vpm --version
vpm list
vpm doctor
```

The image ships `/etc/vpm/vpm.json` with an empty repository list. There is no
production Vampire package repository or signing key yet. Network package
operations therefore refuse to proceed until an administrator configures a
trusted repository URL and Minisign public key.

Python 3, TLS support, zlib and Minisign are included in Buildroot. VPM remains
experimental: it is not transactional, has no rollback and must not be used
to update the running OS or a production server.
