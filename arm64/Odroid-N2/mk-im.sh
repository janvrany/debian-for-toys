#!/bin/bash
#
# Create complete disk image
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../mk-im.sh"

#
# Flash U-Boot to SD card
#
# See https://docs.u-boot.org/en/latest/board/amlogic/odroid-n2.html
#
dd "if=$board_out_dir/u-boot.bin.sd.bin" "of=$board_img_dir/sdcard.img" conv=fsync,notrunc bs=512 skip=1 seek=1
dd "if=$board_out_dir/u-boot.bin.sd.bin" "of=$board_img_dir/sdcard.img" conv=fsync,notrunc bs=1 count=440


