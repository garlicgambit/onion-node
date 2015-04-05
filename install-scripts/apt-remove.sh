#!/bin/bash

# General software cleanup
apt-get purge -y cifs-utils cups-bsd cups-client cups-common desktop-base dillo epiphany-browser epiphany-browser-data galculator gnome-icon-theme gnome-themes-standard gnome-themes-standard-data gpicview gstreamer1.0-* iputils-ping jackd jackd2 java-common krb5-locales lightdm lightdm-gtk-greeter lxappearance lxde lxde-common lxde-icon-theme lxinput lxmenu-data lxpolkit lxrandr lxsession lxsession-edit lxshortcut lxterminal minecraft-pi netcat-openbsd netcat-traditional nfs-common ntp omxplayer openbox openssh-client openssh-server oracle-java8-jdk penguinspuzzle pistore python-minecraftpi python-picamera python3-picamera raspberrypi-artwork rpcbind rsync ruby1.9.1 samba-common smartsim squeak-vm strace supercollider-common tcpd timidity traceroute tsconf wireless-tools wolfram-engine wpagui xpdf xserver-common;

# Cleanup network drivers 
apt-get purge -y firmware-atheros firmware-brcm80211 firmware-libertas firmware-ralink firmware-realtek;

# Cleanup leftovers
apt-get autoremove -y;
apt-get autoclean -y;
