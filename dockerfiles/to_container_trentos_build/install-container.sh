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
    #ca-certificates
    #coreutils
    #rsync
    #bzip2
    #xz-utils
    #wget
    #curl
    nano
    mc
    # build tools
    #build-essential
    #git
    #cmake
    #ninja-build
    #astyle
    clang-tidy
    #doxygen
    graphviz
    # python
    #python3
    python-is-python3
    python3-cryptography
    python3-future
    python3-git
    python3-jinja2
    python3-jsonschema
    python3-libarchive-c
    python3-pyelftools
    python3-simpleeval
    #python3-six
    python3-sortedcontainers
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
    #libxml2
    libxml2-dev
)
apt-get install --no-install-recommends -y ${PACKAGES[@]}

# The base container has 3.18, so at this point in time we have no need to
# install a more recent version. However, the lines below can be used to get the
# most recent version.
#apt-get install --no-install-recommends -y apt-transport-https gnupg software-properties-common
#wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
#apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'
#apt-get update
#apt-get upgrade -y

# Install python package that are not available via apt.
PIP_PACKAGES=(
    #aenum
    hexrec
    #orderedset
    #plyplus
    #pyfdt
)
pip3 install ${PIP_PACKAGES[@]}

# finalize package installation and cleanup
apt-get clean autoclean
apt-get autoremove --yes --purge
rm -rf /var/lib/apt/lists/*

# Fix for a sudo error when running in a container, it is fixed in v1.8.31p1
# eventually, see also https://github.com/sudo-project/sudo/issues/42
echo "Set disable_coredump false" >> /etc/sudo.conf

# build gtest
cmake -S /usr/src/gtest -B /tmp/build-gtest -G Ninja
ninja -C /tmp/build-gtest
cp -v /tmp/build-gtest/lib/*.a /usr/lib/
rm -r /tmp/build-gtest
