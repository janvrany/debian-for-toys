#!/bin/bash
#
# Create complete disk image without installing bootloader!
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../mk-im.sh"

$(dirname $0)/grub2.sh $board_img_dir/sdcard.img
