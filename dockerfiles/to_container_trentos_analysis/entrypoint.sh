#!/bin/bash

#
# Copyright (C) 2019-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#

set -euxo pipefail

# fix runtime uid/gid
eval $( fixuid -q )

# execute the command that was passed to docker run as normal user
exec "$@"
