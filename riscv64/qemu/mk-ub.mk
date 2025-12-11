#!/usr/bin/make  -f

UBOOT_DEFCONFIG=qemu-riscv64_spl_defconfig

sinclude ../mk-ub.mk

# See https://lore.kernel.org/all/20230112001835.GS3787616@bill-the-cat/T/
# but it seems that it does not help.

$(UBOOT_CONFIG)::
	echo "CONFIG_BOOTMETH_VBE=n" >> $@
