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
    rsync coreutils
    git build-essential cmake ninja-build
    python3-git python3-gitdb
    astyle clang-tidy
    doxygen graphviz
    # unit tests tools
    cppcheck check lcov libgtest-dev
    # XML processing
    libxml2-dev libxml2
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -y ${PACKAGES[@]}
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

# gtest
cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

