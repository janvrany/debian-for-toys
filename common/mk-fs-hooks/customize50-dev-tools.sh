#!/bin/bash
#
# Install development tools
#

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#

#
# Install development tools
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
	build-essential \
	git cvs mercurial \
	autoconf file cmake ninja-build pkg-config ccache \
	flex bison texinfo gawk mawk \
	gdb tmux

#
# Install -dev packages
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
	libglib2.0-dev \
	python3-dev libexpat1-dev libncurses-dev libncurses5-dev libncursesw5-dev \
	libdwarf-dev libelf-dev \
	libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev \
	libasound2-dev libcups2-dev libfontconfig1-dev

# Download and install riscv.h and riscv-opc.h - these are really needed only for
# RISC-V development, but won't hurt having them.
sudo wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
sudo wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
