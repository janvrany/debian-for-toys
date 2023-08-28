#!/usr/bin/make  -f

KERNEL_IMAGE=$(KERNEL_OUT_DIR)/arch/riscv/boot/Image.gz
KERNEL_IMAGE_TARGET=Image.gz

include ../mk-os.mk