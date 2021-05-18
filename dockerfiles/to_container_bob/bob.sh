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

echo 'export PATH=/scripts/repo:$PATH' >> /home/${USER_NAME}/.bashrc

PACKAGES=(
    build-essential
    zlib1g-dev
    pkg-config
    libglib2.0-dev
    binutils-dev
    libboost-all-dev
    autoconf
    libtool
    libssl-dev
    libpixman-1-dev
    virtualenv
    checkinstall
    git
    flex
    bison
    sudo
    wget
    nano
    mc
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# Fix for a sudo error when running in a container
# https://github.com/sudo-project/sudo/issues/42
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

# install fixuid to fix the runtime UID/GID problem in the container entrypoint script
wget https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz -O /tmp/fixuid-0.5-linux-amd64.tar.gz
tar -C /usr/local/bin -xzf /tmp/fixuid-0.5-linux-amd64.tar.gz

if ! echo "caa7e0e4c88e1b154586a46c2edde75a23f9af4b5526bb11626e924204585050 /tmp/fixuid-0.5-linux-amd64.tar.gz" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi

rm /tmp/fixuid-0.5-linux-amd64.tar.gz

chown root:root /usr/local/bin/fixuid
chmod 4755 /usr/local/bin/fixuid
mkdir -p /etc/fixuid
printf "user: ${USER_NAME}\ngroup: ${USER_NAME}\npaths: \n- /home/${USER_NAME}\n- /tmp\n" > /etc/fixuid/config.yml