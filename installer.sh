#!/bin/bash

# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# For upgrades and sanity check, remove any existing i2p.list file
rm -f /etc/apt/sources.list.d/i2p.list

# Compile the i2p ppa
echo "deb https://ppa.launchpadcontent.net/i2p-maintainers/i2p/ubuntu bionic main" >> /etc/apt/sources.list.d/i2p.list # Default config reads repos from sources.list.d
echo "deb-src https://ppa.launchpadcontent.net/i2p-maintainers/i2p/ubuntu bionic main " >> /etc/apt/sources.list.d/i2p.list
curl 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x474bc46576fae76e97c1a1a1ab9660b9eb2cc88b' | sudo apt-key add - # Import the key
apt-get update # Update repos

if [[ -n $(cat /etc/os-release |grep kali) ]]
then
	apt-get install libservlet3.1-java libecj-java libgetopt-java glassfish-javaee ttf-dejavu i2p i2p-router libjbigi-jni libjetty8-java #installs i2p and other dependencies
	apt-get -f install # resolves anything else in a broken state
fi

apt-get install -y i2p-keyring #this will ensure you get updates to the repository's GPG key
apt-get install -y secure-delete tor i2p # install dependencies, just in case

# Configure and install the .deb
dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
dpkg -i kali-anonsurf.deb || (apt-get -f install && dpkg -i kali-anonsurf.deb) # this will automatically install the required packages

exit 0
