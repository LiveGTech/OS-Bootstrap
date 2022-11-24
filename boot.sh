#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

mkdir -p build/$PLATFORM

if [ -e cache/$PLATFORM/baseinstall.img ]; then
    echo "Base installed image found; using that instead"

    cp cache/$PLATFORM/baseinstall.img build/$PLATFORM/system.img
elif [ $PLATFORM != "rpi" ]; then
    echo "Creating new base installed image (this might take about 30 minutes or longer)..."

    qemu-img create build/$PLATFORM/system.img 4G

    ./bootkeys.sh &

    bash -c "qemu-system-$ARCH \
        -m 1G \
        -cdrom cache/$PLATFORM/base.iso \
        -hda build/$PLATFORM/system.img \
        -monitor tcp:127.0.0.1:8001,server,nowait \
        $QEMU_ARGS"

    cp build/$PLATFORM/system.img cache/$PLATFORM/baseinstall.img
fi

mkdir -p host/$PLATFORM/cache

if [ $PLATFORM = "rpi" ]; then
    echo "Resizing image..."

    qemu-img resize build/$PLATFORM/system.img 4G
fi

cp cache/$PLATFORM/gshell.AppImage host/$PLATFORM/cache/gshell.AppImage

echo "Mounting disk image to \`build/$PLATFORM/rootfs\`..."

./mount.sh

sudo mkdir -p build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d

sudo tee build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF

sudo cp firstboot.sh build/$PLATFORM/rootfs/root/firstboot.sh

sudo tee -a build/$PLATFORM/rootfs/root/.bashrc << EOF
./firstboot.sh
EOF

sudo tee build/$PLATFORM/rootfs/etc/hostname << EOF
liveg
EOF

sudo sed -i -E -e "s/debian|raspberrypi/liveg/g" build/$PLATFORM/rootfs/etc/hosts

sudo tee build/$PLATFORM/rootfs/etc/issue << EOF
LiveG OS \n \l
EOF

sudo tee build/$PLATFORM/rootfs/etc/os-release << EOF
NAME="LiveG OS"
VERSION="0.2.0"
ID="livegos"
ID_LIKE="debian"
PRETTY_NAME="LiveG OS V0.2.0"
VERSION_ID="0"
HOME_URL="https://liveg.tech/os"
SUPPORT_URL="https://docs.liveg.tech/?product=os"
EOF

sudo sed -i -e "s/ALL=(ALL:ALL) ALL/ALL=(ALL:ALL) NOPASSWD:ALL/g" build/$PLATFORM/rootfs/etc/sudoers

if [ $PLATFORM = "rpi" ]; then
    sudo umount build/$PLATFORM/bootfs || /bin/true
    sudo mount /dev/loop0p1 build/$PLATFORM/bootfs

    sudo tee build/$PLATFORM/bootfs/userconf << EOF
pi:\$6\$c70VpvPsVNCG0YR5\$l5vWWLsLko9Kj65gcQ8qvMkuOoRkEagI90qi3F/Y7rm8eNYZHW8CY6BOIKwMH7a3YYzZYL90zf304cAHLFaZE0
EOF

    sudo touch build/$PLATFORM/bootfs/ssh

    sudo umount build/$PLATFORM/bootfs

    # TODO: We need to somehow access the system via SSH
fi

./unmount.sh

echo "Modification of root file system complete"

echo build/$PLATFORM/system.img

bash -c "qemu-system-$ARCH \
    -m 1G \
    -hda build/$PLATFORM/system.img \
    $QEMU_ARGS"

rm cache/$PLATFORM/system.img