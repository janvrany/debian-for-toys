#!/bin/bash
#
# Create complete disk image
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh"
config "$(dirname $0)/config-local.sh"

#
# Local variables
#
here_dir=$(realpath $(dirname $0))
board_out_dir=$here_dir/build
arch_out_dir=$here_dir/../build

board_img_dir=$here_dir/images
board_img=$board_img_dir/hdd.img

kernel_src_dir=$here_dir/../../3rdparty/linux
kernel_out_dir=$arch_out_dir/linux
rootfs_out_dir=$board_out_dir/root
rootfs_uuid=5b361504-be60-4dd5-bc24-e523f7038e33

#
# Config variables
#
: ${CONFIG_IMAGE_SIZE:=4G}
: ${CONFIG_NFS_ROOT:=:}

#
# Helper function
#
function process_in_file {
	local in=$1
	local out=$2
	sed \
		-e "s#@CONFIG_IMAGE_SIZE@#$CONFIG_IMAGE_SIZE#g" \
		-e "s#@CONFIG_NFS_ROOT@#$CONFIG_NFS_ROOT#g" \
		"$in" > "$out"
}

#
# Create build directories
#
mkdir -p "$board_out_dir"
mkdir -p "$arch_out_dir"

#
# Create root filesystem (if needed)
#
if [ ! -e "$rootfs_out_dir/etc/passwd" ]; then
	mkdir -p "$rootfs_out_dir"
	"$here_dir/mk-fs.sh" "$rootfs_out_dir"
fi

#
# Create GRUB image
#
# See masterzorag/G5_ppc64-linux
#
echo "
configfile /boot/grub/grub.cfg
" | sudo tee "$rootfs_out_dir/tmp/grub.cfg"
#sudo chroot "${rootfs_out_dir}" grub-mkimage -c /tmp/grub.cfg -o /tmp/grub.bin -O powerpc-ieee1275 -C xz -p /usr/lib/grub/powerpc-ieee1275/*.mod
sudo chroot "${rootfs_out_dir}" grub-mkimage -C xz '--prefix=(ieee1275/ide0:1)/boot/grub' --format=powerpc-ieee1275 --config=/tmp/grub.cfg --output=/tmp/grub.bin \
	search_fs_uuid.mod \
	search_fs_file.mod \
	search_label.mod \
	search.mod \
	part_apple.mod \
	part_msdos.mod \
	part_gpt.mod \
	ext2.mod \
	hfs.mod \
	fat.mod \
	fshelp.mod \
	normal.mod \
	halt.mod reboot.mod echo.mod

sudo rm -f "${rootfs_out_dir}/tmp/grub.cfg"
sudo mv    "${rootfs_out_dir}/tmp/grub.bin" "${board_out_dir}/grub"

#
# Create boot partition with GRUB image
#
truncate -s 16M "$board_out_dir/boot.hfs"
#/sbin/mkfs.hfs -v "MAC_BOOT" "$board_out_dir/boot.hfs"
hformat -l "MAC_BOOT" "$board_out_dir/boot.hfs"

hmount "$board_out_dir/boot.hfs"

hcopy "$board_out_dir/grub" :grub
hattrib -t tbxi :grub
hattrib -b :
hdir :
humount "$board_out_dir/boot.hfs"

#
# Create grub.cfg
#
sudo arch-chroot $rootfs_out_dir update-grub2
sudo sed \
	-e 's#root=/dev/.* ro #root=/dev/hda2 ro #g' \
	-e 's#set root=.*$#set root=(ieee1275/ide0:1)#g' \
	-e 's#quiet##g' \
	-i "$rootfs_out_dir/boot/grub/grub.cfg"

#
# Generate the image!
#
if /bin/true; then
truncate -s $CONFIG_IMAGE_SIZE $board_img
if /bin/true; then
/sbin/parted -s $board_img mklabel msdos
#/sbin/parted -s $board_img mkpart "primary fat32 512b 1024kB"
/sbin/parted -s $board_img mkpart "primary hfs 2048s 30719s"
/sbin/parted -s $board_img set "1 boot on"
/sbin/parted -s $board_img mkpart "primary ext4 30720s -1"
else
/sbin/parted -s $board_img mklabel mac
/sbin/parted -s $board_img mkpart "'' 1049kB 16.8MB"
/sbin/parted -s $board_img set "2 boot on"
/sbin/parted -s $board_img mkpart "root 32MB -1"
/sbin/parted -s $board_img set "3 root on"
fi
/sbin/parted -s $board_img print

sudo echo "Dry-running sudo to avoid subsequent authentication"

board_img_dev=$(/usr/bin/sudo losetup --find --show $board_img)
trap "/usr/bin/sudo losetup -d $board_img_dev" EXIT
sudo kpartx -a "$board_img_dev"
ls /dev/mapper/loop*

board_img_part_boot="/dev/mapper/${board_img_dev##*/}p1"
board_img_part_root="/dev/mapper/${board_img_dev##*/}p2"


sudo hformat -l "MAC_BOOT" "$board_img_part_boot"
sudo hmount "$board_img_part_boot"
trap "sudo humount $board_img_part_boot" EXIT
sudo hcopy "$board_out_dir/grub" :grub
sudo hattrib -t tbxi :grub
sudo hattrib -b :
sudo hdir :
sudo humount $board_img_part_boot


sudo /sbin/mkfs.ext4 -U "$rootfs_uuid" "$board_img_part_root"
rootfs_mnt_dir=$(mktemp -d)
sudo mount "$board_img_part_root" "$rootfs_mnt_dir"
trap 'sudo umount $board_img_part_root' EXIT


(cd $rootfs_out_dir && /usr/bin/sudo tar --xattrs --acls -c *) \
	| pv -s "$(/usr/bin/sudo du -s $rootfs_out_dir | cut -f 1)k" \
	| (cd $rootfs_mnt_dir && /usr/bin/sudo tar --xattrs --acls -x)

sudo umount $board_img_part_root

echo $(/usr/bin/sudo blkid $board_img_part_root)

sudo losetup -d $board_img_dev


else
#
# Generate config for genimage
#
process_in_file "$here_dir/config-genimage.cfg.in" "$board_out_dir/config-genimage.cfg"
mkdir -p "$board_img_dir"
sudo rm -rf "$board_out_dir/genimage"
sudo genimage \
	--config "$board_out_dir/config-genimage.cfg" \
	--inputpath "$board_out_dir" \
	--tmppath "$board_out_dir/genimage" \
	--outputpath "$board_img_dir" \
	--rootpath "$rootfs_out_dir" \
	--mkdosfs /sbin/mkdosfs
sudo chown $USER:$(id -g) $board_img_dir/*.*
fi
