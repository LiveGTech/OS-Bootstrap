#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

./unmount.sh # Just to make sure that this mount succeeds

case $PLATFORM in
    x86_64)
        mkdir -p build/$PLATFORM/rootfs
        sudo mount -o loop,offset=1048576 build/$PLATFORM/system.img build/$PLATFORM/rootfs
        ;;

    rpi)
        sudo losetup -P /dev/loop0 build/$PLATFORM/system.img
        sudo mount /dev/loop0p2 build/$PLATFORM/rootfs
        ;;

    arm64)
        mkdir -p build/$PLATFORM/rootfs
        sudo mount -o loop,offset=511705088 build/$PLATFORM/system.img build/$PLATFORM/rootfs
        ;;
esac