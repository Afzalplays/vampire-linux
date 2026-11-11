# Vampire OS

An independent, open-source Linux operating system assembled from upstream
source code by VampireNodes. The project targets x86_64 and is developed as two
editions: Vampire Desktop and Vampire Server.

<sub><strong>Status:</strong> Experimental development — not ready for production.</sub>

## Identity

- **Operating system:** Vampire OS
- **Desktop environment:** Vampire Desktop (planned)
- **Shell:** Vampire Shell (planned)
- **Fetch utility:** [Vampire Fetch](fetch/README.md) — `vfetch`
- **Architecture:** x86_64 / AMD64
- **Editions:** Desktop and Server

## Vampire Fetch

Run the custom system-information display from the repository:

```sh
bash fetch/vfetch
```

Install it locally:

```sh
sudo install -Dm755 fetch/vfetch /usr/local/bin/vfetch
vfetch
```

The fetch utility displays the Vampire castle-and-V emblem, OS metadata, kernel,
CPU, GPU, memory, package count, uptime, and other host details.

## Project documentation

- [Product and engineering blueprint](docs/PRODUCT-BLUEPRINT.md)
- [Desktop UX specification](docs/DESKTOP-UX-SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Package management design](docs/PACKAGE-MANAGEMENT.md)
- [Software Center and app ecosystem](docs/SOFTWARE-CENTER.md)
- [Remote Desktop / RDP security design](docs/REMOTE-DESKTOP.md)
- [OS security baseline](docs/SECURITY-BASELINE.md)
- [Vampire Package Manager prototype](vpm/README.md)
- [VPM repository builder](vpm/REPOSITORY-BUILDER.md)
- [Development roadmap](docs/ROADMAP.md)
- [Third-party licensing policy](docs/LICENSING.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)

## Development status

This repository is an experimental development scaffold. A reproducible
bootable ISO, installer, package manager, desktop environment, update mechanism,
and supported hardware matrix are not yet complete. See the roadmap for the
current work breakdown.

## Independence and upstream sources

The target operating system is not intended to be based on Debian, Ubuntu,
Arch, Fedora, or another distribution. A host Linux distribution may be used
to provide build tools only; it is not the target runtime base. Upstream
components retain their own licenses and notices.
