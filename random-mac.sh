#!/bin/bash
#
# Description:
# TESTING code
# Created this because Raspberry pi doesn't accept mac addresses from the package macchanger.
# This script sets a pseudo-random mac address.
# It is used in combination with the /etc/network/interfaces file
#
# TODO:
# - Generate more random valid mac addresses by replacing the static '00' with pseudo-random code.
#   But don't generate multicast and locally administered addresses.
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
export RANDFILE=/etc/onion-node/.rnd

readonly MAC_START=00:
readonly MAC_END=$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/.$//')
readonly MAC_NEW="${MAC_START}""${MAC_END}"


# Set new mac address
ifconfig eth0 down hw ether "${MAC_NEW}"

# Sleep 10 to fix occasional ifdown/ifup "RTNETLINK answers: Network is unreachable" error.
# In tests 1 second was enough, but use a margin of safety
sleep 10
