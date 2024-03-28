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
DASHBOARD_CONFIG_DIR="$3"

# install latest updates and clean up afterwards, so any changes are clearly
# visible in the logs.
apt-get update
apt-get upgrade -y
apt-get clean autoclean
apt-get autoremove --yes --purge

# workaround: create folder required for java installation
mkdir -p /usr/share/man/man1

# install required packages
PACKAGES=(
    sshfs
    openjdk-11-jre-headless
)
apt-get install -t bullseye --no-install-recommends --yes ${PACKAGES[@]}
apt-get clean autoclean
apt-get autoremove --yes --purge

# cleanup to save some space
rm -rf /usr/share/man/man1
rm -rf /var/lib/apt/lists/*

# setup group for sshfs
groupadd fuse
usermod -a -G fuse ${USER_NAME}

# get and install axivion suite
wget --no-check-certificate https://hc-artefact/axivion_suite/bauhaus-suite-7_3_2-x86_64-gnu_linux.tar.gz -O /tmp/bauhaus-suite.tar.gz

if ! echo "2ac72f355774dabd66a320b25ed42fbeefdd3e2d6189f89e300dbcd7dc63df39 /opt/bauhaus-suite.tar.gz" | sha256sum -c -; then
     echo "Hash of bauhaus-suite.tar.gz invalid"
     exit 1
fi
tar -xzf /tmp/bauhaus-suite.tar.gz -C /opt
rm /tmp/bauhaus-suite.tar.gz
(
    cd /opt/bauhaus-suite
    ./setup.sh
)

echo 'export PATH=/opt/bauhaus-suite/bin:$PATH' >> /home/${USER_NAME}/.bashrc
echo "export AXIVION_DASHBOARD_CONFIG=${DASHBOARD_CONFIG_DIR}" >> /home/${USER_NAME}/.bashrc

# set file-creation mask of "user" with group writeable (ubuntu style)
echo "umask 0002" >> /home/${USER_NAME}/.bashrc
