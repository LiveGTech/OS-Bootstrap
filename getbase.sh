#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# TODO: Keep a local copy of the Debian base image — old versions get deleted after a while
# TODO: Also ensure that `vmlinuz` version in `grub.cfg` and `isogrub.cfg` is correct with new releases — maybe automate this

mkdir -p cache/$PLATFORM

case $PLATFORM in
    x86_64)
        wget -nc https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.5.0-amd64-netinst.iso -O cache/$PLATFORM/base.iso
        ;;

    rpi)
        wget -nc https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-09-26/2022-09-22-raspios-bullseye-armhf-lite.img.xz -O cache/$PLATFORM/baseinstall.img.xz

        if ! [ -e cache/$PLATFORM/baseinstall.img ]; then
            xz -d -k cache/$PLATFORM/baseinstall.img.xz
        fi

        ;;

    arm64)
        wget -nc https://cdimage.debian.org/debian-cd/current/arm64/iso-cd/debian-11.5.0-arm64-netinst.iso -O cache/$PLATFORM/base.iso
        ;;

    pinephone)
        wget -nc https://images.mobian-project.org/pinephone/weekly/mobian-pinephone-phosh-20230122.img.gz -O cache/$PLATFORM/baseinstall.img.gz
        
        if ! [ -e cache/$PLATFORM/baseinstall.img ]; then
            gzip -d cache/$PLATFORM/baseinstall.img.gz
        fi
esac