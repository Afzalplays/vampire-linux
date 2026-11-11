# Vampire OS firewall

The nftables profile is opt-in. It is not applied automatically because a
default-deny inbound policy can disconnect remote administration.

\`\`\`sh
vfirewall status
VAMPIRE_SSH_PORT=22 vfirewall apply
vfirewall clear
vctl start firewall
vctl stop firewall
\`\`\`

The profile allows loopback, established/related traffic, ICMP, ICMPv6, DHCP
replies and new inbound TCP on the configured SSH port. Forwarded inbound
traffic is dropped; outbound traffic is accepted. SSH defaults to port 22.

Before applying remotely, confirm the actual SSH port, required application
ports and console/out-of-band recovery. This prototype has no zone manager,
VPN integration, persistent rule editor or automatic rollback.
