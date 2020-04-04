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

PACKAGES=(
	# install build tools
	git build-essential cmake ninja-build sudo nano

	# install tools
	rsync coreutils

	# install python venv and pytest
	python3-venv python3-pytest python3-pip

	# install qemu
	qemu-system-arm

	# install unit tests tools
	lcov libgtest-dev

	# install dependecies for the tools
	netcat libvdeplug-dev

	# install tools to create internal network
	iptables

	# install tools to debug internal network
	iputils-ping traceroute

	# entrypoint is used to config the network and revert back to normal user
	gosu

	psmisc

	vde2 libvdeplug2-dev libpcap0.8-dev openvpn check

	#install scapy
	python3-scapy tcpdump
)

apt-get install --no-install-recommends -y ${PACKAGES[@]}

# install python requirements for tests
pip3 install pytest-repeat

# in the latest ubuntu the name of the pytest executable has changed
ln -s /usr/bin/pytest-3 /usr/bin/pytest

cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

setcap cap_net_raw,cap_net_admin+eip /usr/bin/python3.7
setcap cap_net_raw,cap_net_admin+eip /usr/sbin/tcpdump


# cleanup
apt-get clean autoclean
apt-get autoremove --yes

