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

if [ $PLATFORM = "arm64" ]; then
    # Debian `arm64` doesn't have `dhcpcd` included, so we'll need to start up a DHCP server manually
    dhclient
fi

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

    parted -m /dev/mmcblk0 u s resizepart 2 8388608 # 4 GiB (4 * 1024 * 1024 * 2)
    resize2fs /dev/mmcblk0p2
fi

if [ $PLATFORM = "pinephone" ]; then
    echo "Expanding filesystem..."

    parted -m /dev/mmcblk0 u s resizepart 2 12582912 # 6 GiB (6 * 1024 * 1024 * 2)
    resize2fs /dev/mmcblk0p2
fi

if [ $PLATFORM = "pinephone" ]; then
    echo "Launching network configuration interface (requires user input)..."

    nmtui # This is because there's no easy way to get Ethernet, so we must connect to Wi-Fi instead

    echo "Setting system clock..."

    hwclock --hctosys
fi

echo "Editing hosts file..."

sed -i -E "s/debian|raspberrypi/liveg/" /etc/hosts

echo "Making changes to system directory structure..."

if [ $PLATFORM = "rpi" ]; then
    usermod --login system pi
    groupmod -n system pi
fi

if [ $PLATFORM = "pinephone" ]; then
    usermod --login system mobian
    groupmod -n system mobian
fi

usermod -m -d /system system

passwd -d system

if [ $depInstall = true ]; then
    echo "Installing dependencies required for adding LiveG APT Repository..."

    apt update
    apt install -y curl gnupg

    echo "Adding LiveG APT Repository to APT sources..."

    curl -s --compressed https://opensource.liveg.tech/liveg-apt/KEY.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/liveg-apt.gpg > /dev/null
    curl -s --compressed https://opensource.liveg.tech/liveg-apt/liveg-apt.list -o /etc/apt/sources.list.d/liveg-apt.list

    echo "Installing dependencies..."

    if [ $PLATFORM = "pinephone" ]; then
        tee /etc/apt/sources.list.d/sid.list << EOF
deb http://http.us.debian.org/debian sid main non-free
deb-src http://http.us.debian.org/debian sid main non-free
EOF

        tee /etc/apt/sources.list.d/buster.list << EOF
deb http://http.us.debian.org/debian bullseye non-free
deb-src http://http.us.debian.org/debian bullseye non-free
EOF
    fi

    apt update
    apt install -y xorg wget chromium fuse libfuse2 fdisk rsync efibootmgr network-manager fonts-noto zlib1g-dev plymouth plymouth-x11
    dpkg -r --force-depends chromium # We only want the dependencies of Chromium

    if [ $PLATFORM = "pinephone" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y dhcpcd5 liveg-pinephone-support
    fi
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

tee -a /system/.bashrc << EOF
/system/scripts/startup.sh
EOF

touch /system/.hushlogin

sed -i -e "s/managed=false/managed=true/g" /etc/NetworkManager/NetworkManager.conf

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
fi

if [ $PLATFORM = "rpi" ] || [ $PLATFORM = "pinephone" ]; then
    echo "Adding Stage 2 script..."

    cp /host/stage2.sh /system/scripts/stage2.sh
    chmod a+x /system/scripts/stage2.sh

    touch /system/stage2
fi

echo "Adding boot animation..."

mkdir -p /usr/share/plymouth/themes/liveg
cp -a /host/common/plymouth/. /usr/share/plymouth/themes/liveg/
cp /host/common/plymouthd.conf /etc/plymouth/plymouthd.conf

if [ $PLATFORM = "rpi" ]; then
    sed "1{s/$/ quiet splash logo.nologo loglevel=2 udev.log_level=2 vt.global_cursor_default=0/}" /boot/cmdline.txt
fi

echo "Cleaning up..."

tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --skip-login --nonewline --noissue --autologin system --noclear %I 38400 linux
EOF

sed -i "/\.\/firstboot\.sh/d" /root/.bashrc

if [ $PLATFORM = "rpi" ] || [ $PLATFORM = "pinephone" ]; then
    sed -i -e "s/root::/root:x:/g" /etc/passwd

    rm /etc/systemd/system/getty.target.wants/serial-getty-firstboot@ttyAMA0.service
    rm /etc/systemd/system/getty.target.wants/serial-getty-firstboot@tty1.service
fi

# TODO: Remove network config for PinePhone

rm -rf /host

echo "All done! Shutting down now..."

shutdown -h now