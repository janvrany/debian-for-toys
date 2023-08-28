CONFIG_IMAGE_KERNEL_IMAGE="$(dirname $(realpath ${BASH_SOURCE[0]}))/../build/linux/arch/riscv/boot/Image.gz"
CONFIG_IMAGE_DTB="$(dirname $(realpath ${BASH_SOURCE[0]}))/../build/linux/arch/riscv/boot/dts/starfive/jh7110-starfive-visionfive-2-v1.3b.dtb"

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../config.sh"