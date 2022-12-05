#!/bin/sh

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

modprobe overlay

mount -t proc proc /proc
mount -t tmpfs tmp /mnt

mkdir /mnt/lower
mkdir /mnt/overlay

mount -t tmpfs rw /mnt/overlay

mkdir /mnt/overlay/upper
mkdir /mnt/overlay/work
mkdir /mnt/root

mount -t iso9660 -o defaults,ro /dev/sr0 /mnt/lower
mount -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/overlay/upper,workdir=/mnt/overlay/work overlay /mnt/root

mkdir /mnt/root/ro
mkdir /mnt/root/rw

cd /mnt/root

pivot_root . mnt

exec chroot . sh -c "$(cat << EOF
mount --move /mnt/mnt/lower/ /ro
mount --move /mnt/mnt/overlay /rw

chmod -R 777 /system
chmod u+s /usr/bin/sudo

exec /sbin/init
EOF
)"