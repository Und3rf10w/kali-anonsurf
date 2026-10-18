#!/bin/bash
# Rule-level tests for the anonsurf firewall.
#
# The test runs inside its own network namespace, so it never touches the host
# firewall. Run it as:
#
#   sudo unshare -rn ./tests/test_firewall.sh
#
# Requirements: iptables, iproute2, python3.

set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
INITD="$ROOT/kali-anonsurf-deb-src/etc/init.d/anonsurf"
IFACE=anonsurf-test0

failures=0
ok() { echo "ok   - $*"; }
no() { echo "FAIL - $*"; failures=$((failures + 1)); }
skip() { echo "skip - $*"; }

[ -f "$INITD" ] || {
	echo "missing $INITD"
	exit 1
}
for bin in iptables ip python3; do
	command -v "$bin" >/dev/null || {
		echo "missing $bin"
		exit 1
	}
done
[ "$(id -u)" -eq 0 ] || {
	echo "run as root inside a network namespace: unshare -rn $0"
	exit 1
}

# The script resolves TOR_UID on load. Inside a user namespace only uid 0 is
# mapped, so the owner match can only be created for uid 0 here; the behavioural
# checks below then remove that rule, which would otherwise match the traffic
# this test generates.
TOR_UID=0
export TOR_UID
# shellcheck disable=SC1090
. "$INITD"

# Does this namespace accept rules for a uid other than 0?
if iptables -N anonsurf-uidprobe 2>/dev/null &&
	iptables -A anonsurf-uidprobe -m owner --uid-owner 65534 -j RETURN 2>/dev/null; then
	UID_SPACE=full
else
	UID_SPACE=restricted
fi
iptables -F anonsurf-uidprobe 2>/dev/null
iptables -X anonsurf-uidprobe 2>/dev/null

# Index (1-based) of the first rule of a chain matching a pattern. Only -A
# lines are counted, so the index matches the rule order in -L output.
rule_index() {
	iptables -t "$1" -S "$2" | grep '^-A' | grep -nE -- "$3" | head -1 | cut -d: -f1
}

# Packet counter of the first rule of a chain whose text contains a pattern.
# iptables-save -c prints every counter inline and never wraps a rule over two
# lines, which iptables -L does as soon as a rule gets long.
rule_packets() { # table chain pattern
	local packets
	packets=$(iptables-save -c -t "$1" 2>/dev/null | grep -F -- "-A $2 " | grep -F -- "$3" |
		head -1 | sed -E 's/^\[([0-9]+):[0-9]+\].*/\1/')
	[ -n "$packets" ] || packets=missing
	echo "$packets"
}

nat_packets() { rule_packets nat "$NAT_CHAIN" "$1"; }
out_packets() { rule_packets filter "$OUT_CHAIN" "$1"; }

expect() { # description expected actual
	if [ "$2" = "$3" ]; then
		ok "$1"
	else
		no "$1 (expected '$2', got '$3')"
	fi
}

expect_at_least() { # description minimum actual
	if [ "$3" = "missing" ]; then
		no "$1 (rule not found)"
	elif [ "$3" -ge "$2" ] 2>/dev/null; then
		ok "$1"
	else
		no "$1 (expected >= $2 packets, got $3)"
	fi
}

expect_match() { # description command pattern
	if $2 | grep -qE -- "$3"; then
		ok "$1"
	else
		no "$1"
	fi
}

send_udp() { # dest port [source port]
	python3 - "$1" "$2" "${3:-0}" <<'PY'
import socket, sys
dst, dport, sport = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
try:
    if sport:
        s.bind(('0.0.0.0', sport))
    s.sendto(b'\x00', (dst, dport))
except OSError:
    # A REJECT in OUTPUT surfaces as EPERM here; the counter still moves.
    pass
PY
}

send_tcp() { # dest port
	python3 - "$1" "$2" <<'PY'
import socket, sys
dst, dport = sys.argv[1], int(sys.argv[2])
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.settimeout(0.3)
try:
    s.connect((dst, dport))
except OSError:
    pass
PY
}

# ---------------------------------------------------------------- fixtures
ip link add "$IFACE" type dummy 2>/dev/null
ip addr add 192.0.2.2/24 dev "$IFACE" 2>/dev/null
ip link set "$IFACE" up 2>/dev/null
ip link set lo up 2>/dev/null
ip route add 255.255.255.255/32 dev "$IFACE" 2>/dev/null
ip route add default dev "$IFACE" 2>/dev/null

# Rules that belong to something else: they must survive start and stop.
iptables -A OUTPUT -d 203.0.113.1/32 -j ACCEPT
iptables -t nat -A OUTPUT -d 203.0.113.2/32 -j RETURN

# ---------------------------------------------------------------- start
if ! firewall_start >/dev/null; then
	echo "FAIL - firewall_start returned non-zero"
	exit 1
fi
ok "firewall_start returned zero"

expect_match "nat chain redirects TCP into the TransPort" \
	"iptables -t nat -S $NAT_CHAIN" "-A $NAT_CHAIN -p tcp -j REDIRECT --to-ports 9040"
expect_match "filter chain rejects everything else" \
	"iptables -S $OUT_CHAIN" "-A $OUT_CHAIN -j REJECT"
expect_match "Tor traffic bypasses the nat redirect" \
	"iptables -t nat -S $NAT_CHAIN" "-m owner --uid-owner $TOR_UID"
