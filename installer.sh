# Ensure we are being ran as root
if [ $(id -u) -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

# For upgrades and sanity check, remove any existing i2p.list file
rm -f /etc/apt/sources.list.d/i2p.list

# Compile the i2p ppa
echo "deb http://deb.i2p2.no/ unstable main" > /etc/apt/sources.list.d/i2p.list # Default config reads repos from sources.list.d
wget https://geti2p.net/_static/i2p-debian-repo.key.asc -O /tmp/i2p-debian-repo.key.asc # Get the latest i2p repo pubkey
apt-key add /tmp/i2p-debian-repo.key.asc # Import the key
rm /tmp/i2p-debian-repo.key.asc # delete the temp key
apt-get update # Update repos
apt-get install i2p-keyring #this will ensure you get updates to the repository's GPG key

# Configure and install the .deb
dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb # Build the deb package
dpkg -i kali-anonsurf.deb || (apt-get -f install && dpkg -i kali-anonsurf.deb) # this will automatically install the required packages

exit 0
