#!/bin/bash

# Install Onion-node crontabs in /etc/crontab

# Variables
ONIONDIR=/etc/onion-node;

# Create backup original /etc/crontab file
echo "Create a backup of the original /etc/crontab file";
if [[ ! -e "$ONIONDIR"/crontab-orig ]]; then
  cp /etc/crontab "$ONIONDIR"/crontab-orig;
fi

# Create temporary crontab file
echo "Create temporary crontab file";
cp "$ONOINDIR"/crontab-orig "$ONIONDIR"/crontab-tmp;
echo "Temporary crontab file created";

# Set /bin/bash as SHELL
echo "Set Bash as SHELL";
sed -i "s/SHELL=\/bin\/sh/SHELL=\/bin\/bash/" "$ONIONDIR"/crontab-tmp;
echo "Bash is set as SHELL";

# Install new crontabs
echo "Setting new crontabs";

echo "###### Begin crontabs for bitcoin node ######" >> "$ONIONDIR"/crontab-tmp;
echo "#" >> "$ONIONDIR"/crontab-tmp;
echo "# Randomly reboot system every 2-4 weeks - a lockfile is set when run the first time" >> "$ONIONDIR"/crontab-tmp;
echo '0  0    * * *   root   /etc/onion-node/random-reboot.sh' >> "$ONIONDIR"/crontab-tmp;
echo "# Check every 24 hours at random interval if time of Tor is accurate and set new .onion address in bitcoin.conf" >> "$ONIONDIR"/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tor-date-check.sh; /etc/onion-node/bitcoin-new-onion-address.sh' >> "$ONIONDIR"/crontab-tmp;
echo "# Check every 24 hours at random interval if system time is accurate" >> "$ONIONDIR"/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tlsdate-script.sh' >> "$ONIONDIR"/crontab-tmp;
echo "# Check every 30 minutes if Tor and bitcoind are running" >> "$ONIONDIR"/crontab-tmp;
echo '*/30  *    * * *   root   /etc/onion-node/check-tor-bitcoin-running.sh' >> "$ONIONDIR"/crontab-tmp;
echo "# DISABLED - Check for Bitcoin updates every 1-10 days" >> "$ONIONDIR"/crontab-tmp;
echo '#0  0    * * *   root   /etc/onion-node/update-bitcoin.sh' >> "$ONIONDIR"/crontab-tmp;
echo "#" >> "$ONIONDIR"/crontab-tmp;
echo "###### End crontabs for bitcoin node ######" >> "$ONIONDIR"/crontab-tmp;
echo "#" >> "$ONIONDIR"/crontab-tmp;

echo "New crontabs set";

# Install new crontab file
echo "Installing new crontab file";
cp "$ONIONDIR"/crontab-tmp /etc/crontab;
echo "New /etc/crontab file has been installed";

# Remove temporary crontab file
echo "Removing temporary crontab file";
rm "$ONIONDIR"/crontab-tmp;
echo "Temporary crontab file has been removed";

echo "Crontab script is done";
