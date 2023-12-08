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
    local ARCH=$3

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}

    if [ ${ARCH} != "amd64" ]; then
        IMAGE_ID+="_${ARCH}"
    fi

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
    local ARCH=$3

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}
    local IMAGE_ARCHIVE=${IMAGE_NAME}_${IMAGE_TAG}

    if [ ${ARCH} != "amd64" ]; then
        IMAGE_ID+="_${ARCH}"
        IMAGE_ARCHIVE+="_${ARCH}"
    fi

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
    local ARCH=$3

    local IMAGE_ID=${IMAGE_NAME}:${IMAGE_TAG}
    local BASE_DIR="${BUILD_SCRIPT_DIR}/to_container_${IMAGE_NAME}"

    if [ ${ARCH} != "amd64" ]; then
        IMAGE_ID+="_${ARCH}"
    fi

    case "${3:-}" in
        "amd64" )
            PLATFORM="linux/amd64"
            ;;
        "arm64" )
            PLATFORM="linux/arm64"
            ;;
    esac

    # There might be a script that creates an installer package
    local INSTALLER="${BASE_DIR}/install-script.sh"
    if [ -f "${INSTALLER}" ]; then
        ${INSTALLER} --build-package
    fi

    echo "Building ${IMAGE_ID} ..."
    local DOCKER_BUILD_PARMAS=(
        buildx build
        --progress plain
        --platform ${PLATFORM}
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
    local ARCH=$3

    local BUILD_DIR="build_${IMAGE_NAME}_${ARCH}_$(date --utc +'%Y%m%d%H%M%S')"
    mkdir -p ${BUILD_DIR}
    (
        cd ${BUILD_DIR}
        build_docker_image ${IMAGE_NAME} ${IMAGE_TAG} ${ARCH}
        #export_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
        #push_docker_image ${IMAGE_NAME} ${IMAGE_TAG}
    )
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

case "${1:-}" in
    trentos_build|trentos_analysis|trentos_test|bob )
        create_docker_image $1 ${TODAY_TAG} ${2:-"amd64"}
        ;;

    "all" )
        create_docker_image trentos_build ${TODAY_TAG} ${2:-"amd64"}
        create_docker_image trentos_analysis ${TODAY_TAG} ${2:-"amd64"}
        create_docker_image trentos_test ${TODAY_TAG} ${2:-"amd64"}
        create_docker_image bob ${TODAY_TAG} ${2:-"amd64"}
        ;;

    * )
        echo -e "Usage: build.sh <target> <architecure>\n" \
                "\n" \
                "  possible targets are:\n" \
                "    trentos_build\n" \
                "    trentos_analysis\n" \
                "    trentos_test\n" \
                "    bob\n" \
                "    all\n" \
                "  [OPTIONAL] possible architectures are:\n" \
                "    amd64 - default\n" \
                "    arm64\n" \
                "\n" \
                "To prevent cross-compile errors run:\n" \
                "docker run --rm --privileged multiarch/qemu-user-static --reset -p yes"
        exit 1
        ;;
esac
