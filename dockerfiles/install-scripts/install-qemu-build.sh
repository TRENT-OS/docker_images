#!/bin/bash

set -euxo pipefail

# ensure apt family tools and pip3 don't try and user interaction
export DEBIAN_FRONTEND=noninteractive

# install latest updates and clean up afterwards, so any changes are clearly
# visible in the logs.
apt-get update
apt-get upgrade -y
apt-get clean autoclean
apt-get autoremove --yes --purge


PACKAGES=(
    # build tools
    build-essential
    git
    cmake
    ninja-build
    astyle
    clang-tidy
    doxygen
    graphviz
    # Custom QEMU
    bison
    flex
    pkg-config
    libglib-perl
    zlib1g-dev
    libglib2.0-dev
    libpixman-1-dev
    libpixman-1-dev
    libgcrypt20-dev
    autoconf
    automake
    libtool
)
apt-get install --no-install-recommends -y ${PACKAGES[@]}

# build custom virt qemu
cd /tmp && git -c http.sslVerify=false clone -b custom_qemu-arm-virt --single-branch --recurse-submodules https://gitlab.com/s0ckl/qemu.git 2>/dev/null
mkdir -p /tmp/qemu/build && cd $_
../configure --target-list="aarch64-softmmu arm-softmmu riscv32-softmmu riscv64-softmmu" --disable-snappy --disable-vnc --disable-vnc-jpeg --disable-vnc-sasl --disable-sdl --disable-pa --disable-brlapi --disable-gtk --disable-libiscsi --disable-libnfs --disable-rbd --disable-libusb 2>/dev/null
make -j8
mkdir -p /tmp/bin/ && cp -t $_ qemu-system-arm qemu-system-aarch64 qemu-system-riscv32 qemu-system-riscv64
rm -rf /tmp/qemu/

# build custom xilinx qemu
cd /tmp && git -c http.sslVerify=false clone -b xilinx_v2023.2 --single-branch --recurse-submodules https://github.com/Xilinx/qemu.git 2>/dev/null
mkdir -p /tmp/qemu/build && cd $_
../configure --target-list="aarch64-softmmu, microblazeel-softmmu" --enable-fdt --disable-kvm --disable-xen --enable-gcrypt 2>/dev/null
make -j8
XILINX_PATH=/tmp/bin/xilinx-
mv qemu-system-aarch64 ${XILINX_PATH}qemu-system-aarch64
mv qemu-system-microblazeel ${XILINX_PATH}qemu-system-microblazeel
rm -rf /tmp/qemu/
