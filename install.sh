#!/bin/bash

# This script will configure a full Bitcoin onion node on a stock Raspbian install

# To do:
# - Nothing yet 

# Variables
BITCOINUSER=pi;
BITCOINDIR=/home/"$BITCOINUSER"/.bitcoin;
SCRIPTDIR=/etc/node-scripts;
CONFIGFILES="$SCRIPTDIR"/config-files;
INSTALLSCRIPTS="$SCRIPTDIR"/install-scripts;

# Start installation
echo "";
echo "The installation of a bitcoin node takes about 1 to 1.5 hours";
sleep 4;
echo "It assumes the system has a clean Raspbian installation, a working network connection and can do DNS lookups";
sleep 5;
echo "If you have that covered, you can just check back in 1 to 1.5 hours";
sleep 10;
echo "Alright... here we go";
echo "";
sleep 3;


# Create directories
mkdir -p /root/.gnupg/;
mkdir -p "$BITCOINDIR";

# Copy files to correct locations
cp "$CONFIGFILES"/sysctl-kernel-hardening.conf /etc/sysctl.d/;
cp "$CONFIGFILES"/sources.list /etc/apt/;
cp "$CONFIGFILES"/collabora.list /etc/apt/sources.list.d/;
cp "$CONFIGFILES"/raspi.list /etc/apt/sources.list.d/;
cp "$CONFIGFILES"/interfaces /etc/network/;
cp "$CONFIGFILES"/dhclient.conf /etc/dhcp/;
cp "$CONFIGFILES"/gitconfig /root/.gitconfig;
cp "$CONFIGFILES"/sudoers /etc/;
cp "$CONFIGFILES"/00-discard-dhclient.conf /etc/rsyslog.d/;
cp "$CONFIGFILES"/gpg.conf /root/.gnupg/;
cp "$CONFIGFILES"/hkps.pool.sks-keyservers.net.pem /etc/ssl/certs/;
cp "$CONFIGFILES"/bitcoin.conf "$BITCOINDIR";

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
"$INSTALLSCRIPTS"/iptables-config-pre-tor.sh;
iptables-save > /etc/node-scripts/iptables.rules;

# Remove unnecessary packages - assume yes '-y'
"$INSTALLSCRIPTS"/apt-remove.sh;

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

# Install latest updates and Tor - assume yes '-y'
"$INSTALLSCRIPTS"/apt-install-tor.sh;

# Allow Tor proces to connect to the web
"$INSTALLSCRIPTS"/iptables-config.sh;
iptables-save > /etc/node-scripts/iptables.rules;

# Put torrc at correct location
cp /etc/tor/torrc /etc/tor/torrc-backup;
cp "$CONFIGFILES"/torrc /etc/tor/torrc;
chmod 644 /etc/tor/torrc;
chown debian-tor:debian-tor /etc/tor/torrc;
/etc/init.d/tor restart;
sleep 30;

# Run tor-date-check
"$SCRIPTDIR"/tor-date-check.sh;

# Wait for tor circuit
echo "Wait for Tor circuit...sleeping 5 minutes";
sleep 300;

# Install other packages - assume yes '-y'
"$INSTALLSCRIPTS"/apt-install-packages.sh;

# Download GPG keys
"$INSTALLSCRIPTS"/download-gpg-keys.sh;

# Install tlsdate from source
"$INSTALLSCRIPTS"/install-tlsdate.sh;

# Install bitcoin from source
"$INSTALLSCRIPTS"/install-bitcoin.sh;

# Install bitcoin node crontabs
"$INSTALLSCRIPTS"/install-crontabs.sh;

# Copy dhcp-script-bitcoin-node to correct location
cp "$CONFIGFILES"/dhcp-script-bitcoin-node /etc/dhcp/dhclient-exit-hooks.d/;
chmod 744 /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;
chown root:root /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;

# Copy unattended-upgrade files to correct location
cp "$CONFIGFILES"/20auto-upgrades /etc/apt/apt.conf.d/;
cp "$CONFIGFILES"/50unattended-upgrades /etc/apt/apt.conf.d/;
chmod 644 /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;
chown root:root /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;

# Done
echo "Script is done...system will reboot in 30 seconds";
sleep 30;
shutdown -r now;
