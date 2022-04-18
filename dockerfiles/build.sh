#!/bin/bash -ue

#-------------------------------------------------------------------------------
#
# Build script
#
# Copyright (C) 2019-2021, HENSOLDT Cyber GmbH
#
#-------------------------------------------------------------------------------

BUILD_SCRIPT_DIR=$(cd `dirname $0` && pwd)
TODAY_TAG=$(date +"%Y%m%d")
REGISTRY="hc-docker:5000"

#-------------------------------------------------------------------------------
function push_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}

    echo "Pushing image to ${REGISTRY}/${IMAGE_ID}"
    docker tag ${IMAGE_ID} ${REGISTRY}/${IMAGE_ID}
    docker push "${REGISTRY}/${IMAGE_ID}"
    #docker tag ${IMAGE_ID} ${REGISTRY}/${IMAGE_NAME}:latest
    #docker push "${REGISTRY}/${IMAGE_ID}:latest"
}

#-------------------------------------------------------------------------------
function export_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}
    local IMAGE_ARCHIVE=${IMAGE_NAME}_${IMAGE_TAG}

    echo "saving image to ${IMAGE_ARCHIVE}"
    docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
}

#-------------------------------------------------------------------------------
function build_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}

    echo "Building ${IMAGE_ID} ..."
    DOCKER_BUILD_PARMAS=(
        build
        -t ${IMAGE_ID}
        --no-cache=true
        --build-arg USER_NAME="user"
        --build-arg USER_ID=1000
        -f ${BUILD_SCRIPT_DIR}/${IMAGE_NAME}.dockerfile
        to_container_${IMAGE_NAME}/
    )
    docker ${DOCKER_BUILD_PARMAS[@]}
}

#-------------------------------------------------------------------------------
function create_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    build_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
    #export_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
    #push_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
}

#-------------------------------------------------------------------------------
function create_trentos_build_env()
{
    local IMAGE_TAG=$1
    create_docker_image trentos_build ${IMAGE_TAG}
}

#-------------------------------------------------------------------------------
function create_trentos_analysis_env()
{
    local IMAGE_TAG=$1
    create_docker_image trentos_analysis ${IMAGE_TAG}
}

#-------------------------------------------------------------------------------
function create_trentos_test_env()
{
    local IMAGE_TAG=$1
    create_docker_image trentos_test ${IMAGE_TAG}
}

#-------------------------------------------------------------------------------
function create_bob()
{
    local IMAGE_TAG=$1
    create_docker_image bob ${IMAGE_TAG}
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

case "${1:-}" in
    "trentos_build.dockerfile" )
        create_trentos_build_env ${TODAY_TAG}
        ;;

    "trentos_analysis.dockerfile" )
        create_trentos_analysis_env ${TODAY_TAG}
        ;;

    "trentos_test.dockerfile" )
        create_trentos_test_env ${TODAY_TAG}
        ;;

    "bob.dockerfile" )
        create_bob ${TODAY_TAG}
        ;;

    "all" )
        create_trentos_build_env ${TODAY_TAG}
        create_trentos_analysis_env ${TODAY_TAG}
        create_trentos_test_env ${TODAY_TAG}
        create_bob ${TODAY_TAG}
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
