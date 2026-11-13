# Vampire OS roadmap

A feature is complete only after implementation, automated tests, and relevant
runtime validation. A design document or build script alone does not make a
feature release-ready.

## 0.1 developer live environment

- [x] Define an independent x86_64 distribution target.
- [x] Add musl, BusyBox init, Linux kernel and Buildroot image configuration.
- [x] Add VFetch, GRUB hybrid ISO builder and SHA-256 generation.
- [x] Add VPM experimental client, signed-index verification and unit tests.
- [x] Add shell/configuration CI checks and QEMU BIOS/UEFI smoke-test script.
- [x] Add initial service dispatcher, DHCP helper and opt-in nftables helper.
- [x] Harden service enablement updates, reject malformed state, deduplicate bulk operations, add status-all and fail-closed restart behavior.
- [x] Add validated settings storage and interactive console launcher MVP.
- [x] Add tests for settings validation, desktop launcher and core console tools.
- [x] Add read-only installer disk discovery and target preflight checks.
- [x] Add hardware, storage, health, log and support diagnostics.
- [x] Add explicit-confirmation reboot, poweroff and halt controls with root checks and isolated command tests.
- [x] Add memory/thermal telemetry, live monitor refresh and private support-report export.
- [x] Add bounded log viewing and follow mode for local diagnostics.
- [x] Add DHCP lease application, DNS configuration and network start/stop lifecycle.
- [x] Add initial Wi-Fi discovery, WPA2 connection, disconnect and credential-file permission checks (hardware validation and persistent profiles remain pending).
- [x] Add firmware-specific read-only UEFI/GPT and BIOS/GPT installation-layout preview to the console installer menu.
- [x] Enforce private permissions on support snapshot directories and report files, including pre-existing directories.
- [x] Build Desktop and Server ISO images in CI.
- [x] Pass legacy BIOS QEMU live-init and serial-login smoke test.
- [x] Pass UEFI QEMU live-init and serial-login test with OVMF (Desktop and Server, CI run 43246672356 / 43246672369).
- [ ] Verify VFetch, DHCP, reboot and shutdown inside both images.
- [x] Publish checksum-verified developer ISO workflow artifacts after BIOS and UEFI tests pass (Desktop and Server artifacts uploaded).

## Core operating system

- [ ] Pin and verify source archives and toolchain inputs.
- [ ] Establish reproducible builds and build provenance.
- [x] Build a dedicated x86_64 musl-based Buildroot toolchain and stable live filesystem layout.
- [x] Add the Vampire Shell branded Bash-compatible launcher and interactive profile.
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
- [x] Add Weston panel launchers for Terminal, Files, Settings, Software Center and Monitor.
- [x] Add console file manager, hardware inventory and diagnostics.\n- [x] Add an interactive service manager to Vampire Desktop for list, status, start, stop, restart and boot enablement.
- [ ] Build the branded Vampire Desktop shell: top panel, floating dock, launcher and window integration.
- [ ] Add non-root graphical login/session management and display manager.
- [ ] Build graphical file manager, terminal and settings applications.
- [ ] Add display, network, sound, power and personalization controls.
- [ ] Validate audio, Bluetooth, printing, touchpads, multi-monitor and accessibility.
- [ ] Implement Voice Access with confirmation-gated destructive actions.

## Installer and recovery

- [x] Read-only disk inventory and installation preflight.
- [ ] Build guided text installer for Server and graphical installer for Desktop.
- [ ] Implement safe partitioning, filesystems, UEFI/BIOS bootloader installation and confirmation gates.
- [ ] Add encrypted installation, recovery media, boot repair and tested restore workflow.

## Server edition

- [x] Add a separate console-first Server Buildroot configuration and ISO workflow.
- [x] Add opt-in Dropbear SSH prototype and service controls.
- [x] Store SSH host keys under configurable `/var/lib/vampire/ssh/` state for persistence on installed systems with persistent `/var`.
- [x] Add monitoring, network, storage and hardware diagnostics.
- [ ] Add persistent SSH host keys, non-root onboarding and hardened defaults.
- [ ] Build multi-host administration, file transfer, deployment and recovery.
- [ ] Integrate secure remote desktop with VPN-only access controls.

## Security and updates

- [x] Add opt-in firewall helper and service integration.
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

The current repository is a developer-stage live environment, not a finished
desktop operating system or production installer. Do not label a feature
release-ready until its implementation and tests are complete.
