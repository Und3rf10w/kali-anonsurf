#!/bin/bash

# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# For upgrades and sanity check, remove any existing i2p.list file
rm -f /etc/apt/sources.list.d/i2p.list

# Install gnupg if not installed
if ! command -v gpg; then
      apt-get update
      apt-get install -y gnupg
fi

# Compile the i2p ppa
echo "deb [signed-by=/usr/share/keyrings/i2p-archive-keyring.gpg] https://deb.i2p.net/ $(dpkg --status tzdata | grep Provides | cut -f2 -d'-') main" > /etc/apt/sources.list.d/i2p.list
curl -o i2p-archive-keyring.gpg https://geti2p.net/_static/i2p-archive-keyring.gpg
chmod 644 i2p-archive-keyring.gpg
mv i2p-archive-keyring.gpg /usr/share/keyrings
apt-get update # Update repos

apt-get install -y secure-delete tor i2p  i2p-router # install dependencies, just in case

# Configure and install the .deb
chmod 755 -R kali-anonsurf-deb-src/DEBIAN   # Ensure the DEBIAN folder is executable
fakeroot dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
dpkg -i kali-anonsurf.deb || (apt-get -f install && dpkg -i kali-anonsurf.deb) # this will automatically install the required packages


# Check if kali-anonsurf package is already installed
if ! dpkg -l | grep -qw kali-anonsurf; then
    echo "The package 'kali-anonsurf' did not install successfully."
    exit 1
fi

exit 0
