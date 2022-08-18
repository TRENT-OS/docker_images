#!/bin/bash

set -euxo pipefail

# fix runtime uid/gid
eval $( fixuid -q )

# Check capabilities of container. Not having them is not fatal, but certain
# things will not work in this case.
NEEDED_CAPS=(cap_net_raw cap_net_admin)
MISSING_CAPS=()
for c in ${NEEDED_CAPS[@]}; do
    if ! capsh --print | grep "Current:" | cut -d ' ' -f3 | grep -q ${c}; then
        MISSING_CAPS+=(${c})
    fi
done
if [ ${#MISSING_CAPS[@]} -gt 0 ]; then
    echo "missing cap: ${MISSING_CAPS[@]}"
fi

sudo /test_setup_internal_network.sh > /dev/null 2>&1

# start services in container
sudo service nginx start
sudo service mosquitto start

# execute the command that was passed to docker run
exec "$@"
