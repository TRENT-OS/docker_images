#!/bin/bash

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# install latest updates and clean up afterwards, so any changes are clearly
# visible in the logs.
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes --purge

# add the user and set an empty passed
useradd --create-home --uid ${USER_ID} -G sudo ${USER_NAME}
passwd -d ${USER_NAME}

PACKAGES=(
    sudo
    ca-certificates
    coreutils
    rsync
    bzip2
    xz-utils
    wget
    curl
    nano
    mc
    # build tools
    build-essential
    binutils-dev
    git
    ninja-build
    autoconf
    flex
    bison
    libtool
    checkinstall
    virtualenv
    pkg-config
    zlib1g-dev
    libglib2.0-dev
    libboost-all-dev
    libssl-dev
    libpixman-1-dev
)
DEBIAN_FRONTEND=noninteractive apt-get install -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes --purge

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf

# Debian repositories have an older version of CMake in them
# So we download the latest one from the official website
wget https://cmake.org/files/v3.17/cmake-3.17.3-Linux-x86_64.sh -O /tmp/cmake.sh
if ! echo "1a99f573512793224991d24ad49283f017fa544524d8513667ea3cb89cbe368b /tmp/cmake.sh" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi
# Install the downloaded CMake version in /opt and symlink the binaries to /usr/local/bin
mkdir /opt/cmake
sh /tmp/cmake.sh --prefix=/opt/cmake --skip-license
ln -s /opt/cmake/bin/cmake     /usr/local/bin/cmake
ln -s /opt/cmake/bin/ccmake    /usr/local/bin/ccmake
ln -s /opt/cmake/bin/cmake-gui /usr/local/bin/cmake-gui
ln -s /opt/cmake/bin/cpack     /usr/local/bin/cpack
ln -s /opt/cmake/bin/ctest     /usr/local/bin/ctest
rm /tmp/cmake.sh
