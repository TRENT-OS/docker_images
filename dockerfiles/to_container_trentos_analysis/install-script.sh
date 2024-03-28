#!/bin/bash -ue

#
# Copyright (C) 2019-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#

SCRIPT_DIR=$(cd `dirname $0` && pwd)
SCRIPT_INSTALL_CONTAINER="install-container.sh"
SCRIPT_ENTRYPOINT="entrypoint.sh"

if [ ${1:-} == "--build-package" ]; then
    TAR_PARAMS=(
        -czf install-package.tgz
        --sort=name     # ensure files are sorted
        --numeric-owner # don't expose local user/group strings
        --owner=0       # no owner (current user will be used when extracting)
        --group=0       # no group (current user's primary group will be used when extracting)
        # installation scripts
        -C ${SCRIPT_DIR}
        install-script.sh
        ${SCRIPT_INSTALL_CONTAINER}
        ${SCRIPT_ENTRYPOINT}
        axivion_suite/
        .ssh/
    )

    tar "${TAR_PARAMS[@]}"
    exit 0
fi

# this is supposed to run in the docker container when creating it
USER_ID=$1
USER_NAME=$2

# setup the entrypoint script
cp -v ${SCRIPT_DIR}/${SCRIPT_ENTRYPOINT} /

DASHBOARD_CONFIG_DIR=/home/${USER_NAME}/axivion-dashboard/config/
cp -rv ${SCRIPT_DIR}/axivion_suite/dashboard* ${DASHBOARD_CONFIG_DIR}
chown -R ${USER_NAME}:${USER_NAME} ${DASHBOARD_CONFIG_DIR}

cp -rv ${SCRIPT_DIR}/axivion_suite/*.key /home/${USER_NAME}/.bauhaus/
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.bauhaus/

cp -rv \
    ${SCRIPT_DIR}/.ssh/id_rsa* \
    ${SCRIPT_DIR}/.ssh/known_hosts \
    /home/${USER_NAME}/.ssh/
chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/.ssh/
# remove group-read permission of private key
chmod 600 /home/${USER_NAME}/.ssh/id_rsa

# run the custom installer
${SCRIPT_DIR}/${SCRIPT_INSTALL_CONTAINER} ${USER_ID} ${USER_NAME} ${DASHBOARD_CONFIG_DIR}

