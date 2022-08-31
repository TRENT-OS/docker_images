#!/bin/bash

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
    # QEMU
    qemu-system-x86
    qemu-system-arm
    qemu-system-misc # qemu-system-riscv64 is just an alias
    ipxe-qemu # also comes with qemu-system-x86
    libcapstone-dev # needed for QEMU v7.1 disassembling feature
    # Test and Demo tools
    mosquitto
    nginx
)
apt-get install --no-install-recommends -y ${PACKAGES[@]}

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
)
pip3 install ${PYTHON_PACKAGES[@]}

# finalize package installation and cleanup
apt-get clean autoclean
apt-get autoremove --yes --purge
rm -rf /var/lib/apt/lists/*

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
setcap cap_net_raw,cap_net_admin+eip /usr/bin/python3.10
setcap cap_net_raw,cap_net_admin+eip /usr/bin/tcpdump
