#!/bin/bash

set -ex

.      "$(dirname $0)/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh"
config "$(dirname $0)/config-local.sh"

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

U_BOOT_SPL=$(dirname $0)/build/u-boot/spl/u-boot-spl
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

#
# Following should work [1] but it does not with
# recent U-Boot [1]
#
# [1]: https://www.qemu.org/docs/master/system/riscv/virt.html
# [2]: https://lore.kernel.org/all/20230112001835.GS3787616@bill-the-cat/T/
#
if [ "y" == "x" ]; then
${QEMU} -nographic \
    -machine virt \
    -m 8G \
    -smp cpus=4 \
    -bios "$U_BOOT_SPL" \
    -device loader,file=$U_BOOT_PROPER,addr=0x80200000 \
    -drive file=${FILESYSTEM_IMAGE},format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::7000-:7000 -device virtio-net-device,netdev=net0
else
KERNEL_IMAGE=$(dirname $0)/../build/linux/arch/riscv/boot/Image
#KERNEL_CMDLINE="earlyprintk rw root=/dev/vda4 rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 net.ifnames=1"
KERNEL_CMDLINE="earlyprintk rw root=/dev/vda4 rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 net.ifnames=1"
OPENSBI=$(dirname $0)/build/opensbi/platform/generic/firmware/fw_jump.bin

typeset qemu_img_fmt=$(qemu-img info $1 | grep 'file format' | cut -d ' '  -f 3)

${QEMU} \
    -machine virt \
    -m 8G \
    -smp cpus=4 \
    -display none -serial stdio \
    -bios "$OPENSBI" \
    -kernel "$KERNEL_IMAGE" \
    -append "$KERNEL_CMDLINE" \
    -drive file=${FILESYSTEM_IMAGE},if=virtio \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::7000-:7000 -device virtio-net-device,netdev=net0
fi
