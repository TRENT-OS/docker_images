#!/bin/bash

set -euxo pipefail

BRIDGE_NAME=br0
TAP_INTERFACES=(tap0 tap1)
IP_ADDRESS=10.0.0.1
# netmask length in bits
NETWORK_SIZE=24

# create the bridge
sudo ip link add ${BRIDGE_NAME} type bridge

# add TAP devices to bridge
for TAP in "${TAP_INTERFACES[@]}"; do
    sudo ip tuntap add ${TAP} mode tap
    sudo ip link set ${TAP} master ${BRIDGE_NAME}
    sudo ip link set ${TAP} up
done

sudo ip addr add ${IP_ADDRESS}/${NETWORK_SIZE} dev ${BRIDGE_NAME}
sudo ip link set ${BRIDGE_NAME} up

# enable NAT of the internal network
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i ${BRIDGE_NAME} -j ACCEPT

# forward external packets through nat
# used by echo server (port 5555)
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 5555 -j DNAT  --to 10.0.0.11:5555
sudo iptables -t nat -A PREROUTING -i eth0 -p udp --dport 5555 -j DNAT  --to 10.0.0.11:5555

# Filter RST packets send by the linux network stack (needed for scapy).
# There is one test expecting a RST packet. This is why we add an exception 
# rule here and allow the sending of RST is the source and destination ports
# are 88.
sudo iptables -A OUTPUT -p tcp --sport 88 --tcp-flags RST RST -s ${IP_ADDRESS} --dport 88 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --tcp-flags RST RST -s ${IP_ADDRESS} -j DROP
