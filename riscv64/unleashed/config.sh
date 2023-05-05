CONFIG_IMAGE_KERNEL_IMAGE="$(dirname $(realpath ${BASH_SOURCE[0]}))/../build/linux/arch/riscv/boot/Image"
CONFIG_IMAGE_DTB="$(dirname $(realpath ${BASH_SOURCE[0]}))/../build/linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb"

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../config.sh"