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
	flex bison gawk mawk \
	gdb tmux

#
# Install -dev packages
#
#
# Packages required to build (selected) projects
#
PACKAGES_GDB="  python3-dev,
                libexpat1-dev,
                libncurses-dev,
                libncurses5-dev,
                libncursesw5-dev,
                libdebuginfod-dev,
                libgmp-dev,
                libmpfr-dev,
                liblzma-dev,
                libreadline-dev,
                guile-3.0-dev,
                texinfo
            "
PACKAGES_GDB_TEST="
                dejagnu,
                python3-unidiff,
                python3-termcolor,
                gfortran,
                gnat,
                rustc,
                libc6-dbg
            "

#
# See https://jan.vrany.io/stx/wiki/Documentation/BuildingStXWithRakefiles#Debianonx86_64andotherderivativessuchasUbuntuorMint
#
PACKAGES_STX="  pkg-config
                libc6-dev
                libx11-dev
                libxext-dev
                libxinerama-dev
                unixodbc-dev
                libgl1-mesa-dev
                libfl-dev
                libxft-dev
                libbz2-dev
                zlib1g
                zlib1g-dev
                libxfixes-dev
            "

PACKAGES_OMR="  zlib1g
                zlib1g-dev
                libglib2.0-dev
                libdwarf-dev
                libelf-dev
                libx11-dev
                libxext-dev
                libxrender-dev
                libxrandr-dev
                libxtst-dev
                libxt-dev
                libasound2-dev
                libcups2-dev
                libfontconfig1-dev
                file
                "

PACKAGES="      ${PACKAGES_GDB}
                ${PACKAGES_GDB_TEST}
                ${PACKAGES_STX}
                ${PACKAGES_OMR}
                "




chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install $PACKAGES

# Download and install riscv.h and riscv-opc.h - these are really needed only for
# RISC-V development, but won't hurt having them.
sudo wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
sudo wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
