#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# Make a backup
if [ -e cache/$PLATFORM/system.img ]; then
    rsync --info=progress2 cache/$PLATFORM/system.img build/$PLATFORM/system.img
else
    rsync --info=progress2 build/$PLATFORM/system.img cache/$PLATFORM/system.img
fi

./unmount.sh

GRUB_DIR_ARGS=""

if [ $PLATFORM = "x86_64" ] || [ $PLATFORM = "arm64" ]; then
    # Install EFI bootloader

    sudo losetup -P /dev/loop0 build/$PLATFORM/system.img

    sudo mount /dev/loop0p1 build/$PLATFORM/bootfs
    sudo mount /dev/loop0p2 build/$PLATFORM/rootfs

    if [ $PLATFORM = "arm64" ]; then
        # Download ARM64 copy of GRUB EFI files on x86-64 host

        wget -nc http://ftp.uk.debian.org/debian/pool/main/g/grub2/grub-efi-arm64-bin_2.06-13+deb12u1_arm64.deb -O cache/$PLATFORM/grub-efi-arm64-bin.deb

        if [ ! -e cache/$PLATFORM/grub-efi-arm64-bin ]; then
            dpkg-deb -R cache/$PLATFORM/grub-efi-arm64-bin.deb cache/$PLATFORM/grub-efi-arm64-bin
        fi

        TARGET_ARGS="--target=arm64-efi --directory=cache/$PLATFORM/grub-efi-arm64-bin/usr/lib/grub/arm64-efi"
        GRUB_DIR_ARGS="--directory=build/$PLATFORM/rootfs/$GRUB_LOCATION"
    fi

    sudo grub-install $TARGET_ARGS --efi-directory=build/$PLATFORM/bootfs --boot-directory=build/$PLATFORM/rootfs/boot --removable
fi

./mount.sh

sudo cp host/$PLATFORM/isogrub.cfg build/$PLATFORM/rootfs/boot/grub/grub.cfg
sudo cp host/$PLATFORM/isofstab build/$PLATFORM/rootfs/etc/fstab
sudo cp host/$PLATFORM/initoverlay.sh build/$PLATFORM/rootfs/sbin/initoverlay

sudo grub-mkrescue -o build/$PLATFORM/system.iso build/$PLATFORM/rootfs \
    --modules="part_msdos part_gpt normal linux configfile search" \
    $GRUB_DIR_ARGS \
    -- \
    -volid LiveG-OS-IM \
    -chmod a+rwx,g-w,o-w,ug+s,+t,g-s,-t /usr/bin/sudo -- \
    -chmod a+rwx /usr/sbin/initoverlay --

./unmount.sh

# TODO: Make next parts optional depending if wanting to test to see if
# succeeded (if we automate, then next part should be skipped so script exits
# when everything is complete).

qemu-img create cache/$PLATFORM/test.img 6G

echo "Testing without EFI"

bash -c "$QEMU_COMMAND \
    -m 2G \
    -cdrom build/$PLATFORM/system.iso \
    -hdb cache/$PLATFORM/test.img \
    -boot order=d \
    $QEMU_ARGS"

echo "Booting installation without EFI"

bash -c "$QEMU_COMMAND \
    -m 2G \
    -hda cache/$PLATFORM/test.img \
    $QEMU_ARGS"

echo "Testing with EFI"

bash -c "$QEMU_COMMAND \
    -m 2G \
    -cdrom build/$PLATFORM/system.iso \
    -hdb cache/$PLATFORM/test.img \
    -boot order=d \
    -bios /usr/share/qemu/OVMF.fd \
    $QEMU_ARGS"

echo "Booting installation with EFI"

bash -c "$QEMU_COMMAND \
    -m 2G \
    -hda cache/$PLATFORM/test.img \
    -bios /usr/share/qemu/OVMF.fd \
    $QEMU_ARGS"