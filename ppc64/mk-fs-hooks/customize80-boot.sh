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
# Install kernel and grub
#
chroot "${ROOT}" /usr/bin/apt-get --allow-unauthenticated -y install \
	linux-image-generic \
	grub2

#
# Install grub modules
#
sudo cp -ar "${ROOT}/usr/lib/grub/powerpc-ieee1275" "${ROOT}/boot/grub"
