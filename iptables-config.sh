#!/bin/bash

# Configure iptables firewall

# What to expect from this configuration:
# - Default deny policy
# - Only accepts outbound Tor traffic from the 'debian-tor' user
# - UDP port 53 (DNS) for the root user is redirected to a Tor DNSPort, this is to allow outbound Apt and Git traffic
# - UDP port 67 (DHCP) for the root user allowed for outbound DHCP traffic
# - TCP port 80 (HTTP) for the root user is redirected to a Tor Transport, this is to allow outbound Apt traffic

# To Do:
# - Nothing yet

# Variables
IPTABLES=/sbin/iptables;
ECHO=/bin/echo;
TOR_UID=`id -u debian-tor`;
TOR_DNS_PORT=9053;
TOR_TRANSPORT1=9550;
TOR_TRANSPORT2=9650; # Not in use
TOR_TRANSPORT3=9750; # Not in use
LAN_INT=eth0;

# Flush iptables chains
"$ECHO" "Flush iptables chains";
"$IPTABLES" -F;
"$IPTABLES" -t nat -F;
"$ECHO" "iptables flushed";

# iptables default policies
"$ECHO" "Loading iptables DROP policies";
"$IPTABLES" -P INPUT DROP;
"$IPTABLES" -P OUTPUT DROP;
"$IPTABLES" -P FORWARD DROP;
"$ECHO" "iptables DROP policies loaded";


# INPUT chain
"$ECHO" "Loading INPUT chain";

# Drop invalid packets
"$IPTABLES" -A INPUT -m state --state INVALID -j DROP;

# Drop invalid syn packets
"$IPTABLES" -A INPUT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP;
"$IPTABLES" -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP;
"$IPTABLES" -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP;

# Drop incoming fragments
"$IPTABLES" -A INPUT -f -j DROP;

# Drop incoming xmas packets
"$IPTABLES" -A INPUT -p tcp --tcp-flags ALL ALL -j DROP;

# Drop incoming null packets
"$IPTABLES" -A INPUT -p tcp --tcp-flags ALL NONE -j DROP;

# Normal INPUT rules
"$IPTABLES" -A INPUT -i lo -j ACCEPT;
"$IPTABLES" -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT;

### Logging is disabled to extend lifetime SD cards ###
#"$IPTABLES" -A INPUT -j LOG;
"$IPTABLES" -A INPUT -j DROP;
"$ECHO" "INPUT chain loaded";


# OUTPUT chain
"$ECHO" "Loading OUTPUT chain";

# Drop invalid packets
"$IPTABLES" -A OUTPUT -m state --state INVALID -j DROP;

# Prevent Tor transport data leaks
"$IPTABLES" -A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,FIN ACK,FIN -j DROP;
"$IPTABLES" -A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,RST ACK,RST -j DROP;

# Normal OUTPUT rules
"$IPTABLES" -A OUTPUT -o lo -j ACCEPT;
"$IPTABLES" -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT;
"$IPTABLES" -A OUTPUT -o "$LAN_INT" -d 127.0.0.1 -p udp --dport "$TOR_DNS_PORT" -m state --state NEW -m owner --uid-owner 0 -j ACCEPT;
"$IPTABLES" -A OUTPUT -o "$LAN_INT" -d 127.0.0.1 -p tcp --dport "$TOR_TRANSPORT1" --syn -m state --state NEW -m owner --uid-owner 0 -j ACCEPT;
"$IPTABLES" -A OUTPUT -o "$LAN_INT" -p tcp --syn -m state --state NEW -m owner --uid-owner "$TOR_UID" -j ACCEPT;
"$IPTABLES" -A OUTPUT -o "$LAN_INT" -p udp --dport 67 -m state --state NEW -m owner --uid-owner 0 -j ACCEPT;

### Logging is disabled to extend lifetime SD cards ###
#"$IPTABLES" -A OUTPUT -j LOG --log-uid;
"$IPTABLES" -A OUTPUT -j DROP;
"$ECHO" "OUTPUT chain loaded";


# PREROUTING chain
"$ECHO" "Loading PREROUTING chain";
# Redirect DNS traffic from root to TOR_DNS_PORT
"$IPTABLES" -t nat -A OUTPUT -o "$LAN_INT" -p udp --dport 53 -m state --state NEW -m owner --uid-owner 0 -j REDIRECT --to-ports "$TOR_DNS_PORT";
# Redirect HTTP traffic from root to TOR_TRANSPORT
"$IPTABLES" -t nat -A OUTPUT -o "$LAN_INT" -p tcp --dport 80 --syn -m state --state NEW -m owner --uid-owner 0 -j REDIRECT --to-ports "$TOR_TRANSPORT1";
"$ECHO" "PREROUTING chain loaded";

"$ECHO" "iptables script loaded";
