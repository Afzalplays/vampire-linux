# Vampire OS hardware diagnostics

Read-only x86_64 bring-up and support commands:

- \`vhardware\`: CPU, logical cores, memory, DRM devices, block devices and network interfaces.
- \`vstorage\`: block-device and mounted-filesystem inventory; never writes storage.
- \`vhealth\`: checks core mountpoints, essential commands and OS metadata.
- \`vlogs\`: reads logread, /var/log/messages or the kernel ring buffer.
- \`vdiagnose\`: combines health, hardware, monitor, storage, network, firewall and logs.

`vlogs [--follow] [--lines COUNT]` reads a bounded number of recent log lines (1–5000) or follows the active log stream.\n\n`vdiagnose --save [DIRECTORY]` writes a local support report with restrictive mode `0600`; the default location is `/var/log/vampire/support`. The Desktop support-snapshot menu uses this export path.\n\nA support snapshot can expose hardware identifiers, interface names, local
addresses, mounted volume names and log contents. Inspect and redact it before
sharing. No diagnostic command uploads data. These tools are not SMART tests,
memory tests, GPU stress tests, firmware updaters or hardware certification.


## Live system monitor

`vmonitor --once` prints a read-only snapshot of host/kernel, uptime, load,
memory pressure, thermal zones, root filesystem usage and network interfaces.
`vmonitor --watch [SECONDS]` refreshes the display every 2 seconds by default;
the interval is restricted to 1–60 seconds. Missing procfs or thermal telemetry
is reported as unavailable rather than treated as a fatal system error.
For isolated regression tests, the procfs and sysfs roots can be redirected with
`VAMPIRE_PROC_ROOT` and `VAMPIRE_SYS_ROOT`.
