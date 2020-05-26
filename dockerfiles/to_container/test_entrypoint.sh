#!/bin/bash

set -euxo pipefail

sudo /bin/bash /tmp/test_setup_internal_network.sh > /dev/null 2>&1

# execute the command that was passed to docker run
exec "$@"