# kali-anonstealth

ParrotSec's anonsurf and stealth, ported to work with Kali Linux.

## How to use this repo

This repo contains the sources of both the anonsurf and pandora packages from ParrotSec combined into one.

Modifications have been made to prevent data leakage and use the DNS servers of Private Internet Access (this is simple to change).

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

## Compiling the .deb

