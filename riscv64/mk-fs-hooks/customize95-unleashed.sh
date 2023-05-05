#!/bin/bash

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#


#
# Configure ethernet device
#
echo "
# On HiFive Unleashed one has to set rx/tx ringbuffers
# to maximum size otherwise the connection is flaky
# (high packet loss). Dunno why.
#
# Following set's ring buffer sizes to hardware maximum.
[Match]
Driver=macb

[Link]
RxBufferSize=max
TxBufferSize=max
" | sudo tee "$ROOT/etc/systemd/network/50-unleashed.link"

# On HiFive Unleashed, one of the tty's are denoted as console
# (/dev/console) using console= kernel parameter. Therefore we have
# to disable getty on the original device otherwise 2 gettys would
# be started, pointing to the same device (albeit under different names
# in /dev) and compete over. This would make the console unusable.
#
# Note, that the list below is valid for 5.0 and 5.6 kernels, when upgrading
# to a newer version, more may need to be added.
#
chroot "${ROOT}" systemctl mask serial-getty@.service
chroot "${ROOT}" systemctl mask getty@.service
chroot "${ROOT}" systemctl mask getty-static.service

# And enable the only /dev/console.
chroot "${ROOT}" systemctl unmask console-getty.service
chroot "${ROOT}" systemctl enable console-getty.service

# Download and install riscv.h and riscv-opc.h - these are needed for
# OMR RISC-V port and for Smalltalk/X
sudo wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'
sudo wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=2f973f134d7752cbc662ec65da8ad8bbe4c6fb8f'

# # This is workaround for CMake-based cross compilation for OMR/OpenJ9
# (cd "${ROOT}/usr/lib/riscv64-linux-gnu" && sudo ln -s ../../../lib/riscv64-linux-gnu/libz.so.1 .)
