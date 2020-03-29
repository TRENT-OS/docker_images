#!/bin/bash 

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# add the user
useradd -u ${USER_ID} ${USER_NAME} -d /home/${USER_NAME}
mkdir /home/${USER_NAME}
adduser ${USER_NAME} sudo
passwd -d ${USER_NAME}
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}
chmod -R ug+rw /home/${USER_NAME}

apt-get update

# install build tools
apt-get install --no-install-recommends -y git build-essential cmake ninja-build sudo nano

# install tools
apt-get install --no-install-recommends -y rsync coreutils

# install python venv and pytest
apt-get install --no-install-recommends -y python3-venv python3-pytest python3-pip

# install python requirements for tests
pip3 install pytest-repeat

# in the latest ubuntu the name of the pytest executable has changed
ln -s /usr/bin/pytest-3 /usr/bin/pytest

# install qemu
apt-get install --no-install-recommends -y qemu-system-arm

# install unit tests tools
apt-get install --no-install-recommends -y lcov libgtest-dev
cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

# install dependecies for the tools
apt-get install --no-install-recommends -y netcat libvdeplug-dev

# install tools to create internal network
apt-get install --no-install-recommends -y iptables

# install tools to debug internal network
apt-get install --no-install-recommends -y iputils-ping traceroute

# entrypoint is used to config the network and revert back to normal user
apt-get install --no-install-recommends -y gosu

apt-get install --no-install-recommends -y psmisc

apt-get install --no-install-recommends -y vde2 libvdeplug2-dev libpcap0.8-dev openvpn check

#install scapy
apt-get install --no-install-recommends -y python3-scapy tcpdump


setcap cap_net_raw,cap_net_admin+eip /usr/bin/python3.7
setcap cap_net_raw,cap_net_admin+eip /usr/sbin/tcpdump


# cleanup
apt-get clean autoclean
apt-get autoremove --yes

