# Vampire OS hardware diagnostics

Read-only x86_64 bring-up and support commands:

- \`vhardware\`: CPU, logical cores, memory, DRM devices, block devices and network interfaces.
- \`vstorage\`: block-device and mounted-filesystem inventory; never writes storage.
- \`vhealth\`: checks core mountpoints, essential commands and OS metadata.
- \`vlogs\`: reads logread, /var/log/messages or the kernel ring buffer.
- \`vdiagnose\`: combines health, hardware, monitor, storage, network, firewall and logs.

`vdiagnose --save [DIRECTORY]` writes a local support report with restrictive mode `0600`; the default location is `/var/log/vampire/support`. The Desktop support-snapshot menu uses this export path.\n\nA support snapshot can expose hardware identifiers, interface names, local
addresses, mounted volume names and log contents. Inspect and redact it before
sharing. No diagnostic command uploads data. These tools are not SMART tests,
memory tests, GPU stress tests, firmware updaters or hardware certification.
