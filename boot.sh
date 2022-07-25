#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

mkdir -p build

if [ -e cache/baseinstall.img ]; then
    echo "Base installed image found; using that instead"

    cp cache/baseinstall.img build/system.img
else
    echo "Creating new base installed image (this might take about 30 minutes or longer)..."

    qemu-img create build/system.img 1G

    ./bootkeys.sh &

    qemu-system-x86_64 \
        -m 1G \
        -cdrom cache/base.iso \
        -hda build/system.img \
        -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
        -device virtio-net-pci,netdev=net0 \
        -monitor tcp:127.0.0.1:8001,server,nowait

    cp build/system.img cache/baseinstall.img
fi

echo "Mounting disk image to \`build/rootfs\`..."

sudo umount build/rootfs || /bin/true
mkdir -p build/rootfs
sudo mount -o loop,offset=1048576 build/system.img build/rootfs

sudo mkdir -p build/rootfs/etc/systemd/system/getty@tty1.service.d

sudo tee build/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin system --noclear %I 38400 linux
EOL

sudo tee build/rootfs/etc/sudoers.d/nopasswd << EOL
system ALL=(ALL:ALL) NOPASSWD: ALL
EOL

sudo cp nextboot.sh build/rootfs/home/system/nextboot.sh

sudo tee -a build/rootfs/home/system/.bashrc << EOL
./nextboot.sh
EOL

sudo umount build/rootfs

echo "Modification of root file system complete"

qemu-system-x86_64 \
    -m 1G \
    -hda build/system.img \
    -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
    -device virtio-net-pci,netdev=net0