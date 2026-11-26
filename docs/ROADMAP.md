# Vampire OS roadmap

A feature is complete only after implementation, automated tests, and relevant
runtime validation. A design document or build script alone does not make a
feature release-ready.

## 0.1 developer live environment

- [x] Define an independent x86_64 distribution target.
- [x] Add musl, BusyBox init, Linux kernel and Buildroot image configuration.
- [x] Add VFetch, GRUB hybrid ISO builder and SHA-256 generation. Validate the installed VPM package count in VFetch regression tests.
- [x] Add VPM experimental client, signed-index verification and unit tests.
- [x] Add shell/configuration CI checks and QEMU BIOS/UEFI smoke-test script.
- [x] Add push/PR quality workflow for Python compilation (including installed runtime utilities), shell syntax checks (including runtime helpers) and regression tests (GitHub Actions passed on 2026-11-25).
- [x] Add initial service dispatcher, DHCP helper and opt-in nftables helper.
- [x] Harden service enablement updates, reject malformed state, deduplicate bulk operations, add status-all and fail-closed restart behavior; reject symlinked state paths and store enablement state with private permissions.
- [x] Add validated settings storage and interactive console launcher MVP.
- [x] Harden settings writes with process-unique staging files and symlink refusal; add CLI regression tests.
- [x] Add isolated tests for applying desktop appearance settings and boot-time settings recovery; refuse symlinked persistent settings during bootstrap.
- [x] Validate the complete settings schema in the runtime apply helper; reject symlinked settings, parent and backup paths during writes and recovery. Allocate recovery backups exclusively with private permissions.
- [x] Add tests for settings validation, desktop launcher and core console tools.
- [x] Verify the settings menu clearly distinguishes stored preferences from graphical controls not yet implemented.
- [x] Add read-only installer disk discovery and target preflight checks.
- [x] Add non-destructive installer CLI and fake-sysfs preflight tests for read-only planning, mounted disks and partitions, active disk/partition swap, stacked devices, unavailable mount tables, read-only media and undersized targets.
- [x] Add hardware, storage, health, log and support diagnostics.
- [x] Add explicit-confirmation reboot, poweroff and halt controls with root checks and isolated command tests.
- [x] Add automated safe regression coverage for power status, argument validation, non-root rejection and mocked confirmed action dispatch (quality CI run `45614758508`).
- [x] Add memory/thermal telemetry, live monitor refresh and private support-report export.
- [x] Add bounded log viewing and follow mode for local diagnostics.
- [x] Add DHCP lease application, DNS configuration and network start/stop lifecycle.
- [x] Add initial Wi-Fi discovery, WPA2 connection, disconnect and credential-file permission checks (hardware validation and persistent profiles remain pending).
- [x] Add firmware-specific read-only UEFI/GPT and BIOS/GPT installation-layout preview to the console installer menu.
- [x] Enforce private permissions on support snapshot directories and report files, including pre-existing directories.
- [x] Build Desktop and Server ISO images in CI.
- [x] Pass legacy BIOS QEMU live-init and serial-login smoke test.
- [x] Pass UEFI QEMU live-init and serial-login test with OVMF (Desktop and Server, CI run 43246672356 / 43246672369).
- [x] Verify VFetch executes from the installed rootfs and DHCP obtains a lease during BIOS/UEFI live and installed-disk boot tests for both editions.
- [x] Verify power-status reporting and that reboot/poweroff/halt reject unconfirmed requests in both installed editions.
- [ ] Exercise confirmed reboot and poweroff end-to-end inside disposable QEMU sessions and verify the expected restart/shutdown behaviour.
- [x] Publish checksum-verified developer ISO workflow artifacts after BIOS and UEFI tests pass (Desktop and Server artifacts uploaded).

## Core operating system

- [ ] Pin and verify source archives and toolchain inputs.
- [ ] Establish reproducible builds and build provenance.
- [x] Build a dedicated x86_64 musl-based Buildroot toolchain and stable live filesystem layout.
- [x] Add the Vampire Shell branded Bash-compatible launcher and interactive profile.
- [x] Add static programmable completion for Vampire power, settings, networking, services, VPM, installer, display and launcher commands; regression-test nested settings and Wi-Fi actions.
- [ ] Replace the Bash compatibility engine with a dedicated Vampire Shell parser/runtime.
- [ ] Implement a production Vampire Init supervisor.
- [ ] Implement users, groups, permissions, logging and device management.
- [x] Implement a DHCP client lifecycle with lease address, default route and DNS updates.
- [ ] Complete Wi-Fi, VPN and persistent network profile support.
- [ ] Add firmware handling and a tested rescue mode.

## Package management

