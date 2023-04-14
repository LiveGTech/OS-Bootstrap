#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

echo "Writing bootloader..."

./mount.sh

sudo cp host/$PLATFORM/fstab build/$PLATFORM/rootfs/etc/fstab
sudo host/$PLATFORM/p-boot/p-boot-conf host/$PLATFORM/p-boot /dev/loop0p1

./unmount.sh

dd if=host/$PLATFORM/p-boot/p-boot-serial.bin of=build/$PLATFORM/system.img bs=1024 seek=8 conv=notrunc