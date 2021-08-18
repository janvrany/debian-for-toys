#/bin/bash

set -e

. $(dirname $0)/../../common/functions.sh

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <FILESYSTEM_IMAGE>"
    exit 1
fi

FILESYSTEM_IMAGE=$1

if [ ! \( -b "$FILESYSTEM_IMAGE" -o -f "$FILESYSTEM_IMAGE" \) ]; then
    echo "E: Invalid FILESYSTEM_IMAGE (not a block device or file): $FILESYSTEM_IMAGE"
    exit 1
fi

KERNEL_ARCH=powerpc
KERNEL_IMAGE=$(realpath $(dirname $0))/linux/arch/$KERNEL_ARCH/boot/zImage.pseries

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "E: Invalid KERNEL_IMAGE (no such file): $KERNEL_IMAGE"
    echo
    echo "I: Did you forgot to run 'mk-os.mk' script?"
    exit 2
fi

if [ -z "$QEMU" ]; then
    QEMU=qemu-system-ppc64
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
#if ! confirm "Continue"; then
#    exit 0
#fi

${QEMU} -nographic -nodefaults \
    -machine pseries -cpu power10 \
    -m 2G \
    -kernel "$KERNEL_IMAGE" -append "root=/dev/vda rw" \
    -monitor pty -serial stdio \
    -prom-env "input-device=/vdevice/vty@71000000" \
    -prom-env "output-device=/vdevice/vty@71000000" \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::7000-:7000 -device virtio-net-pci,netdev=net0 \
    -drive file=${FILESYSTEM_IMAGE},if=none,format=raw,id=hd0 -device virtio-blk-pci,drive=hd0