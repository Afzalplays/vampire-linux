# Vampire OS security baseline

This document defines the minimum security posture expected before a Vampire OS image is considered suitable for general users. It is a target specification, not a statement that these controls are already implemented.

## Boot and platform integrity

- Support UEFI Secure Boot with documented signing and key-enrollment procedures.
- Verify bootloader, kernel and initramfs signatures where the platform supports it.
- Use TPM 2.0 measured-boot integration as an optional hardening feature; do not make TPM mandatory for basic installation.
- Provide recovery media and a documented recovery path that does not silently bypass signature checks.

## Accounts and privilege

- Create a non-root user during installation; disable remote root login by default.
- Use narrowly scoped privilege escalation with auditable authorization.
- Apply secure password hashing, account lockout/rate limiting and optional MFA for remote administration.
- Keep service accounts isolated, with no interactive login unless explicitly required.

## Storage, network and services

- Offer full-disk encryption during installation, with clear recovery-key handling.
- Enable a deny-by-default inbound firewall profile; expose only services explicitly enabled by the administrator.
- Ship with unnecessary network listeners and services disabled.
- Provide secure DNS and time synchronization configuration options.
- Keep remote desktop and remote administration bound to private interfaces until explicitly configured otherwise.

## Application isolation and permissions

- Support application sandboxing and least-privilege execution.
- Separate system packages from user-scoped applications.
- Make camera, microphone, screen capture, removable storage, clipboard and file access permissions visible and revocable.
- Do not run the graphical software store as root; use a narrow privileged helper for approved package operations.
- Keep browser and document-preview processes isolated from core system services.

## Updates and software supply chain

- Require signed repository metadata and verified package hashes.
- Use reproducible builds where practical; publish source revision, build recipe, license data and SBOM.
- Scan dependencies and track known vulnerabilities.
- Support staged updates, rollback and recovery before enabling unattended system upgrades.
- Provide security advisories and a process for reporting and fixing vulnerabilities.
- Protect signing keys offline or in controlled signing infrastructure; document rotation and revocation.

## Detection, audit and recovery

- Provide structured system and security logs with access controls and retention settings.
- Record authentication failures, privilege changes, package changes, service exposure and remote sessions.
- Include firewall, system integrity, storage health and update status in a security dashboard.
- Provide backup and restore tools, recovery shell access and documented incident-response steps.
- Avoid claiming that a scanner or dashboard makes a system secure; security requires updates, configuration and review.

## Release gates

A release candidate must pass at least:

1. Static analysis and dependency/license checks.
2. Package signature, hash, path traversal, archive bomb and permission tests.
3. Secure Boot and recovery-path tests on supported UEFI hardware or emulators.
4. Firewall scan confirming only documented listeners are exposed.
5. Authentication, lockout, MFA and session-revocation tests.
6. RDP certificate, encryption, redirection-policy and isolation tests.
7. Upgrade interruption and rollback tests.
8. SBOM generation, vulnerability triage and documented known issues.

All features remain subject to hardware support and upstream project capabilities. Security defaults must fail closed when trust verification fails.
