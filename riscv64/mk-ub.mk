#!/usr/bin/make  -f

ifndef UBOOT_DEFCONFIG
	$(error "UBOOT_DEFCONFIG not defined, please define in 'arch/board/mk-ub.mk')
endif


UBOOT_ARCH=riscv
UBOOT_CROSS_COMPILE=/opt/riscv/bin/riscv64-unknown-linux-gnu-
UBOOT_OUT_DIR ?= $(shell realpath .)/build/u-boot

OPENSBI_PLATFORM=generic
OPENSBI_SRC_DIR=../../3rdparty/opensbi
OPENSBI_OUT_DIR=$(shell realpath .)/build/opensbi

all:: $(UBOOT_OUT_DIR)/fw_dynamic.bin

$(UBOOT_OUT_DIR)/fw_dynamic.bin: $(OPENSBI_OUT_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_dynamic.bin | $(UBOOT_OUT_DIR)
	cp $< $@

$(OPENSBI_OUT_DIR):
	mkdir -p $(OPENSBI_OUT_DIR)

$(OPENSBI_OUT_DIR)/platform/$(OPENSBI_PLATFORM)/firmware/fw_dynamic.bin: | $(OPENSBI_OUT_DIR)
	$(MAKE) -C $(OPENSBI_SRC_DIR) \
		O=$(OPENSBI_OUT_DIR) \
		CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) \
		PLATFORM=$(OPENSBI_PLATFORM)

sinclude ../../common/mk-ub.mk
