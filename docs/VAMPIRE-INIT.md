# Vampire service control

Vampire OS currently uses BusyBox init as PID 1. `vctl` is the interim
service dispatcher; it is not yet the planned production Vampire Init
supervisor.

Services are executable scripts in `/etc/vampire/services.d/` and implement
`start`, `stop`, and `status`. Boot-enabled service names are stored one
per line in `/etc/vampire/services.enabled`.

## Commands

- `vctl list` — list installed services and boot state.
- `vctl status network` — query one service.
- `vctl start network`, `vctl stop network`, `vctl restart network`.
- `vctl enable network` / `vctl disable network` — persist boot enablement.
- `vctl start-all` / `vctl stop-all` — operate on enabled services.

The live image enables DHCP networking by default. Boot startup continues if
an optional service fails. Service names are restricted to alphanumeric
characters, underscore, dot and hyphen; the enabled list is never evaluated
as shell code.

## Current limitations

This is not systemd compatibility or a production supervisor. Dependency
ordering, readiness notifications, restart policies, cgroups, privilege
separation, structured persistent logs, parallel boot, and a dedicated
shutdown transaction remain future work. BusyBox init remains responsible
for PID 1, getty respawning, reboot and shutdown. Its shutdown hook runs
`/etc/init.d/rcK`, which stops enabled services, syncs pending writes, and then
remounts/unmounts filesystems read-only where supported.
