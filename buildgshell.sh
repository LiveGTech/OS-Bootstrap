#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

function copyAppImage {
    mkdir -p cache/$2
    cp $GSHELL_PROVIDED_DIST/$1 cache/$2/gshell.AppImage
}

if [ -e cache/$PLATFORM/gshell.AppImage ]; then
    echo "gShell already exists; skipping build process..."

    exit
fi

if [ "$GSHELL_PROVIDED_DIST" != "" ]; then
    echo "gShell dist folder provided: $GSHELL_PROVIDED_DIST"
else
    mkdir -p build/gshell

    pushd build/gshell
        git clone https://github.com/LiveGTech/gShell.git
    popd

    pushd build/gshell/gShell
        npm install
        npm run dist
    popd

    export GSHELL_PROVIDED_DIST="build/gshell/gShell/dist"
fi

copyAppImage gShell-$GSHELL_VERSION.AppImage x86_64
copyAppImage gShell-$GSHELL_VERSION-arm64.AppImage arm64
copyAppImage gShell-$GSHELL_VERSION-armv7l.AppImage rpi
copyAppImage gShell-$GSHELL_VERSION-arm64.AppImage pinephone