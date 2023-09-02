#!/bin/bash
#
# Common configuration for RISC-V boards / images
#

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#
: ${CONFIG_NFS_HOME:=}

#
# Install support for NFS client
#

sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    nfs-common

#
# Define mounts
#

echo "
[Unit]
Description=Mount /boot (EFI) partition
Before=local-fs.target

[Mount]
What=PARTLABEL=boot
Where=/boot
Type=vfat
Options=ro

" | sudo tee "$ROOT/etc/systemd/system/boot.mount"
chroot "${ROOT}" systemctl enable boot.mount

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

echo "
#
# /boot is mounted using 'boot.mount' unit
#
# To modify, disable or enable the /boot mount, use
#
#     systemctl edit boot.mount
#     systemctl disable boot.mount
#     systemctl enable boot.mount
#
" | sudo tee -a "$ROOT/etc/fstab"


if [ -z "$CONFIG_NFS_HOME" ]; then
echo "
[Unit]
Description=Mount /home over NFS
After=network.target
Before=remote-fs.target

[Mount]
Where=/home
Type=nfs4
Options=rw,async,noatime,nodiratime,vers=4.2,ac,rsize=4096,wsize=4096

[Install]
WantedBy=multi-user.target
" | sudo tee "$ROOT/etc/systemd/system/home.mount"
mkdir "$ROOT/etc/systemd/system/home.mount.d"
echo "
#
# Overrides for /home mount. At the very minimum
# you need to uncomment and edit line specifing
# NFS export to mount (What=)
#
# Once done, test it with
#
#     systemctl start home.mount
#
# and enable it with
#
#     systemctl enable home.mount
#
[Mount]
#What=<nfs export to mount as /home>
" | sudo tee "$ROOT/etc/systemd/system/home.mount.d/override.conf"

chroot "${ROOT}" systemctl disable home.mount

echo "
#
# If you wish to mount /home over NFS (or SMB/CIFS), please modify accordingly
# using
#
#    sudo systemctl edit home.mount
#
# At minimum, you'd need to specify 'What=server:/export'
# After that, enable the mount by
#
#   sudo systemctl enable home.mount
#
" | sudo tee -a "$ROOT/etc/fstab"

else
echo "
[Unit]
Description=Mount /home over NFS
After=network.target
Before=remote-fs.target

[Mount]
What=$CONFIG_NFS_HOME
Where=/home
Type=nfs4
Options=rw,async,noatime,nodiratime,vers=4.2,ac,rsize=4096,wsize=4096

[Install]
WantedBy=multi-user.target
" | sudo tee "$ROOT/etc/systemd/system/home.mount"
chroot "${ROOT}" systemctl enable home.mount

echo "
#
# /home is auto-mounted using 'home.mount' unit
#
# To modify, disable or enable mount of /home, use
#
#     systemctl edit home.mount
#     systemctl disable home.mount
#     systemctl enable home.mount
#

" | sudo tee -a "$ROOT/etc/fstab"
fi
