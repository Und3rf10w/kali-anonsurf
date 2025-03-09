#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Function to handle errors
handle_error() {
    echo "An error occurred. Exiting..."
    exit 1
}

# Trap errors and call the error handling function
trap handle_error ERR

# Remove any existing i2p.list file for upgrades and sanity check
rm -f /etc/apt/sources.list.d/i2p.list || echo "No existing i2p.list file found."

# Install gnupg if not installed
if ! command -v gpg > /dev/null 2>&1; then
    echo "Installing gnupg..."
    apt-get update || handle_error
    apt-get install -y gnupg || handle_error
fi

# Compile the i2p ppa
echo "Setting up i2p repository..."
echo "deb [signed-by=/usr/share/keyrings/i2p-archive-keyring.gpg] https://deb.i2p.net/ $(dpkg --status tzdata | grep Provides | cut -f2 -d'-') main" > /etc/apt/sources.list.d/i2p.list || handle_error

# Download and install the i2p archive keyring
echo "Downloading i2p archive keyring..."
curl -o i2p-archive-keyring.gpg https://geti2p.net/_static/i2p-archive-keyring.gpg || handle_error
chmod 644 i2p-archive-keyring.gpg || handle_error
mv i2p-archive-keyring.gpg /usr/share/keyrings || handle_error

# Update package repositories
echo "Updating package repositories..."
apt-get update || handle_error

# Install dependencies
echo "Installing dependencies..."
apt-get install -y secure-delete tor i2p i2p-router || handle_error

# Ensure the DEBIAN folder is executable
echo "Setting permissions for kali-anonsurf-deb-src/DEBIAN..."
chmod 755 -R kali-anonsurf-deb-src/DEBIAN || handle_error

# Check if fakeroot is installed and build the .deb package
if command -v fakeroot > /dev/null 2>&1; then
    echo "fakeroot is available, using it to build the .deb package."
    fakeroot dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb || handle_error
else
    echo "fakeroot is not available, building the .deb package without it."
    dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb || handle_error
fi

# Install the .deb package
echo "Installing kali-anonsurf..."
dpkg -i kali-anonsurf.deb || (apt-get -f install && dpkg -i kali-anonsurf.deb) || handle_error

# Verify that the kali-anonsurf package is installed
if ! dpkg -l | grep -qw kali-anonsurf; then
    echo "The package 'kali-anonsurf' did not install successfully."
    handle_error
fi

echo "Installation completed successfully."
exit 0
