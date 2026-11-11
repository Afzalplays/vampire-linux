# Vampire service control

The first live image continues to use BusyBox init. The service scripts below
provide an interim interface while a real Vampire Init supervisor is developed.

Executable services live in `/etc/vampire/services.d/` and accept one of
`start`, `stop`, or `status`. Examples: `vctl start network`,
`vctl status network`, and `vctl list`.

Current components:
- `vctl`: validates service names and dispatches to service scripts.
- `network`: DHCP helper using BusyBox `udhcpc`.
- `vnetwork`: selects a non-loopback interface and requests a DHCP lease.
- `vguard`: optional nftables rules; never enabled automatically.

This is not systemd compatibility or a production supervisor. Dependency
ordering, restart policies, cgroups, readiness, persistent logs and parallel
boot remain future work.
