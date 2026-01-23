#!/usr/bin/make  -f

UBOOT_DEFCONFIG=qemu_arm_defconfig

sinclude ../mk-ub.mk

$(UBOOT_CONFIG)::
	echo 'CONFIG_BOOTCOMMAND="load virtio 0:1 $${kernel_addr_r} efi/debian/grubram.efi; bootefi $${kernel_addr_r}"' >> $@

