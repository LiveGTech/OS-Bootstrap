#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

xset s 0

cd /system/bin
./gshell.AppImage --appimage-extract-and-run -- --real > /system/logs/gshell.log