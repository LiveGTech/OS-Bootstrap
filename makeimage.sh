#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

if ! [ -e build/$PLATFORM/system.img ]; then
    qemu-img create build/$PLATFORM/system.img 6G

    echo "Formatting image..."

    (
        echo o # Create DOS partition table
        echo n # New partition
        echo p # Primary
        echo 1 # Partition number
        echo 8192 # First sector at 4 MiB (4 * 1024 * 2)
        echo +248M # 128 MiB space
        echo n # New partition
        echo p # Primary
        echo 2 # Partition number
        echo 516096 # First sector after first partition ((4 + 248) * 1024 * 2)
        echo # Default last sector (fill remaining to end)
        echo w # Write and exit
    ) | fdisk build/$PLATFORM/system.img

    sudo losetup -P /dev/loop0 build/$PLATFORM/system.img
    sudo mkfs.ext4 /dev/loop0p2 -L LiveG-OS

    ./mount.sh

    sudo losetup -P /dev/loop1 cache/$PLATFORM/baseinstall.img
    mkdir -p build/$PLATFORM/base-bootfs
    mkdir -p build/$PLATFORM/base-rootfs
    sudo mount /dev/loop1p1 build/$PLATFORM/base-bootfs
    sudo mount /dev/loop1p2 build/$PLATFORM/base-rootfs

    echo "Copying root filesystem..."

    # Copy base installation root FS to system root FS
    sudo rsync -ah --info=progress2 --no-inc-recursive --exclude=/dev --exclude=/proc --exclude=/sys build/$PLATFORM/base-rootfs/ build/$PLATFORM/rootfs/
    sudo rsync -ah --info=progress2 --no-inc-recursive build/$PLATFORM/base-bootfs/ build/$PLATFORM/rootfs/boot/

    ./unmount.sh
fi