- [x] Experimental VPM CLI, signed metadata and payload hash verification.
- [x] Dependency resolution, architecture checks and guarded extraction.
- [x] Integrate experimental VPM client and doctor into the live root filesystem.
- [x] Add confirmation-gated console frontend for VPM package operations.
- [ ] Reproducible package recipes and maintained signed repository.
- [ ] Transactional install/upgrade, rollback and recovery.
- [ ] Configure production trust keys and maintained signed repository.
- [ ] Build graphical Vampire Software Center and installer integration.

## Desktop edition

- [x] Add Weston DRM/Wayland compositor and upstream desktop-shell packages for graphics bring-up.
- [x] Add console-mode vdesktop launcher and validated vsettings backend.
- [x] Add theme, accent, transparency, blur, terminal, dock and top-panel preference storage.
- [x] Add a Wayland terminal autostart with the Vampire Shell profile and branded dark terminal palette.
- [x] Apply validated theme, accent, panel visibility/transparency, reduced-motion and terminal-opacity settings to the next Weston session.
- [x] Set Foot terminal and terminal-hosted Settings preview to translucent 90% opacity by default; keep opacity user-adjustable with a solid-background option (regression-tested).
- [x] Add Weston panel launchers for Terminal, Files, Settings, Software Center and Monitor.
- [x] Add a searchable keyboard-driven Vampire Launcher and expose it as a Weston panel entry; the graphical floating dock and graphical launcher remain pending.
- [x] Require the Desktop live-ISO smoke test to verify vsettings, settings bootstrap/apply helpers and Weston/Foot base configurations are present in the initramfs.
- [x] Require the Desktop installer-rootfs artifact check to verify the same settings runtime and base configuration payload.
- [x] Add console file manager, hardware inventory and diagnostics.
- [x] Add an interactive service manager to Vampire Desktop for list, status, start, stop, restart and boot enablement.
- [ ] Build the branded Vampire Desktop shell: top panel, floating dock, launcher and window integration.
- [x] Reject symlinked XDG runtime roots, per-user directories and ancestors in graphical preflight; add regression coverage.
- [ ] Add non-root graphical login/session management and display manager.
- [ ] Build graphical file manager, terminal and settings applications.
- [x] Add read-only DRM connector and advertised-mode inventory (`vdisplay`) with fake-sysfs regression coverage; current active mode and display control remain unsupported.
- [x] Add a validated JSON output mode to `vdisplay` for future desktop settings clients, with connected/disconnected, mode-filtering and empty-inventory regression tests.
- [x] Execute installed `vdisplay --json` in the Desktop rootfs chroot and parse its empty-inventory response before BIOS/UEFI disk boot.
- [ ] Add adaptive display scaling plus display, network, sound, power and personalization controls.
- [ ] Validate audio, Bluetooth, printing, touchpads, multi-monitor and accessibility.
- [ ] Implement Voice Access with confirmation-gated destructive actions.

## Mobile support

- [x] Define platform boundaries: responsive PWA, device-specific Android port and iOS companion experience; document why desktop/server x86_64 ISOs are not phone images.
- [x] Implement responsive Vampire OS mobile portal with PWA manifest, install prompt, safe-area-aware layouts and static offline cache; add automated contract tests.
- [x] Build responsive Vampire OS project/download PWA for Android and iOS browsers (static portal, manifest, install prompt and offline shell implemented; HTTPS hosting remains to be enabled).
- [x] Add automated PWA contract tests for install metadata, viewport/safe-area handling, reduced motion and static-only offline caching.
- [ ] Run manual installability, touch accessibility, portrait/landscape and offline-documentation checks on physical Android and iOS devices.
- [ ] Design secure mobile server-administration UX with authentication and MFA.
- [ ] Select and document a supported ARM64 Android reference device and bootloader requirements.
- [ ] Bring up a device-specific kernel, device tree, firmware and core hardware drivers.
- [ ] Implement a touch-first mobile shell and adaptive phone/tablet interfaces.
- [ ] Validate radio, audio, camera, sensors, GPU, suspend/resume, encryption, recovery and updates on each supported device.
- [ ] Evaluate a native iOS companion app if PWA capabilities are insufficient; no iOS replacement OS/ISO is planned.

## Installer and recovery

