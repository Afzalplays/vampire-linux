# Vampire OS architecture

## Goal

Vampire OS is intended to be an independently assembled Linux distribution.
It uses the upstream Linux kernel and selected upstream user-space projects,
but is not a respin or derivative of Debian, Ubuntu, Arch, Fedora, or another
Linux distribution.

A host distribution may provide build tools. Its package manager, filesystem
layout, and user-space binaries must not become the target system's runtime
foundation.

## Initial target

- Architecture: x86_64 (AMD64)
- Editions: Vampire Desktop and Vampire Server
- Kernel: upstream Linux
- C library direction: musl for the initial minimal userspace
- Initial userspace: BusyBox-based bring-up environment
- Boot path: GRUB and an initramfs during early development

## Development stages

1. Stage 0: build a minimal userspace, kernel, initramfs, and QEMU-testable image.
2. Stage 1: establish a reproducible toolchain, filesystem hierarchy, device
   management, logging, networking, and service supervision.
3. Stage 2: define package metadata, dependency handling, signed repositories,
   and reproducible package builds.
4. Stage 3: implement installation, upgrades, recovery, and administration.
5. Stage 4: build the graphical session, Vampire Desktop shell, and settings.
6. Stage 5: build the Vampire Software Center, signed application catalogue,
   reproducible package pipeline, and privileged install service.
7. Stage 6: integrate secure RDP Mode with adaptive display quality, session
   isolation, authentication, policy controls, and audit logging.
8. Stage 7: add signed release artifacts, checksums, SBOMs, hardware testing,
   and release criteria.

## Current status

This repository is experimental development scaffolding, not a production OS.
A successful reproducible ISO build, installer, update mechanism, and supported
hardware matrix have not yet been established.

See [LICENSING.md](LICENSING.md) and [ROADMAP.md](ROADMAP.md).
