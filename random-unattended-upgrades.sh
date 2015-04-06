#!/bin/bash

set -eu

# Automatically install system updates at a random interval

# Variables

# 216000 seconds is 5 days
MINTIME=0;
MAXTIME=216000;
RANDOMTIME="$(shuf -i "$MINTIME"-"$MAXTIME" -n 1)";
LOCKDIR=/tmp/random-unattended-upgrades.lock/;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  exit 0;
fi

# Random sleep
echo "Sleeping for "$RANDOMTIME" seconds";
sleep "$RANDOMTIME";

# Update repositories
apt-get update;

# Install system updates
unattended-upgrades;
