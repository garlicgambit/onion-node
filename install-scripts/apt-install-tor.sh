#!/bin/bash

# Fetch updates
apt-get update;

# Install updates
apt-get upgrade -y;

# Install Tor
apt-get install -y tor;
