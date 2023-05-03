#!/usr/bin/make  -f

ifndef KERNEL_ARCH
	$(error "KERNEL_ARCH not defined, please define in 'arch/mk-os.mk')
endif
ifndef KERNEL_CROSS_COMPILE
	$(error "KERNEL_CROSS_COMPILE not defined, please define in 'arch/mk-os.mk')
endif


KERNEL_SRC_DIR ?= $(shell realpath ../../3rdparty/linux)
KERNEL_OUT_DIR ?= $(shell realpath linux)

KERNEL_IMAGE ?= $(KERNEL_OUT_DIR)/arch/$(KERNEL_ARCH)/boot/Image
KERNEL_IMAGE_TARGET ?= $(shell basename $(KERNEL_IMAGE))

KERNEL_CONFIG=$(KERNEL_OUT_DIR)/.config
KERNEL_CONFIG_COMMON=$(shell realpath ../../common/linux-config.txt)
KERNEL_CONFIG_ARCH=$(shell realpath ../linux-config.txt)
KERNEL_CONFIG_BOARD=$(shell realpath linux-config.txt)

.PHONY: all

all::  $(KERNEL_IMAGE)

$(KERNEL_OUT_DIR):
	mkdir -p $@

$(KERNEL_CONFIG): $(KERNEL_SRC_DIR) | $(KERNEL_OUT_DIR)
	cp $(KERNEL_CONFIG_COMMON) $@
	cat $(KERNEL_CONFIG_ARCH) >> $@
	if [ -f $(KERNEL_CONFIG_BOARD) ]; then $(KERNEL_CONFIG_BOARD) >> $@; fi
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		olddefconfig

$(KERNEL_IMAGE): $(KERNEL_CONFIG) $(KERNEL_SRC_DIR)/Makefile
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_IMAGE_TARGET)

.PHONY: menuconfig
menuconfig:
	cp $(KERNEL_CONFIG) $(KERNEL_CONFIG).before-menuconfig
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		menuconfig

