#!/usr/bin/make  -f

KERNEL_ARCH=powerpc
KERNEL_CROSS_COMPILE = powerpc64le-linux-gnu-

KERNEL_IMAGE=$(KERNEL_OUT_DIR)/arch/$(KERNEL_ARCH)/boot/zImage

sinclude ../../common/mk-os.mk