#!/bin/bash
#
# Description:
# This script tries to bootstrap the current time in order to get Tor up and running.
#
# TODO:
# - Issues might arise when the system has been offline for a while + Tor consensus file exists + Tor hasn't established a circuit
#   system time will be in the future compared to Tor consensus
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly ONION_DIR=/etc/onion-node
readonly ANONDATE_SCRIPT="${ONION_DIR}"/anondate
readonly LOCK_DIR=/tmp/tor-bitcoin.lock/


# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script"
  exit 0
fi

# Set lockfile/dir - mkdir is atomic
# For portability flock or other Linux only tools are not used
if mkdir "${LOCK_DIR}"; then
  trap 'rmdir "${LOCK_DIR}"; exit' INT TERM EXIT # remove LOCKDIR when script is interrupted, terminated or finished
  echo "Successfully acquired lock on ${LOCK_DIR}"
else
  echo "Failed to acquire lock on ${LOCK_DIR}"
  exit 0
fi

# Only run when tor is running
if pgrep "tor" -u "debian-tor" >> /dev/null; then
  echo "Tor is running"
else
  echo "Tor is not running...starting tor"
  /etc/init.d/tor start
  echo "Tor is started"
  echo "Sleeping for 30 seconds to let the Tor process start smoothly"
  sleep 30
fi

# Check if Tor has consensus and check if Tor has an invalid certificate date
tries=0
while [[ $("${ANONDATE_SCRIPT}" --has-consensus) == "false" ]] && [[ "${tries}" -lt 40 ]]; do
  if "${ANONDATE_SCRIPT}" --tor-cert-lifetime-invalid | grep --quiet "wrong"; then
    echo "Time on Tor certificate NOT valid...setting time from Tor certificate"
    echo "Stopping Tor"
    /etc/init.d/tor stop
    echo "Sleeping for 30 seconds to let the Tor process stop smoothly"
    sleep 30
    date -s "$("${ANONDATE_SCRIPT}" --tor-cert-valid-after)"
    echo "New time is $(date +"%X %x")"
    echo "Removing old Tor logfile"
    rm -rf /var/log/tor/log
    echo "Starting Tor"
    /etc/init.d/tor start
    echo "Sleeping for 30 seconds to let the Tor process start smoothly"
    sleep 30
    break
  else
    echo "Tor has no consensus or Tor certificate time yet...waiting for 30 seconds"
    sleep 30
    tries=$(( ${tries} +1 ))
      if [[ "${tries}" -eq 20 ]]; then
        echo "Restart Tor to get Tor consensus"
        /etc/init.d/tor restart
        echo "Tor is restarted"
        echo "Sleeping for 30 seconds to let the Tor process restart smoothly"
        sleep 30
      fi
      if [[ "${tries}" -eq 40 ]]; then
        echo "Tor consensus not loaded...exiting script"
        exit 0
      fi
  fi
done

# Verify Tor time is in valid range
if [[ "$("${ANONDATE_SCRIPT}" --current-time-in-valid-range)" != "true" ]]; then
  echo "System time to far off Tor consensus"
  echo "Stopping Tor"
  /etc/init.d/tor stop
  echo "Sleeping for 30 seconds to let the Tor process stop smoothly"
  sleep 30
  echo "Tor service stopped"
  echo "Setting new system time based on Tor consensus"
  date -s "$("${ANONDATE_SCRIPT}" --show-middle-range)"
  echo "New system time is set to Tor consensus"
  echo "Remove old Tor log files"
  rm -rf /var/log/tor/log
  echo "Old Tor log files removed"
  echo "Starting Tor..."
  /etc/init.d/tor start
  echo "Sleeping for 30 seconds to let the Tor process start smoothly"
  sleep 30;  
  echo "Tor started"
else
  echo "The system time is within the Tor consensus"
fi
