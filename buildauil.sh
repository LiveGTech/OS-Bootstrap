#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

if [ -e host/$PLATFORM/cache/Adapt-UI-Linux ]; then
    echo "Adapt UI Linux theme already exists; skipping build process..."

    exit
fi

if [ "$AUIL_PROVIDED_PATH" != "" ]; then
    echo "Adapt UI Linux theme folder provided: $AUIL_PROVIDED_PATH"
else
    mkdir -p build/auil

    pushd build/auil
        git clone https://github.com/LiveGTech/Adapt-UI-Linux.git
    popd

    export AUIL_PROVIDED_PATH="build/auil"
fi

mkdir -p host/$PLATFORM/cache
cp -r $AUIL_PROVIDED_PATH/* host/$PLATFORM/cache