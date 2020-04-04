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

# update package list
apt-get update

PACKAGES=(
	# install riscv gdb
	gdc-riscv64-linux-gnu

	# install ddd
	ddd
)

apt-get install --no-install-recommends -y ${PACKAGES[@]}
# cleanup
apt-get clean autoclean
apt-get autoremove --yes