- [x] Read-only disk inventory and installation preflight.
- [x] Add checksum-verified rootfs validation and guarded staging into an existing target directory.
- [x] Add VPM archive-extraction regression tests for traversal, absolute paths, links, duplicate entries, overwrite refusal and partial-write rollback.
- [x] Reject rootfs archive entries nested beneath symlink or non-directory ancestors before extraction; add focused regression tests.
- [x] Generate deterministic fstab and GRUB configuration for a staged target root using kernel-supported GPT PARTUUID root selection (bootloader installation remains pending).
- [x] Regression-test the UEFI ESP GRUB handoff as exact newline-delimited configuration; Server installed-disk UEFI boot passed in CI run `45596621598`.
- [x] Embed GPT, ext-family, FAT, filesystem-UUID search and GRUB configfile modules in the removable UEFI bootloader; Server installed-disk UEFI boot passed in CI run `45596621598`.
- [x] Report required disk-installation tools without performing destructive actions.
- [x] Implement guided text-mode erase-and-install flow in the console launcher (graphical installer remains pending).
- [x] Implement GPT partitioning, FAT32/ext4 formatting, rootfs staging, UUID configuration, BIOS/UEFI GRUB installation and exact typed destructive confirmation.
- [x] Repeat disk safety preflight immediately after destructive confirmation to reject target-use changes before the first partition write.
- [x] Verify firmware-specific GRUB boot files and generated configuration exist before reporting installer success.
- [x] Discover and mount the installation ISO payload read-only for offline installation.
- [x] Validate Server edition installation end-to-end on disposable BIOS and UEFI QEMU disks; both installed images reached Vampire init, serial login and DHCP lease (CI run `45596621598`).
- [ ] Validate Desktop edition installation end-to-end on disposable BIOS and UEFI QEMU disks.
- [x] Extend the Desktop installed-rootfs gate to reset and validate shipped settings, apply the appearance runtime, and verify generated Weston/Foot configuration before QEMU boot.
- [ ] Add installed-system command execution checks for VFetch, reboot/shutdown and recovery cleanup.
- [ ] Add encrypted installation, recovery media, boot repair and tested restore workflow.

## Server edition

- [x] Add a separate console-first Server Buildroot configuration and ISO workflow.
- [x] Add opt-in Dropbear SSH prototype and service controls.
- [x] Store SSH host keys under configurable `/var/lib/vampire/ssh/` state for persistence on installed systems with persistent `/var`.
- [x] Add monitoring, network, storage and hardware diagnostics.
- [x] Add non-root SSH public-key onboarding with per-user authorized_keys, strict permissions, duplicate detection and symlink rejection; keep password authentication and root login disabled.
- [x] Test SSH host-key reuse across repeated daemon starts and reject symlinked home-directory and host-key path ancestors.
- [ ] Validate host-key persistence across an actual installed-system reboot and complete production SSH hardening.
- [ ] Build multi-host administration, file transfer, deployment and recovery.
- [ ] Integrate secure remote desktop with VPN-only access controls.

## Security and updates

- [x] Add opt-in firewall helper and service integration; validate candidate nftables rules before replacing the active policy.
- [x] Add signed update-manifest verification and checksum-verified image staging (download only).
- [x] Add a staged-image re-verification command against the currently signed manifest.
- [ ] Configure production signing keys, trust rotation and maintained update metadata.
- [ ] Implement atomic OS/application update application, history and rollback.
- [ ] Implement Secure Boot signing, disk encryption and application isolation.
- [ ] Add audit logging, login protection, SBOM and vulnerability response.

## Stable release gates

- [ ] BIOS/UEFI validation on virtual and physical hardware.
- [ ] Install to a blank virtual disk, reboot from installed disk and test recovery.
- [ ] Hardware compatibility and accessibility test matrix.
- [ ] Reproducible signed artifacts, notices and release notes.

## Current validation snapshot (2026-11-25)

- [x] Source commit `85bcee0` passed the Vampire OS build checks workflow.
- [x] Source commit `85bcee0` passed the Vampire OS quality gates workflow.
- [x] Source commit `85bcee0` passed installer syntax and safety checks.
- [x] Fix ISO workflow path filters so changes to `tests/test_configure_installed_root.py` trigger Desktop and Server image validation.
- [x] Workflow-filter commit `7350182` passed quality gates; the following main commit `26b217e` only updates this validation record.
- [x] Server edition disposable-disk installation and installed-disk boot passed in both BIOS and UEFI firmware in CI run `45596621598`.
- [ ] Desktop edition disposable-disk installation and installed-disk boot remain unverified.
- [ ] Repeat both edition build, live-ISO, and installed-disk tests on the current main head; add installed-system runtime checks for VFetch, power controls and installer cleanup.
- [x] Run VFetch, service/network/firewall command integration and mocked power-control regression tests in quality CI run `45614758508`.
- [x] Require Desktop installer rootfs archives to include the Weston session launcher, graphical preflight and Vampire app/terminal launchers; regression-test Desktop/Server payload rules and reject unknown editions (quality CI run `45615705180`).

The current repository is a developer-stage live environment, not a finished
desktop operating system or production installer. Do not label a feature
release-ready until its implementation and tests are complete.
