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

# Add the user and set an empty password.
# The Haskell toolchain comes pre-installed in /etc/stack in the seL4 build
# container, with the files owned by the group 'stack'. Add user to this group
# to access the toolchain.
useradd --create-home --uid ${USER_ID} -G sudo,stack ${USER_NAME}
passwd -d ${USER_NAME}
# The Haskell toolchain looks in the user's home folder for its configuration
# and the installed Haskell compiler. If it doesn't find them there it tries
# downloading them from the internet. In order to avoid this we link the
# pre-installed version.
ln -s /etc/stack/ /home/${USER_NAME}/.stack

echo 'export PATH=/scripts/repo:$PATH' >> /home/${USER_NAME}/.bashrc

PACKAGES=(
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
    git
    cmake
    ninja-build
    astyle
    clang-tidy
    doxygen
    graphviz
    # python
    python3-git
    python3-gitdb
    # needed for the python cryptography module
    cargo
    rustc
    # unit tests tools
    cppcheck
    check
    iwyu
    lcov
    libgtest-dev
    # XML processing
    libxml2
    libxml2-dev
)
apt-get install -t bullseye --no-install-recommends -y ${PACKAGES[@]}

# We install setuptools and wheel on their own, otherwise the dependencies
# aren't resolved correctly and pip install fails
# setuptools is set to version <58 because the newer versions do not support
# 2to3: https://setuptools.readthedocs.io/en/latest/history.html#v58-0-0 which
# breaks the container build.
pip3 install 'setuptools<58'
pip3 install wheel
PIP_PACKAGES=(
    aenum
    cryptography
    future
    hexrec
    jsonschema
    jinja2
    libarchive-c
    orderedset
    plyplus
    pyelftools
    pyfdt
    simpleeval
    six
    sortedcontainers
)
pip3 install ${PIP_PACKAGES[@]}

# finalize package installation and cleanup
apt-get clean autoclean
apt-get autoremove --yes --purge
rm -rf /var/lib/apt/lists/*

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf

# The repository version of cmake was updated to 3.18, so at this point in time
# we have no need to install it manually. We keep this code commented here for
# future use when we need to install a cmake version not available in the
# repositories.
#
# wget https://cmake.org/files/v3.17/cmake-3.17.3-Linux-x86_64.sh -O /tmp/cmake.sh
#
# if ! echo "1a99f573512793224991d24ad49283f017fa544524d8513667ea3cb89cbe368b /tmp/cmake.sh" | sha256sum -c -; then
#      echo "Hash failed"
#      exit 1
# fi
#
# # Install the downloaded CMake version in /opt and symlink the binaries to /usr/local/bin
# mkdir /opt/cmake
# sh /tmp/cmake.sh --prefix=/opt/cmake --skip-license
# ln -s /opt/cmake/bin/cmake     /usr/local/bin/cmake
# ln -s /opt/cmake/bin/ccmake    /usr/local/bin/ccmake
# ln -s /opt/cmake/bin/cmake-gui /usr/local/bin/cmake-gui
# ln -s /opt/cmake/bin/cpack     /usr/local/bin/cpack
# ln -s /opt/cmake/bin/ctest     /usr/local/bin/ctest
#
# rm /tmp/cmake.sh

# build gtest
cmake -S /usr/src/gtest -B /tmp/build-gtest -G Ninja
ninja -C /tmp/build-gtest
cp -v /tmp/build-gtest/lib/*.a /usr/lib/
rm -r /tmp/build-gtest
