#!/bin/bash

# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# For upgrades and sanity check, remove any existing i2p.list file
rm -f /etc/apt/sources.list.d/i2p.list

# Compile the i2p ppa
echo "deb https://ppa.launchpadcontent.net/i2p-maintainers/i2p/ubuntu noble main" > /etc/apt/sources.list.d/i2p.list # Default config reads repos from sources.list.d
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB9660B9EB2CC88B  # Add i2p maintainer keys # TODO: Is there a more universal way to do this?
apt-get update # Update repos

if [[ -n $(cat /etc/os-release |grep kali) ]]
then
	apt-get install libservlet3.1-java libecj-java libgetopt-java glassfish-javaee ttf-dejavu i2p i2p-router libjbigi-jni libjetty8-java #installs i2p and other dependencies
	apt-get -f install # resolves anything else in a broken state
fi

apt-get install -y secure-delete tor i2p # install dependencies, just in case

# Configure and install the .deb
dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
dpkg -i kali-anonsurf.deb || (apt-get -f install && dpkg -i kali-anonsurf.deb) # this will automatically install the required packages

exit 0
