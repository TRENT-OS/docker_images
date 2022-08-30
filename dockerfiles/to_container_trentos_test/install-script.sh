#!/bin/bash -ue

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
        demo_iot_mosquitto_config/
        nginx/
        test_setup_internal_network.sh
    )

    tar "${TAR_PARAMS[@]}"
    exit 0
fi

# this is supposed to run in the docker container when creating it
USER_ID=$1
USER_NAME=$2

# setup the entrypoint scripts
cp -v \
    ${SCRIPT_DIR}/${SCRIPT_ENTRYPOINT} \
    ${SCRIPT_DIR}/test_setup_internal_network.sh \
    /

# run the custom installer
${SCRIPT_DIR}/${SCRIPT_INSTALL_CONTAINER} ${USER_ID} ${USER_NAME}

# now all tools are installed we can set our custom configuration
mv /etc/mosquitto /etc/mosquitto.org
cp -vr ${SCRIPT_DIR}/demo_iot_mosquitto_config/mosquitto/ /etc/mosquitto/
cp -v ${SCRIPT_DIR}/nginx/default /etc/nginx/sites-enabled/
