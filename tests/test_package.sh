#!/bin/bash
# Package and installer checks, run inside a throwaway container.
set -u
fail=0
ok() { echo "ok   - $*"; }
no() { echo "FAIL - $*"; fail=$((fail + 1)); }
check() { if eval "$1" >/dev/null 2>&1; then ok "$2"; else no "$2"; fi; }

echo "== os-release =="
grep -E '^(ID|VERSION_CODENAME|UBUNTU_CODENAME|DEBIAN_CODENAME)=' /etc/os-release

echo "== installer =="
chmod +x ./installer.sh
if ./installer.sh >/tmp/installer.log 2>&1; then
	ok "installer.sh returned zero"
else
	no "installer.sh failed, see /tmp/installer.log"
	tail -25 /tmp/installer.log
fi
grep -E 'I2P|deb.i2p.net' /tmp/installer.log | head -5

echo "== package contents =="
check 'command -v anonsurf' "anonsurf is in PATH"
check 'test -f /etc/init.d/anonsurf' "/etc/init.d/anonsurf installed"
check 'test -f /etc/tor/torrc.d/50-anonsurf.conf' "torrc fragment installed"
check 'test ! -f /etc/tor/torrc.anon' "old torrc.anon is gone"
check 'grep -qxF "%include /etc/tor/torrc.d/*.conf" /etc/tor/torrc' "torrc includes torrc.d"
check 'test -f /etc/tor/torrc' "torrc still exists"
check '! grep -qxF "VirtualAddrNetwork 10.192.0.0/10" /etc/tor/torrc' "torrc was not replaced by the fragment"

echo "== tor configuration =="
if tor --defaults-torrc /usr/share/tor/tor-service-defaults-torrc -f /etc/tor/torrc --verify-config 2>/tmp/torver.log; then
	ok "tor --verify-config accepts torrc + fragment"
else
	no "tor --verify-config failed"
	tail -10 /tmp/torver.log
fi

echo "== command surface =="
check 'anonsurf 2>&1 | grep -q start' "anonsurf prints usage"
anonsurf status >/tmp/status.log 2>&1
check 'test $? -eq 0' "anonsurf status exits zero"
grep -q "ANONSURF_NAT is absent\|nat chain ANONSURF_NAT is absent" /tmp/status.log && ok "status reports the absent chain"

echo "== removal =="
if dpkg -r kali-anonsurf >/tmp/remove.log 2>&1; then ok "dpkg -r succeeded"; else no "dpkg -r failed"; tail -5 /tmp/remove.log; fi
check '! grep -qxF "%include /etc/tor/torrc.d/*.conf" /etc/tor/torrc' "include removed from torrc on remove"
if tor --defaults-torrc /usr/share/tor/tor-service-defaults-torrc -f /etc/tor/torrc --verify-config 2>/dev/null; then
	ok "tor configuration still valid after removal"
else
	no "tor configuration broken after removal"
fi

echo
[ "$fail" -eq 0 ] && echo "all container assertions passed" || echo "$fail assertion(s) failed"
exit "$fail"
