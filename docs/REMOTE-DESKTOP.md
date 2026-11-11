# Vampire Remote Desktop (RDP Mode)

## Goal

Vampire Desktop will include an optional **RDP Mode** for remote graphical access. It should deliver a responsive desktop at high visual quality while remaining secure by default. This is a design specification; a working RDP server, client integration, and performance benchmark have not yet been delivered.

## User experience and quality

- Adaptive resolution and display scaling, including high-DPI displays
- User-selectable image quality, colour depth and bandwidth mode
- Hardware-accelerated encoding when supported, with a safe software fallback
- Smooth pointer movement, keyboard input and multi-monitor support
- Audio playback and microphone redirection only when explicitly enabled
- Clipboard and file transfer as separate permissions, disabled by default for untrusted sessions
- Network-adaptive bitrate and frame rate to reduce latency on weak connections
- Session reconnect, lock screen, disconnect and administrator-controlled timeout
- Clear status display for connection quality, encryption, active devices and session owner

Quality presets should include **Balanced**, **High Quality**, and **Low Bandwidth**. High Quality should prioritize colour fidelity and resolution; Low Bandwidth should reduce bitrate and frame rate without disabling security.

## Security baseline

1. Bind to localhost or a trusted private interface by default. Do not expose RDP to the public internet automatically.
2. Recommend VPN or private overlay access for remote connections. Firewall rules must be explicit.
3. Require modern TLS with certificate validation; reject obsolete protocol versions and weak cipher suites.
4. Require Network Level Authentication or an equivalent pre-session authentication gate where supported.
5. Support per-user access, strong password policy, optional MFA, lockout/rate limiting, and session revocation.
6. Prohibit remote root/administrator desktop login by default. Use normal user accounts and privilege escalation only when needed.
7. Isolate sessions and enforce file, device, clipboard, audio and drive-redirection policies.
8. Keep security logs for authentication, failed logins, session start/end, policy changes and administrative actions.
9. Apply security updates promptly; expose server version and security state to administrators.
10. Provide a one-click emergency disable switch and revoke active sessions when the service is disabled.

## Architecture direction

- Evaluate a maintained RDP implementation such as FreeRDP-compatible server components and Wayland/PipeWire integration.
- Keep the remote-access daemon separate from the desktop shell and run it with the least privileges possible.
- Use systemd-independent service supervision compatible with Vampire Init; do not assume systemd is the target init.
- Separate the RDP transport/authentication layer from capture, encoding, input and session policy.
- Provide an administrator panel for enablement, users, allowed networks, certificates, MFA policy, session limits and audit logs.

Implementation must be selected after a compatibility and security review of upstream components. Do not write a new cryptographic protocol or invent custom encryption.

## Acceptance tests

- No listener is exposed on public interfaces until an administrator explicitly enables it.
- Invalid certificates, weak protocol settings and failed authentication are rejected.
- MFA and per-user access policies are enforced where configured.
- Clipboard, drive, audio and device redirection obey individual policy toggles.
- Sessions can be terminated immediately and are logged.
- Benchmark latency, frame rate, CPU/GPU use and image quality over LAN and constrained networks.
- Test Wayland and X11 fallback paths, multi-monitor, HiDPI, reconnect and screen-lock behavior.
