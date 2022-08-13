#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

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

qemu-img create cache/test.img 4G

qemu-system-x86_64 \
    -enable-kvm \
    -m 2G \
    -cdrom build/system.iso \
    -hdb cache/test.img \
    -boot order=d

# For performing the installation:
# sudo mount -t tmpfs root-rw /tmp
# mkdir /tmp/base
# Next steps to be done inside gShell:
# sudo fdisk /dev/sda
# sudo mkfs.ext4 /dev/sda1 -L "LiveG-OS"
# sudo mount /dev/sda1 /tmp/base
# sudo rsync \
#     -ah \
#     --info=progress2 \
#     --no-inc-recursive \
#     --exclude=/dev --exclude=/proc --exclude=/sys \
#     / /tmp/base
# sudo mkdir /tmp/base/dev
# sudo mkdir /tmp/base/proc
# sudo mkdir /tmp/base/sys
# sudo mount --bind /dev /tmp/base/dev
# sudo mount --bind /proc /tmp/base/proc
# sudo mount --bind /sys /tmp/base/sys
# sudo mount --bind /usr /tmp/base/usr
# sudo chroot /tmp/base /bin/bash -c "grub-install /dev/sda"