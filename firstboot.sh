#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

PLATFORM=%PLATFORM

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
echo "Platform: $PLATFORM"

depInstall=true

dhclient

while test $# -gt 0; do
    case $1 in
        --skip-dep-install)
            depInstall=false
            ;;
    esac

    shift
done

if [ $PLATFORM = "rpi" ]; then
    echo "Expanding filesystem..."

    parted -m /dev/mmcblk0 u s resizepart 2 8388608 # 4 GiB in 512-byte sectors
    resize2fs /dev/mmcblk0p2
fi

echo "Editing hosts file..."

sed -i -E "s/debian|raspberrypi/liveg/" /etc/hosts

echo "Making changes to system directory structure..."

if [ $PLATFORM = "rpi" ]; then
    usermod --login system pi
    groupmod -n system pi
fi

usermod -m -d /system system

passwd -d system

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
cp /host/cache/gshell.AppImage /system/bin/gshell.AppImage
chmod a+x /system/bin/gshell.AppImage

mkdir -p /system/storage
mkdir -p /system/logs

cp /host/device.gsc /system/storage/device.gsc

echo "Adding startup scripts..."

mkdir -p /system/scripts

cp /host/startup.sh /system/scripts/startup.sh
chmod a+x /system/scripts/startup.sh

cp /host/xload.sh /system/scripts/xload.sh
chmod a+x /system/scripts/xload.sh

sudo tee -a /system/.bashrc << EOF
/system/scripts/startup.sh
EOF

if [ $PLATFORM = "x86_64" ]; then
    echo "Adding installation helper files..."

    mkdir -p /system/install

    cp /host/grub.cfg /system/install/grub.cfg
    cp /host/fstab /system/install/fstab
    cp /host/fstab-swap /system/install/fstab-swap
fi

if [ $PLATFORM = "rpi" ]; then
    echo "Enabling network management backend..."

    systemctl enable NetworkManager

    echo "Changing system behaviour..."

    cp /usr/share/raspi-config/10-blanking.conf /etc/X11/xorg.conf.d

    echo "Adding Stage 2 script..."

    cp /host/stage2.sh /system/scripts/stage2.sh
    chmod a+x /system/scripts/stage2.sh

    touch /system/stage2
fi

echo "Cleaning up..."

tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin system --noclear %I 38400 linux
EOF

sed -i "/\.\/firstboot\.sh/d" /root/.bashrc

if [ $PLATFORM = "rpi" ]; then
    sed -i -e "s/root::/root:x:/g" /etc/passwd

    rm /etc/systemd/system/getty.target.wants/serial-getty-firstboot@ttyAMA0.service
    rm /etc/systemd/system/getty.target.wants/serial-getty-firstboot@tty1.service
fi

rm -rf /host

echo "All done! Shutting down now..."

shutdown -h now