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

# workaround: get and build python version 3.8 required by axivion suite because
# installation via apt is conflicting with installed python version 3.9
wget https://www.python.org/ftp/python/3.8.10/Python-3.8.10.tgz -O /tmp/Python-3.8.10.tgz

if ! echo "b37ac74d2cbad2590e7cd0dd2b3826c29afe89a734090a87bf8c03c45066cb65 /tmp/Python-3.8.10.tgz" | sha256sum -c -; then
     echo "Hash of Python-3.8.10.tgz invalid"
     exit 1
fi

cd /tmp
tar -xf Python-3.8.10.tgz

cd Python-3.8.10
./configure --enable-optimizations
make -j 8
make altinstall

cd ..
rm Python-3.8.10.tgz
rm Python-3.8.10 -r

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
