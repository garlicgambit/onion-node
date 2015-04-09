#!/bin/bash

# Install crontabs in /etc/crontab

# Create temporary crontab file
echo "Install crontabs in /etc/crontab...create a temporary crontab file first";
cp /etc/crontab /etc/onion-node/crontab-tmp;
echo "Temporary crontab file created";

# Set /bin/bash as SHELL
echo "Set Bash as SHELL";
sed -i "s/SHELL=\/bin\/sh/SHELL=\/bin\/bash/" /etc/onion-node/crontab-tmp;
echo "Bash is set as SHELL";

# Install new crontabs
echo "Setting new crontabs";
echo "###### Begin crontabs for bitcoin node ######" >> /etc/onion-node/crontab-tmp;
echo "#" >> /etc/onion-node/crontab-tmp;
echo "# Randomly reboot system every 2-4 weeks - a lockfile is set when run the first time" >> /etc/onion-node/crontab-tmp;
echo '0  0    * * *   root   /etc/onion-node/random-reboot.sh' >> /etc/onion-node/crontab-tmp;
echo "# Check every 24 hours at random interval if time of Tor is accurate and set new .onion address in bitcoin.conf" >> /etc/onion-node/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tor-date-check.sh; /etc/onion-node/bitcoin-new-onion-address.sh' >> /etc/onion-node/crontab-tmp;
echo "# Check every 24 hours at random interval if system time is accurate" >> /etc/onion-node/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m; /etc/onion-node/tlsdate-script.sh' >> /etc/onion-node/crontab-tmp;
echo "# Check every 30 minutes if Tor and bitcoind are running" >> /etc/onion-node/crontab-tmp;
echo '*/30  *    * * *   root   /etc/onion-node/check-tor-bitcoin-running.sh' >> /etc/onion-node/crontab-tmp;
echo "#" >> /etc/onion-node/crontab-tmp;
echo "###### End crontabs for bitcoin node ######" >> /etc/onion-node/crontab-tmp;
echo "#" >> /etc/onion-node/crontab-tmp;
echo "New crontabs set";

# Install new crontab file
echo "Installing new crontab file";
cp /etc/onion-node/crontab-tmp /etc/crontab;
echo "New /etc/crontab file has been installed";

# Remove temporary crontab file
echo "Removing temporary crontab file";
rm /etc/onion-node/crontab-tmp;
echo "Temporary crontab file has been removed";

echo "Crontab script is done";
