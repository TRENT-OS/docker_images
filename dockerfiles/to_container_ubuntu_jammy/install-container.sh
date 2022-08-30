#!/bin/bash

set -euxo pipefail

USER_ID="$1"
USER_NAME="$2"

# add the user and set an empty passed
useradd --create-home --uid ${USER_ID} -G sudo ${USER_NAME}
passwd -d ${USER_NAME}

PACKAGES=(
    sudo
    wget
    nano
    mc
)
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes

# install fixuid to fix the runtime UID/GID problem in the container entrypoint script
wget https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz -O /tmp/fixuid.gz
if ! echo "caa7e0e4c88e1b154586a46c2edde75a23f9af4b5526bb11626e924204585050 /tmp/fixuid.gz" | sha256sum -c -; then
     echo "Hash failed"
     exit 1
fi
tar -C /usr/local/bin -xzf /tmp/fixuid.gz
rm /tmp/fixuid.gz
chown root:root /usr/local/bin/fixuid
chmod 4755 /usr/local/bin/fixuid
mkdir -p /etc/fixuid
printf "user: ${USER_NAME}\ngroup: ${USER_NAME}\npaths: \n- /home/${USER_NAME}\n- /tmp\n" > /etc/fixuid/config.yml
