# Vampire Package Manager (vpm)

`vpm` is the experimental native package-management project for Vampire OS.
The current Python client is a developer prototype to exercise repository
metadata, package discovery, HTTPS downloads, signature verification, and
SHA-256 payload verification. It is not yet suitable for managing a real OS.

## Planned user commands

```sh
vpm update
vpm search firefox
vpm info firefox
vpm install firefox
vpm upgrade
vpm remove firefox
vpm list
```

Only `update`, `search`, `info`, `install`, and `list` are currently
implemented. Upgrade and remove are intentionally not exposed until the package
database tracks exact installed file ownership and safe rollback.

## Prototype prerequisites

- Python 3
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

Each repository serves:

- `index.json`: JSON package catalogue
- `index.json.minisig`: detached minisign signature
- Package archives referenced by relative HTTPS URLs

See [REPOSITORY-FORMAT.md](REPOSITORY-FORMAT.md).

## Security and limitations

The client verifies signed indexes and package SHA-256 hashes, rejects unsafe
archive paths and special files, and does not execute package scripts. However,
it does not yet provide transactional installation, file ownership tracking,
uninstall, upgrades, conflict resolution, rollback, repository key rotation,
or a production-grade sandbox. Do not use it on a production machine or against
the host root filesystem. A native implementation and security review are
required before system integration.
