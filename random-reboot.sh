#!/bin/bash

set -eu

# Automatically reboot the system every 2-4 weeks
# This is an unattended device, so a regular reboot might fix some system issues

# To do:
# - set crontab every day at 0 0 * * *

# Variables

# 1209600 seconds is 2 weeks, 2419200 seconds is 4 weeks
MINTIME=1209600;
MAXTIME=2419200;
RANDOMTIME="$(shuf -i "$MINTIME"-"$MAXTIME" -n 1)";
LOCKDIR=/tmp/randomreboot.lock/;

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  exit 0;
fi

# Sleep for 2-4 weeks
echo "Sleeping for "$RANDOMTIME" seconds";
sleep "$RANDOMTIME";

# Reboot system
shutdown -r 0;
