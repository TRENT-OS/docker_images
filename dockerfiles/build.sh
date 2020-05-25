#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# Build script
#
# Copyright (C) 2019, Hensoldt Cyber GmbH
#
#-------------------------------------------------------------------------------

BUILD_SCRIPT_DIR=$(cd `dirname $0` && pwd)

#USER_NAME=$(whoami)
USER_NAME=user

USER_ID=$(id -u)

TIMESTAMP=$(date +"%Y%m%d")
REGISTRY="docker:5000"
#-------------------------------------------------------------------------------
function create_docker_image()
{
    local IMAGE_BASE=$1

    local IMAGE_ID=${IMAGE_BASE}:${TIMESTAMP}
    echo "Building ${IMAGE_ID} ..."
    docker build \
        -t ${IMAGE_ID} \
        --build-arg USER_NAME=${USER_NAME} \
        --build-arg USER_ID=${USER_ID} \
        -f ${BUILD_SCRIPT_DIR}/${IMAGE_BASE}.dockerfile to_container/

    echo "Saving image to ${IMAGE_ID} ..."
    docker tag ${IMAGE_ID} ${REGISTRY}/${IMAGE_BASE}:latest
    docker tag ${IMAGE_ID} ${REGISTRY}/${IMAGE_ID}

    #echo "Pushing image to ${REGISTRY}/${IMAGE_ID}"
    #docker push "${REGISTRY}/${IMAGE_ID}"
    #docker push "${REGISTRY}/${IMAGE_BASE}:latest"
    
    #echo "saving image to ${IMAGE_ARCHIVE} ..."
    #docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}
}


#-------------------------------------------------------------------------------
function create_seos_build_env()
{
    create_docker_image seos_build_env
}


#-------------------------------------------------------------------------------
function create_seos_debug_env()
{
    create_docker_image seos_debug_env
}


#-------------------------------------------------------------------------------
function create_seos_test_env()
{
    create_docker_image seos_test_env
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if [[ "${1:-}" == "seos_build_env.dockerfile" ]]; then
    create_seos_build_env

elif [[ "${1:-}" == "seos_debug_env.dockerfile" ]]; then
    create_seos_debug_env

elif [[ "${1:-}" == "seos_test_env.dockerfile" ]]; then
    create_seos_test_env

elif [[ "${1:-}" == "all" ]]; then
    create_seos_build_env
    create_seos_debug_env
    create_seos_test_env

else
    echo -e "build.sh <target> \
    \n\npossible targets are:\
    \n\t seos_build_env.dockerfile\
    \n\t seos_debug_env.dockerfile\
    \n\t seos_test_env.dockerfile\
    \n\t all\
    "
fi
