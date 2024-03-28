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
    cmake
    ninja-build
    autoconf
    flex
    bison
    libtool
    checkinstall
    pkg-config
    zlib1g-dev
    libglib2.0-dev
    libboost-all-dev
    libssl-dev
    libpixman-1-dev
    # python, package manager and packages
    python3
    python-is-python3
    python3-pip
    python3-virtualenv
)
apt-get install -y ${PACKAGES[@]}

# install a more recent CMake version
apt-get install --no-install-recommends -y apt-transport-https gnupg software-properties-common
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'
apt-get update
apt-get upgrade -y

# finalize package installation and cleanup
apt-get clean autoclean
apt-get autoremove --yes --purge
rm -rf /var/lib/apt/lists/*

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf
