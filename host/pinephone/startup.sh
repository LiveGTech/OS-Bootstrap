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

    # Update staging
    if [ -f /system/gshell-staging-ready ]; then
        if [ -f /system/scripts/update-reboot.sh ]; then
            /system/scripts/update-reboot.sh
        fi

        pushd /system/bin
            if [ -f gshell-update.AppImage ]; then
                # gShell files are moved this way to prevent a bad state in case of unscheduled system shutdown
                mv gshell.AppImage gshell-old.AppImage
                mv gshell-update.AppImage gshell.AppImage
                rm gshell-old.AppImage
            fi
        popd

        rm /system/gshell-staging-ready
    fi

    startx /system/scripts/xload.sh -- -nocursor > /dev/null 2>&1
done