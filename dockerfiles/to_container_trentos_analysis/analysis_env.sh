#!/bin/bash

set -euxo pipefail

PACKAGES=(
)

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -t bullseye --no-install-recommends  -y ${PACKAGES[@]}
DEBIAN_FRONTEND=noninteractive apt-get clean autoclean
DEBIAN_FRONTEND=noninteractive apt-get autoremove --yes
