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

# let the user use the Haskell stack pre-installed for root
echo "allow-different-user: true" >> /root/.stack/config.yaml
groupadd stack
usermod -a -G stack ${USER_NAME}
chmod a+x /root && chgrp -R stack /root/.stack
chmod -R g=u /root/.stack
cd /home/${USER_NAME}
ln -s /root/.stack

PACKAGES=(
    rsync coreutils
    git build-essential cmake ninja-build
    astyle clang-tidy
    doxygen graphviz
    # unit tests tools
    cppcheck check lcov libgtest-dev
    # XML processing
    libxml2-dev libxml2
)
apt-get update
apt-get install --no-install-recommends -y ${PACKAGES[@]}
apt-get clean autoclean
apt-get autoremove --yes

# gtest
cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib

