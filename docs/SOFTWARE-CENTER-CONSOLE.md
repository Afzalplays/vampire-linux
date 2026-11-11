# Vampire Software Center — console frontend

The live image includes `vsoftware`, a keyboard-driven frontend for VPM:

```sh
vsoftware
```

It supports signed-index refresh, search, package information, install,
removal and installed-package listing. Install and removal ask for explicit
confirmation. VPM still enforces its own root requirement and package checks.

This is a console frontend, not the planned graphical Software Center. The
image ships with no configured package repositories; package discovery and
network installs remain unavailable until a trusted Vampire repository and
Minisign key are published and configured.
