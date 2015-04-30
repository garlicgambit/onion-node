#!/bin/bash
#
# Description:
# Install general software packages for Onion node
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Special APTPACKAGE install.sh check - this package is checked when running install.sh
# This should be the first package to get installed.
apt-get install -y macchanger || true

# Install other software
apt-get install -y gnupg-curl unattended-upgrades || true

# Install bitcoin dependencies
apt-get install -y autoconf build-essential libboost-chrono-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libtool libssl-dev || true

# Install tlsdate dependencies
apt-get install -y autoconf autotools-dev build-essential fakeroot libevent-dev libssl-dev libtool pkg-config || true
