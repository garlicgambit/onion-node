#!/bin/bash

# Install crontabs in /etc/crontab

# Create temporary crontab file
echo "Install crontabs in /etc/crontab...create a temporary crontab file first";
cp /etc/crontab /etc/node-scripts/crontab-tmp;
echo "Temporary crontab file created";

# Set /bin/bash as SHELL
echo "Set Bash as SHELL";
sed -i "s/SHELL=\/bin\/sh/SHELL=\/bin\/bash/" /etc/node-scripts/crontab-tmp;
echo "Bash is set as SHELL";

# Install new crontabs
echo "Setting new crontabs";
echo "###### Begin crontabs for bitcoin node ######" >> /etc/node-scripts/crontab-tmp;
echo "#" >> /etc/node-scripts/crontab-tmp;
echo "# Check every 24 hours at random interval if time of Tor is accurate and set new .onion address in bitcoin.conf" >> /etc/node-scripts/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m ; /etc/node-scripts/tor-date-check.sh; /etc/node-scripts/bitcoin-new-onion-address.sh' >> /etc/node-scripts/crontab-tmp;
echo "# Check every 24 hours at random interval if system time is accurate" >> /etc/node-scripts/crontab-tmp;
echo '0  0    * * *   root   /bin/sleep $(($RANDOM \% 1435))m ; /etc/node-scripts/tlsdate-script.sh' >> /etc/node-scripts/crontab-tmp;
echo "#" >> /etc/node-scripts/crontab-tmp;
echo "###### End crontabs for bitcoin node ######" >> /etc/node-scripts/crontab-tmp;
echo "#" >> /etc/node-scripts/crontab-tmp;
echo "New crontabs set";

# Install new crontab file
echo "Installing new crontab file";
cp /etc/node-scripts/crontab-tmp /etc/crontab;
echo "New /etc/crontab file has been installed";

# Remove temporary crontab file
echo "Removing temporary crontab file";
rm /etc/node-scripts/crontab-tmp;
echo "Temporary crontab file has been removed";

echo "Crontab script is done";
