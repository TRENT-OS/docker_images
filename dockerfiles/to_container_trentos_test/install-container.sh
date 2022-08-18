#!/bin/bash

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# add the user and set an empty passed
useradd --create-home --uid ${USER_ID} -G sudo ${USER_NAME}
passwd -d ${USER_NAME}

# setup repository for CMake
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y apt-transport-https ca-certificates gnupg software-properties-common wget
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
DEBIAN_FRONTEND=noninteractive apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'

PACKAGES=(
    sudo
    gosu
    coreutils
    rsync
    psmisc
    nano
    mc
    # network tools
    iptables
    iputils-ping
    netcat
    openvpn
    tcpdump
    traceroute
    tshark
    vde2
    libpcap0.8-dev
    libvdeplug-dev
    libvdeplug2-dev
    # python package manager and packages
    python3-pip
    python3-venv
    python3-pytest
    python3-git
    python3-gitdb
    python3-scapy
    # build tools
    build-essential
    git
    cmake
    ninja-build
    astyle
    clang-tidy
    doxygen
    graphviz
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
    qemu-system-arm
    qemu-system-riscv64
    # Test and Demo tools
    mosquitto
    nginx
)
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# install python requirements for tests
PYTHON_PACKAGES=(
    fabric
    pytest-benchmark
    pytest-dependency
    pytest-repeat
    pytest-testconfig
)
DEBIAN_FRONTEND=noninteractive pip3 install ${PYTHON_PACKAGES[@]}

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf

# provide /usr/bin/pytest for compatibility reasons, it used to exists in older
# Ubuntu versions.
ln -s /usr/bin/pytest-3 /usr/bin/pytest

# patched qemu downloaded from internal server
wget --no-check-certificate https://hc-artefact/release/qemu/hc-qemu_1-20203731653_amd64.deb -O /tmp/qemu.deb
if ! echo "77278942c0b0d31a9b621d8258b396ef060d947e8fd4eef342c91de5b0e4aebf /tmp/qemu.deb" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y /tmp/qemu.deb
rm /tmp/qemu.deb

# patched qemu 6.0 downloaded from internal server
wget --no-check-certificate https://hc-artefact/release/qemu/hc-qemu-6.0.0_1-20213411106_amd64.deb -O /tmp/qemu.deb
if ! echo "7496a70c50fe9109392a3dd5c632b8182589366d53dcff786a6478e09ab474db /tmp/qemu.deb" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y /tmp/qemu.deb
rm /tmp/qemu.deb

# riscv toolchain downloaded from internal server
wget --no-check-certificate https://hc-artefact/release/riscv-gnu-toolchain/hc-riscv-gnu-toolchain_1-20213311845_amd64.deb -O /tmp/riscv.deb
if ! echo "87a43ca5b1cdc3b47e4ee85fa9522f3bb56a30f8bcafc4884f1d0f75b8699b4c /tmp/riscv.deb" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y /tmp/riscv.deb
rm /tmp/riscv.deb
echo 'export PATH="/opt/hc/riscv-toolchain/bin:$PATH"' >> /home/user/.bashrc

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
