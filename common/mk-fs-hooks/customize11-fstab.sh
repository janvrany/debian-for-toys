#!/bin/bash
#
# Create default /etc/fstab
#

source "$(dirname $(realpath ${BASH_SOURCE[0]}))/../../3rdparty/toolbox/functions.sh"
config "$(dirname $0)/../config.sh" || error "Cannot read config.sh: $1"
config "$(dirname $0)/../config-local.sh"
ensure_ROOT $1

#
# Config variables
#

#
# Create default /etc/fstab
#
echo "
proc                /proc       proc    defaults            0       0
sysfs               /sys        sysfs   defaults,nofail     0       0
devpts              /dev/pts    devpts  defaults,nofail     0       0

#
# Uncomment and edit line below to mount home over NFS
#
#server:/export     /home       nfs4    noatime,async       0       0
" | sudo tee "$ROOT/etc/fstab"