#!/bin/bash

# Installer for kali-anonsurf.
#
# Installs the runtime dependencies, builds the .deb from the sources in this
# repository and installs it. I2P is optional: deb.i2p.net only publishes some
# suites, and guessing one from the distribution name installs packages built
# for a different base. The suite is therefore taken from /etc/os-release and
# validated against the repository before it is used.

set -u

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be ran as root"
	exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
	apt-get update
	apt-get install -y gnupg
fi

# Runtime dependencies of the package. socat signals NEWNYM to Tor; the
# conntrack tool is packaged as conntrack-tools on Debian and as conntrack on
# Ubuntu, so it is installed by capability instead of by name.
apt-get update
apt-get install -y secure-delete tor iptables socat
if ! command -v conntrack >/dev/null 2>&1; then
	apt-get install -y conntrack-tools 2>/dev/null || apt-get install -y conntrack 2>/dev/null ||
		echo "warning: install conntrack-tools or conntrack, otherwise connections opened before 'anonsurf start' keep bypassing Tor" >&2
fi

# --- I2P (optional) ---------------------------------------------------------
if [ -r /etc/os-release ]; then
	# shellcheck disable=SC1091
	. /etc/os-release
fi

# deb.i2p.net serves Debian and Ubuntu suites. Try the distribution's own
# codename first, then the Debian one, and accept the first suite that the
# repository actually publishes. Distributions that track another base
# (Ubuntu derived, Kali, Parrot) expose it through one of these variables.
i2p_suite_candidates() {
	[ -n "${UBUNTU_CODENAME:-}" ] && echo "$UBUNTU_CODENAME"
	[ -n "${VERSION_CODENAME:-}" ] && echo "$VERSION_CODENAME"
	[ -n "${DEBIAN_CODENAME:-}" ] && echo "$DEBIAN_CODENAME"
	# Some releases only expose the Debian suite through tzdata.
	[ -n "${ID:-}" ] &&
		dpkg --status tzdata 2>/dev/null | grep -m1 '^Provides:' | cut -d- -f2
	echo "sid"
}

I2P_SUITE=""
while read -r candidate; do
	[ -n "$candidate" ] || continue
	if curl -fsSL --max-time 20 "https://deb.i2p.net/dists/$candidate/Release" >/dev/null 2>&1; then
		I2P_SUITE=$candidate
		break
	fi
done <<EOF
$(i2p_suite_candidates)
EOF

rm -f /etc/apt/sources.list.d/i2p.list
if [ -n "$I2P_SUITE" ]; then
	if ! curl -fsSLo /usr/share/keyrings/i2p-archive-keyring.gpg \
		https://i2p.net/i2p-archive-keyring.gpg; then
		echo "Failed to download the I2P archive keyring, skipping I2P" >&2
		I2P_SUITE=""
	fi
fi

if [ -n "$I2P_SUITE" ]; then
	echo "deb [signed-by=/usr/share/keyrings/i2p-archive-keyring.gpg] https://deb.i2p.net/ $I2P_SUITE main" \
		> /etc/apt/sources.list.d/i2p.list
	apt-get update
	apt-get install -y i2p
else
	echo "I2P repository is not available for ID=${ID:-unknown} ${VERSION_CODENAME:-}; skipping I2P" >&2
	echo "Install it manually if you need 'anonsurf starti2p'." >&2
fi

# --- package ----------------------------------------------------------------
chmod 755 kali-anonsurf-deb-src/DEBIAN

if command -v fakeroot >/dev/null; then
	echo "fakeroot is available, using it to build the .deb package."
	fakeroot dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb
else
	echo "fakeroot is not available, building the .deb package without it."
	dpkg-deb -b kali-anonsurf-deb-src/ kali-anonsurf.deb
fi

if ! dpkg -i kali-anonsurf.deb; then
	# Only repair the dependency state of this package; do not let apt resolve
	# unrelated broken packages as a side effect of the install.
	apt-get install -y --fix-broken
	dpkg -i kali-anonsurf.deb
fi

if ! dpkg -l | grep -qw kali-anonsurf; then
	echo "The package 'kali-anonsurf' did not install successfully."
	exit 1
fi

exit 0