expect_match "DHCP is excluded from the nat redirect" \
	"iptables -t nat -S $NAT_CHAIN" "--dport 67 -j RETURN"
if iptables -t nat -S "$NAT_CHAIN" | grep -F -- '-p udp' | grep -qF -- '--to-ports 9040'; then
	no "no UDP is ever sent to the TransPort"
else
	ok "no UDP is ever sent to the TransPort"
fi

# start twice must not duplicate the jumps
firewall_start >/dev/null
expect "nat OUTPUT jump is present exactly once" 1 \
	"$(iptables -t nat -S OUTPUT | grep -c -- "-j $NAT_CHAIN")"
expect "filter OUTPUT jump is present exactly once" 1 \
	"$(iptables -S OUTPUT | grep -c -- "-j $OUT_CHAIN")"

expect "unrelated filter rule survived start" 1 \
	"$(iptables -S OUTPUT | grep -c -- "-d 203.0.113.1/32 -j ACCEPT")"
expect "unrelated nat rule survived start" 1 \
	"$(iptables -t nat -S OUTPUT | grep -c -- "-d 203.0.113.2/32 -j RETURN")"

# ---------------------------------------------------------------- behaviour
# ---------------------------------------------------------------- behaviour
if [ "$UID_SPACE" = restricted ]; then
	# The bypass rule would otherwise match the traffic sent below.
	iptables -t nat -D "$NAT_CHAIN" -m owner --uid-owner "$TOR_UID" -j RETURN
	iptables -D "$OUT_CHAIN" -m owner --uid-owner "$TOR_UID" -j ACCEPT
	ok "removed the uid bypass rules; no uid map available in this namespace"
fi

send_udp 255.255.255.255 67 68
expect_at_least "DHCP discover is returned, not redirected" 1 "$(nat_packets --dport\ 67)"
expect "DHCP discover is not rejected" 0 "$(out_packets REJECT)"

send_udp 1.1.1.1 53
expect_at_least "DNS over UDP is redirected to the DNSPort" 1 "$(nat_packets --dport\ 53)"

before=$(out_packets REJECT)
send_udp 1.1.1.1 9999
after=$(out_packets REJECT)
if [ "$before" = "0" ] && [ "$after" = "1" ]; then
	ok "non-DNS UDP is rejected instead of pretending to use Tor"
else
	no "non-DNS UDP is rejected instead of pretending to use Tor (REJECT went from $before to $after)"
fi

send_tcp 203.0.113.10 443
expect_at_least "generic TCP is redirected to the TransPort" 1 \
	"$(nat_packets "$NAT_CHAIN -p tcp -j REDIRECT --to-ports 9040")"

send_tcp 10.192.1.5 80
expect_at_least ".onion range is redirected before the 10/8 exclusion" 1 \
	"$(nat_packets '-d 10.192.0.0/10')"
expect ".onion traffic does not hit the 10/8 exclusion" 0 \
	"$(nat_packets '-d 10.0.0.0/8 -j RETURN')"

send_tcp 192.168.1.5 22
expect_at_least "LAN destinations are excluded from the redirect" 1 \
	"$(nat_packets '-d 192.168.0.0/16')"

if [ "$UID_SPACE" = full ] && command -v setpriv >/dev/null 2>&1; then
	# Traffic from the Tor user must be accepted, not rejected.
	before=$(out_packets REJECT)
	setpriv --reuid=65534 --regid=65534 --clear-groups python3 - <<'PY'
import socket
try:
    socket.socket(socket.AF_INET, socket.SOCK_DGRAM).sendto(b'\x00', ('1.1.1.1', 9999))
except OSError:
    pass
PY
	after=$(out_packets REJECT)
	expect "traffic from the Tor uid is not rejected" "$before" "$after"
else
	skip "Tor uid exception (needs a full uid space and setpriv)"
fi

# ---------------------------------------------------------------- stop
firewall_stop >/dev/null
ok "firewall_stop returned zero"

if iptables -t nat -S "$NAT_CHAIN" >/dev/null 2>&1; then
	no "nat chain $NAT_CHAIN still exists after stop"
else
	ok "nat chain $NAT_CHAIN removed"
fi
if iptables -S "$OUT_CHAIN" >/dev/null 2>&1; then
	no "filter chain $OUT_CHAIN still exists after stop"
else
	ok "filter chain $OUT_CHAIN removed"
fi
expect "no nat OUTPUT jump left" 0 \
	"$(iptables -t nat -S OUTPUT | grep -c -- "$NAT_CHAIN")"
expect "no filter OUTPUT jump left" 0 \
	"$(iptables -S OUTPUT | grep -c -- "$OUT_CHAIN")"
expect "unrelated filter rule survived stop" 1 \
	"$(iptables -S OUTPUT | grep -c -- "-d 203.0.113.1/32 -j ACCEPT")"
expect "unrelated nat rule survived stop" 1 \
	"$(iptables -t nat -S OUTPUT | grep -c -- "-d 203.0.113.2/32 -j RETURN")"

firewall_stop >/dev/null 2>&1
ok "firewall_stop is idempotent"

echo
if [ "$failures" -eq 0 ]; then
	echo "all assertions passed"
	exit 0
fi
echo "$failures assertion(s) failed"
	exit 1
