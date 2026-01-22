#!/bin/bash
#
# Setup GRUB2 into disk image. Please note that kernel
# should be already installed in the image!
#
# This script currently supports only UEFI on AArch64.
# It should be eventually merged with toolbox's grub2.sh
# and moved there.
#
source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/config-local.sh"

#
# Config variables
#
: ${CONFIG_GRUB_CMDLINE_LINUX_CUSTOM:=}
: ${CONFIG_BUILD_TMP_DIR:="$(dirname $0)/tmp"}
#   CONFIG_CONSOLE_DEV

#
# Options
#
usage() {
	echo "Install GRUB bootloader given the disk image.

Usage: $0 [-h] [-g] IMAGE

  -g ... Use to make image bootable on wide range of hardware and virtual machines.
         Without -g, image is optimized to boot quickly on KVM/QEMU virtual machines.

  -h ... Print this message.
" 1>&2;
}

optimize_for_kvm_vm=yes

while getopts ":gh" o; do
    case "${o}" in
        g)
            optimize_for_kvm_vm=no
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: ${OPTARG}"
            ;;
    esac
done
shift $((OPTIND-1))

#
# Install Linux kernel and GRUB2
#
if [ -z "$1" ]; then
    usage
    exit 1
elif [ -d "$1" ]; then
	error "Invalid root filesystem image (directory): $1"
	usage
	exit 2
fi

tmp="$CONFIG_BUILD_TMP_DIR"
mkdir -p $tmp

ensure_ROOT "$1"

#
# Setup arch-specific variables
#
arch=$(/usr/bin/sudo chroot "${ROOT}" dpkg-architecture -q DEB_TARGET_ARCH)
case "$arch" in
	arm64)
		CROSS=aarch64-linux-gnu-
		QEMU="qemu-system-aarch64 -cpu cortex-a57"
		: ${CONFIG_CONSOLE_DEV:="ttyAMA0"}
		GRUB_TARGET=arm64-efi
		GRUB_EFI_IMAGE=grubaa64.efi
		;;
	armhf)
		CROSS=arm-linux-gnueabihf-
		QEMU="qemu-system-arm"
		: ${CONFIG_CONSOLE_DEV:="ttyAMA0"}
		GRUB_TARGET=arm-efi
		GRUB_EFI_IMAGE=grubarm.efi
		;;
	*)
		error "Unsupported architecture: $arch"
		exit 3
		;;
esac



#
# Install grub-efi packages and
#
sudo chroot "${ROOT}" apt-get --allow-unauthenticated -y install grub-efi
if [ "$optimize_for_kvm_vm" == "yes" ]; then
	sudo chroot "${ROOT}" apt-get --allow-unauthenticated -y install \
		qemu-guest-agent
fi
sudo chroot "${ROOT}" apt-get clean

#
# Configure and regenerate initramfs
#
echo '
#
# Always include virtio_blk, virtio_net and sdhci modules in initramfs
#
virtio_blk
virtio_net
sdhci
' | sudo tee -a "$ROOT/etc/initramfs-tools/modules"

echo '
#
# Include most modules in order to boot on most systems.
#
MODULES=most
' | sudo tee "$ROOT/etc/initramfs-tools/conf.d/modules"
sudo chroot "${ROOT}" update-initramfs -c -k all

if [ "$optimize_for_kvm_vm" == "yes" ]; then
echo '
#
# Only include required modules in initramfs. This significantly
# reduces the size of initramfs and speeds up boot. This is especially
# handy when used as start-on-demand CI build node.
#
MODULES=dep
' | sudo tee "$ROOT/etc/initramfs-tools/conf.d/modules"
fi # if [ "$optimize_for_kvm_vm" == "yes" ]...

#
# Configure GRUB
#
echo '
#
# Disable os prober. There are no other systems.
#
GRUB_DISABLE_OS_PROBER=true
' | sudo tee "$ROOT/etc/default/grub.d/os-prober.cfg"

echo '
#
# Make root filesystem writable. Why the hell is
# this needed?
#
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX rw"
' | sudo tee "$ROOT/etc/default/grub.d/rw.cfg"


if [ ! -z "$CONFIG_GRUB_CMDLINE_LINUX_CUSTOM" ]; then
echo "
#
# Custom linux cmdline options
#
GRUB_CMDLINE_LINUX=\"\$GRUB_CMDLINE_LINUX $CONFIG_GRUB_CMDLINE_LINUX_CUSTOM\"
" | sudo tee "$ROOT/etc/default/grub.d/custom.cfg"
fi

if [ "$optimize_for_kvm_vm" == "yes" ]; then
echo "
#
# Enable serial console in Linux:
#
GRUB_CMDLINE_LINUX=\"\$GRUB_CMDLINE_LINUX console=$CONFIG_CONSOLE_DEV\"

