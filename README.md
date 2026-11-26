# Vampire OS

An independent, open-source Linux operating system assembled from upstream
source code by VampireNodes. The project targets x86_64 and is developed as two
editions: Vampire Desktop and Vampire Server.

<sub><strong>Status:</strong> Experimental development — not ready for production.</sub>

## Identity

- **Operating system:** Vampire OS
- **Desktop environment:** Vampire Desktop (Weston-based graphical preview with Foot terminal and app launchers; custom shell still in development)
- **Shell:** Vampire Shell (Bash-compatible branded shell launcher available as `vsh`; dedicated parser/runtime planned)
- **Fetch utility:** [Vampire Fetch](fetch/README.md) — `vfetch`
- **Architecture:** x86_64 / AMD64
- **Editions:** Desktop and Server (x86_64); mobile web/PWA support is planned separately

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
- [Mobile support and Android/iOS compatibility](docs/MOBILE-SUPPORT.md)
- [Server edition](docs/SERVER-EDITION.md)
- [Desktop UX specification](docs/DESKTOP-UX-SPEC.md)
- [Settings, voice, updates and boot specification](docs/SETTINGS-VOICE-UPDATES-BOOT.md)
- [Voice Access design](docs/VOICE-ACCESS.md)
- [BIOS/UEFI installer and recovery design](docs/BOOT-INSTALLER-RECOVERY.md)
- [QEMU BIOS/UEFI boot-test procedure](docs/QEMU-BOOT-TESTS.md)
- [Settings defaults](docs/SETTINGS-DEFAULTS.md)
- [Console tools guide](docs/CONSOLE-TOOLS.md)
- [Command reference](rootfs-overlay/usr/bin/vhelp)
- [Vampire Shell](docs/VAMPIRE-SHELL.md)
- [Hardware diagnostics](docs/HARDWARE-DIAGNOSTICS.md)
- [Networking, DHCP and Wi-Fi](docs/NETWORKING.md)
- [Optional firewall](docs/FIREWALL.md)
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

The live-image build path is in `build/`. The Desktop profile includes Weston,
a Foot Wayland terminal, a branded dark terminal profile and panel launchers
for Terminal, Files, Settings, Software Center and Monitor. The Server profile is
console-first and uses a separate Buildroot defconfig. Both include Vampire
console tools, DHCP networking, the experimental VPM runtime, signed-update
verifier and an optional public-key-only SSH service. The Desktop profile also
includes Wi-Fi scanning/association tools and common Intel iwlwifi firmware;
the Server profile remains intentionally minimal. The custom Vampire
compositor shell, native graphical apps and multi-user login are still under
development. The current Desktop and Server ISOs target x86_64 PCs/servers and are not phone images. Mobile browser access, an Android device-specific port and iOS companion experience are separate planned work; see [mobile support](docs/MOBILE-SUPPORT.md).

Build the Desktop ISO with `bash build/build-live-iso.sh`; build the Server ISO
with `VAMPIRE_EDITION=server bash build/build-live-iso.sh`. Each edition has a
separate Buildroot output directory and ISO filename. CI build checks exercise the BIOS and UEFI boot-test scripts. On commit
`12cc6d99ed4ab8dffa7a82441f2fc52b5dba82a8`, both Desktop and Server ISO builds
completed and passed QEMU SeaBIOS and OVMF CODE/VARS live-init plus serial-login
smoke tests (workflow runs `43246672356` and `43246672369`). Checksum-bearing
developer ISO artifacts were uploaded by those runs. This is virtual firmware
smoke-test evidence only; physical-machine installation, post-install reboot,
and hardware compatibility remain unverified. See
[the live ISO build guide](build/README.md) and
[the QEMU boot-test guide](docs/QEMU-BOOT-TESTS.md).

The `Vampire OS quality gates` GitHub Actions workflow runs Python bytecode compilation, shell syntax validation, and the complete Python regression suite on pushes and pull requests. The settings CLI now uses process-unique atomic staging files and refuses symlinked settings targets; its regression tests cover successful writes, invalid values, duplicate settings and symlink refusal. Desktop appearance application and settings bootstrap/recovery now have isolated end-to-end regression tests, including invalid configuration recovery and symlink rejection. The text-mode installer has non-destructive CLI and isolated fake-sysfs preflight tests covering read-only planning, mounted disks and partitions, active disk/partition swap, stacked devices, unavailable mount tables, read-only media and undersized targets. The installed-root configuration contract has focused Python regression tests
for BIOS PARTUUID boot arguments, UEFI ESP mounting, malformed or missing
identifiers, and symlink refusal. Rootfs staging has separate security tests
for required system files, traversal paths, duplicate entries, escaping
symlinks, and refusing to merge into a non-empty destination. The read-only
`vmonitor` utility has isolated procfs/sysfs tests for uptime, load, memory,
thermal readings, missing telemetry and live refresh argument handling. VPM archive extraction also has regression coverage for traversal, absolute paths, symlinks, duplicate entries, overwrite refusal and partial-write rollback. Run the
suite from the repository root with:

```sh
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

The DHCP and Wi-Fi command-line helpers have isolated regression tests; see [networking documentation](docs/NETWORKING.md) for their current scope and limitations. The custom graphical desktop, graphical installer, production package repository and transactional package manager, update application/rollback service, and supported hardware matrix remain incomplete. A confirmation-gated text-mode BIOS/UEFI erase-and-install path is implemented, but it still needs disposable-disk QEMU installation and installed-disk reboot validation. This is a developer live environment, not a finished or production-ready operating system.

## Independence and upstream sources

The target operating system is not intended to be based on Debian, Ubuntu,
Arch, Fedora, or another distribution. A host Linux distribution may be used
to provide build tools only; it is not the target runtime base. Upstream
components retain their own licenses and notices.
