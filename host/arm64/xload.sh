#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

xset s 0

sudo dmidecode | grep -i "Product Name: VirtualBox"

if [ $? = 0 ]; then
    xrandr --output Virtual1 --mode 1280x720
fi

cd /system/bin
./gshell.AppImage --appimage-extract-and-run -- --real > /system/logs/gshell.log