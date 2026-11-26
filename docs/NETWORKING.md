# Vampire OS networking

The initial live image uses BusyBox networking tools and the Vampire DHCP
lifecycle helper. Run `vctl start network` or `vnetwork start eth0` to
request a DHCP lease. When no interface is specified, the helper selects the
first non-loopback interface under `/sys/class/net`.

## Wired networking

- `vnetwork start [IFACE]` brings the interface up and starts BusyBox
  `udhcpc` in the background.
- `vnetwork status [IFACE]` displays interface addresses and DHCP process
  state.
- `vnetwork stop [IFACE]` stops only a verified `udhcpc` process and
  removes a resolver file managed by Vampire OS.
- `vnetwork restart [IFACE]` stops and starts the DHCP client.
- The DHCP hook validates lease IPv4 addresses, routers and DNS servers
  before applying interface, route and resolver changes.

The resolver file defaults to `/run/vampire/resolv.conf`. DHCP refuses
symlinked resolver files and symlinked parent directories. The resolver is
runtime state and is not retained across a reboot.

## Wi-Fi

The current helper supports Wi-Fi interface discovery, scan, WPA2-Personal
passphrase connection, status and disconnect:

```sh
vnetwork wifi list
vnetwork wifi scan wlan0
vnetwork wifi connect wlan0 "Network name"
vnetwork wifi status wlan0
vnetwork wifi disconnect wlan0
```

The connect command prompts for the passphrase without echo when attached to a
terminal. It validates WPA passphrase length, writes the generated
wpa_supplicant configuration with mode 0600, and starts DHCP after association.
The configuration is stored under `/etc/vampire/`; on a live image this is
temporary unless the user has configured persistence.

Saved profiles can be reactivated with `vnetwork wifi auto`. To enable
automatic activation at boot on an installed system, run
`vctl enable wifi`; disable it with `vctl disable wifi`. The optional Wi-Fi
service only reads regular profile files with mode 0600, refuses symlinked
profile paths, waits for WPA association, and then requests DHCP. The generic
wired-network service skips wireless interfaces so DHCP does not race ahead of
Wi-Fi authentication. The Desktop network menu also exposes saved-profile
reconnection.

Current limitations: WPA3/Enterprise authentication, managed profile
selection and deletion, automatic retry/backoff after a failed association,
static IPv4 profiles, VPN integration, and a graphical network settings panel
are not implemented.
Hardware compatibility still requires testing with physical wireless adapters
and firmware.

## Diagnostics

```sh
vnetwork status
vnetwork wifi list
vctl status network
ip addr
ip route
cat /etc/resolv.conf
```

If a DHCP lease fails, inspect the interface name, link state, firmware and
kernel driver before changing firewall rules. Do not paste Wi-Fi passphrases
or private network credentials into support reports.

## Firewall

`vguard status` inspects nftables when installed. `vguard apply` installs
an inbound-drop policy allowing loopback, established traffic, ICMP and SSH
TCP port 22 by default. Set `VAMPIRE_SSH_PORT` before applying if SSH uses
another port. Review the policy before using it on a remote server.
`vguard clear` removes only the Vampire-owned table. The firewall is not
auto-applied at boot.
