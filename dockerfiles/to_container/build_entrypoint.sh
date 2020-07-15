#!/bin/bash

set -euxo pipefail

#fix runtime uid/gid
eval $( fixuid -q )

# execute the command that was passed to docker run as normal user
exec "$@"