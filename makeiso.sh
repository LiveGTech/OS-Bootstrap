#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# Make a backup
if [ -e cache/system.img ]; then
    rsync --info=progress2 cache/system.img build/system.img
else
    rsync --info=progress2 build/system.img cache/system.img
fi

sudo umount build/rootfs || /bin/true
sudo mount -o loop,offset=1048576 build/system.img build/rootfs

sudo cp host/isogrub.cfg build/rootfs/boot/grub/grub.cfg
sudo cp host/isofstab build/rootfs/etc/fstab
sudo cp host/initoverlay.sh build/rootfs/sbin/initoverlay

sudo grub-mkrescue -o build/system.iso build/rootfs --directory=build/rootfs/usr/lib/grub/i386-pc -- \
    -volid LiveG-OS-IM \
    -chmod a+rwx,g-w,o-w,ug+s,+t,g-s,-t /usr/bin/sudo -- \
    -chmod a+rwx /usr/sbin/initoverlay --

sudo umount build/rootfs

# TODO: Make next parts optional depending if wanting to test to see if
# succeeded (if we automate, then next part should be skipped so script exits
# when everything is complete).

qemu-img create cache/test.img 4G

qemu-system-x86_64 \
    -enable-kvm \
    -m 2G \
    -cdrom build/system.iso \
    -hdb cache/test.img \
    -boot order=d