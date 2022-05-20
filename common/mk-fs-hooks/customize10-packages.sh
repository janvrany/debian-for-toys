#!/bin/bash

ROOT="$1"

set -e
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated update
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
    isc-dhcp-client adduser apt base-files base-passwd bash bsdutils \
    coreutils dash debconf debian-archive-keyring debian-ports-archive-keyring \
    debianutils diffutils dpkg e2fsprogs findutils gpgv grep gzip \
    hostname init-system-helpers libbz2-1.0 libc-bin libc6 libffi-dev libgcc1 \
    libgmp10 liblz4-1 liblzma5 libncursesw5 libstdc++6 login mawk \
    mount ncurses-base ncurses-bin passwd perl-base sed tar \
    tzdata util-linux zlib1g nano wget busybox net-tools ifupdown \
    iputils-ping ntp lynx dialog ca-certificates less \
    build-essential apt-utils openssh-server openssh-client \
    nfs-client sudo bash-completion tmux adduser acl socat git vim ethtool \
    texinfo python3-dev flex bison libexpat1-dev libncurses-dev gawk \
    libncurses5-dev libncursesw5-dev procps udev locales zip unzip \
    lsb-release dbus \
    # libgnutls30 \

# When installing systemd, we have to umount /proc in
# chroot. This is because setting ACLs on guestmount-mounted
# filesystem does not work - despite using acl,user_xattr ext4
# options. Umounting /proc causes postinst script to skip
# ACL setting.
#
# See https://salsa.debian.org/systemd-team/systemd/-/blob/debian/master/debian/systemd.postinst#L46-L53
#
# Sigh!
chroot "${ROOT}" umount /proc
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
    systemd systemd-sysv
chroot "${ROOT}" mount -t proc proc /proc

# Following are needed for OMR / OpenJ9
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
    cmake \
    libdwarf-dev libelf-dev \
    libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev \
    libasound2-dev libcups2-dev libfontconfig1-dev ccache

chroot "${ROOT}" dpkg --configure -a
