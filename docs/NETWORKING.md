# Vampire OS networking

The initial live image uses BusyBox networking tools. Run `vctl start network`
or `vnetwork start eth0` to request a DHCP lease. The helper selects the first
non-loopback interface when no interface is specified.

Wi-Fi onboarding, static profiles, DNS search domains, VPN integration and a
graphical network settings panel are not implemented yet.

## Firewall

`vguard status` inspects nftables when installed. `vguard apply` installs an
inbound-drop policy allowing loopback, established traffic, ICMP and SSH TCP
port 22 by default. Set `VAMPIRE_SSH_PORT` before applying if SSH uses another
port. Review the policy before using it on a remote server. `vguard clear`
removes only the Vampire-owned table. The firewall is not auto-applied at boot.
