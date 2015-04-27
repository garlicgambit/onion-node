#!/bin/bash
#
# Description:
# Control the bitcoind process
#
# TODO:
# - Nothing yet...
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly BITCOIN_USER=bitcoinuser


# Check whether the bitcoind process is running
if pgrep "bitcoind" >> /dev/null; then
  echo "The bitcoind process is running."
else
 echo "The bitcoind process is not running."
 exit 0
fi

# Check wether the bitcoind process is ready to receive stop command - check for 30 minutes
tries=0
while ! sudo -u "${BITCOIN_USER}" bitcoin-cli getinfo >> /dev/null && [[ "${tries}" -lt 60 ]]; do
  echo "bitcoin-cli is not ready to accept commands...sleeping for 30 seconds"
  sleep 30
  tries=$(( ${tries} +1 ))
done

# Stop the bitcoind process - whether the bitcoind command is ready or not
echo "Stopping bitcoind process"
sudo -u "${BITCOIN_USER}" bitcoin-cli stop
echo "Sent bitcoind process the stop signal"

# Wait till the bitcoind process is gone - check for 30 minutes
tries=0
while pgrep "bitcoind" >> /dev/null && [[ "${tries}" -lt 60 ]]; do
  echo "bitcoind is still running...sleeping for 30 seconds"
  sleep 30
  tries=$(( ${tries} +1 ))
done

# Kill the bitcoind process if it is still running at this stage
tries=0
while pgrep "bitcoind" >> /dev/null && [[ "${tries}" -lt 10 ]]; do
  echo "bitcoind process is still running at this late state...not a good sign...going to kill it nicely now"
  pkill bitcoind
  echo "Sleep for 30 seconds...and check again"
  sleep 30
  tries=$(( ${tries} +1 ))
  if [[ "${tries}" -eq 5 ]]; then
    echo "bitcoind process still running... send kill -9 signal for bitcoind process"
    pkill -9 bitcoind
    sleep 10
  fi
done

echo "Script is done"
