#
# Copyright (C) 2019-2024, HENSOLDT Cyber GmbH
# 
# SPDX-License-Identifier: GPL-2.0-or-later
#
# For commercial licensing, contact: info.cyber@hensoldt.net
#

FROM ubuntu
MAINTAINER Carmelo carmelo.pintaudi@hensoldt-cyber.com

RUN apt-get update && apt-get upgrade -y

# add the jenkins user with UID 1000
RUN useradd jenkins

# install tools
RUN apt-get install -y autoconf2.64 texinfo autogen gprbuild gnat-7 build-essential pkg-config libncurses5-dev wget libexpat-dev git file sudo python python-future python-tempita python-ply python-six expect libxml2-utils tclsh

# checkout genode
RUN git clone https://github.com/genodelabs/genode.git

# build toolchain
RUN ["/genode/tool/tool_chain", "x86"]
