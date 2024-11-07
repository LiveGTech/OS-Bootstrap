#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

mkdir -p build/$PLATFORM

if [ $PLATFORM = "pinephone" ] && ! [ -e cache/$PLATFORM/system.img ]; then
    echo "Creating new base installed image..."

    ./makeimage.sh
elif [ -e cache/$PLATFORM/baseinstall.img ]; then
    echo "Base installed image found; using that instead"

    cp cache/$PLATFORM/baseinstall.img build/$PLATFORM/system.img
elif [ $PLATFORM != "rpi" ]; then
    echo "Creating new base installed image (this might take about 30 minutes or longer)..."

    qemu-img create build/$PLATFORM/system.img 6G

    ./bootkeys.sh &

    if [ $PLATFORM = "arm64" ]; then
        bash -c "$QEMU_COMMAND \
            -m 4G \
            -device virtio-scsi-pci,id=scsi0 \
            -device scsi-cd,bus=scsi0.0,drive=cdrom0 \
            -drive id=cdrom0,format=raw,if=none,file=cache/$PLATFORM/base.iso \
            -device virtio-scsi-pci,id=scsi1 \
            -device scsi-hd,bus=scsi1.0,drive=hd0 \
            -drive id=hd0,format=raw,if=none,file=build/$PLATFORM/system.img \
            $QEMU_ARGS"
    else
        bash -c "$QEMU_COMMAND \
            -m 2G \
            -cdrom cache/$PLATFORM/base.iso \
            -hda build/$PLATFORM/system.img \
            -monitor tcp:127.0.0.1:8001,server,nowait \
            $QEMU_ARGS"
    fi

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

sudo mkdir -p build/$PLATFORM/rootfs/host
sudo cp -a host/$PLATFORM/. build/$PLATFORM/rootfs/host/
sudo cp -a host/common/. build/$PLATFORM/rootfs/host/common

sudo mkdir -p build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d

if [ $PLATFORM = "arm64" ]; then
    sudo tee build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
    [Service]
    ExecStart=
    ExecStart=-/sbin/agetty --autologin root --noclear ttyAMA0 115200 vt102
EOF
else
    sudo tee build/$PLATFORM/rootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
    [Service]
    ExecStart=
    ExecStart=-/sbin/agetty --autologin root --noclear %I 38400 linux
EOF
fi

if [ $PLATFORM = "rpi" ]; then
    sudo mkdir -p build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants

    sudo cp host/$PLATFORM/serial-getty-firstboot@.service build/$PLATFORM/rootfs/lib/systemd/system/serial-getty-firstboot@.service

    if [ $EMULATING = true ]; then
        sudo ln -s /lib/systemd/system/serial-getty-firstboot@.service build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants/serial-getty-firstboot@ttyAMA0.service
        sudo ln -s /dev/null build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants/serial-getty@ttyAMA0.service
    else
        sudo ln -s /lib/systemd/system/serial-getty-firstboot@.service build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants/serial-getty-firstboot@tty1.service
        sudo ln -s /dev/null build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants/serial-getty@tty1.service
    fi

    sudo sed -i -e "s/root:x:/root::/g" build/$PLATFORM/rootfs/etc/passwd
fi

if [ $PLATFORM = "pinephone" ]; then
    sudo rm build/$PLATFORM/rootfs/etc/systemd/system/display-manager.service

    sudo mkdir -p build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants
    sudo ln -s /lib/systemd/system/getty@.service build/$PLATFORM/rootfs/etc/systemd/system/getty.target.wants/getty@tty1.service

    sudo rm build/$PLATFORM/rootfs/usr/lib/systemd/system/default.target
    sudo ln -s multi-user.target build/$PLATFORM/rootfs/usr/lib/systemd/system/default.target
fi

sudo cp firstboot.sh build/$PLATFORM/rootfs/root/firstboot.sh
sudo sed -i -e "s/%PLATFORM/$PLATFORM/g" build/$PLATFORM/rootfs/root/firstboot.sh

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
VERSION="$GSHELL_VERSION"
ID="livegos"
ID_LIKE="debian"
PRETTY_NAME="LiveG OS $GSHELL_VERSION"
VERSION_ID=$GSHELL_VERNUM
HOME_URL="https://liveg.tech/os"
SUPPORT_URL="https://docs.liveg.tech/?product=os"
EOF

sudo sed -i -e "s/ALL=(ALL:ALL) ALL/ALL=(ALL:ALL) NOPASSWD:ALL/g" build/$PLATFORM/rootfs/etc/sudoers

if [ $PLATFORM = "x86_64" ]; then
    sudo tee -a build/$PLATFORM/rootfs/etc/systemd/logind.conf << EOF
HandlePowerKey=ignore
HandleLidSwitch=ignore
EOF
fi

if [ $PLATFORM = "rpi" ]; then
    mkdir -p build/$PLATFORM/bootfs
    sudo umount build/$PLATFORM/bootfs || /bin/true
    sudo mount /dev/loop0p1 build/$PLATFORM/bootfs

    cp build/$PLATFORM/bootfs/kernel8.img host/$PLATFORM/cache/kernel8.img
    cp build/$PLATFORM/bootfs/bcm2710-rpi-3-b-plus.dtb host/$PLATFORM/cache/rpi3.dtb

    sudo tee build/$PLATFORM/bootfs/userconf << EOF
pi:\$6\$c70VpvPsVNCG0YR5\$l5vWWLsLko9Kj65gcQ8qvMkuOoRkEagI90qi3F/Y7rm8eNYZHW8CY6BOIKwMH7a3YYzZYL90zf304cAHLFaZE0
EOF

    sudo sed -i "s|quiet init=/usr/lib/raspberrypi-sys-mods/firstboot||" build/$PLATFORM/bootfs/cmdline.txt

    sync

    sudo umount build/$PLATFORM/bootfs
fi

./unmount.sh

if [ $PLATFORM = "arm64" ]; then
    sudo umount build/$PLATFORM/bootfs || /bin/true
    sudo mount -o loop,offset=1048576 build/$PLATFORM/system.img build/$PLATFORM/bootfs

    sudo mkdir -p build/$PLATFORM/bootfs/EFI/boot
    sudo cp build/$PLATFORM/bootfs/EFI/debian/grubaa64.efi build/$PLATFORM/bootfs/EFI/boot/bootaa64.efi

    sudo umount build/$PLATFORM/bootfs
fi

echo "Modification of root file system complete"

if [ $PLATFORM = "pinephone" ]; then
    ./makebootable.sh
fi

bash -c "$QEMU_COMMAND \
    -m 2G \
    -hda build/$PLATFORM/system.img \
    $QEMU_ARGS"

rm cache/$PLATFORM/system.img
