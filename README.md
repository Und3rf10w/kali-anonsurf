# kali-anonstealth

ParrotSec's anonsurf and stealth, ported to work with Kali Linux.

## How to use this repo

This repo contains the sources of both the anonsurf and pandora packages from ParrotSec combined into one.

Anonsurf routes all outgoing TCP traffic through Tor using an iptables transparent proxy. Pandora overwrites the RAM when the system is shutting down.

This repo can be compiled into a deb package to correctly install it on a Kali system. The installer works on any Debian or Ubuntu based distribution (`kali-rolling` and Ubuntu `noble` are tested).

The easiest way to get this working is to just run the installer. See the installation section for further info.

## Usage

### anonsurf

```bash
Usage:
 anonsurf {start|stop|restart|change|status|myip}

 start - Start system-wide anonymous
          tunneling under TOR proxy through iptables
 stop - Remove the anonsurf firewall rules and return to clear navigation
 restart - Combines "stop" and "start" options
 change - Asks Tor for new circuits (SIGNAL NEWNYM)
 status - Show the Tor unit, the active firewall rules and the DNS backend
 myip - Print the egress address (RISKY: it makes a request from the tunnel)
----[ I2P related features ]----
 starti2p - Start i2p services
 stopi2p - Stop i2p services
```

NOTE: DO NOT run this as `service anonsurf $COMMAND`. Run it as `anonsurf $COMMAND`.

### pandora

Pandora automatically overwrites the RAM when the system is shutting down. Pandora can also be ran manually:

```bash
pandora bomb
```

NOTE: This will clear the entire system cache, including active SSH tunnels or sessions.

## What `anonsurf start` changes on the host

Everything is reverted by `anonsurf stop`.

| Area | Change |
|---|---|
| Firewall | Rules live in the `ANONSURF_NAT` and `ANONSURF_OUT` chains only. No built-in chain is flushed, so UFW, Docker, libvirt and VPN rules keep working |
| TCP | Redirected to Tor's `TransPort` (9040), including `.onion` names mapped into `10.192.0.0/10` |
| DNS | Handled through `systemd-resolved`, `resolvconf` or `/etc/resolv.conf`, whichever the host uses, and set to `127.0.0.1` |
| UDP | Not redirected: Tor cannot carry it. Traffic to non-local destinations is rejected by `ANONSURF_OUT`, except DNS and DHCP |
| DHCP | Explicitly excluded from the redirect, so the lease keeps renewing |
| IPv6 | Disabled through `/etc/sysctl.d/98-kali-anonsurf.conf` and re-enabled on stop |
| Existing connections | Dropped with `conntrack -F`; a connection opened before `start` would otherwise keep using the real address |
| Long-lived apps | Browsers and other clients listed in `DANGEROUS_APPS` are terminated |

The Tor configuration is not replaced. The package installs `/etc/tor/torrc.d/50-anonsurf.conf` and adds `%include /etc/tor/torrc.d/*.conf` to `/etc/tor/torrc`, so bridges, pluggable transports, `ControlPort` and hidden services survive.

## Requirements and limitations

- `conntrack-tools` (Debian) or `conntrack` (Ubuntu) is needed to drop pre-existing connections. Without it, `anonsurf start` warns and open connections keep bypassing Tor.
- `socat` is needed by `anonsurf change` to send `NEWNYM` over the Tor control socket.
- Stop `systemd-timesyncd` before `start`. NTP uses UDP and is therefore rejected, and Tor refuses a consensus document when the clock drifts too far.
- A transparent proxy is not an anonymity system. All applications share the Tor circuits selected for their destinations, which links their traffic. Use Tor Browser for browsing, and `torsocks` for individual commands, when unlinkability matters.
- Exit nodes are frequently blocked. Expect captchas and geo-blocked sites.

## Overrides

`/etc/default/anonsurf` is sourced on start:

```bash
# UID Tor runs as.
TOR_UID=debian-tor
# Destinations that are never routed through Tor.
TOR_EXCLUDE="192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"
# Set to 0 to keep applications running on start/stop.
ANONSURF_KILL_APPS=1
# Set to 0 to keep pre-existing connections (they bypass Tor).
ANONSURF_FLUSH_CONNTRACK=1
```

## Installation

This package comes with an installer that makes things extremely easy:

```bash
./installer.sh
```

Once the installer is complete, you will be able to use both the anonsurf and pandora modules. I2P is optional: the installer adds the I2P repository only for the suite it actually publishes for your distribution, and skips the installation otherwise. Install `i2p` manually if you need `anonsurf starti2p`.

## Tests

```bash
sudo unshare -rn ./tests/test_firewall.sh   # rule set and cleanup, in a throwaway namespace
sudo docker run --rm -v "$PWD:/src" -w /src ubuntu:24.04 ./tests/test_package.sh
```
