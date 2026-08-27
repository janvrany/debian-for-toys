#!/bin/bash
#
# Create complete disk image
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../mk-im.sh"

#
# Resize the root partition. Why the hell this is needed?
#
guestfish -a $board_img_dir/hdd.img -- run : resize2fs /dev/sda2

#
# Install GRUB
#
$(dirname $0)/grub2.sh $board_img_dir/hdd.img
