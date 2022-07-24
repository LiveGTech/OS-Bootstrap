#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

mkdir -p build
qemu-img create build/system.img 1G

./bootkeys.sh &

qemu-system-x86_64 \
    -m 1G \
    -cdrom cache/base.iso \
    -hda build/system.img \
    -netdev user,id=net0,hostfwd=tcp::8002-:8000 \
    -device virtio-net-pci,netdev=net0 \
    -monitor tcp:127.0.0.1:8001,server,nowait