#!/usr/bin/make  -f

.PHONY: all
all::

ifndef UBOOT_ARCH
	$(error "UBOOT_ARCH not defined, please define in 'arch/mk-ub.mk')
endif
ifndef UBOOT_CROSS_COMPILE
	$(error "UBOOT_CROSS_COMPILE not defined, please define in 'arch/mk-ub.mk')
endif
ifndef UBOOT_DEFCONFIG
	$(error "UBOOT_DEFCONFIG not defined, please define in 'arch/board/mk-ub.mk')
endif


UBOOT_SRC_DIR ?= $(shell realpath ../../3rdparty/u-boot)
UBOOT_OUT_DIR ?= $(shell realpath .)/build/u-boot
UBOOT_CONFIG  ?= $(UBOOT_OUT_DIR)/.config

.PHONY: u-boot
all::  u-boot


$(UBOOT_OUT_DIR):
	mkdir -p $@

$(UBOOT_CONFIG): | $(UBOOT_OUT_DIR)
	$(MAKE) -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) \
		CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) \
		$(UBOOT_DEFCONFIG)

u-boot: $(UBOOT_CONFIG)
	$(MAKE) -C $(UBOOT_SRC_DIR) O=$(UBOOT_OUT_DIR) \
 		CROSS_COMPILE=$(UBOOT_CROSS_COMPILE)