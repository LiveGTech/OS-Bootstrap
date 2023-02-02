#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# Apply write permissions to `system` user
sudo chown -R system:system /system
sudo chmod -R a+w /system

if xset q &> /dev/null; then
    # X11 already running, so we might be running from a virtual terminal or something else
    exit
fi

if [ -f /system/stage2 ]; then
    /system/scripts/stage2.sh
fi

while true; do
    clear
    startx /system/scripts/xload.sh > /dev/null 2>&1
done