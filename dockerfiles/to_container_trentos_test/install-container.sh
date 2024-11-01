#!/bin/bash

#
# Copyright (C) 2019-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#

set -euxo pipefail

# ensure apt family tools and pip3 don't try and user interaction
export DEBIAN_FRONTEND=noninteractive

USER_ID="$1"
USER_NAME="$2"

# install latest updates and clean up afterwards, so any changes are clearly
# visible in the logs.
apt-get update
apt-get upgrade -y
apt-get clean autoclean
apt-get autoremove --yes --purge

# add the user and set an empty passed
useradd --create-home --uid ${USER_ID} -G sudo ${USER_NAME}
passwd -d ${USER_NAME}

PACKAGES=(
    sudo
    gosu
    ca-certificates
    coreutils
    rsync
    psmisc
    bzip2
    xz-utils
    wget
    curl
    picocom
    lrzsz
    nano
    mc
    # network tools
    iproute2
    iptables
    iputils-ping
    netcat
    openvpn
    tcpdump
    traceroute
    tshark
    uml-utilities
    vde2
    libpcap0.8-dev
    libvdeplug-dev
    libvdeplug2-dev
    # python, package manager and packages
    python3
    python-is-python3
    python3-pip
    python3-venv
    # build tools
    build-essential
    git
    cmake
    ninja-build
    astyle
    clang-tidy
    doxygen
    graphviz
    # device tree utils
    libfdt-dev
    device-tree-compiler
    # image creation tools
    dosfstools
    mtools
    # unit tests tools
    cppcheck
    check
    lcov
    libgtest-dev
    # XML processing
    libxml2-dev
    libxml2
    # Test and Demo tools
    mosquitto
    nginx
)
apt-get install --no-install-recommends -y ${PACKAGES[@]}

# install a more recent CMake version
apt-get install --no-install-recommends -y apt-transport-https gnupg software-properties-common
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'
apt-get update
apt-get upgrade -y

# install python package that are not available via apt
PYTHON_PACKAGES=(
    fabric
    GitPython
    pytest
    pytest-benchmark
    pytest-dependency
    pytest-repeat
    pytest-testconfig
    scapy
    pyftdi
    pyusb
    pyserial
	websocket-client
)
pip3 install ${PYTHON_PACKAGES[@]}

# finalize package installation and cleanup
apt-get clean autoclean
apt-get autoremove --yes --purge
rm -rf /var/lib/apt/lists/*

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf

# build gtest
cmake -S /usr/src/gtest -B /tmp/build-gtest -G Ninja
ninja -C /tmp/build-gtest
cp -v /tmp/build-gtest/lib/*.a /usr/lib/
rm -r /tmp/build-gtest

# Set capabilities, so the tools can run as normal user also and no "sudo" is
# required. However, this requires the container is started with the params
# "--cap-add=NET_ADMIN --cap-add=NET_RAW", otherwise the tool will not work and
# the error is something like "bash: /usr/bin/python3: Operation not permitted".
# It's best to do this set at the end of the setup, otherwise python's pip will
# fail during the container creation, as the caps are missing when the docker
# builder run. Maybe it's better to do this in the entrypoint script after a
# check that the cap are available.
setcap cap_net_raw,cap_net_admin+eip /usr/bin/python3.8
setcap cap_net_raw,cap_net_admin+eip /usr/sbin/tcpdump
