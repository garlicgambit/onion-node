#!/bin/bash

# TESTING code
#
# Created this because Raspberry pi wouldn't accept mac addresses from macchanger
# but this seems to have the same issues when using it in /etc/network/interfaces file.
# Prefer to use /etc/network/interfaces file, to keep network configuration at one point.
# Need to troubleshoot the problem further/get another fix

export RANDFILE=/etc/onion-node/.rnd;

MACSTART=00:;
MACEND=$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//');
MACNEW="$MACSTART""$MACEND";

ifconfig eth0 down hw ether "$MACNEW";
# Sleep 10 to fix ifdown/ifup "RTNETLINK answers: Network is unreachable"
# In tests 1 second was enough, but use a margin of safety
sleep 10;
