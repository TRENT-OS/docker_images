#!/bin/bash

set -euxo pipefail

sudo /bin/bash /tmp/test_setup_internal_network.sh > /dev/null 2>&1

# start servives in container
sudo service nginx start
sudo service mosquitto start

# execute the command that was passed to docker run
exec "$@"