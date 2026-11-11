# Vampire OS package management

Vampire OS will use its own package ecosystem: **Vampire Package Manager
(`vpm`)**. It is intended to provide the workflows users expect from apt,
dnf, pacman, and winget without inheriting another distribution's package
database or package format.

## User experience target

```sh
vpm update
vpm search firefox
vpm info firefox
vpm install firefox
vpm upgrade
vpm remove firefox
vpm list
```

The first prototype implements only update, search, info, install, and list.
Upgrade and remove must wait until exact file ownership and rollback are
implemented.

## Architecture

1. **Repository metadata:** versioned JSON catalogue, signed with minisign.
2. **Transport:** HTTPS only.
3. **Package artifacts:** versioned tar archives with a strict path policy.
4. **Integrity:** SHA-256 digest per package; repository signature authenticates
   the catalogue and its expected hashes.
5. **Dependency resolution:** explicit dependency graph; detect missing packages
   and cycles before installation.
6. **Installed database:** records package versions; file ownership tracking is
   required before safe removal or upgrade.
7. **Build service:** reproducible recipes build packages from upstream source.
8. **Trust:** public signing keys are distributed with trusted OS images and
   rotated through a documented trust process.

## Non-negotiable security requirements

- Never accept unsigned or invalid repository metadata.
- Never use HTTP for repository or package downloads.
- Verify package hashes before unpacking.
- Reject archive path traversal and unexpected file types.
- Do not execute arbitrary install scripts as root.
- Keep package operations transactional, recoverable, and auditable.
- Provide source provenance, license notices, and an SBOM.

## Current implementation status

The Python client in [vpm/](../vpm/README.md) is an experimental prototype,
not a production package manager. It currently lacks atomic transactions,
file ownership, safe removal, upgrade, conflict handling, rollback, and a
native minimal-system implementation. It must not be used to modify a
production host.
