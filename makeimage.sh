#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

rm build/$PLATFORM/image.img || /bin/true
qemu-img create build/$PLATFORM/image.img +4G

(
    echo o # Create DOS partition table
    echo n # New partition
    echo p # Primary
    echo 1 # Partition number
    echo 8192 # First sector at 4 MiB
    echo +248M # 248 MiB space
    echo n # New partition
    echo p # Primary
    echo 2 # Partition number
    echo 516096 # First sector after first partition
    echo # Default last sector (fill remaining to end)
    echo w # Write and exit
) | fdisk build/$PLATFORM/image.img

mkdir -p build/$PLATFORM/image-bootfs
mkdir -p build/$PLATFORM/image-rootfs

./unmount.sh
./mount.sh

sudo losetup -P /dev/loop1 build/$PLATFORM/image.img

sudo mkfs.vfat /dev/loop1p1
sudo fatlabel /dev/loop1p1 LiveG-Boot
sudo mkfs.ext4 /dev/loop1p2 -L LiveG-OS

sudo mount /dev/loop1p1 build/$PLATFORM/image-bootfs
sudo mount /dev/loop1p2 build/$PLATFORM/image-rootfs

sudo rsync -ar --info=progress2 --no-inc-recursive build/$PLATFORM/rootfs/ build/$PLATFORM/image-rootfs

sudo cp host/$PLATFORM/fstab build/$PLATFORM/image-rootfs/etc/fstab

sudo rsync -ar --info=progress2 --no-inc-recursive build/$PLATFORM/image-rootfs/boot/ build/$PLATFORM/image-bootfs

sudo mkdir -p build/$PLATFORM/image-bootfs/dtb/allwinner
sudo rsync -ar --info=progress2 --no-inc-recursive host/$PLATFORM/dtb/ build/$PLATFORM/image-bootfs/dtb/allwinner

sudo mkdir -p build/$PLATFORM/image-bootfs/extlinux
sudo cp host/$PLATFORM/extlinux.conf build/$PLATFORM/image-bootfs/extlinux/extlinux.conf

if [ $PLATFORM = "pinephone" ]; then
    echo "Adding p-boot..."

    host/$PLATFORM/p-boot/p-boot-conf host/$PLATFORM/p-boot build/$PLATFORM/image.img
    dd if=host/$PLATFORM/p-boot/p-boot.bin of=build/$PLATFORM/image.img bs=1024 seek=8
    sync

    echo "p-boot added"
fi

./unmount.sh