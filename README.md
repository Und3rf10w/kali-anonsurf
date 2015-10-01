# kali-anonstealth

ParrotSec's anonsurf and stealth, ported to work with Kali Linux.

## How to use this repo

This repo contains the sources of both the anonsurf and pandora packages from ParrotSec combined into one.

Modifications have been made to prevent data leakage (disabe ip checks through FrozenDNS), use the DNS servers of Private Internet Access (instead of FrozenDNS) and fixes for users who don't use the resolvconf application.

This repo can be compiled into a deb package to correctly install it on a Kali system.


NOTE: This may work with any debian/ubuntu system, but this has only been tested to work on a Kali 2.0 amd64 system

## Configuring the i2p ppa
Before we can install this package, we must first configure the i2p ppa. This can be done in Kali like so:

```bash
echo "deb http://deb.i2p2.no/ jessie main" > /etc/apt/sources.list.d/i2p.list
wget https://geti2p.net/_static/i2p-debian-repo.key.asc -O /tmp/i2p-debian-repo.key.asc
apt-key add /tmp/i2p-debian-repo.key.asc
rm /tmp/i2p-debian-repo.key.asc
apt-get update
apt-get install i2p-keyring #this will ensure you get updates to the repository's GPG key
```

## Compiling and installing the .deb
```bash
dpkg-deb -b kali-anonsurf-1.0/
dpkg -i kali-anonsurf-1.0.deb || (apt-get -f install && dpkg -i kali-anonsurf-1.0.deb) # this will automatically install the required packages
```

## CLI Usage
### Pandora
Pandora automatically overwrites the RAM when the system is shutting down. Pandora can also be ran manually:
```bash
pandora bomb
```

NOTE: This will clear the entire system cache, including active SSH tunnels or sessions.

### anonsurf
Anonsurf will anonymize the entire system under TOR using IPTables. It will also allow you to start and stop i2p as well.
```bash
Usage:
 anonsurf {start|stop|restart|change|status}

 start - Start system-wide anonymous
          tunneling under TOR proxy through iptables
 stop - Reset original iptables settings
          and return to clear navigation
 restart - Combines "stop" and "start" options
 change - Changes identity restarting TOR
 status - Check if AnonSurf is working properly
----[ I2P related features ]----
 starti2p - Start i2p services
 stopi2p - Stop i2p services
```
