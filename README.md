# kali-anonstealth

ParrotSec's anonsurf and stealth, ported to work with Kali Linux.

## How to use this repo

This repo contains the sources of both the anonsurf and pandora packages from ParrotSec combined into one.

Modifications have been made to use the DNS servers of Private Internet Access (instead of FrozenDNS), and fixes for users who don't use the resolvconf application. I have removed some functionality such as the gui and iceweasel in ram.

This repo can be compiled into a deb package to correctly install it on a Kali system.

The easiest way to get this working is to just run the installer. See the installation section for further info.

NOTE: This may work with any debian/ubuntu system, but this has only been tested to work on a kali-rolling amd64 system

## Usage
### Pandora
Pandora automatically overwrites the RAM when the system is shutting down. Pandora can also be ran manually:
```bash
pandora bomb
```

NOTE: This will clear the entire system cache, including active SSH tunnels or sessions.

### anonsurf
Anonsurf will anonymize the entire system under TOR using IPTables. It will also allow you to start and stop i2p as well.

NOTE: DO NOT run this as ```service anonsurf $COMMAND```. Run this as ```anonsurf $COMMAND```

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

## Installation
This package comes with an installer that makes things extremely easy:

```bash
./installer.sh
```

Once the installer is complete, you will be able to use both the anonsurf and pandora modules.
