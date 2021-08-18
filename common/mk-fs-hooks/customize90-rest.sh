#!/bin/bash

ROOT="$1"
ARCH=$(chroot "${ROOT}" dpkg --print-architecture)

sudo sh -c "cat >${ROOT}/etc/fstab <<EOF
proc                /proc       proc    defaults            0       0
sysfs               /sys        sysfs   defaults,nofail     0       0
devpts              /dev/pts    devpts  defaults,nofail     0       0

#
# Uncomment and edit line below to mount home over NFS
#
#server:/export     /home       nfs4    noatime,async       0       0


EOF
"

sudo sh -c "cat >${ROOT}/etc/network/interfaces <<EOF
source-directory /etc/network/interfaces.d
auto lo
iface lo inet loopback

auto enp0s0
iface enp0s0 inet dhcp
EOF
"

sudo sh -c "echo \"debian-testing-${ARCH}\" > \"${ROOT}/etc/hostname\""

chroot "${ROOT}" apt autoremove

echo "Enter password for user 'root', i.e, \"root\" (no quotes):"
chroot "${ROOT}" /usr/bin/passwd root

if [ "$USER" != "root" ]; then
	echo "Creating user $USER..."
	chroot "${ROOT}" useradd --create-home --uid $(id --user) $USER

	echo "Enter password for user '$USER':"
	chroot "${ROOT}" /usr/bin/passwd $USER
	chroot "${ROOT}" /usr/bin/chsh -s /bin/bash $USER
	sudo sh -c "cat >${ROOT}/etc/sudoers.d/$USER <<EOF
${USER}     ALL=(ALL:ALL) ALL
EOF
"
fi

