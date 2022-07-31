#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

clear

echo " _     _            ____    ___  ____  "
echo "| |   (_)_   _____ / ___|  / _ \\/ ___| "
echo "| |   | \\ \\ / / _ \\ |  _  | | | \\___ \\ "
echo "| |___| |\\ V /  __/ |_| | | |_| |___) |"
echo "|_____|_| \\_/ \\___|\\____|  \\___/|____/ "
echo "                                       "
echo " ____              _       _                         _             "
echo "| __ )  ___   ___ | |_ ___| |_ _ __ __ _ _ __  _ __ (_)_ __   __ _ "
echo "|  _ \\ / _ \\ / _ \\| __/ __| __| '__/ _\` | '_ \\| '_ \\| | '_ \\ / _\` |"
echo "| |_) | (_) | (_) | |_\\__ \\ |_| | | (_| | |_) | |_) | | | | | (_| |"
echo "|____/ \\___/ \\___/ \\__|___/\\__|_|  \\__,_| .__/| .__/|_|_| |_|\\__, |"
echo "                                        |_|   |_|            |___/"
echo ""
echo "The LiveG OS bootstrapping firstboot script is running"

echo "Making changes to system directory structure..."

usermod -m -d /system system

echo "Installing X11..."

apt install -y xorg wget chromium fuse libfuse2 fdisk rsync
dpkg -r --force-depends chromium # We only want the dependencies of Chromium

echo "All done! Shutting down now..."

shutdown -h now