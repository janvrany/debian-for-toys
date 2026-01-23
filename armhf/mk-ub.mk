#!/usr/bin/make  -f

ifndef UBOOT_DEFCONFIG
	$(error "UBOOT_DEFCONFIG not defined, please define in 'arch/board/mk-ub.mk')
endif


UBOOT_ARCH?=armhf
UBOOT_CROSS_COMPILE?=arm-linux-gnueabihf-
UBOOT_OUT_DIR ?= $(shell realpath .)/build/u-boot

sinclude ../../common/mk-ub.mk
