#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

if [ -e cache/system.img ]; then
    cp cache/system.img build/system.img
else
    cp build/system.img cache/system.img
fi

sudo umount build/rootfs || /bin/true
sudo mount -o loop,offset=1048576 build/system.img build/rootfs

sudo cp host/isogrub.cfg build/rootfs/boot/grub/grub.cfg
sudo cp host/isofstab build/rootfs/etc/fstab

sudo grub-mkrescue -o build/system.iso build/rootfs -- \
    -volid LiveG-OS \
    -chmod a+rwx,g-w,o-w,ug+s,+t,g-s,-t /usr/bin/sudo

sudo umount build/rootfs

qemu-img create cache/test.img 3G

qemu-system-x86_64 \
    -m 1G \
    -cdrom build/system.iso \
    -hda cache/test.img