#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# TODO: Keep a local copy of the Debian base image — old versions get deleted after a while

mkdir -p cache/$PLATFORM

case $PLATFORM in
    x86_64)
        wget -nc https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.0.0-amd64-netinst.iso -O cache/$PLATFORM/base.iso
        ;;

    rpi)
        wget -nc https://downloads.raspberrypi.com/raspios_lite_armhf/images/raspios_lite_armhf-2023-10-10/2023-10-10-raspios-bookworm-armhf-lite.img.xz -O cache/$PLATFORM/baseinstall.img.xz

        if ! [ -e cache/$PLATFORM/baseinstall.img ]; then
            xz -d -k cache/$PLATFORM/baseinstall.img.xz
        fi

        ;;

    arm64)
        wget -nc https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-12.0.0-arm64-netinst.iso -O cache/$PLATFORM/base.iso
        ;;

    pinephone)
        wget -nc https://images.mobian.org/pinephone/mobian-pinephone-phosh-12.0.img.gz -O cache/$PLATFORM/baseinstall.img.gz
        
        if ! [ -e cache/$PLATFORM/baseinstall.img ]; then
            gzip -d cache/$PLATFORM/baseinstall.img.gz
        fi
esac