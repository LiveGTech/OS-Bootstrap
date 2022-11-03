#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# TODO: Keep a local copy of the Debian base image — old versions get deleted after a while
# TODO: Also ensure that `vmlinuz` version in `grub.cfg` and `isogrub.cfg` is correct with new releases — maybe automate this

mkdir -p cache/$PLATFORM
wget -nc https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.5.0-amd64-netinst.iso -O cache/$PLATFORM/base.iso