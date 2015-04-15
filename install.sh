#!/bin/bash

# This script will configure a full Bitcoin onion node on a stock Raspbian install

# To do:
# - Nothing yet 

# Variables
DEFAULT_USER=pi;
BITCOIN_USER=bitcoinuser;
BITCOIN_DIR=/home/"${BITCOIN_USER}"/.bitcoin;
ONION_DIR=/etc/onion-node;
CONFIG_FILES="${ONION_DIR}"/config-files;
INSTALL_SCRIPTS="${ONION_DIR}"/install-scripts;
APT_PACKAGE=macchanger; # This package should be installed with apt-install-packages.sh
LOCK_DIR=/tmp/tor-bitcoin.lock/;

# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

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

# Check if a lockfile/LOCKDIR exists, wait max 2 hours
TRIES=0
while [[ -d "${LOCK_DIR}" ]] && [[ "$TRIES" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0;
fi

# Make install.sh script re-runnable

# Stop bitcoin process
"${ONION_DIR}"/bitcoin-control.sh

# Remove unattended-upgrades file
if [[ -r /etc/apt/apt.conf.d/20auto-upgrades ]]; then
  rm /etc/apt/apt.conf.d/20auto-upgrades;
fi

# Remove unattended-upgrades file
if [[ -r /etc/apt/apt.conf.d/50unattended-upgrades ]]; then
  rm /etc/apt/apt.conf.d/50unattended-upgrades;
fi

# Remove user pi from 'adm' group
deluser "${DEFAULT_USER}" adm;

# Create bitcoinuser - this user runs the bitcoind process
useradd --create-home "${BITCOIN_USER}";

# Lockdown bitcoinuser account - disable shell access and disable login
usermod --shell /usr/sbin/nologin --lock --expiredate 1 "${BITCOIN_USER}";

# Create directories
mkdir -p /root/.gnupg/;
mkdir -p "${BITCOIN_DIR}";

# Copy files to correct locations
cp "${CONFIG_FILES}"/sysctl-kernel-hardening.conf /etc/sysctl.d/;
cp "${CONFIG_FILES}"/sources.list /etc/apt/;
cp "${CONFIG_FILES}"/collabora.list /etc/apt/sources.list.d/;
cp "${CONFIG_FILES}"/raspi.list /etc/apt/sources.list.d/;
cp "${CONFIG_FILES}"/interfaces /etc/network/;
cp "${CONFIG_FILES}"/dhclient.conf /etc/dhcp/;
cp "${CONFIG_FILES}"/gitconfig /root/.gitconfig;
cp "${CONFIG_FILES}"/sudoers /etc/;
cp "${CONFIG_FILES}"/00-discard-dhclient.conf /etc/rsyslog.d/;
cp "${CONFIG_FILES}"/gpg.conf /root/.gnupg/;
cp "${CONFIG_FILES}"/hkps.pool.sks-keyservers.net.pem /etc/ssl/certs/;
cp "${CONFIG_FILES}"/bitcoin.conf "${BITCOIN_DIR}";

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
chmod 700 "${BITCOIN_DIR}";
chown -R "${BITCOIN_USER}":"${BITCOIN_USER}" "${BITCOIN_DIR}";

# Run iptables-config.sh to configure iptables
"${INSTALL_SCRIPTS}"/iptables-config-pre-tor.sh;
iptables-save > "${ONION_DIR}"/iptables.rules;

# Remove unnecessary packages - assume yes '-y'
"${INSTALL_SCRIPTS}"/apt-remove.sh;

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
"${INSTALL_SCRIPTS}"/apt-install-tor.sh;

# Allow Tor proces to connect to the web
"${INSTALL_SCRIPTS}"/iptables-config.sh;
iptables-save > "${ONION_DIR}"/iptables.rules;

# Put torrc at correct location
cp /etc/tor/torrc /etc/tor/torrc-backup;
cp "${CONFIG_FILES}"/torrc /etc/tor/torrc;
chmod 644 /etc/tor/torrc;
chown debian-tor:debian-tor /etc/tor/torrc;
/etc/init.d/tor restart;
sleep 30;

# Run tor-date-check
rmdir "${LOCK_DIR}"; # tor-date-check.sh has it's own lockfile
"${ONION_DIR}"/tor-date-check.sh;

# Check if a lockfile/LOCKDIR exists, wait max 2 hours
TRIES=0
while [[ -d "${LOCK_DIR}" ]] && [[ "$TRIES" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0;
fi

# Check if APTPACKAGE is installed, if not run apt-install-packages.sh
# Sometimes Tor is really slow to setup a circuit and needs a request to get started
# So the apt-get requests might fail the first time, because no Tor circuit is available
# Hopefully apt will work in a later run...
TRIES=0
while [[ ! $(dpkg-query -W "${APT_PACKAGE}" 2>/dev/null ) ]] && [[ "$TRIES" -lt 20 ]]; do
  echo ""${APT_PACKAGE}" is not installed...will run apt-install-packages.sh";
  "${INSTALL_SCRIPTS}"/apt-install-packages.sh;
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ $TRIES -eq 20 ]]; then
    echo "ERROR: "${APT_PACKAGE}" is not installed";
    echo "The installation has failed...probably due to network/Tor issues";
    echo "Check network/Tor connection and run the installer again and see if you get better results";
    echo "The installation is aborted";
    exit 0;
  fi
done;

# Download GPG keys
"${INSTALL_SCRIPTS}"/download-gpg-keys.sh;

# Install tlsdate from source
rmdir "${LOCK_DIR}"; # install-tlsdate.sh has it's own lockfile
"${INSTALL_SCRIPTS}"/install-tlsdate.sh;

# Check if a lockfile/LOCKDIR exists, wait max 2 hours
TRIES=0
while [[ -d "${LOCK_DIR}" ]] && [[ "$TRIES" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0;
fi

# Install bitcoin from source
rmdir "${LOCK_DIR}"; # install-bitcoin.sh has it's own lockfile
"${INSTALL_SCRIPTS}"/install-bitcoin.sh;

# Check if a lockfile/LOCKDIR exists, wait max 2 hours
TRIES=0
while [[ -d "${LOCK_DIR}" ]] && [[ "$TRIES" -lt 120 ]]; do
  echo "Temporarily not able to acquire lock on "${LOCK_DIR}"";
  echo "Other processes might be running...retry in 60 seconds";
  sleep 60;
  TRIES=$(( $TRIES +1 ));
done;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "${LOCK_DIR}"";
else
  echo "Failed to acquire lock on "${LOCK_DIR}"";
  echo "The installation script failed...run the install.sh script again to see if you get better results."
  echo "Tip: Reboot the system if the installation keeps failling."
  exit 0;
fi

# Install bitcoin node crontabs
"${INSTALL_SCRIPTS}"/install-crontabs.sh;

# Copy dhcp-script-bitcoin-node to correct location
cp "${CONFIG_FILES}"/dhcp-script-bitcoin-node /etc/dhcp/dhclient-exit-hooks.d/;
chmod 744 /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;
chown root:root /etc/dhcp/dhclient-exit-hooks.d/dhcp-script-bitcoin-node;

# Copy unattended-upgrade files to correct location
cp "${CONFIG_FILES}"/20auto-upgrades /etc/apt/apt.conf.d/;
cp "${CONFIG_FILES}"/50unattended-upgrades /etc/apt/apt.conf.d/;
chmod 644 /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;
chown root:root /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/50unattended-upgrades;

# Done
echo "Script is done...system will reboot in 30 seconds";
sleep 30;
shutdown -r now;
