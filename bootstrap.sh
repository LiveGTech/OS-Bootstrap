#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

export PLATFORM="x86_64"
export QEMU_ARGS=""

if [[ "$1" != "" ]]; then
    export PLATFORM=$1
fi

case $PLATFORM in
    x86_64)
        export ARCH="x86_64"
        ;;

    *)
        echo "Invalid platform specified" >&2
        exit 1
        ;;
esac

./server.sh
./getbase.sh
./boot.sh
./makeiso.sh