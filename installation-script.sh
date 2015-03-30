#!/bin/bash

# This script will configure a full Bitcoin onion node on a stock Raspbian install

# To do:
# - Install Tor first, then fetch all other apt packages via Tor

# Variables
BITCOINDIR=/home/pi/.bitcoin/;
BITCOINUSER=pi;
SCRIPTDIR=/etc/node-scripts/;

# Start installation
echo "";
echo "The installation of a bitcoin node takes about 1 to 1.5 hours";
sleep 4;
echo "It assumes the system has a clean Raspbian installation, a working network connection and can do DNS lookups";
sleep 4;
echo "If you have that covered, you can just check back in 1 to 1.5 hours";
sleep 10;
echo "Alright... here we go";
echo "";
sleep 3;


# Go to correct directory
cd "$SCRIPTDIR";

# Create directories
mkdir -p /root/.gnupg/;
mkdir -p "$BITCOINDIR";

# Copy files to correct locations
cp sysctl-kernel-hardening.conf /etc/sysctl.d/;
cp sources.list /etc/apt/;
cp collabora.list raspi.list /etc/apt/sources.list.d/;
cp interfaces /etc/network/;
cp dhclient.conf /etc/dhcp/;
cp gitconfig /root/.gitconfig;
cp sudoers /etc/;
cp 00-discard-dhclient.conf /etc/rsyslog.d/;
cp gpg.conf /root/.gnupg/;
cp hkps.pool.sks-keyservers.net.pem /etc/ssl/certs/;
cp bitcoin.conf "$BITCOINDIR";

# Set correct file/folder permissions
chmod 644 /etc/sysctl.d/sysctl-kernel-hardening.conf;
chown root:root /etc/sysctl.d/sysctl-kernel-hardening.conf;
chmod 644 /etc/apt/sources.list;
chown root:root /etc/apt/sources.list;
chmod 644 /etc/apt/sources.list.d/collabora.list /etc/apt/sources.list.d/raspi.list;
chown root:root /etc/apt/sources.list.d/collabora.list /etc/apt/sources.list.d/raspi.list;
chmod 744 /etc/network/interfaces;
chown root:root /etc/network/interfaces;
chmod 644 /etc/dhcp/dhclient.conf;
chown root:root /etc/dhcp/dhclient.conf;
chmod 644 /root/.gitconfig;
chown root:root /root/.gitconfig;
chmod 440 /etc/sudoers;
chown root:root /etc/sudoers;
chmod 644 /etc/rsyslog.d/00-discard-dhclient.conf;
chown root:root /etc/rsyslog.d/00-discard-dhclient.conf;
chmod 700 /root/.gnupg/;
chmod 600 /root/.gnupg/gpg.conf;
chown -R root:root /root/.gnupg/;
chmod 644 /etc/ssl/certs/hkps.pool.sks-keyservers.net.pem;
chown root:root /etc/ssl/certs/hkps.pool.sks-keyservers.net.pem;
chmod 700 "$BITCOINDIR";
chown -R "$BITCOINUSER":"$BITCOINUSER" "$BITCOINDIR";

# Run iptables-config.sh to configure iptables
./iptables-config-pre-tor.sh;
iptables-save > /etc/node-scripts/iptables.rules;

# Remove unnecessary packages - assume yes '-y'
./apt-remove.sh;

# Configure network interface to go up
ifdown eth0;
ifup eth0;

# Wait for DHCP ip address
echo "";
echo "Wait for DHCP ip address...sleeping 120 seconds";
echo "Now is a good time to plug in the network cable...if you have not done so yet";
echo "Otherwise, sit back and relax";
echo "";
sleep 120;

# Install packages - assume yes '-y'
./apt-install.sh;

# Allow Tor proces to connect to the web
./iptables-config.sh;
iptables-save > /etc/node-scripts/iptables.rules;

# Put torrc at correct location
cp /etc/tor/torrc /etc/tor/torrc-backup;
cp torrc /etc/tor/torrc;
chmod 644 /etc/tor/torrc;
chown debian-tor:debian-tor /etc/tor/torrc;
/etc/init.d/tor restart;
sleep 30;

# Run tor-date-check
./tor-date-check.sh;

# Wait for tor circuit
echo "Wait for Tor circuit...sleeping 120 seconds";
sleep 120;

# Download GPG keys
./download-gpg-keys.sh;

# Install tlsdate from source
./install-tlsdate.sh;

# Go to correct directory
cd "$SCRIPTDIR";

# Install bitcoin from source
./install-bitcoin.sh;

# Go to correct directory
cd "$SCRIPTDIR";

# Install bitcoin node crontabs
./install-crontabs.sh;

# Copy dhcp-script-bitcoin-node to correct location
cp dhcp-script-bitcoin-node /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;
chmod 744 /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;
chown root:root /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;

# Copy unattended-upgrade files to correct location
cp 20auto-upgrades 50unattended-upgrades /etc/apt/apt.conf.d/;
chmod 644 /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;
chown root:root /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;

# Done
echo "Script is done...system will reboot in 30 seconds";
sleep 30;
shutdown -r now;
