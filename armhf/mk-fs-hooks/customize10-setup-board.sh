#!/bin/bash
#
# Common configuration for AArch64 boards / images
#

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Install support for NFS client
#
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    nfs-common nfs4-acl-tools

#
# Install initramfs hooks to allow mounting (root) using
# NFS v4. See [1]
#
# [1]: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=409272
#
install -m 755 \
        -d "$ROOT/etc/initramfs-tools/hooks"
echo "#!/bin/sh
test "xprereqs" = "x\$1" && exit
. /usr/share/initramfs-tools/hook-functions
echo \"Deleting of nfsmount (\${DESTDIR}/usr/bin/nfsmount) so that copy_exec will
overwrite\"
rm -f \${DESTDIR}/usr/bin/nfsmount
copy_exec /sbin/mount.nfs /usr/bin/nfsmount
" | sudo tee "${ROOT}/etc/initramfs-tools/hooks/50-nfsv4-support.sh"
sudo chmod 0744 ${ROOT}/etc/initramfs-tools/hooks/50-nfsv4-support.sh

#
# Install Linux kernel 
#
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    linux-image-armmp zstd

#
# Define mounts
#

echo "
[Unit]
Description=Mount /tmp
Before=local-fs.target

[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
" | sudo tee "$ROOT/etc/systemd/system/tmp.mount"
chroot "${ROOT}" systemctl enable tmp.mount

#
# Configure kernel installation script to put
# symlinks (vmlinuz and initrd.img) to /boot directory.
# This way, the extlinux.conf may refer to those linke
# whatever kernel version they point to so if kernel gets
# upgraded, the system will still boot and using newest
# kernel.
echo "
do_symlinks = yes
do_bootloader = no
do_initrd = yes
link_in_boot = yes
" | sudo tee "$ROOT/etc/kernel-img.conf"
