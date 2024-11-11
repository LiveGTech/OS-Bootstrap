#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

PLATFORM=%PLATFORM

if [ $PLATFORM = "pinephone" ]; then
    plymouth --quit
fi

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

if [ -f /tmp/firstboot-running ]; then
    echo "Firstboot script is already running!"
    exit
fi

touch /tmp/firstboot-running

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

    echo Yes | parted -m /dev/mmcblk0 ---pretend-input-tty u s resizepart 2 6GiB
    resize2fs /dev/mmcblk0p2
fi

if [ $PLATFORM = "pinephone" ]; then
    echo "Expanding filesystem..."

    parted -m /dev/mmcblk0 u s resizepart 2 6GiB
    resize2fs /dev/mmcblk0p2
fi

if [ $PLATFORM = "pinephone" ]; then
    echo "Launching network configuration interface (requires user input)..."

    nmtui # This is because there's no easy way to get Ethernet, so we must connect to Wi-Fi instead

    echo "Setting system clock..."

    date -s "$(wget -qSO- --max-redirect=0 liveg.tech 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
fi

echo "Editing hosts file..."

sed -i -E "s/debian|raspberrypi/liveg/" /etc/hosts

echo "Making changes to system directory structure..."

if [ $PLATFORM = "rpi" ]; then
    usermod --login system pi
    groupmod -n system pi

    nmtui # Not needed if connected via Ethernet

    echo "Syncing system clock..."

    timedatectl set-ntp true

    echo "Waiting for clock to sync... (5 seconds)"

    sleep 5
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

    tee /etc/apt/preferences.d/100-liveg-pinning << EOF
Package: *
Pin: origin opensource.liveg.tech
Pin-Priority: 1000
EOF

    echo "Installing dependencies..."

    if [ $PLATFORM = "x86_64" ] || [ $PLATFORM = "arm64" ] || [ $PLATFORM = "pinephone" ]; then
        tee /etc/apt/sources.list.d/bookworm.list << EOF
deb http://deb.debian.org/debian bookworm contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian bookworm contrib non-free non-free-firmware

deb http://security.debian.org bookworm-security contrib non-free non-free-firmware
deb-src http://security.debian.org bookworm-security contrib non-free non-free-firmware
EOF
    fi

    apt update
    DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" xorg libxkbcommon0 wget fuse libfuse2 fdisk rsync pv efibootmgr network-manager fonts-noto zlib1g-dev plymouth plymouth-x11 fonts-urw-base35 pipewire-audio speech-dispatcher espeak
    DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --no-install-recommends chromium

    apt --fix-broken install -y

    if [ $PLATFORM = "x86_64" ] || [ $PLATFORM = "arm64" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y dosfstools nvidia-driver firmware-misc-nonfree
    fi

    if [ $PLATFORM = "x86_64" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y grub-efi-amd64 firmware-iwlwifi
    fi

    if [ $PLATFORM = "rpi" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y gldriver-test raspberrypi-kernel=1:1.20230405-1
    fi

    if [ $PLATFORM = "pinephone" ]; then
        DEBIAN_FRONTEND=noninteractive apt install -y dhcpcd5 liveg-pinephone-support
    fi

    apt --fix-broken install -y

    dpkg -r --force-depends chromium || true # We only want the dependencies of Chromium
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

echo "Adding Adapt UI Linux theme..."

mkdir -p /usr/share/themes/Adapt-UI-Linux
cp -r /host/cache/Adapt-UI-Linux/* /usr/share/themes/Adapt-UI-Linux

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

if [ $PLATFORM = "x86_64" ] || [ $PLATFORM = "arm64" ]; then
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

    tee -a /boot/firmware/config.txt << EOF
framebuffer_depth=32
EOF
fi

if [ $PLATFORM = "rpi" ] || [ $PLATFORM = "pinephone" ]; then
    echo "Adding Stage 2 script..."

    cp /host/stage2.sh /system/scripts/stage2.sh
    chmod a+x /system/scripts/stage2.sh

    touch /system/stage2
fi

echo "Adding rules to allow access to USB devices..."

tee /etc/udev/rules.d/00-all-usb.rules << EOF
SUBSYSTEM=="usb", MODE="0660", GROUP="plugdev"
EOF

echo "Adding boot animation..."

mkdir -p /usr/share/plymouth/themes/liveg
cp -a /host/common/plymouth/. /usr/share/plymouth/themes/liveg/
cp /host/common/plymouthd.conf /etc/plymouth/plymouthd.conf

if [ $PLATFORM = "rpi" ]; then
    sed -i "1{s/$/quiet splash logo.nologo loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 plymouth.ignore-serial-consoles/}" /boot/firmware/cmdline.txt
fi

echo "Modifying theme for graphical Linux app integration..."

mkdir -p /usr/share/gtk-3.0

tee /usr/share/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=Adapt-UI-Linux
gtk-icon-theme-name=Adapt-UI-Linux
gtk-font-name=URW Gothic 10
gtk-cursor-theme-size=18
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-decoration-layout=:menu
EOF

update-initramfs -u

echo "Cleaning up..."

tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --skip-login --nonewline --noissue --autologin system --noclear %I 38400 linux
EOF

sed -i "/\.\/firstboot\.sh/d" /root/.bashrc

if [ $PLATFORM = "rpi" ] || [ $PLATFORM = "pinephone" ]; then
    sed -i -e "s/root::/root:x:/g" /etc/passwd

    rm -f /etc/systemd/system/getty.target.wants/serial-getty-firstboot@ttyAMA0.service
    rm -f /etc/systemd/system/getty.target.wants/serial-getty-firstboot@tty1.service
fi

rm /etc/NetworkManager/system-connections/*

rm -rf /host

echo "All done! Shutting down now..."

shutdown -h now