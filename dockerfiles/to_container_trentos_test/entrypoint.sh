#!/bin/bash

set -euxo pipefail

# fix runtime uid/gid
eval $( fixuid -q )

sudo /test_setup_internal_network.sh > /dev/null 2>&1

# start services in container
sudo service nginx start
sudo service mosquitto start

# execute the command that was passed to docker run
exec "$@"
