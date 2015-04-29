#!/bin/bash
#
# Description:
# Fetch latest package updates, upgrade to latest packages and install tor.
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Fetch updates
apt-get update || true

# Install updates
apt-get upgrade -y || true

# Install Tor
apt-get install -y tor || true
