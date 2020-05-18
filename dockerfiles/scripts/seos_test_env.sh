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


PACKAGES=(
    sudo nano
    rsync coreutils psmisc
    git build-essential cmake ninja-build
    python3-git python3-gitdb
    astyle clang-tidy
    doxygen graphviz
    # unit tests tools
    cppcheck check lcov libgtest-dev
    python3-pip python3-venv python3-pytest
    # network tools
    libvdeplug-dev vde2 libvdeplug2-dev libpcap0.8-dev
    netcat iptables tcpdump iputils-ping traceroute openvpn python3-scapy
    # entrypoint is used to config the network and revert back to normal user
    gosu
    # QEMU
    qemu-system-arm
    qemu-system-riscv64
)
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# install python requirements for tests
pip3 install pytest-repeat

# in the latest ubuntu the name of the pytest executable has changed
ln -s /usr/bin/pytest-3 /usr/bin/pytest

# gtest
cd /usr/src/gtest && cmake CMakeLists.txt && make && cp lib/*.a /usr/lib

setcap cap_net_raw,cap_net_admin+eip /usr/bin/python3.8
setcap cap_net_raw,cap_net_admin+eip /usr/sbin/tcpdump



