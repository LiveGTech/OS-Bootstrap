#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

export PLATFORM="x86_64"
export GSHELL_VERSION="0.3.0"
export GSHELL_VERNUM=6
export GSHELL_PROVIDED_DIST=""
export QEMU_ARGS=""
export EMULATING=true

envOnly=false

if [[ $1 != "" ]]; then
    export PLATFORM=$1
fi

case $PLATFORM in
    x86_64)
        export ARCH="x86_64"
        export GRUB_LOCATION="usr/lib/grub/i386-pc"

        export QEMU_ARGS="\
            -enable-kvm \
            -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
            -device virtio-net-pci,netdev=net0 \
        "

        ;;

    rpi)
        export ARCH="aarch64"

        export QEMU_ARGS="\
            -machine raspi3b \
            -cpu cortex-a53 \
            -dtb host/rpi/cache/rpi3.dtb \
            -serial mon:stdio \
            -nographic \
            -kernel host/rpi/cache/kernel8.img \
            -usb \
            -netdev user,id=net0,hostfwd=tcp::8002-:8000,hostfwd=tcp::2222-:22 \
            -device usb-net,netdev=net0 \
            -append 'rw earlyprintk=ttyAMA0,115200 loglevel=8 console=ttyAMA0,115200 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait' \
        "

        ;;

    arm64|pinephone)
        export ARCH="aarch64"
        export GRUB_LOCATION="usr/lib/grub/arm64-efi"

        export QEMU_ARGS="\
            -machine virt \
            -cpu cortex-a53 \
            -smp 8 \
            -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
            -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
            -device virtio-net-pci,netdev=net0 \
            -device usb-ehci \
            -device usb-kbd \
            -monitor tcp:127.0.0.1:8001,server,nowait \
        "

        ;;

    *)
        echo "Invalid platform specified" >&2
        exit 1
        ;;
esac

export QEMU_COMMAND="qemu-system-$ARCH"

while test $# -gt 0; do
    case $1 in
        --env-only)
            envOnly=true
            ;;

        --no-emulation)
            export EMULATING=false
            export QEMU_COMMAND=./manual.sh

            echo "Emulation has been disabled; images must be manually run"

            ;;

        --gshell-dist)
            shift
            export GSHELL_PROVIDED_DIST=$1
            ;;
    esac

    shift
done

if [ $envOnly = true ]; then
    echo "In shell that has environment variables for execution of other scripts only"

    bash --rcfile <(
        cat ~/.bashrc
        echo "_PS1=\$PS1"
        echo "PS1=\"($PLATFORM) \$_PS1\""
    )

    exit
fi

sudo true # Ensure recent password entry in case `NOPASSWD` has not been set

./server.sh
./buildgshell.sh
./buildauil.sh
./getbase.sh
./boot.sh

case $PLATFORM in
    rpi|pinephone)
        # These devices don't need an ISO file; just use image file instead
        ;;

    *)
        # Build an ISO file from the current image file
        ./makeiso.sh
        ;;
esac