#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# Build script
#
# Copyright (C) 2019, Hensoldt Cyber GmbH
#
#-------------------------------------------------------------------------------

BUILD_SCRIPT_DIR=$(cd `dirname $0` && pwd)


#-------------------------------------------------------------------------------
function create_docker_image()
{
    local IMAGE=$1

    docker build \
        -t ${IMAGE} \
        --build-arg USER_NAME=$(whoami) \
        --build-arg USER_ID=$(id -u) \
        - \
        < ${BUILD_SCRIPT_DIR}/${IMAGE}.dockerfile
}


#-------------------------------------------------------------------------------
function create_seos_build_env()
{
    create_docker_image seos_build_env
}


#-------------------------------------------------------------------------------
function create_seos_test_env()
{
    create_docker_image seos_test_env
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if [[ "${1:-}" == "seos_build_env" ]]; then
    create_seos_build_env

elif [[ "${1:-}" == "seos_test_env" ]]; then
    create_seos_test_env

elif [[ "${1:-}" == "all" ]]; then
    create_seos_build_env
    create_seos_test_env

else
    echo -e "build.sh <target> \
    \n\npossible targets are:\
    \n\t seos_build_env\
    \n\t seos_test_env\
    \n\t all\
    "
fi
