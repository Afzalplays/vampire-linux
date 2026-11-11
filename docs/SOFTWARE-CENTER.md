# Vampire Software Center and application ecosystem

## Product goal

Vampire OS should make software discovery and installation straightforward for desktop and server users. The official experience will combine a graphical **Vampire Software Center** with the terminal **Vampire Package Manager (vpm)**. Both clients use the same signed repository metadata and package trust policy.

This is a target design, not a claim that the store or full package ecosystem is already implemented.

## Application catalogue

The catalogue is organized by category and supported edition:

- Internet: web browsers, mail clients, download tools, VPN clients
- Office and productivity: documents, spreadsheets, PDF tools, notes
- Graphics and media: image editors, video editors, audio tools, players
- Development: editors, IDEs, compilers, SDKs, Git, containers, databases
- Games: game launchers, compatibility tools, emulators where legally distributable
- System: file managers, archive tools, backup, disk and hardware utilities
- Networking: SSH, remote administration, diagnostics, monitoring
- Security: firewall management, audit, malware scanning, cryptography and privacy utilities
- Server: web servers, databases, caches, runtimes, control-plane and observability tools
- Drivers and firmware: hardware-specific packages with explicit provenance and compatibility metadata

The catalogue must show package description, publisher/maintainer, version, supported architectures and editions, permissions, source/license, download size, dependencies, update channel, and security status. Do not promise that every third-party application is available; availability depends on upstream licensing, source availability, architecture, and maintainer review.

## Package sources and build pipeline

1. Prefer building from upstream source with reproducible recipes.
2. Record upstream project, exact source revision, checksums, license, patches, build dependencies and build instructions.
3. Produce package archives plus an SBOM and provenance attestation.
4. Run static analysis, malware scanning where appropriate, package policy checks, and isolated build tests.
5. Sign repository indexes and release metadata; verify package hashes before installation.
6. Publish to stable, testing and community channels with clear maintainer ownership.
7. Promote testing packages only after automated and hardware testing.

No package should silently import another Linux distribution's binary package database or runtime assumptions. Third-party binary applications may be offered only as clearly labelled compatibility packages, isolated where practical and with their own license terms.

## Installation and system safety

The production design requires dependency resolution, exact file ownership, conflict detection, atomic transactions, rollback, update recovery, disk-space checks, and auditable logs. System packages and user-scoped applications must be distinguishable. GUI installs must use a privileged helper with narrow, authenticated requests; the GUI itself must never run as root.

Package scripts are not trusted merely because a repository is signed. Prefer declarative install actions and tightly constrained hooks in an isolated environment. Enforce signature verification, least privilege, sandboxing, and explicit permission prompts.

## Planned user experience

```sh
vpm update
vpm search browser
vpm install firefox
vpm upgrade
vpm remove firefox
vpm history
```

The current VPM prototype does not yet implement all these commands and is not safe for production installation. See [the prototype status](../vpm/README.md).
