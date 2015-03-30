#!/bin/bash

# Get time with tlsdate at random site at random time

# Right now this is just a simple solution to get/set the current time from a list of remote sources at a random time
# Probably need to look around for other solutions like: sdwdate, bitcoin timeoffset, etc.

# To Do
# - Would like to add .onion websites
# - Ask site owners for permission to add site to list
# - Maybe add some dedicated sites/servers for time checking
# - Might integrate with renewing tor/bitcoin .onion address, to prevent problems with availability Tor process, but this might make profiling easier. Try this for now.

# ISSUES
# - No sanity checking on time results
# - Single point of failure; not checking time from multiple sources and comparing them

# Only run as root
if [[ "$(id -u)" != "0" ]]; then
  echo "ERROR: Must be run as root...exiting script";
  exit 0;
fi 

# Check if tor is available 
# We do not start the Tor process here, that is done with the refresh .onion address script
TRIES=0;
while [[ "$(pgrep "tor" -u debian-tor >> /dev/null && echo "Running")" != "Running" ]] && [[ "$TRIES" -lt 8 ]]; do
  echo "Tor is not running...waiting for 30 seconds";
  sleep 30;
  TRIES=$(( $TRIES +1 ));
  if [[ "$TRIES" -eq 8 ]]; then
    echo "Tor is not running...checking at a later time...exiting script";
    exit 0;
  fi 
done;

# List of websites
arr[0]="www.riseup.net"
arr[1]="www.eff.org"
arr[2]="www.theprivacyblog.com"
arr[3]="www.aclu.org"
arr[4]="www.fsf.org"
arr[5]="www.1984.is"
arr[6]="www.privacyassociation.org"
arr[7]="www.democracynow.org"
arr[8]="www.debian.org"
arr[9]="www.grc.com"
arr[10]="www.mageia.org"
arr[11]="www.gnu.org"
arr[12]="www.mozilla.org"
arr[13]="www.startpage.com"
arr[14]="www.ixquick.com"
arr[15]="www.lkml.com"
arr[16]="www.ipredator.se"
arr[17]="www.linux.com"
arr[18]="www.mirbsd.org"
arr[19]="www.duckduckgo.com"
arr[20]="www.fedoraproject.org"
arr[21]="gnunet.org"
arr[22]="www.kernel.org"
arr[23]="www.bitcointalk.com"
arr[24]="www.guardianproject.info"
arr[25]="www.xkcd.com"

# Hosts that give wrong results
# www.epic.org - wrong time
# www.privacyinternational.org - wrong time
# www.apache.org - wrong certificate
# www.lkml.org - wrong time
# www.blokko.com - wrong time
# www.ghostery.com - wrong time
# + more...

RANDOMNUMBER=$[ $RANDOM % 26 ];

RANDOMDOMAIN=${arr["$RANDOMNUMBER"]};

# Debug tlsdate command
#/usr/local/bin/tlsdate -n -v -V -x socks5://127.0.0.1:9250 -H "$RANDOMDOMAIN";

# Actual tlsdate command
/usr/local/bin/tlsdate -x socks5://127.0.0.1:9250 -H "$RANDOMDOMAIN";

echo "Script is done";
