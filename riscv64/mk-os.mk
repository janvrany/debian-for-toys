#!/usr/bin/make  -f

KERNEL_ARCH=riscv
KERNEL_CROSS_COMPILE =/opt/riscv/bin/riscv64-unknown-linux-gnu-

KERNEL_IMAGE=$(KERNEL_OUT_DIR)/arch/$(KERNEL_ARCH)/boot/Image

sinclude ../../common/mk-os.mk

OPENSBI_PLATFORM=generic
OPENSBI_SRC_DIR=../opensbi
OPENSBI_OUT_DIR=$(OPENSBI_SRC_DIR)/build/platform/$(OPENSBI_PLATFORM)/firmware

# Following is for QEMU
all::  $(OPENSBI_OUT_DIR)/fw_jump.bin

$(OPENSBI_OUT_DIR)/fw_jump.bin:
	$(MAKE) -C $(OPENSBI_SRC_DIR) \
		CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) \
		PLATFORM=$(OPENSBI_PLATFORM)


# Following is for FU540 (Unleashed)
all::  $(OPENSBI_OUT_DIR)/fw_payload.bin

$(OPENSBI_OUT_DIR)/fw_payload.bin: $(KERNEL_IMAGE) $(KERNEL_SOURCE)/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb
	$(MAKE) -C $(OPENSBI_SRC_DIR) \
		CROSS_COMPILE=$(KERNEL_CROSS_COMPILE)  \
		PLATFORM=$(OPENSBI_PLATFORM) \
		FW_PAYLOAD_FDT_PATH=$(shell realpath $(KERNEL_SOURCE)/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb) \
		FW_PAYLOAD_PATH=$(shell realpath $(KERNEL_IMAGE))

$(KERNEL_SOURCE)/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb:  $(KERNEL_IMAGE)
	$(MAKE) -C $(KERNEL_SRC_DIR) O=$(KERNEL_OUT_DIR) ARCH=$(KERNEL_ARCH) \
		CROSS_COMPILE=$(KERNEL_CROSS_COMPILE) $(KERNEL_IMAGE_TARGET) dtbs


