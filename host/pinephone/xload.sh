#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

xset s 0

# TODO: Enable GPU acceleration (`./gshell.AppImage -- --real`) after fixing text rendering by compiling on PinePhone hardware itself
# This is because the FreeType library doesn't seem to link correctly when built on non-ARM64 hardware

cd /system/bin
./gshell.AppImage --appimage-extract-and-run -- --disable-gpu --real &> /system/logs/gshell.log