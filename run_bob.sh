#!/bin/bash -ue

# default image
DOCKER_IMAGE="bob:20220901"

# default to allocating a pseudo-TTY when starting a docker container
TTY=-t

while getopts ":i:d:hn" PARAM; do
    case ${PARAM} in
        h )
            printf "%s\n" \
                "Usage:"
                "$(basename $0) [-h] [-n] [-i image] [-d param] [command]"
                ""
                "    -h        print help and exit"
                "    -n        don't allocate a TTY for docker run"
                "    -i image  image to start"
                "    -d param  pass param to the parameter list of docker run."
            exit 0
            ;;
        n )
            TTY=""
            ;;
        i )
            DOCKER_IMAGE=${OPTARG}
            ;;
        d )
            DOCKER_ARGS+=( ${OPTARG} )
            ;;

        \? )
            echo "Invalid option: ${OPTARG}" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid option: ${OPTARG} requires an argument" 1>&2
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

if [ "${#}" -eq "0" ]; then
    ARGS=(bash)
else
    ARGS=("$@")
fi

DOCKER_RUN_PARMAS=(
    run
    # --interactive: keep STDIN open even if not attached
    -i
    # tty setting
    ${TTY}
    # discard any changes on container exit
    --rm
    # set host name is container
    --hostname bob
    # no need use enforce a user here using -u $(id -u), the container has
    # defaults setup and the fixuid executed in the entrypoint takes care of
    # aligned the file ownership
    #
    # mount /etc/localtime in container as read only, so clock is valid
    -v /etc/localtime:/etc/localtime:ro \
    # mount current working directory on host in container as /host
    -v $(pwd):/host
    # set the current directory in the container to /host
    -w /host
    # docker parameters passed on command line
    ${DOCKER_ARGS[@]}
    # docker image to use
    ${DOCKER_IMAGE}
    # process to execute
    "${ARGS[@]}"
)

set -x
docker ${DOCKER_RUN_PARMAS[@]}
