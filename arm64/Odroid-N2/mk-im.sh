#!/bin/bash
#
# Create complete disk image
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../mk-im.sh"

#
# Install extlinux.conf
#
guestfish -a "$board_img_dir/sdcard.img" -- \
    run : \
    mount /dev/sda1 / : \
    mkdir /extlinux : \
    write /extlinux/extlinux.conf "
menu title Debian Boot Options
timeout 100
default l0

label l0
        menu label Linux
        kernel /vmlinuz
        append initrd=/initrd.img earlyprintk rw rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 root=LABEL=root

label l0-recovery
        menu label Linux (recovery mode)
        kernel /vmlinuz
        append initrd=/initrd.img earlyprintk rw rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 root=LABEL=root single

label o0
        menu label Linux (previous)
        kernel /vmlinuz.old
        append initrd=/initrd.img.old earlyprintk rw rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 root=LABEL=root

label o0-recovery
        menu label Linux (previous, recovery mode)
        kernel /vmlinuz.old
        append initrd=/initrd.img.old earlyprintk rw rhgb rootwait rootfstype=ext4 LANG=en_US.UTF-8 root=LABEL=root single
" : \
   mkdir /boot : \
   write etc/systemd/system/boot.mount "
[Unit]
Description=Mount /boot partition
ConditionPathExists=/dev/disk/by-label/boot
Before=local-fs.target

[Mount]
What=LABEL=boot
Where=/boot
Type=ext4
Options=rw
"

chroot "${ROOT}" systemctl enable boot.mount

#
# Flash U-Boot to SD card
#
# See https://docs.u-boot.org/en/latest/board/amlogic/odroid-n2.html
#
dd "if=$board_out_dir/u-boot.bin.sd.bin" "of=$board_img_dir/sdcard.img" conv=fsync,notrunc bs=512 skip=1 seek=1
dd "if=$board_out_dir/u-boot.bin.sd.bin" "of=$board_img_dir/sdcard.img" conv=fsync,notrunc bs=1 count=440


