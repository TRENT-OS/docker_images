#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# Build script
#
# Copyright (C) 2019, Hensoldt Cyber GmbH
#
#-------------------------------------------------------------------------------

BUILD_SCRIPT_DIR=$(cd `dirname $0` && pwd)

if [[ "${1:-}" == "seos_build_env" ]]; then
    (
        cd ${BUILD_SCRIPT_DIR}/sel4-camkes-l4v-dockerfiles
        ./build.sh -b camkes
        cd ..
        docker build -t seos_build_env --build-arg USER_NAME=$(whoami) --build-arg USER_ID=$(id -u) - < seos_build_env.dockerfile
    )
elif [[ "${1:-}" == "seos_test_env" ]]; then
    (
        cd ${BUILD_SCRIPT_DIR}
        docker build -t seos_test_env --build-arg USER_NAME=$(whoami) --build-arg USER_ID=$(id -u) - < seos_test_env.dockerfile
    )
else
    echo -e "build.sh <target> \
    \n\npossible targets are:\
    \n\t seos_build_env\
    \n\t seos_test_env"
fi
