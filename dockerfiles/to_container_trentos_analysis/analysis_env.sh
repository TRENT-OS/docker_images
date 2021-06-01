#!/bin/bash

set -euxo pipefail

USER_NAME="$1"
DASHBOARD_CONFIG_DIR="$2"

# workaround: create folder required for java installation
mkdir -p /usr/share/man/man1

# install required packages
PACKAGES=(
    sshfs
    openjdk-11-jre-headless
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -t bullseye --no-install-recommends --yes ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# cleanup to save some space
rm -rf /usr/share/man/man1
rm -rf /var/lib/apt/lists/*

# setup group for sshfs
groupadd fuse
usermod -a -G fuse ${USER_NAME}

# get and install axivion suite
wget --no-check-certificate https://hc-artefact/axivion_suite/bauhaus-suite-7_1_5-x86_64-gnu_linux.tar.gz -O /opt/bauhaus-suite.tar.gz

if ! echo "72ff69be0728cccbcb45190b5899814a2e96a23f69352c4434dc60290d4f6458 /opt/bauhaus-suite.tar.gz" | sha256sum -c -; then
     echo "Hash of bauhaus-suite.tar.gz invalid"
     exit 1
fi

cd /opt
tar xzf bauhaus-suite.tar.gz
rm bauhaus-suite.tar.gz

cd bauhaus-suite
./setup.sh

echo 'export PATH=/opt/bauhaus-suite/bin:$PATH' >> /home/${USER_NAME}/.bashrc
echo "export AXIVION_DASHBOARD_CONFIG=${DASHBOARD_CONFIG_DIR}" >> /home/${USER_NAME}/.bashrc

# set file-creation mask of "user" with group writeable (ubuntu style)
echo "umask 0002" >> /home/${USER_NAME}/.bashrc
