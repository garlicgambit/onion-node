#!/bin/bash

# TESTING code
#
# Created this because Raspberry pi wouldn't accept mac addresses from macchanger
# but this seems to have the same issues when using it in /etc/network/interfaces file.
# Prefer to use /etc/network/interfaces file, to keep network configuration at one point.
# Need to troubleshoot the problem further/get another fix

export RANDFILE=/etc/node-scripts/.rnd;

MACSTART=00:;
MACEND=$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//');
MACNEW="$MACSTART""$MACEND";

ifconfig eth0 down hw ether "$MACNEW";
