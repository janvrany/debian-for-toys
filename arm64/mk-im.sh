#!/bin/bash
#
# Create complete disk image
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh"
config "$(dirname $0)/config-local.sh"

#
# Local variables
#
here_dir=$(realpath $(dirname $0))
board_out_dir=$here_dir/build
arch_out_dir=$here_dir/../build

board_img_dir=$here_dir/images

kernel_src_dir=$here_dir/../../3rdparty/linux
kernel_out_dir=$arch_out_dir/linux
rootfs_out_dir=$board_out_dir/root

#
# Config variables
#
: ${CONFIG_IMAGE_SIZE:=8G}

#
# Helper function
#
function process_in_file {
	local in=$1
	local out=$2
	sed \
		-e "s#@CONFIG_IMAGE_SIZE@#$CONFIG_IMAGE_SIZE#g" \
		"$in" > "$out"
}

#
# Create build directories
#
mkdir -p "$board_out_dir"
mkdir -p "$arch_out_dir"

#
# Create / compile U-Boot, Linux kernel and root filesystem
#
make -f "$here_dir/mk-ub.mk" -j $(nproc)

if [ ! -e "$rootfs_out_dir/etc/passwd" ]; then
	mkdir -p "$rootfs_out_dir"
	"$here_dir/mk-fs.sh" "$rootfs_out_dir"
fi

#
# Generate extlinux.conf
#
process_in_file "$here_dir/extlinux.conf.in" "$board_out_dir/extlinux.conf"

#
# Generate config for genimage
#
process_in_file "$here_dir/config-genimage.cfg.in" "$board_out_dir/config-genimage.cfg"

#
# Generate the image!
#
mkdir -p "$board_img_dir"
sudo rm -rf "$board_out_dir/genimage"
sudo genimage \
	--config "$board_out_dir/config-genimage.cfg" \
	--inputpath "$board_out_dir" \
	--tmppath "$board_out_dir/genimage" \
	--outputpath "$board_img_dir" \
	--rootpath "$rootfs_out_dir" \
	--mkdosfs /sbin/mkdosfs
sudo chown $USER:$(id -g) "$board_img_dir/sdcard.img"


