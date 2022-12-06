#!/bin/bash

# LiveG OS Bootstrap Toolchain
# 
# Copyright (C) LiveG. All Rights Reserved.
# 
# https://liveg.tech/os
# Licensed by the LiveG Open-Source Licence, which can be found at LICENCE.md.

# This code injects keystrokes into the QEMU VM to launch setup with preseed
# file without user input. It's called by `boot.sh`.

function monitorexec {
    echo "Sending key: $1"
    echo $1 | nc -N 127.0.0.1 8001
}

function typein {
    for (( i = 0; i < ${#1}; i++ )); do
        char=${1:$i:1}

        case $char in
            " ")
                monitorexec "sendkey spc"
                ;;

            "=")
                monitorexec "sendkey equal"
                ;;

            ":")
                monitorexec "sendkey shift-semicolon"
                ;;

            "/")
                monitorexec "sendkey slash"
                ;;

            ".")
                monitorexec "sendkey dot"
                ;;

            *)
                monitorexec "sendkey $char"
                ;;
        esac
    done
}

if [ $PLATFORM = "pinephone" ]; then
    # TODO: Load preseed config
else
    sleep 4
    monitorexec "sendkey esc"
    sleep 1
    typein "auto url=http://10.0.2.2:8000/preseed.cfg"
    sleep 1
    monitorexec "sendkey ret"
fi