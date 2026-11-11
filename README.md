# Vampire OS

An independent, open-source Linux operating system assembled from upstream
source code by VampireNodes. The project targets x86_64 and is developed as two
editions: Vampire Desktop and Vampire Server.

<sub><strong>Status:</strong> Experimental development — not ready for production.</sub>

## Identity

- **Operating system:** Vampire OS
- **Desktop environment:** Vampire Desktop (graphical shell planned; console launcher MVP available as `vdesktop`)
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
- [Server edition](docs/SERVER-EDITION.md)
- [Desktop UX specification](docs/DESKTOP-UX-SPEC.md)
- [Settings, voice, updates and boot specification](docs/SETTINGS-VOICE-UPDATES-BOOT.md)
- [Voice Access design](docs/VOICE-ACCESS.md)
- [BIOS/UEFI installer and recovery design](docs/BOOT-INSTALLER-RECOVERY.md)
- [Settings defaults](docs/SETTINGS-DEFAULTS.md)
- [Console tools guide](docs/CONSOLE-TOOLS.md)
- [Vampire Files console manager](docs/FILES-CONSOLE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Package management design](docs/PACKAGE-MANAGEMENT.md)
- [Software Center and app ecosystem](docs/SOFTWARE-CENTER.md)
- [Software Center console frontend](docs/SOFTWARE-CENTER-CONSOLE.md)
- [Remote Desktop / RDP security design](docs/REMOTE-DESKTOP.md)
- [OS security baseline](docs/SECURITY-BASELINE.md)
- [Vampire Package Manager prototype](vpm/README.md)
- [VPM live-image integration](docs/VPM-INTEGRATION.md)
- [Signed update metadata MVP](docs/SECURE-UPDATES-MVP.md)
- [Graphical session bring-up](docs/GRAPHICAL-SESSION.md)
- [VPM repository builder](vpm/REPOSITORY-BUILDER.md)
- [Development roadmap](docs/ROADMAP.md)
- [Third-party licensing policy](docs/LICENSING.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)
- [Code of conduct](CODE_OF_CONDUCT.md)

## Development status

The live-image build path is in `build/`. The Desktop profile includes Weston as an upstream Wayland/DRM graphical bring-up preview; the Server profile is console-first and uses a separate Buildroot defconfig. Both include the Vampire console tools, VPM runtime, signed-update verifier and optional public-key-only SSH service. The custom Vampire graphical shell is still under development.

Build the Desktop ISO with `bash build/build-live-iso.sh`; build the Server ISO with `VAMPIRE_EDITION=server bash build/build-live-iso.sh`. Each edition has a separate Buildroot output directory and ISO filename.

The ISO has not yet been built and boot-validated in this repository's release
pipeline. The custom graphical desktop, disk-writing installer, production package repository and transactional package manager, update application/rollback service, and supported hardware matrix remain incomplete.
See [the live ISO build guide](build/README.md) and the roadmap.

## Independence and upstream sources

The target operating system is not intended to be based on Debian, Ubuntu,
Arch, Fedora, or another distribution. A host Linux distribution may be used
to provide build tools only; it is not the target runtime base. Upstream
components retain their own licenses and notices.
