#!/bin/bash

# Install other software
apt-get install -y gnupg-curl macchanger unattended-upgrades;

# Install bitcoin dependencies
apt-get install -y autoconf build-essential libboost-chrono-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libtool libssl-dev;

# Install tlsdate dependencies
apt-get install -y autoconf autotools-dev build-essential fakeroot libevent-dev libssl-dev libtool pkg-config;
