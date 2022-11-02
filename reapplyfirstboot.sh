#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

sudo umount build/$PLATFORM/rootfs || /bin/true
mkdir -p build/$PLATFORM/rootfs
sudo mount -o loop,offset=1048576 build/$PLATFORM/system.img build/$PLATFORM/rootfs

sudo mkdir -p build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d

sudo tee build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF

sudo cp firstboot.sh build/$PLATFORM/rootfs/root/firstboot.sh

sudo tee -a build/$PLATFORM/rootfs/root/.bashrc << EOF
./firstboot.sh --skip-dep-install
EOF

sudo umount build/$PLATFORM/rootfs

qemu-system-$ARCH \
    -enable-kvm \
    -m 1G \
    -hda build/$PLATFORM/system.img \
    -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
    -device virtio-net-pci,netdev=net0 \
    $QEMU_ARGS