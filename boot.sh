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

    qemu-img create build/system.img 4G

    ./bootkeys.sh &

    qemu-system-x86_64 \
        -enable-kvm \
        -m 1G \
        -cdrom cache/base.iso \
        -hda build/system.img \
        -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
        -device virtio-net-pci,netdev=net0 \
        -monitor tcp:127.0.0.1:8001,server,nowait

    cp build/system.img cache/baseinstall.img
fi

mkdir -p host/cache
cp cache/gshell.AppImage host/cache/gshell.AppImage

echo "Mounting disk image to \`build/rootfs\`..."

sudo umount build/rootfs || /bin/true
mkdir -p build/rootfs
sudo mount -o loop,offset=1048576 build/system.img build/rootfs

sudo mkdir -p build/rootfs/etc/systemd/system/getty@tty1.service.d

sudo tee build/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF

sudo cp firstboot.sh build/rootfs/root/firstboot.sh

sudo tee -a build/rootfs/root/.bashrc << EOF
./firstboot.sh
EOF

sudo tee build/rootfs/etc/hostname << EOF
liveg
EOF

sudo sed -i -e "s/debian/liveg/g" /etc/hosts

sudo tee build/rootfs/etc/issue << EOF
LiveG OS \n \l
EOF

sudo umount build/rootfs

echo "Modification of root file system complete"

qemu-system-x86_64 \
    -enable-kvm \
    -m 1G \
    -hda build/system.img \
    -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
    -device virtio-net-pci,netdev=net0

rm cache/system.img