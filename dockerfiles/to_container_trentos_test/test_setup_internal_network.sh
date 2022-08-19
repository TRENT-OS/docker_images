#!/bin/bash

# This script must run with proper access rights, usually via sudo.

set -euxo pipefail

BRIDGE_NAME=br0
TAP_INTERFACES=(tap0 tap1 tap2 tap3)
IP_ADDRESS=10.0.0.1
# netmask length in bits
NETWORK_SIZE=24

# create the bridge
ip link add ${BRIDGE_NAME} type bridge

# add TAP devices to bridge
for TAP in "${TAP_INTERFACES[@]}"; do
    ip tuntap add ${TAP} mode tap
    ip link set ${TAP} master ${BRIDGE_NAME}
    ip link set ${TAP} up
done

ip addr add ${IP_ADDRESS}/${NETWORK_SIZE} dev ${BRIDGE_NAME}
ip link set ${BRIDGE_NAME} up

# enable NAT of the internal network
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i ${BRIDGE_NAME} -j ACCEPT

# forward external packets through nat
# used by echo server (port 5555)
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 5555 -j DNAT --to 10.0.0.11:5555
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 5555 -j DNAT --to 10.0.0.11:5555

# used by filter demo
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 5560 -j DNAT --to 10.0.0.10:5560
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 5560 -j DNAT --to 10.0.0.10:5560

# forward port range 10000:10999 to 10.0.0.10
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 10000:10999 -j DNAT --to 10.0.0.10:10000-10999
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 10000:10999 -j DNAT --to 10.0.0.10:10000-10999

# forward port range 11000:11999 to 10.0.0.11
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 11000:11999 -j DNAT --to 10.0.0.11:11000-11999
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 11000:11999 -j DNAT --to 10.0.0.11:11000-11999

# Filter RST packets send by the linux network stack (needed for scapy).
# There is one test expecting a RST packet. This is why we add an exception
# rule here and allow the sending of RST is the source and destination ports
# are 88.
iptables -A OUTPUT -p tcp --sport 88 --tcp-flags RST RST -s ${IP_ADDRESS} --dport 88 -j ACCEPT
iptables -A OUTPUT -p tcp --tcp-flags RST RST -s ${IP_ADDRESS} -j DROP
