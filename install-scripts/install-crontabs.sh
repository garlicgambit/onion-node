#!/bin/bash

set -eu;

# Install Onion-node crontabs in /etc/crontab

# Variables
ONION_DIR=/etc/onion-node;

# Create backup original /etc/crontab file
echo "Create a backup of the original /etc/crontab file";
if [[ ! -e "${ONION_DIR}"/crontab-orig ]]; then
  cp /etc/crontab "${ONION_DIR}"/crontab-orig;
fi

# Create temporary crontab file
echo "Create temporary crontab file";
cp "${ONION_DIR}"/crontab-orig "${ONION_DIR}"/crontab-tmp;
echo "Temporary crontab file created";

# Set /bin/bash as SHELL
echo "Set Bash as SHELL";
sed -i "s/SHELL=\/bin\/sh/SHELL=\/bin\/bash/" "${ONION_DIR}"/crontab-tmp;
echo "Bash is set as SHELL";

# Install new crontabs
echo "Setting new crontabs";

echo "###### Begin crontabs for bitcoin node ######" >> "${ONION_DIR}"/crontab-tmp;
echo "#" >> "${ONION_DIR}"/crontab-tmp;
echo "# Randomly reboot system every 2-4 weeks - a lockfile is set when run the first time" >> "${ONION_DIR}"/crontab-tmp;
echo '0  0    * * *   root   /etc/onion-node/random-reboot.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "# Check every 24 hours at random interval if time of Tor is accurate and set new .onion address in bitcoin.conf" >> "${ONION_DIR}"/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tor-date-check.sh; /etc/onion-node/bitcoin-new-onion-address.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "# Check every 24 hours at random interval if system time is accurate" >> "${ONION_DIR}"/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tlsdate-script.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "# Check for system updates at random interval every 0-5 days" >> "${ONION_DIR}"/crontab-tmp;
echo '0  0    * * *   root   /etc/onion-node/random-unattended-upgrades.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "# Check every 30 minutes if Tor and bitcoind are running" >> "${ONION_DIR}"/crontab-tmp;
echo '*/30  *    * * *   root   /etc/onion-node/check-tor-bitcoin-running.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "# DISABLED - Check for Bitcoin updates every 1-10 days" >> "${ONION_DIR}"/crontab-tmp;
echo '#0  0    * * *   root   /etc/onion-node/update-bitcoin.sh' >> "${ONION_DIR}"/crontab-tmp;
echo "#" >> "${ONION_DIR}"/crontab-tmp;
echo "###### End crontabs for bitcoin node ######" >> "${ONION_DIR}"/crontab-tmp;
echo "#" >> "${ONION_DIR}"/crontab-tmp;

echo "New crontabs set";

# Install new crontab file
echo "Installing new crontab file";
cp "${ONION_DIR}"/crontab-tmp /etc/crontab;
echo "New /etc/crontab file has been installed";

# Remove temporary crontab file
echo "Removing temporary crontab file";
rm "${ONION_DIR}"/crontab-tmp;
echo "Temporary crontab file has been removed";

echo "Crontab script is done";
