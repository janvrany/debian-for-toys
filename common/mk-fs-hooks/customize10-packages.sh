#!/bin/bash

ROOT="$1"

set -e
chroot "${ROOT}" /usr/bin/apt-get update
chroot "${ROOT}" /usr/bin/apt-get -y install \
    isc-dhcp-client adduser apt base-files base-passwd bash bsdutils \
    coreutils dash debconf debian-archive-keyring debian-ports-archive-keyring \
    debianutils diffutils dpkg e2fsprogs findutils gpgv grep gzip \
    hostname init-system-helpers libbz2-1.0 libc-bin libc6 libffi-dev libgcc1 \
    libgmp10 libgnutls30 liblz4-1 liblzma5 libncursesw5 libstdc++6 login mawk \
    mount ncurses-base ncurses-bin passwd perl-base sed systemd systemd-sysv tar \
    tzdata util-linux zlib1g nano wget busybox net-tools ifupdown \
    iputils-ping ntp lynx dialog ca-certificates less \
    build-essential apt-utils openssh-server openssh-client \
    nfs-client sudo bash-completion tmux adduser acl socat git vim ethtool \
    texinfo python3-dev flex bison libexpat1-dev libncurses-dev gawk \
    libncurses5-dev libncursesw5-dev procps udev locales zip unzip

# Following are needed for OMR / OpenJ9
chroot "${ROOT}" /usr/bin/apt-get -y install \
    cmake \
    libdwarf-dev libelf-dev \
    libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev \
    libasound2-dev libcups2-dev libfontconfig1-dev ccache

chroot "${ROOT}" dpkg --configure -a