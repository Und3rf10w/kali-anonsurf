#!/bin/bash

# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# For upgrades and sanity check, remove any existing i2p.list file
rm -r /etc/apt/sources.list.d/i2p.list

# Compile the i2p ppa
echo "deb http://deb.i2p2.no/ unstable main" > /etc/apt/sources.list.d/i2p.list # Default config reads repos from sources.list.d
wget https://geti2p.net/_static/i2p-debian-repo.key.asc -O /tmp/i2p-debian-repo.key.asc # Get the latest i2p repo pubkey
apt-key add /tmp/i2p-debian-repo.key.asc # Import the key
rm /tmp/i2p-debian-repo.key.asc # delete the temp key
apt update # Update repos

if [[ -n $(cat /etc/os-release |grep kali) ]]
then
	apt install libservlet3.0-java 
	wget http://ftp.us.debian.org/debian/pool/main/j/jetty8/libjetty8-java_8.1.16-4_all.deb
	apt install libjetty8-java_8.1.16-4_all.deb # This should succeed without error
	apt install libecj-java libgetopt-java libservlet3.0-java glassfish-javaee ttf-dejavu i2p i2p-router libjbigi-jni #installs i2p and other dependencies
	apt-get -f install # resolves anything else in a broken state
fi

apt install  i2p-keyring #this will ensure you get updates to the repository's GPG key
apt install  secure-delete tor i2p # install dependencies, just in case

# Configure and install the .deb
apt install kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
apt install kali-anonsurf.deb || (apt -f install && apt install  kali-anonsurf.deb) # this will automatically install the required packages

echo "Done"

exit0
