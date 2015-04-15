#!/bin/bash

set -eu

# TESTING code
#
# Created this because Raspberry pi wouldn't accept mac addresses from the package macchanger.
# This script sets a pseudo-random mac address.
# It is used in combination with the /etc/network/interfaces file

# To do
# - Generate more random valid mac addresses by replacing the static '00' with pseudo-random code.
#   But don't generate multicast and locally administered addresses.

export RANDFILE=/etc/onion-node/.rnd;

MAC_START=00:;
MAC_END=$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//');
MAC_NEW="${MAC_START}""${MAC_END}";

ifconfig eth0 down hw ether "${MAC_NEW}";
# Sleep 10 to fix occasional ifdown/ifup "RTNETLINK answers: Network is unreachable" error.
# In tests 1 second was enough, but use a margin of safety
sleep 10;
