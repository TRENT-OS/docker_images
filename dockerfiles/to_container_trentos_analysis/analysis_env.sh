#!/bin/bash

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# install required packages
PACKAGES=(
    sshfs
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -t bullseye --no-install-recommends  -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# setup group for sshfs
groupadd fuse
usermod -a -G fuse ${USER_NAME}
