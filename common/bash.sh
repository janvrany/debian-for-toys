#/bin/bash

set -e

. $(dirname $0)/../../common/functions.sh

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"
unbind_filesystems

sudo arch-chroot "${ROOT}"