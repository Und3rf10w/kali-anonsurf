#!/bin/bash

# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# Install xterm for Stretch updates and orginal repo reactivation
apt-get install xterm -y

# For upgrades and sanity check, remove any existing i2p.list file
rm -f /etc/apt/sources.list.d/i2p.list

# Compile the i2p ppa
echo "deb http://deb.i2p2.no/ unstable main" > /etc/apt/sources.list.d/i2p.list # Default config reads repos from sources.list.d
wget https://geti2p.net/_static/i2p-debian-repo.key.asc -O /tmp/i2p-debian-repo.key.asc # Get the latest i2p repo pubkey
apt-key add /tmp/i2p-debian-repo.key.asc # Import the key
rm /tmp/i2p-debian-repo.key.asc # delete the temp key
apt-get update # Update repos

cp /etc/apt/sources.list /etc/apt/sources.list.backup # backup
# Second backup created in case user stops the script after this point , then on next startup this script will
# copy the already changed sources file before as backup, and user lost his original sources lists
file="/etc/apt/sources.list.anonsurf"
if [ ! -f "$file" ]
then
cp /etc/apt/sources.list /etc/apt/sources.list.anonsurf
fi
rm -f /etc/apt/sources.list
touch /etc/apt/sources.list
echo "deb http://deb.debian.org/debian/ stretch main contrib non-free" > /etc/apt/sources.list
xterm -T " Updating Repositories Debian Stretch " -geometry 100x30 -e "sudo apt-get clean && sudo apt-get clean cache && sudo apt-get update -y"
sleep 1

if [[ -n $(cat /etc/os-release |grep kali) ]]
then

	apt-get install libservlet3.0-java

xterm -T " Reactivating your original repositories " -geometry 100x30 -e "rm -f /etc/apt/sources.list && cp /etc/apt/sources.list.backup /etc/apt/sources.list"
#now we can remove the emergency backup securely
xterm -T " RRemoving emergency backup securly " -geometry 100x30 -e "rm -f /etc/apt/sources.list.anonsurf && rm -f /etc/apt/sources.list.backup"
apt-get clean
xterm -T " Updating Your Repo " -geometry 100x30 -e "apt-get update"

 	apt-get install libjetty9-java -y # This should succeed without error
	apt-get install libecj-java libgetopt-java libservlet3.0-java i2p i2p-router libjbigi-jni -y #installs i2p and other dependencies
	apt-get --fix-broken install # resolves anything else in a broken state
fi

apt-get install -y i2p-keyring #this will ensure you get updates to the repository's GPG key
apt-get install -y secure-delete tor i2p # install dependencies, just in case

# Configure and install the .deb
dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
apt install kali-anonsurf.deb || (apt-get -f install && apt install kali-anonsurf.deb) # this will automatically install the required packages

xterm -T " cleaning your cache " -geometry 100x30 -e "apt-get clean apt-get clean cache apt-get autoclean"

exit 0
