#!/bin/bash

set -eu

# This script tries to bootstrap the current time in order to get Tor up and running.

# To Do:
# - Issues might arise when the system has been offline for a while + Tor consensus file exists + Tor hasn't established a circuit
#   system time will be in the future compared to Tor consensus

# Variables
PATH=$PATH:/etc/onion-node/;
LOCKDIR=/tmp/tor-bitcoin.lock/;


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "$LOCKDIR"; then
  trap 'rmdir "$LOCKDIR"; exit' INT TERM EXIT; # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on "$LOCKDIR"";
else
  echo "Failed to acquire lock on "$LOCKDIR"";
  exit 0;
fi

# Only run when tor is running
if [[ "$(pgrep "tor" -u debian-tor >> /dev/null && echo "Running")" == "Running" ]]; then
  echo "Tor is running";
else
  echo "Tor is not running...starting tor";
  /etc/init.d/tor start;
  echo "Tor is started";
  echo "Sleeping for 30 seconds to let the Tor process start smoothly";
  sleep 30;
fi

# Check if Tor has consensus and check if Tor has an invalid certificate date
TRIES=0;
while [[ $(anondate --has-consensus) == "false" ]] && [[ "$TRIES" -lt 40 ]]; do
  if [[ "$(anondate --tor-cert-lifetime-invalid | grep "wrong")" ]]; then
    echo "Time on Tor certificate NOT valid...setting time from Tor certificate";
    echo "Stopping Tor";
    /etc/init.d/tor stop;
    echo "Sleeping for 30 seconds to let the Tor process stop smoothly";
    sleep 30;
    date -s "$(anondate --tor-cert-valid-after)";
    echo "New time is $(date +"%X %x")";
    echo "Removing old Tor logfile";
    rm -rf /var/log/tor/log;
    echo "Starting Tor";
    /etc/init.d/tor start;
    echo "Sleeping for 30 seconds to let the Tor process start smoothly";
    sleep 30;
    break;
  else
    echo "Tor has no consensus or Tor certificate time yet...waiting for 30 seconds";
    sleep 30;
    TRIES=$(( $TRIES +1 ));
      if [[ "$TRIES" -eq 20 ]]; then
        echo "Restart Tor to get Tor consensus";
        /etc/init.d/tor restart;
        echo "Tor is restarted";
        echo "Sleeping for 30 seconds to let the Tor process restart smoothly";
        sleep 30;
      fi
      if [[ "$TRIES" -eq 40 ]]; then
        echo "Tor consensus not loaded...exiting script";
        exit 0;
      fi
  fi
done

# Verify Tor time is in valid range
if [[ "$(anondate --current-time-in-valid-range)" != "true" ]]; then
  echo "System time to far off Tor consensus";
  echo "Stopping Tor";
  /etc/init.d/tor stop;
  echo "Sleeping for 30 seconds to let the Tor process stop smoothly";
  sleep 30;
  echo "Tor service stopped";
  echo "Setting new system time based on Tor consensus";
  date -s "$(anondate --show-middle-range)";
  echo "New system time is set to Tor consensus";
  echo "Remove old Tor log files";
  rm -rf /var/log/tor/log;
  echo "Old Tor log files removed";
  echo "Starting Tor...";
  /etc/init.d/tor start;
  echo "Sleeping for 30 seconds to let the Tor process start smoothly";
  sleep 30;  
  echo "Tor started";
else
  echo "The system time is within the Tor consensus";
fi
