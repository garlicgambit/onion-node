#!/bin/bash
#
# Description:
# This script generates and sets a pseudo-random mac address on interface eth0.
# This script is created because the Raspberry Pi doesn't accept mac addresses
# from the macchanger package.
# It is not completely random because it won't set broadcast, multicast
# or 'locally administered' mac addresses. This is done by setting the
# second hexadecimal character in the mac address to zero.
#
# This script is used in combination with the /etc/network/interfaces file.
#
# TODO:
# - Get macchanger package to work
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
export RANDFILE=/etc/onion-node/.rnd

readonly MAC_NEW=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//; s/[a-f0-9]/0/2')


# Set new mac address
ifconfig eth0 down hw ether "${MAC_NEW}"

# Sleep 10 seconds to fix occasional ifdown/ifup "RTNETLINK answers: Network is
# unreachable" error.
# In tests 1 second was enough, but use a margin of safety
sleep 10
