#!/bin/sh

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

modprobe overlay

mount -t proc proc /proc
mount -t tmpfs mnt /mnt

mkdir /mnt/lower
mkdir /mnt/upper 
mkdir /mnt/work 
mkdir /mnt/root

mount -t iso9660 -o noatime,suid,errors=remount-ro,ro /dev/sr0 /mnt/lower
mount -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/upper,workdir=/mnt/work overlay /mnt/root

cd /mnt/root
pivot_root . mnt

exec chroot . /sbin/init