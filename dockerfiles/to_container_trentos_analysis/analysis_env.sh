#!/bin/bash

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# workaround: create folder required for java installation
mkdir -p /usr/share/man/man1

# install required packages
PACKAGES=(
    sshfs
    openjdk-11-jre-headless
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -t bullseye --no-install-recommends  -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# cleanup to save space
rm -rf /var/lib/apt/lists/*

# setup group for sshfs
groupadd fuse
usermod -a -G fuse ${USER_NAME}
