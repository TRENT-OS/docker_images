#!/bin/bash -ue

SCRIPT_DIR=$(cd `dirname $0` && pwd)
INSTALL_PACKAGE="install-package.tgz"
SCRIPT_INSTALL_CONTAINER="install-container.sh"
SCRIPT_ENTRYPOINT="entrypoint.sh"

if [ ${1:-} == "--build-package" ]; then
    TAR_PARAMS=(
        -czf ${INSTALL_PACKAGE}
        --sort=name     # ensure files are sorted
        --numeric-owner # don't expose local user/group strings
        --owner=0       # no owner (current user will be used when extracting)
        --group=0       # no group (current user's primary group will be used when extracting)
        # installation scripts
        -C ${SCRIPT_DIR}
        ${SCRIPT_INSTALL_CONTAINER}
        ${SCRIPT_ENTRYPOINT}
    )

    tar "${TAR_PARAMS[@]}"
    exit 0
fi

# this is supposed to run in the docker container when creating it
USER_ID=$1
USER_NAME=$2

# extract the installation package and run the installer script
tar -xf ${SCRIPT_DIR}/${INSTALL_PACKAGE} -C ${SCRIPT_DIR}/

# run the custom installer
${SCRIPT_DIR}/${SCRIPT_INSTALL_CONTAINER} ${USER_ID} ${USER_NAME}

# setup the entrypoint script
cp -v ${SCRIPT_DIR}/${SCRIPT_ENTRYPOINT} /
