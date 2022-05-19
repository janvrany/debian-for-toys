#!/bin/bash

ROOT="$1"
ARCH=$(chroot "${ROOT}" dpkg --print-architecture)
RELEASE=$(chroot "${ROOT}" lsb_release -c | cut -f 2)

cat >${ROOT}/etc/fstab <<EOF
proc                /proc       proc    defaults            0       0
sysfs               /sys        sysfs   defaults,nofail     0       0
devpts              /dev/pts    devpts  defaults,nofail     0       0

#
# Uncomment and edit line below to mount home over NFS
#
#server:/export     /home       nfs4    noatime,async       0       0
EOF


cat >${ROOT}/etc/network/interfaces.d/lo <<EOF
auto lo
iface lo inet loopback
EOF

cat >${ROOT}/etc/network/interfaces.d/enp0s0 <<EOF
auto enp0s0
iface enp0s0 inet dhcp
EOF

echo "debian-${RELEASE}-${ARCH}" > "${ROOT}/etc/hostname"

chroot "${ROOT}" apt autoremove

echo "Enter password for user 'root', i.e, \"root\" (no quotes):"
chroot "${ROOT}" /usr/bin/passwd root

if [ ! -z "$SUDO_USER" ]; then
	# Since this is a hook, $SUDO_USER is likely to be 'root'.
	# In that case, we try to detect real user that called
	# mk-os.sh differently, using admittedly a super-hacky way...
	if [ "$SUDO_USER" == "root" ]; then
		if [ ! -z "$XAUTHORITY" ]; then
			USER_ID=$(echo "$XAUTHORITY" | cut -d / -f 4)
			USER=$(id --user --name "$USER_ID" 2>/dev/null || echo "$SUDO_USER")
		fi
	else
		USER=$SUDO_USER
	fi
	HOME=$(grep $USER /etc/passwd | cut -d : -f 6)
fi

if [ "$USER" != "root" ]; then
	echo "Creating user $USER..."
	chroot "${ROOT}" groupadd --gid=$(id --group $USER) $(id --group --name $USER) || true
	chroot "${ROOT}" useradd --create-home --uid $(id --user $USER) --gid=$(id --group $USER) $USER
	HOME_IN_ROOT="$ROOT/$(grep $USER "${ROOT}/etc/passwd" | cut -d : -f 6)"

	echo "Enter password for user '$USER':"
	chroot "${ROOT}" /usr/bin/passwd $USER
	chroot "${ROOT}" /usr/bin/chsh -s /bin/bash $USER
	cat >${ROOT}/etc/sudoers.d/$USER <<EOF
${USER}     ALL=(ALL:ALL) ALL
EOF
	# Install SSH keys
	for pubkey in id_rsa.pub id_dsa.pub; do
		if [ -r "$HOME/.ssh/$pubkey" ]; then
			mkdir -p "$HOME_IN_ROOT/.ssh"
			cat "$HOME/.ssh/$pubkey" >> "$HOME_IN_ROOT/.ssh/authorized_keys"
			chmod -R go-rwx "$HOME_IN_ROOT/.ssh"
			chown -R $(id --user $USER) "$HOME_IN_ROOT/.ssh"
		fi
	done
fi