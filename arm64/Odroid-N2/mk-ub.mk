#!/usr/bin/make  -f

UBOOT_DEFCONFIG=odroid-n2_defconfig

sinclude ../mk-ub.mk

# Sign U-Boot, see
#
# https://docs.u-boot.org/en/latest/board/amlogic/odroid-n2.html#u-boot-manual-signing

UBOOT_BIN=$(UBOOT_OUT_DIR)/u-boot.bin
UBOOT_BIN_ODROID_N2=$(shell realpath .)/build/u-boot.bin.sd.bin

all:: $(UBOOT_BIN_ODROID_N2)

$(UBOOT_BIN_ODROID_N2): $(UBOOT_BIN)
	(cd ../../3rdparty/amlogic-boot-fip && ./build-fip.sh odroid-n2 $(shell realpath $(UBOOT_BIN)) $(shell dirname $(UBOOT_BIN_ODROID_N2)))


$(UBOOT_OUT_DIR): u-boot

