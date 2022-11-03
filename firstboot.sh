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

depInstall=true

while test $# -gt 0; do
    case $1 in
        --skip-dep-install)
            depInstall=false
            ;;
    esac

    shift
done

echo "Editing hosts file..."

sed -i "s/debian/liveg/" /etc/hosts

echo "Making changes to system directory structure..."

usermod -m -d /system system

if [ $depInstall = true ]; then
    echo "Installing dependencies required for adding LiveG APT Repository..."

    apt update
    apt install -y curl gnupg

    echo "Adding LiveG APT Repository to APT sources..."

    curl -s --compressed https://opensource.liveg.tech/liveg-apt/KEY.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/liveg-apt.gpg > /dev/null
    curl -s --compressed https://opensource.liveg.tech/liveg-apt/liveg-apt.list -o /etc/apt/sources.list.d/liveg-apt.list

    echo "Installing dependencies..."

    apt update
    apt install -y xorg wget chromium fuse libfuse2 fdisk rsync efibootmgr
    dpkg -r --force-depends chromium # We only want the dependencies of Chromium
else
    echo "Skipped installation of dependencies"
fi

echo "Downloading gShell..."

mkdir -p /system/bin
wget http://10.0.2.2:8000/cache/gshell.AppImage -O /system/bin/gshell.AppImage
chmod a+x /system/bin/gshell.AppImage

mkdir -p /system/storage
mkdir -p /system/logs

wget http://10.0.2.2:8000/device.gsc -O /system/storage/device.gsc

echo "Adding startup scripts..."

mkdir -p /system/scripts

wget http://10.0.2.2:8000/startup.sh -O /system/scripts/startup.sh
chmod a+x /system/scripts/startup.sh

wget http://10.0.2.2:8000/xload.sh -O /system/scripts/xload.sh
chmod a+x /system/scripts/xload.sh

sudo tee -a /system/.bashrc << EOF
/system/scripts/startup.sh
EOF

echo "Adding installation helper files..."

mkdir -p /system/install

wget http://10.0.2.2:8000/grub.cfg -O /system/install/grub.cfg
wget http://10.0.2.2:8000/fstab -O /system/install/fstab
wget http://10.0.2.2:8000/fstab-swap -O /system/install/fstab-swap

sudo tee -a /system/.bashrc << EOF
/system/scripts/startup.sh
EOF

echo "Cleaning up..."

tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin system --noclear %I 38400 linux
EOF

sed -i "/\.\/firstboot\.sh/d" /root/.bashrc

echo "All done! Shutting down now..."

shutdown -h now