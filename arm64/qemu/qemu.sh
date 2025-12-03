#!/bin/bash

set -e

#
# Run using QEMU
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh"
config "$(dirname $0)/config-local.sh"

#
# Config variables
#
# None

#
#
#
if [ -z "$1" ]; then
    echo "usage: $(basename $0) <FILESYSTEM_IMAGE>"
    exit 1
fi

FILESYSTEM_IMAGE=$1

if [ ! \( -b "$FILESYSTEM_IMAGE" -o -f "$FILESYSTEM_IMAGE" \) ]; then
    echo "E: Invalid FILESYSTEM_IMAGE (not a block device or file): $FILESYSTEM_IMAGE"
    exit 1
fi

U_BOOT_BIN=$(dirname $0)/build/u-boot/u-boot.bin


if [ ! -f "$U_BOOT_BIN" ]; then
    echo "E: Invalid U_BOOT_BIN (no such file): $U_BOOT_BIN"
    echo
    echo "I: Did you forgot to run 'mk-ub.mk' script?"
    exit 2
fi

if [ -z "$QEMU" ]; then
    QEMU=qemu-system-aarch64
fi

echo "To (SSH) connect to running Debian, do"
echo
echo "    ssh localhost -p 5555"
echo
echo "Local port 7000 is forwarded to running Debian, port 7000,"
echo "you may use this for example for remote debugging using"
echo "gdbserver:"
echo
echo "    (gdb) target remote localhost:7000"
echo
if ! confirm "Continue"; then
    exit 0
fi


${QEMU} -nographic \
    -machine virt \
    -cpu cortex-a57 \
    -m 8G \
    -smp cpus=4 \
    -bios "$U_BOOT_BIN" \
    -drive file=${FILESYSTEM_IMAGE},format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::7000-:7000 -device virtio-net-device,netdev=net0
