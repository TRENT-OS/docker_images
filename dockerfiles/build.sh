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
        -f ${BUILD_SCRIPT_DIR}/${IMAGE_BASE}.dockerfile to_container_${IMAGE_BASE}/

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
function create_trentos_build_env()
{
    create_docker_image trentos_build
}

#-------------------------------------------------------------------------------
function create_trentos_test_env()
{
    create_docker_image trentos_test
}

#-------------------------------------------------------------------------------
function create_bob()
{
    create_docker_image bob
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if [[ "${1:-}" == "trentos_build.dockerfile" ]]; then
    create_trentos_build_env

elif [[ "${1:-}" == "trentos_test.dockerfile" ]]; then
    create_trentos_test_env

elif [[ "${1:-}" == "bob.dockerfile" ]]; then
    create_bob

elif [[ "${1:-}" == "all" ]]; then
    create_trentos_build_env
    create_trentos_test_env
    create_bob

else
    echo -e "build.sh <target> \
    \n\npossible targets are:\
    \n\t trentos_build.dockerfile\
    \n\t trentos_test.dockerfile\
    \n\t bob.dockerfile\
    \n\t all\
    "
fi
