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
    IMG_SIZE=$(docker save ${IMAGE_ID} | wc -c | numfmt --to=iec-i)
    echo "raw image size is ${IMG_SIZE}, saving compressed..."
    docker save ${IMAGE_ID} | pv | bzip2 > ${IMAGE_ARCHIVE}.bz2
    #docker save ${IMAGE_ID} | xz -v -T0 > ${IMAGE_ARCHIVE}.xz
}

#-------------------------------------------------------------------------------
function build_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}
    local BASE_DIR="${BUILD_SCRIPT_DIR}/to_container_${IMAGE_NAME}"

    # There might be a script that creates an installer package
    local INSTALLER="${BASE_DIR}/install-script.sh"
    if [ -f "${INSTALLER}" ]; then
        ${INSTALLER} --build-package
    fi

    echo "Building ${IMAGE_ID} ..."
    local DOCKER_BUILD_PARMAS=(
        build
        --progress plain
        --platform linux/amd64  # linux/arm64, linux/arm/v7, linux/riscv64
        --no-cache
        -t ${IMAGE_ID}
        --build-arg USER_NAME="user"
        --build-arg USER_ID=1000
        -f ${BASE_DIR}/dockerfile
        .
    )
    docker ${DOCKER_BUILD_PARMAS[@]}
}

#-------------------------------------------------------------------------------
function create_docker_image()
{
    local IMAGE_NAME=$1
    local IMAGE_TAG=$2

    local BUILD_DIR="build_${IMAGE_NAME}_$(date --utc +'%Y%m%d%H%M%S')"
    mkdir -p ${BUILD_DIR}
    (
        cd ${BUILD_DIR}
        build_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
        #export_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
        #push_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
    )
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

case "${1:-}" in
    trentos_build|trentos_analysis|trentos_test|bob )
        create_docker_image $1 ${TODAY_TAG}
        ;;

    "all" )
        create_docker_image trentos_build ${TODAY_TAG}
        create_docker_image trentos_analysis ${TODAY_TAG}
        create_docker_image trentos_test ${TODAY_TAG}
        create_docker_image bob ${TODAY_TAG}
        ;;

    * )
        echo -e "Usage: build.sh <target>\n" \
                "\n" \
                "  possible targets are:\n" \
                "    trentos_build\n" \
                "    trentos_analysis\n" \
                "    trentos_test\n" \
                "    bob\n" \
                "    all\n"
        exit 1
        ;;
esac