#
# ...and also in GRUB:
#
GRUB_TERMINAL=console
" | sudo tee "$ROOT/etc/default/grub.d/console.cfg"

echo '
#
# Disable predictable network interface names.
# The rationale is that the image will likely run as
# VM or on some board with single NIC anyway and this
# makes it easier to configure network.
#
# See https://www.freedesktop.org/wiki/Software/systemd/PredictableNetworkInterfaceNames/
#
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX net.ifnames=0"
' | sudo tee "$ROOT/etc/default/grub.d/ifnames.cfg"

echo '
#
# Set timeout to 1. This saves us 4 secs when booting, especially
# handy when used as start-on-demand CI build node.
#
GRUB_TIMEOUT=1
' | sudo tee "$ROOT/etc/default/grub.d/timeout.cfg"

fi # if [ "$optimize_for_kvm_vm" == "yes" ]...


#
# Install helper to power off the machine programatically
#
make -C "$(dirname $(realpath ${BASH_SOURCE[0]}))/../3rdparty/toolbox/helpers" \
	CROSS=$CROSS \
	O=$ROOT/tmp

#
# Install GRUB self-installation script to /tmp
#
echo "#!/bin/bash
set -x
# Install GRUB into EFI partition
mkdir -p /efi
mount /dev/disk/by-uuid/????-???? /efi
grub-install --target $GRUB_TARGET --efi-directory /efi
echo \"FS0:\EFI\debian\\$GRUB_EFI_IMAGE\" > /efi/startup.nsh

# Update GRUB and initramfs
update-grub2
update-initramfs -c -k all

# Switch off the VM
/tmp/off
" | sudo tee "$ROOT/tmp/grub-self-install.sh"
sudo chmod ugo+x "$ROOT/tmp/grub-self-install.sh"
sudo rm -rf "${ROOT}/run/systemd"

if [ -L "${ROOT}/vmlinuz" ]; then
	vmlinuz_link=/vmlinuz
elif [ -L "${ROOT}/boot/vmlinuz" ]; then
	vmlinuz_link=/boot/vmlinuz
else
	vmlinuz_link=/vmlinuz
fi

if [ -L "${ROOT}/initrd.img" ]; then
	initrd_link=/initrd.img
elif [ -L "${ROOT}/boot/initrd.img" ]; then
	initrd_link=/boot/initrd.img
else
	initrd_link=/initrd.img
fi

umount_ROOT

sleep 1

root_img_fmt=$(qemu-img info $1 | grep 'file format' | cut -d ' '  -f 3)
root_dev=$(part_ROOT $1)
vmlinuz="$(guestfish -a "$1" -m $root_dev:/ readlink $vmlinuz_link)"
initrd="$(guestfish -a "$1" -m $root_dev:/ readlink $initrd_link)"

guestfish -a "$1" -m $root_dev:/ copy-out $(dirname $vmlinuz_link)/$vmlinuz $tmp
guestfish -a "$1" -m $root_dev:/ copy-out $(dirname $vmlinuz_link)/$initrd $tmp

rm -f $tmp/vmlinuz $tmp/initrd.img
mv $tmp/$(basename $vmlinuz) $tmp/vmlinuz
mv $tmp/$(basename $initrd) $tmp/initrd.img

if [ "$optimize_for_kvm_vm" == "yes" ]; then
	# If the image is intended to boot only on KVM/QEMU, then use virtio
	# block device (which will likely be used). Otherwise, update-initramfs
	# would pull in SATA modules, making initrd larger and this slowing down
	# boot.

	$QEMU \
    	-M virt -m "512M" \
		-kernel "$tmp/vmlinuz" -initrd "$tmp/initrd.img" -append "root=LABEL=root rw init=/tmp/grub-self-install.sh" \
		-nographic \
		-drive if=none,id=disk0,file=$1,format=$root_img_fmt \
  		-device virtio-blk-device,drive=disk0 \
		-netdev user,id=hostnet0 -device virtio-net-pci,netdev=hostnet0
else
	# Otherwise, use SATA. Note that virtio_blk module us always included so
	# this image should boot using virtio block device too,
	$QEMU \
    	-m "512M" \
		-kernel "$tmp/vmlinuz" -initrd "$tmp/initrd.img" -append "root=$root_dev rw init=/tmp/grub-self-install.sh" \
		-drive if=none,id=disk0,cache=none,aio=native,file=$1,format=$root_img_fmt -device ahci,id=ahci -device ide-hd,drive=disk0,bus=ahci.0 \
		-netdev user,id=hostnet0 -device virtio-net-pci,netdev=hostnet0
fi