#!/bin/bash

set -ex

env

ROOT="$1"
ARCH=$(chroot "${ROOT}" dpkg --print-architecture)
RELEASE=$(chroot "${ROOT}" lsb_release -c | cut -f 2)


# For some weird reason, ethernet device is still
# using old scheme and it is named eth0 rather than
# enp0s0.
#
# So to make networking work out of the box, we have
# to remove config for enp0s0 (created by customize90-rest.sh)
# and add new one for eth0.
#
# Also, on Sifive FU540 (Unleashed) one has to set rx/tx
# ringbuffers to maximum size otherwise the connection os
# flaky. Dunno why.
#
# Double sigh!
rm ${ROOT}/etc/network/interfaces.d/enp0s0
cat >${ROOT}/etc/network/interfaces.d/eth0 <<EOF
auto eth0
iface eth0 inet dhcp
  # On Sifive FU540 (Unleashed) one has to set rx/tx
  # ringbuffers to maximum size otherwise the connection os
  # flaky. Dunno why.
  up sleep 5; ethtool -G eth0 rx 8192 2>/dev/null; ethtool -G eth0 tx 4096 2>/dev/null; true
EOF

mkdir -p ${ROOT}/etc/systemd/system/systemd-networkd-wait-online.service.d
cat >${ROOT}/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf <<EOF
# Mysteriously, this service fails on QEMU. It does not seem to affect
# the system anyhow, but 'systemctl status' reports "degraded" state which may
# cause some concerns when one checks it (well, I'd start searching why's that
# only to waste time). So following effectively disables the service making
# 'systemctl status' happy.
#
[Service]
ExecStart=
ExecStart=/bin/true
EOF

# HiFive Unleashed, one of the tty's are denoted as console
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
wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=HEAD'
wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=HEAD'

# This is workaround for CMake-based cross compilation for OMR/OpenJ9
(cd "${ROOT}/usr/lib/riscv64-linux-gnu" && sudo ln -s ../../../lib/riscv64-linux-gnu/libz.so.1 .)
