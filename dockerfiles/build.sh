#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# Build script
#
# Copyright (C) 2019-2021, HENSOLDT Cyber GmbH
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
	    --no-cache=true \
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
function create_trentos_analysis_env()
{
    create_docker_image trentos_analysis
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

case "${1:-}" in
    "trentos_build.dockerfile" )
        create_trentos_build_env
        ;;

    "trentos_analysis.dockerfile" )
        create_trentos_analysis_env
        ;;

    "trentos_test.dockerfile" )
        create_trentos_test_env
        ;;

    "bob.dockerfile" )
        create_bob
        ;;

    "all" )
        create_trentos_build_env
        create_trentos_analysis_env
        create_trentos_test_env
        create_bob
        ;;

    * )
        echo -e "Usage: build.sh <target>\n" \
                "\n" \
                "  possible targets are:\n" \
                "    trentos_build.dockerfile\n" \
                "    trentos_analysis.dockerfile\n" \
                "    trentos_test.dockerfile\n" \
                "    bob.dockerfile\n" \
                "    all\n"
        exit 1
        ;;
esac
