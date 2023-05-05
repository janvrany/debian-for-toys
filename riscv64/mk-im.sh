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

#
# Config variables
#
: ${CONFIG_IMAGE_SIZE:=4G}
: ${CONFIG_IMAGE_ROOTDEV:=/dev/vda4}
: ${CONFIG_IMAGE_KERNEL_IMAGE:="$kernel_out_dir/arch/riscv/boot/Image.gz"}
: ${CONFIG_IMAGE_DTB:=}

#
# Helper function
#

function process_in_file {
	local in=$1
	local out=$2
	sed \
		-e "s#@CONFIG_IMAGE_SIZE@#$CONFIG_IMAGE_SIZE#g" \
		-e "s#@CONFIG_IMAGE_KERNEL_VER@#$CONFIG_IMAGE_KERNEL_VER#g" \
		-e "s#@CONFIG_IMAGE_KERNEL_VER@#$CONFIG_IMAGE_KERNEL_VER#g" \
		-e "s#@CONFIG_IMAGE_KERNEL_IMAGE@#$CONFIG_IMAGE_KERNEL_IMAGE#g" \
		-e "s#@CONFIG_IMAGE_DTB@#$CONFIG_IMAGE_DTB#g" \
		"$in" > "$out"
}

#
# Create / compile U-Boot, Linux kernel and root filesystem
#
make -f "$here_dir/mk-ub.mk" -j $(nproc)

make -f "$here_dir/mk-os.mk" -j $(nproc) "KERNEL_OUT_DIR=$kernel_out_dir" "KERNEL_IMAGE=$CONFIG_IMAGE_KERNEL_IMAGE"
CONFIG_IMAGE_KERNEL_VER="$(cat $kernel_out_dir/include/config/kernel.release)-$(git -C $kernel_src_dir rev-parse --short HEAD)"

if [ ! -e "$arch_out_dir/root/etc/passwd" ]; then
	mkdir -p "$arch_out_dir/root"
	"$here_dir/mk-fs.sh" "$arch_out_dir/root"
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
	--rootpath "$arch_out_dir/root" \
	--mkdosfs /sbin/mkdosfs
sudo chown $USER:$(id -g) $board_img_dir/*.*
