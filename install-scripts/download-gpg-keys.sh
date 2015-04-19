#!/bin/bash
#
# Description:
# Download gpg keys
#
# TODO:
# - check tlsdate gpg key
# - check sks-keyservers.net key
# - automatically refresh gpg keys: parcimonie
# - randomize time between gpg key lookups: parcimonie
# - use different Tor circuits for gpg key lookups: parcimonie
# - might be better to add gpg key lookup to the relevant script,
#   instead of centralized script
#

# Bash options
set -o errexit # exit script when a command fails
set -o nounset # exit script when a variable is not set


# Variables
readonly MIN_TIME=60;
readonly MAX_TIME=300;
readonly RANDOM_TIME="$(shuf -i "${MIN_TIME}"-"${MAX_TIME}" -n 1)";


# Download gpg key Onion-node developer - Jules Mercier
tries=0;
while [[ "${tries}" -lt 10 ]]; do
  echo "Download gpg key onion-node developer Jules Mercier";
  gpg --recv-keys 4B8BBB5F5F2238A0BD72BE97F7698FEE3295ABB5 && break;
  sleep 30;
  tries=$(( ${tries} +1 ));
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: Downloading GPG key has failed.";
    echo "The script will exit now.";
    exit 0;
  fi
done;

# Sleep for 60-300 seconds between gpg key lookups
echo "Sleeping for "${RANDOM_TIME}" seconds";
sleep "${RANDOM_TIME}";

# Download gpg key Bitcoin developer - Wladimir J. van der Laan
tries=0;
while [[ "${tries}" -lt 10 ]]; do
  echo "Download gpg key bitcoin developer - Wladimir J. van der Laan";
  gpg --recv-keys 71A3B16735405025D447E8F274810B012346C9A6 && break;
  sleep 30;
  tries=$(( ${tries} +1 ));
  if [[ "${tries}" -eq 10 ]]; then
    echo "ERROR: Downloading GPG key has failed.";
    echo "The script will exit now.";
    exit 0;
  fi
done;
