#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

sudo umount -l build/$PLATFORM/bootfs || /bin/true
sudo umount -l build/$PLATFORM/rootfs || /bin/true
sudo umount -l build/$PLATFORM/base-bootfs || /bin/true
sudo umount -l build/$PLATFORM/base-rootfs || /bin/true
sudo losetup -d /dev/loop0 || /bin/true
sudo losetup -d /dev/loop1 || /bin/true