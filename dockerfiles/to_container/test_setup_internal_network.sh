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

# filter RST packets send by the linux network stack (needed for scapy)
sudo iptables -A OUTPUT -p tcp --tcp-flags RST RST -s ${IP_ADDRESS} -j DROP