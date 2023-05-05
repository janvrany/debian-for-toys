#/bin/bash

set -e

. $(dirname $0)/../../3rdparty/toolbox/functions.sh

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <FILESYSTEM_IMAGE>"
    exit 1
fi

FILESYSTEM_IMAGE=$1

if [ ! \( -b "$FILESYSTEM_IMAGE" -o -f "$FILESYSTEM_IMAGE" \) ]; then
    echo "E: Invalid FILESYSTEM_IMAGE (not a block device or file): $FILESYSTEM_IMAGE"
    exit 1
fi

U_BOOT_SPL=$(dirname $0)/build/u-boot/spl/u-boot-spl.bin
U_BOOT_PROPER=$(dirname $0)/build/u-boot/u-boot.itb

if [ ! -f "$U_BOOT_SPL" ]; then
    echo "E: Invalid U_BOOT_SPL (no such file): $U_BOOT_SPL"
    echo
    echo "I: Did you forgot to run 'mk-ub.mk' script?"
    exit 2
fi
if [ ! -f "$U_BOOT_PROPER" ]; then
    echo "E: Invalid U_BOOT_PROPER (no such file): $U_BOOT_PROPER"
    echo
    echo "I: Did you forgot to run 'mk-ub.mk' script?"
    exit 2
fi

if [ -z "$QEMU" ]; then
    QEMU=qemu-system-riscv64
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

${QEMU} \
    -machine sifive_u,msel=11 -smp 5 -m 8G \
    -display none -serial stdio \
    -bios "$U_BOOT_SPL" \
    -drive file=${FILESYSTEM_IMAGE},if=sd,format=raw