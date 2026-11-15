# Vampire Package Manager (vpm)

`vpm` is the experimental native package-management project for Vampire OS.
The current Python client is a developer prototype for signed repository
metadata, package discovery, HTTPS downloads, and SHA-256 payload verification.
It is not yet suitable for managing a real operating system.

## Implemented prototype commands

```sh
vpm update
vpm search firefox
vpm info firefox
vpm install firefox -y
vpm remove firefox
vpm list
```

The `install` command accepts `-y` / `--yes` for apt-style command
compatibility. The prototype currently has no interactive confirmation prompt,
so the flag does not bypass a prompt or add a new privilege mode.

Implemented: update, search, info, list, install, basic remove, signed index
verification, HTTPS-only downloads (including redirect downgrade rejection),
strict package name/version/digest/dependency metadata validation, SHA-256 payload
verification, dependency resolution, architecture checks, guarded archive
extraction, and basic installed-file ownership records.

Not implemented: upgrade, crash-safe multi-package transactions, conflict
resolution, shared-directory ownership, package triggers, repository key
rotation, or a production-grade sandbox.

## Prototype prerequisites

- Python 3.10+
- HTTPS access to a configured repository
- `minisign` for signed repository-index verification
- SHA-256 support from Python's standard library

Copy `vpm.example.json` to `/etc/vpm/vpm.json`, replace the example URL and
public key with values from a repository you control, and install the client:

```sh
sudo install -Dm755 vpm/vpm /usr/local/bin/vpm
sudo install -d -m755 /etc/vpm
sudo install -m644 vpm/vpm.example.json /etc/vpm/vpm.json
```

The example repository uses the reserved `.invalid` domain and cannot be used
to download packages. Do not point the client at an untrusted repository.

## Repository format

Each repository serves `index.json`, its detached
`index.json.minisig` signature, and package archives referenced by relative
HTTPS URLs. See [REPOSITORY-FORMAT.md](REPOSITORY-FORMAT.md) and
[REPOSITORY-BUILDER.md](REPOSITORY-BUILDER.md).

The local index builder creates repository metadata and can sign it with a
locally held Minisign key. It does not yet compile source packages or produce
reproducible package builds.

## Security and limitations

The client verifies signed indexes and package SHA-256 hashes, rejects unsafe
archive paths and special files, and does not execute package scripts. Removal
only deletes recorded regular files and refuses legacy records without a
trustworthy file manifest.

Package extraction rolls back files and directories created by a failed
extraction; a later package or installed-database failure also rolls back files
from earlier packages. The installed database is replaced atomically using a
private temporary file. Removal quarantines owned files beside their originals
and restores them if the database commit fails. These are bounded failure
recovery measures, not a crash-safe transaction journal: power loss during a
multi-package operation can still require manual recovery. The prototype does
not track shared-directory ownership, configuration-file modifications,
package triggers, or concurrent filesystem changes. Do not use it to manage a
production machine or host root filesystem. A native implementation and
security review are required before system integration.

Run `python3 vpm/doctor.py` to check local prerequisites. A warning is expected
until a real signed repository is configured.
