#/bin/bash

set -e

. $(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <FILESYSTEM_IMAGE>"
    exit 1
fi

FILESYSTEM_IMAGE=$1

if [ ! \( -b "$FILESYSTEM_IMAGE" -o -f "$FILESYSTEM_IMAGE" \) ]; then
    echo "E: Invalid FILESYSTEM_IMAGE (not a block device or file): $FILESYSTEM_IMAGE"
    exit 1
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

if /bin/false; then

${QEMU} -nographic -nodefaults \
    -cpu 970 \
    -monitor pty -serial stdio \
    -prom-env "input-device=/vdevice/vty@71000000" \
    -prom-env "output-device=/vdevice/vty@71000000" \
    -prom-env 'boot-device=/vdevice/v-scsi@71000002/disk:1,\\grub' \
    -prom-env "boot-file=grub" \
    -hda ${FILESYSTEM_IMAGE}

else

${QEMU} -nographic -nodefaults \
    -cpu 970 \
    -L pc_bios -boot d -M mac99,via=pmu \
    -monitor pty -serial stdio \
    -prom-env "input-device=/vdevice/vty@71000000" \
    -prom-env "output-device=/vdevice/vty@71000000" \
    -prom-env 'boot-device=disk:0,\\grub' \
    -prom-env "boot-file=grub" \
    -device ahci,id=ahci -device ide-hd,drive=drive0,bus=ahci.0 -drive if=none,id=drive0,cache=none,aio=native,file=${FILESYSTEM_IMAGE}
    #-hda ${FILESYSTEM_IMAGE}



fi