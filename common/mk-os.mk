#!/usr/bin/make  -f

ifndef KERNEL_ARCH
	$(error "KERNEL_ARCH not defined, please define in 'arch/mk-os.mk')
endif
ifndef KERNEL_CROSS_COMPILE
	$(error "KERNEL_CROSS_COMPILE not defined, please define in 'arch/mk-os.mk')
endif


KERNEL_SRC_DIR ?= $(shell realpath ../../3rdparty/linux)
KERNEL_OUT_DIR ?= $(shell realpath .)/build/linux

KERNEL_IMAGE ?= $(KERNEL_OUT_DIR)/arch/$(KERNEL_ARCH)/boot/Image
KERNEL_IMAGE_TARGET ?= $(shell basename $(KERNEL_IMAGE))

KERNEL_CONFIG=$(KERNEL_OUT_DIR)/.config
KERNEL_CONFIG_DEFAULT ?= defconfig
KERNEL_CONFIG_COMMON ?= $(shell realpath ../../common/config-linux.txt)
KERNEL_CONFIG_ARCH ?= $(shell realpath ../config-linux.txt)
KERNEL_CONFIG_BOARD ?= $(shell realpath config-linux.txt)
KERNEL_CONFIG_LOCAL ?= $(shell realpath config-linux-local.txt)

.PHONY: all

all::  $(KERNEL_IMAGE)

$(KERNEL_OUT_DIR):
	mkdir -p $@

$(KERNEL_CONFIG_LOCAL):
	@echo "# DO NOT COMMIT!" >> $@
	@echo "# Local kernel tunables, there's no need to change anything." >> $@
	@echo "" >> $@
	@echo "# CONFIG_INITRAMFS_SOURCE=\"abs/path/to/rootfs.cpio\"" >> $@
	@echo "#" >> $@
	@echo "# or" >> $@
	@echo "# CONFIG_CMDLINE_BOOL=y" >> $@
	@echo "# CONFIG_CMDLINE=\"root=/dev/nfs rw nfsroot=192.168.1.1:/srv/some/root,vers=3\"" >> $@

$(KERNEL_CONFIG):: $(KERNEL_SRC_DIR) $(KERNEL_CONFIG_COMMON) $(KERNEL_CONFIG_LOCAL) | $(KERNEL_OUT_DIR)
	cp $(KERNEL_CONFIG_COMMON) $@
	if [ -f $(KERNEL_CONFIG_ARCH) ]; then cat $(KERNEL_CONFIG_ARCH) >> $@; fi
	if [ -f $(KERNEL_CONFIG_BOARD) ]; then cat $(KERNEL_CONFIG_BOARD) >> $@; fi
	cat $(KERNEL_CONFIG_LOCAL) >> $@
	cp $@ $@.tmp
	sort $@.tmp | uniq > $@
	rm $@.tmp
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) olddefconfig

ifneq (,$(wildcard $(KERNEL_CONFIG_ARCH)))
$(KERNEL_CONFIG):: $(KERNEL_CONFIG_ARCH)
endif
ifneq (,$(wildcard $(KERNEL_CONFIG_BOARD)))
$(KERNEL_CONFIG):: $(KERNEL_CONFIG_BOARD)
endif


$(KERNEL_IMAGE): $(KERNEL_CONFIG) $(KERNEL_SRC_DIR)/Makefile
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_IMAGE_TARGET) dtbs

.PHONY: menuconfig
menuconfig:
	cp $(KERNEL_CONFIG) $(KERNEL_CONFIG).before-menuconfig
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		menuconfig


