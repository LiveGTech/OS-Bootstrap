#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

resizeFilesystem() {
    storageSize=$(cat "/sys/block/mmcblk0/size")
    currentEnd=$(sudo parted -m /dev/mmcblk0p2 unit s print | tr -d "s" | grep -e "^1:" | cut -d ":" -f 3)
    targetEnd=$((storageSize - 1))

    if [ $currentEnd == $targetEnd ]; then
        echo "Filesystem already at target size"

        return
    fi

    echo "Resizing filesystem..."

    if ! sudo parted -m /dev/mmcblk0 u s resizepart 2 $targetEnd; then
        echo "Failed to resize filesystem"
    fi

    sudo resize2fs /dev/mmcblk0p2 > /dev/null 2>&1
}

clear
echo "LiveG OS Stage 2 has started"

rm /system/stage2

# Run Stage 2 payload

resizeFilesystem

# Exit Stage 2

echo "Stage 2 completed"